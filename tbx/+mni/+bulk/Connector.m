classdef Connector < mni.bulk.BulkData
    %Connector Bush and joint elements (QRG ch.9).
    %
    % Valid Bulk Data Types:
    %   - 'CBUSH'  : EID PID GA GB GO/X1 X2 X3 CID / S OCID S1 S2 S3
    %                (G0 form: integer in field 6, fields 7-8 blank -> 'G0')
    %   - 'PBUSH'  : PID and the "K", "B", "GE", "RCV", "M", "T" lines
    %   - 'RJOINT' : EID GA GB CB
    %
    % Blank integer / real fields that have a meaning of their own are NaN
    % (CBUSH GB blank = grounded, CID blank = orientation from X / G0).

    properties (Hidden = true)
        %CBUSH orientation grid G0 (NaN if X1-X3 given), one per entry
        G0 = [];
        %PBUSH extra keyword lines ("T"), one struct per entry
        Extra = {};
    end

    methods % construction
        function obj = Connector(varargin)
            addBulkDataSet(obj, 'CBUSH', ...
                'BulkProps'  , {'EID', 'PID', 'GA', 'GB', 'X', 'CID', 'S', 'OCID', 'SI'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'i' , 'i' , 'r', 'i'  , 'r', 'i'   , 'r' }, ...
                'PropDefault', {''   , NaN  , ''  , NaN , NaN, NaN  , 0.5, -1    , NaN }, ...
                'IDProp'     , 'EID', ...
                'PropMask'   , {'X', 3, 'SI', 3}, ...
                'AttrList'   , {'X', {'nrows', 3}, 'SI', {'nrows', 3}}, ...
                'SetMethod'  , {'PID', @validateIntOrBlank, 'GB', @validateIntOrBlank, ...
                'X', @validateRealOrBlank, 'CID', @validateIntOrBlank, ...
                'OCID', @validateIntOrBlank, 'SI', @validateRealOrBlank}, ...
                'Connections', {'PID', 'mni.bulk.Connector', 'Prop'});
            addBulkDataSet(obj, 'PBUSH', ...
                'BulkProps'  , {'PID', 'K', 'B', 'GE', 'RCV', 'MASS'}, ...
                'PropTypes'  , {'i'  , 'r', 'r', 'r' , 'r'  , 'r'   }, ...
                'PropDefault', {''   , 0  , 0  , 0   , 1    , 0     }, ...
                'IDProp'     , 'PID', ...
                'PropMask'   , {'K', 6, 'B', 6, 'GE', 6, 'RCV', 4}, ...
                'AttrList'   , {'K', {'nrows', 6}, 'B', {'nrows', 6}, 'GE', {'nrows', 6}, ...
                'RCV', {'nrows', 4}});
            addBulkDataSet(obj, 'RJOINT', ...
                'BulkProps'  , {'EID', 'GA', 'GB', 'CB'}, ...
                'PropTypes'  , {'i'  , 'i' , 'i' , 'c' }, ...
                'PropDefault', {''   , ''  , ''  , ''  }, ...
                'IDProp'     , 'EID', ...
                'SetMethod'  , {'CB', @validateDOF});
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            switch obj.CardName
                case 'CBUSH'
                    obj.BulkAssignFunction = @assignCBUSHData;
                    obj.EntryProps = {'G0'};
                    obj.G0 = nan(1, obj.NumBulk);
                case 'PBUSH'
                    obj.BulkAssignFunction = @assignPBUSHData;
                    obj.EntryProps = {'Extra'};
                    obj.Extra = cell(1, obj.NumBulk);
            end
        end
    end

    methods % assigning data during import
        function assignCBUSHData(obj, propData, index, BulkMeta)
            %assignCBUSHData CBUSH with the GO / X1 alternative (QRG CBUSH:
            %an integer in field 6 with fields 7-8 blank is the grid G0).
            f = strtrim(reshape(propData, 1, []));
            f(end + 1 : 16) = {''};
            isG0 = ~isempty(f{5}) && isempty(regexp(f{5}, '[.E]', 'once')) && ...
                isempty(f{6}) && isempty(f{7});
            g0 = NaN;
            if isG0
                g0 = str2double(f{5});
                f{5} = '';
            end
            assignCardData(obj, f, index, BulkMeta);
            obj.G0(index) = g0;
        end
        function assignPBUSHData(obj, propData, index, ~)
            %assignPBUSHData PBUSH keyword lines (QRG PBUSH): field 3 of
            %each line is "K", "B", "GE", "RCV", "M" or "T".
            f = strtrim(reshape(propData, 1, []));
            f(end + 1 : 8 * ceil(numel(f) / 8)) = {''};
            L = reshape(f, 8, [])';
            obj.PID(index) = str2double(L{1, 1});
            extra = struct();
            for r = 1 : size(L, 1)
                kw = upper(L{r, 2});
                v  = str2double(L(r, 3 : 8));
                v(cellfun(@isempty, L(r, 3 : 8))) = NaN;
                switch kw
                    case 'K'
                        obj.K(:, index)  = i_zero(v(1 : 6))';
                    case 'B'
                        obj.B(:, index)  = i_zero(v(1 : 6))';
                    case 'GE'
                        obj.GE(:, index) = i_zero(v(1 : 6))';
                    case 'RCV'
                        rcv = v(1 : 4);
                        rcv(isnan(rcv)) = 1;
                        obj.RCV(:, index) = rcv';
                    case 'M'
                        obj.MASS(index) = i_zero(v(1));
                    case ''
                        continue
                    otherwise
                        extra.(matlab.lang.makeValidName(kw)) = v;
                end
            end
            obj.Extra{index} = extra;
            function v = i_zero(v)
                v(isnan(v)) = 0;
            end
        end
    end
end
