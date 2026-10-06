classdef TestQrgBulkExamples < matlab.unittest.TestCase
    %TestQrgBulkExamples Imports the Example entries of the MSC Nastran
    %Quick Reference Guide with mni.import_matran and checks every field
    %value Matran stores against the QRG example.
    %
    % Each QRG example is written to a temporary bulk data file in small
    % field format (continuation lines with a blank field 1). Fields left
    % blank in the example must hold the Matran default.

    properties (TestParameter)
        Card = TestQrgBulkLayout.matranCards();
    end

    properties
        TmpDir
    end

    methods (TestClassSetup)
        function setup(tc)
            tc.assumeTrue(QrgSpec.isAvailable(), ...
                'QRG spec missing - run tools/qrg/extract_qrg.py');
            tc.TmpDir = tempname;
            mkdir(tc.TmpDir);
            tc.addTeardown(@() rmdir(tc.TmpDir, 's'));
        end
    end

    methods (Test)
        function examplesImport(tc, Card)
            c = QrgSpec.card(Card);
            tc.assumeNotEmpty(c, sprintf('%s not in the QRG.', Card));
            tc.assumeFalse(any(strcmp(Card, QrgNames.CustomParsed)), ...
                'Dedicated parser - see TestQrgCustomCards.');
            tc.assumeNotEmpty(c.examples, sprintf('%s: no QRG example.', Card));
            for iE = 1 : numel(c.examples)
                [~, ~, blk] = QrgSpec.exampleFields(Card, iE);
                if blk.large_field
                    continue %large field illustration of a small field example
                end
                bad = TestQrgBulkExamples.checkExample(tc, Card, iE);
                tc.verifyEmpty(bad, sprintf('%s example %d (QRG p.%d):\n  %s\n  input:\n    %s', ...
                    Card, iE, blk.page, strjoin(bad, '\n  '), ...
                    strjoin(QrgSpec.exampleLines(Card, iE), '\n    ')));
            end
        end
    end

    methods (Static)
        function bad = checkExample(tc, card, iE)
            %checkExample Imports example 'iE' and returns mismatch messages.
            bad   = {};
            lines = QrgSpec.exampleLines(card, iE);
            vals  = QrgSpec.exampleFields(card, iE);
            file  = fullfile(tc.TmpDir, sprintf('%s_%d.bdf', lower(card), iE));
            fid   = fopen(file, 'w');
            fprintf(fid, '%s\n', lines{:});
            fclose(fid);
            ws = warning('off', 'all');
            cleanup = onCleanup(@() warning(ws));
            try
                fem = mni.import_matran(file, 'Verbose', false);
            catch err
                bad{end + 1} = sprintf('import failed: %s', err.message);
                return
            end
            clear cleanup
            if ~isprop(fem, card)
                bad{end + 1} = 'entry not imported';
                return
            end
            obj = fem.(card);
            [pos, info] = MatranCards.layout(card);
            meta = getBulkMeta(info.Object);
            n = numel(pos);
            if ~isempty(info.ListStart)
                n = info.ListStart - 1;
            end
            for k = 1 : n
                if isempty(pos{k}) || strcmp(pos{k}, 'b')
                    continue
                end
                if k <= numel(vals)
                    expStr = strtrim(vals{k});
                else
                    expStr = '';
                end
                %CBAR / CBEAM / CBUSH alternate format: field 6 holds the grid G0
                if k == 5 && any(strcmp(card, {'CBAR', 'CBEAM', 'CBUSH'})) && ...
                        isprop(obj, 'G0') && isfinite(obj.G0(1))
                    if obj.G0(1) ~= nasNum(expStr)
                        bad{end + 1} = sprintf('G0: expected %s, got %g', expStr, obj.G0(1)); %#ok<AGROW>
                    end
                    expStr = '';
                end
                [name, row] = TestQrgBulkExamples.splitName(pos{k});
                got = obj.(name);
                if iscell(got)
                    got = got{row, 1};
                else
                    got = got(row, 1);
                end
                fmt = meta.Format(meta.Format ~= 'b');
                slot = nnz(meta.Format(1 : k) ~= 'b'); %named 'b' props occupy a slot
                dflt = meta.Default{slot};
                src  = QrgNames.derivedDefault(card, pos{k});
                if isempty(expStr) && ~isempty(src)
                    [sn, sr] = TestQrgBulkExamples.splitName(src);
                    dflt = obj.(sn)(sr, 1); %QRG: blank takes the value of 'src'
                end
                msg = TestQrgBulkExamples.compareValue(fmt(slot), expStr, got, dflt);
                if ~isempty(msg)
                    bad{end + 1} = sprintf('field %d %s: %s', k, pos{k}, msg); %#ok<AGROW>
                end
            end
            %List entries: compare the list values (THRU expanded)
            if ~isempty(info.ListStart)
                bad = [bad, TestQrgBulkExamples.checkList(card, obj, info, vals)];
            end
        end
        function msg = compareValue(type, expStr, got, dflt)
            msg = '';
            if strcmp(type, 'c')
                exp = expStr;
                if isempty(exp)
                    exp = dflt;
                end
                if isnumeric(got)
                    got = num2str(got);
                end
                if ~strcmpi(strtrim(char(got)), strtrim(char(exp)))
                    msg = sprintf('expected ''%s'', got ''%s''', char(exp), char(got));
                end
                return
            end
            if isempty(expStr)
                exp = dflt;
                if ischar(exp) || isempty(exp)
                    return %no default defined (required field left blank)
                end
            else
                exp = nasNum(expStr);
            end
            if isnan(exp) && ~isempty(expStr)
                msg = sprintf('QRG value ''%s'' is not numeric but Matran expects type ''%s''', expStr, type);
                return
            end
            if ~isnumeric(got) || ~isscalar(got) || ...
                    (abs(got - exp) > 1e-9 * max(1, abs(exp)) && ~(isnan(got) && isnan(exp)))
                msg = sprintf('expected %g, got %s', exp, mat2str(got));
            end
        end
        function bad = checkList(card, obj, info, vals)
            bad = {};
            lists = info.ListProp;
            raw = vals(info.IntendedListStart : end);
            raw = strtrim(raw(~cellfun(@isempty, strtrim(raw))));
            raw = raw(~strcmpi(raw, 'ENDT'));
            if strcmp(card, 'RBE3') || isempty(raw)
                return %RBE3 groups are checked by TestQrgRigidElements
            end
            if strcmp(card, 'RBE2')
                %QRG: ALPHA, TREF follow the GM list (first real number)
                iReal = find(~cellfun(@isempty, regexp(raw, '[.eE]', 'once')), 1);
                if ~isempty(iReal)
                    tail = raw(iReal : end);
                    raw  = raw(1 : iReal - 1);
                    if abs(obj.ALPHA - nasNum(tail{1})) > 1e-12 * abs(nasNum(tail{1}))
                        bad{end + 1} = sprintf('ALPHA: expected %s, got %g', tail{1}, obj.ALPHA);
                    end
                end
            end
            %expand THRU
            num = {};
            for i = 1 : numel(raw)
                if strcmpi(raw{i}, 'THRU')
                    a = nasNum(raw{i - 1}); b = nasNum(raw{i + 1});
                    num = [num, num2cell(a + 1 : b - 1)]; %#ok<AGROW>
                else
                    num{end + 1} = nasNum(raw{i}); %#ok<AGROW>
                end
            end
            num = [num{:}];
            nL = numel(lists);
            for i = 1 : nL
                exp = num(i : nL : end);
                got = obj.(lists{i});
                if iscell(got)
                    got = got{1};
                end
                got = got(:)';
                if ~isequal(size(got), size(exp)) || any(abs(got - exp) > 1e-9 * max(1, abs(exp)))
                    bad{end + 1} = sprintf('list %s: expected %s, got %s', lists{i}, ...
                        mat2str(exp), mat2str(got)); %#ok<AGROW>
                end
            end
        end
        function [name, row] = splitName(p)
            tok = regexp(p, '^(\w+)\((\d+)\)$', 'tokens', 'once');
            if isempty(tok)
                name = p; row = 1;
            else
                name = tok{1}; row = str2double(tok{2});
            end
        end
    end
end
