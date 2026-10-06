classdef TestQrgBulkLayout < matlab.unittest.TestCase
    %TestQrgBulkLayout Checks that every bulk data entry Matran imports
    %reads its fields from the positions given in the MSC Nastran Quick
    %Reference Guide (QRG).
    %
    % The QRG layouts come from unit_testing/qrg/spec/qrg_bulk.json
    % (tools/qrg/extract_qrg.py). Matran layouts come from the
    % 'BulkDataProps' of the mni.bulk classes (see MatranCards.layout).
    %
    % Run:
    %   >> addpath tbx unit_testing/qrg
    %   >> runtests('TestQrgBulkLayout')

    properties (TestParameter)
        Card = TestQrgBulkLayout.matranCards();
    end

    methods (Static)
        function c = matranCards()
            try
                t = MatranCards.list();
                c = {t.Card};
            catch
                c = {''};
            end
            if isempty(c)
                c = {''};
            end
        end
    end

    methods (TestClassSetup)
        function checkSpec(tc)
            tc.assumeTrue(QrgSpec.isAvailable(), ...
                'QRG spec missing - run tools/qrg/extract_qrg.py');
        end
    end

    methods (Test)
        function fieldPositionsMatchQrg(tc, Card)
            %Every field Matran reads sits where the QRG puts it (for the
            %list entries: every field before the list).
            c = TestQrgBulkLayout.qrgCard(tc, Card);
            tc.assumeFalse(strcmp(Card, 'PBUSH'), 'PBUSH: keyword lines, see TestQrgCustomCards.');
            [pos, info] = MatranCards.layout(Card);
            n = numel(pos);
            if ~isempty(info.ListStart)
                n = info.ListStart - 1;
            end
            msgs = {};
            for iF = 1 : numel(c.formats)
                [q, rc] = QrgSpec.formatFields(Card, iF);
                bad = TestQrgBulkLayout.compare(Card, pos(1 : n), q, rc);
                if isempty(bad)
                    return %matches this format
                end
                msgs{end + 1} = sprintf('format %d: %s', iF, strjoin(bad, '; ')); %#ok<AGROW>
            end
            tc.verifyFail(sprintf('%s (QRG p.%d) field layout differs:\n  %s', ...
                Card, c.page, strjoin(msgs, '\n  ')));
        end
        function listStartsAtQrgPosition(tc, Card)
            %List entries: the list begins where the QRG says and the
            %first list fields carry the QRG names.
            c = TestQrgBulkLayout.qrgCard(tc, Card);
            [~, info] = MatranCards.layout(Card);
            tc.assumeNotEmpty(info.ListStart, 'Not a list entry.');
            tc.verifyEqual(info.ListStart, info.IntendedListStart, sprintf( ...
                ['%s: Matran starts the list at field %d (one field per ', ...
                'property before the list) but blanks / masked properties put ', ...
                'it at field %d.'], Card, info.ListStart, info.IntendedListStart));
            q = QrgSpec.formatFields(Card);
            lists = info.ListProp;
            %lists introduced by a keyword ("UM" on RBE3) are not positional
            lists = setdiff(lists, QrgNames.keywordLists(Card), 'stable');
            k = info.IntendedListStart;
            %skip blank QRG fields in front of the list (TABLE entries)
            while k <= numel(q) && QrgNames.isBlank(q{k})
                k = k + 1;
            end
            for i = 1 : numel(lists)
                tc.verifyTrue(k + i - 1 <= numel(q) && ...
                    QrgNames.matches(Card, lists{i}, q{k + i - 1}), sprintf( ...
                    '%s (QRG p.%d): list property ''%s'' expected at field %d, QRG has ''%s''.', ...
                    Card, c.page, lists{i}, k + i - 1, q{min(k + i - 1, numel(q))}));
            end
        end
        function coversQrgFields(tc, Card)
            %Every named field of the QRG (main format, before any list)
            %is read by Matran, unless listed in QrgKnownGaps.
            c = TestQrgBulkLayout.qrgCard(tc, Card);
            tc.assumeFalse(any(strcmp(Card, QrgNames.CustomParsed)), ...
                'Dedicated parser - see TestQrgCustomCards.');
            [pos, info] = MatranCards.layout(Card);
            tc.assumeEmpty(info.ListStart, 'List entry - see listStartsAtQrgPosition.');
            [q, rc] = QrgSpec.formatFields(Card);
            gaps = QrgKnownGaps.fields(Card);
            missing = {};
            for k = 1 : numel(q)
                if QrgNames.isBlank(q{k}) || QrgNames.isEtc(q{k}) || ...
                        any(strcmp(QrgNames.normalise(q{k}), QrgNames.normalise(gaps)))
                    continue
                end
                if k > numel(pos) || ~QrgNames.matches(Card, pos{k}, q{k})
                    missing{end + 1} = sprintf('%s (line %d field %d)', q{k}, rc(k, 1), rc(k, 2)); %#ok<AGROW>
                end
            end
            tc.verifyEmpty(missing, sprintf('%s (QRG p.%d): fields not read by Matran: %s', ...
                Card, c.page, strjoin(missing, ', ')));
        end
    end

    methods (Static, Access = private)
        function c = qrgCard(tc, card)
            tc.assumeNotEmpty(card, 'No Matran cards found (tbx not on path?).');
            c = QrgSpec.card(card);
            tc.assumeNotEmpty(c, sprintf('%s not in the QRG.', card));
            tc.assumeNotEmpty(c.formats, sprintf('%s: no QRG format table extracted.', card));
        end
        function bad = compare(card, pos, q, rc)
            bad = {};
            for k = 1 : numel(pos)
                if k > numel(q)
                    bad{end + 1} = sprintf('field %d ''%s'' beyond the QRG entry', k, pos{k}); %#ok<AGROW>
                elseif ~QrgNames.matches(card, pos{k}, q{k})
                    bad{end + 1} = sprintf('field %d (line %d/col %d) Matran ''%s'' vs QRG ''%s''', ...
                        k, rc(k, 1), rc(k, 2), pos{k}, q{k}); %#ok<AGROW>
                end
            end
        end
    end
end
