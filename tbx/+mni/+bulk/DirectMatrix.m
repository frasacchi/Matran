classdef DirectMatrix < mni.bulk.BulkData
    %DirectMatrix Direct matrix input entries (QRG ch.9 DMI, DMIG).
    %
    % Every DMI / DMIG entry (header or column) is one bulk data entry;
    % 'matrices' assembles them per matrix name.
    %
    % Valid Bulk Data Types:
    %   - 'DMI'  : header  NAME "0" FORM TIN TOUT _ M N
    %              columns NAME J I1 A(I1,J) A(I1+1,J) ... [THRU Ix] I2 A(I2,J) ...
    %   - 'DMIG' : header  NAME "0" IFO TIN TOUT POLAR _ NCOL
    %              columns NAME GJ CJ _ G1 C1 A1 [B1] G2 C2 A2 [B2] ...
    %
    % Syntax:
    %   >> m = matrices(fem.DMI);   %struct array, see the method help

    properties (Hidden = true)
        %Data fields of each entry after NAME (cellstr per entry)
        Fields = {};
    end

    methods % construction
        function obj = DirectMatrix(varargin)
            addBulkDataSet(obj, 'DMI', ...
                'BulkProps'  , {'NAME', 'J'}, ...
                'PropTypes'  , {'c'   , 'i'}, ...
                'PropDefault', {''    , 0  });
            addBulkDataSet(obj, 'DMIG', ...
                'BulkProps'  , {'NAME', 'GJ'}, ...
                'PropTypes'  , {'c'   , 'i' }, ...
                'PropDefault', {''    , 0   });
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            obj.BulkAssignFunction = @assignMatrixData;
            obj.EntryProps = {'Fields'};
            obj.Fields = cell(1, obj.NumBulk);
        end
    end

    methods
        function assignMatrixData(obj, propData, index, ~)
            f = strtrim(reshape(propData, 1, []));
            f(end + 1 : 2) = {''};
            obj.NAME{index} = f{1};
            if strcmp(obj.CardName, 'DMI')
                obj.J(index) = str2double(f{2});
            else
                obj.GJ(index) = str2double(f{2});
            end
            last = find(~cellfun(@isempty, f), 1, 'last');
            obj.Fields{index} = f(2 : max(last, 2));
        end
        function m = matrices(obj)
            %matrices Assembled matrices, struct array with fields
            %   Name, Form, Tin, Tout, M, N, Data (DMI: M x N matrix)
            %   Name, IFO, Tin, Tout, Polar, NCOL, Entries (DMIG: table
            %   with GJ, CJ, GI, CI, A, B)
            names = unique(obj.NAME, 'stable');
            if strcmp(obj.CardName, 'DMI')
                m = struct('Name', {}, 'Form', {}, 'Tin', {}, 'Tout', {}, ...
                    'M', {}, 'N', {}, 'Data', {});
            else
                m = struct('Name', {}, 'IFO', {}, 'Tin', {}, 'Tout', {}, ...
                    'Polar', {}, 'NCOL', {}, 'Entries', {});
            end
            for k = 1 : numel(names)
                idx = find(strcmp(obj.NAME, names{k}));
                if strcmp(obj.CardName, 'DMI')
                    m(end + 1) = i_dmi(names{k}, obj.Fields(idx)); %#ok<AGROW>
                else
                    m(end + 1) = i_dmig(names{k}, obj.Fields(idx)); %#ok<AGROW>
                end
            end
        end
    end
end

function m = i_dmi(name, F)
%i_dmi DMI header + column entries (QRG DMI remarks 5-9, 13)
isHdr = cellfun(@(f) strcmp(f{1}, '0'), F);
assert(nnz(isHdr) == 1, 'mni:bulk:DMI', 'DMI %s: expected one header entry.', name);
h = F{isHdr};
h(end + 1 : 8) = {''};
form = str2double(h{2}); tin = str2double(h{3}); tout = str2double(h{4});
M = str2double(h{6}); N = str2double(h{7});
cplx = any(tin == [3, 4]);
A = zeros(M, N);
for c = find(~isHdr)
    f = F{c};
    j = str2double(f{1});
    tok = f(2 : end);
    tok = tok(~cellfun(@isempty, tok));
    row = NaN; k = 1;
    while k <= numel(tok)
        t = tok{k};
        if isempty(regexp(t, '[.E]', 'once')) && ~strcmp(t, 'THRU') %row index
            row = str2double(t);
            k = k + 1;
            continue
        end
        if strcmp(t, 'THRU') %repeat the last value through row tok{k+1}
            last = str2double(tok{k + 1});
            A(row : last, j) = A(row - 1, j);
            row = last + 1;
            k = k + 2;
            continue
        end
        if cplx
            v = complex(str2double(t), str2double(tok{k + 1}));
            k = k + 2;
        else
            v = str2double(t);
            k = k + 1;
        end
        A(row, j) = v;
        row = row + 1;
    end
end
m = struct('Name', name, 'Form', form, 'Tin', tin, 'Tout', tout, 'M', M, 'N', N, 'Data', A);
end

function m = i_dmig(name, F)
%i_dmig DMIG header + column entries (QRG DMIG)
isHdr = cellfun(@(f) strcmp(f{1}, '0'), F);
assert(nnz(isHdr) == 1, 'mni:bulk:DMIG', 'DMIG %s: expected one header entry.', name);
h = F{isHdr};
h(end + 1 : 8) = {''};
tin = str2double(h{3});
cplx = any(tin == [3, 4]);
E = zeros(0, 6);
for c = find(~isHdr)
    f = F{c};
    f(end + 1 : 8) = {''};
    gj = str2double(f{1}); cj = str2double(f{2});
    tok = f(4 : end);      %G1 C1 A1 [B1] ... (field 5 of the entry blank)
    tok(end + 1 : 4 * ceil(numel(tok) / 4)) = {''};
    per = 3 + cplx;
    if ~cplx
        %entries come in groups of 4 fields with the B field blank
        per = 4;
    end
    for k = 1 : per : numel(tok) - 2
        if isempty(tok{k})
            continue
        end
        b = 0;
        if cplx
            b = str2double(tok{k + 3});
        end
        ci = str2double(tok{k + 1});
        E(end + 1, :) = [gj, i_zero(cj), str2double(tok{k}), i_zero(ci), ...
            str2double(tok{k + 2}), i_zero(b)]; %#ok<AGROW>
    end
end
m = struct('Name', name, 'IFO', str2double(h{2}), 'Tin', tin, 'Tout', str2double(h{4}), ...
    'Polar', str2double(h{5}), 'NCOL', str2double(h{7}), ...
    'Entries', array2table(E, 'VariableNames', {'GJ', 'CJ', 'GI', 'CI', 'A', 'B'}));
end

function v = i_zero(v)
%i_zero Blank component (scalar point) / imaginary part -> 0
if isnan(v)
    v = 0;
end
end
