classdef BeamProp < mni.bulk.BulkData
    %BeamProp Describes the properties of a bulk.Beam object.
    %
    % The definition of the 'BeamProp' object matches that of the PBEAM
    % bulk data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'PBEAM'
    %   - 'PBAR'
    %   - 'PROD'
    %   - 'PBARL'  (cross-section dimensions, see mni.bulk.beamSection)
    %   - 'PBEAML' (cross-section dimensions at end A, stations and end B)
        
    properties (Hidden = true)
        %PBEAM intermediate stations (0 < X/XB < 1), one cell per entry
        %holding a struct array (SO, X_XB, A, I1, I2, I12, J, NSM, C, D, E, F)
        %PBEAML: all stations incl. end B, struct array (SO, X_XB, DIM, NSM)
        Stations = {};
        %PBARL / PBEAML dimensions and NSM of end A, one cell per entry
        DIM = {};
        NSMA = [];
    end
    
    methods % constructor
        function obj = BeamProp(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'PBAR', ...
                'BulkProps'  , {'PID', 'MID', 'A', 'I1', 'I2', 'J', 'NSM',      'C', 'D', 'E', 'F', 'K', 'I12'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'r', 'r' , 'r' , 'r', 'r'  , 'b', 'r', 'r', 'r', 'r', 'r', 'r'}  , ...
                'PropDefault', {''   , ''   , 0  ,  0  , 0   , 0  , 0    , 0  , 0  , 0  , 0  , 0  , 0}    , ...
                'IDProp'     , 'PID', ...
                'PropMask'   , {'C', 2, 'D', 2, 'E', 2, 'F', 2, 'K', 2}, ...
                'Connections', {'MID', 'mni.bulk.Material', 'Materials'}, ...
                'AttrList'   , { ...
                'A', {'nonnegative'}, 'I1' , {'nonnegative'}, 'I2' , {'nonnegative'}, ...
                'J', {'nonnegative'}, 'C'  , {'nrows', 2}   , 'NSM', {'nonnegative'}, ...
                'D', {'nrows', 2}   , 'E'  , {'nrows', 2}   , 'F'  , {'nrows', 2}   , ...
                'K', {'nrows', 2}});
            addBulkDataSet(obj, 'PBEAM', ...
                'BulkProps'  , { ...
                'PID', 'MID', 'A_A', 'I1_A', 'I2_A', 'I12_A', 'J_A', 'NSM_A', ...
                'C_A', 'D_A', 'E_A', 'F_A', ...
                'SO', 'X_XB', 'A_B', 'I1_B', 'I2_B', 'I12_B', 'J_B', 'NSM_B', ...
                'C_B', 'D_B', 'E_B', 'F_B', ...
                'K', 'S', 'NSIA', 'NSIB', 'CW', ...
                'M_A', 'M_B', 'N_A', 'N_B'}, ...
                'PropTypes'  , { ...
                'i', 'i', 'r', 'r', 'r', 'r', 'r', 'r', ...
                'r', 'r', 'r', 'r', ...
                'c', 'r', 'r', 'r', 'r', 'r', 'r', 'r', ...
                'r', 'r', 'r', 'r', ...
                'r', 'r', 'r', 'r', 'r', ...
                'r', 'r', 'r', 'r'}, ...
                'PropDefault', { ...
                '', '', '', '', '', 0, 0, 0,  ...
                0 , 0 , 0 , 0 , ...
                '', '', 0 , 0 , 0 , 0, 0, 0, ...
                0 , 0 , 0 , 0 , ...
                1, 0, 0, 0, 0 , ...
                0, 0, 0, 0}, ...
                'PropMask'   , { ...
                'C_A', 2, 'D_A', 2, 'E_A', 2, 'F_A', 2, ...
                'C_B', 2, 'D_B', 2, 'E_B', 2, 'F_B', 2, ...
                'K'  , 2, 'S'  , 2, 'CW' , 2, 'M_A', 2, ...
                'M_B', 2, 'N_A', 2, 'N_B', 2}, ...
                'IDProp'     , 'PID', ...
                'Connections', {'MID', 'mni.bulk.Material', 'Materials'}, ...
                'AttrList'   , { ...
                'A_A' , {'nonnegative'}, 'I1_A', {'nonnegative'} , ...
                'I2_A', {'nonnegative'}, ...
                'J_A' , {'nonnegative'}, 'NSM_A', {'nonnegative'}, ...
                'C_A' , {'nrows', 2}   , 'D_A'  , {'nrows', 2}   , ...
                'E_A' , {'nrows', 2}   , 'F_A'  , {'nrows', 2}   , ...
                'A_B' , {'nonnegative'}, 'I1_B' , {'nonnegative'}, ...
                'I2_B', {'nonnegative'}, ...
                'J_B', {'nonnegative'} , 'NSM_B', {'nonnegative'}, ...
                'C_B', {'nrows', 2}    , 'D_B'  , {'nrows', 2}   , ...
                'E_B', {'nrows', 2}    , 'F_B'  , {'nrows', 2}   , ...
                'K'  , {'nrows', 2}    , 'S'    , {'nrows', 2}   , ...
                'CW' , {'nrows', 2}    , 'M_A'  , {'nrows', 2}   , ...
                'M_B', {'nrows', 2}    , 'N_A'  , {'nrows', 2}   , ...
                'N_B', {'nrows', 2}});
            addBulkDataSet(obj, 'PROD', ...
                'BulkProps'  , {'PID', 'MID', 'A', 'J', 'C', 'NSM'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'r', 'r', 'r', 'r'  }, ...
                'PropDefault', {''   , ''   , '' , 0  , 0  , 0    }, ...
                'IDProp'     , 'PID', ...
                'Connections', {'MID', 'mni.bulk.Material', 'Materials'});
            addBulkDataSet(obj, 'PBARL', ...
                'BulkProps'  , {'PID', 'MID', 'GROUP', 'TYPE'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'c'    , 'c'   }, ...
                'PropDefault', {''   , ''   , 'MSCBML0', ''  }, ...
                'IDProp'     , 'PID', ...
                'Connections', {'MID', 'mni.bulk.Material', 'Materials'});
            addBulkDataSet(obj, 'PBEAML', ...
                'BulkProps'  , {'PID', 'MID', 'GROUP', 'TYPE'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'c'    , 'c'   }, ...
                'PropDefault', {''   , ''   , 'MSCBML0', ''  }, ...
                'IDProp'     , 'PID', ...
                'Connections', {'MID', 'mni.bulk.Material', 'Materials'});
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            if any(strcmp(obj.CardName, {'PBARL', 'PBEAML'}))
                obj.BulkAssignFunction = @assignDimData;
                obj.EntryProps = {'DIM', 'NSMA', 'Stations'};
                obj.DIM      = cell(1, obj.NumBulk);
                obj.NSMA     = zeros(1, obj.NumBulk);
                obj.Stations = cell(1, obj.NumBulk);
            end
            
            if strcmp(obj.CardName, 'PBEAM')
                obj.BulkAssignFunction = @assignPBeamData;
                obj.EntryProps = {'Stations'};
                obj.Stations   = cell(1, obj.NumBulk);
            end
            
        end
    end
    
    methods (Static)
        function n = numDims(type)
            %numDims Number of DIMi of a PBARL / PBEAML cross-section type.
            t = {'ROD', 1; 'TUBE', 2; 'TUBE2', 2; 'I', 6; 'CHAN', 4; 'T', 4; 'BOX', 4; ...
                'BAR', 2; 'CROSS', 4; 'H', 4; 'T1', 4; 'I1', 4; 'CHAN1', 4; 'Z', 4; ...
                'CHAN2', 4; 'T2', 4; 'BOX1', 6; 'HEXA', 3; 'HAT', 4; 'HAT1', 5; ...
                'DBOX', 10; 'L', 4};
            k = find(strcmpi(t(:, 1), strtrim(type)), 1);
            assert(~isempty(k), 'mni:bulk:BeamProp', 'Unknown cross-section TYPE ''%s''.', type);
            n = t{k, 2};
        end
    end

    methods % assigning data during import
        function assignH5BulkData(obj, bulkNames, bulkData)
            %assignH5BulkData Assigns the object data during the import
            %from a .h5 file.
            
            prpNames   = obj.CurrentBulkDataProps;
            
            %Build the prop data 
            prpData       = cell(size(prpNames));            
            prpData(ismember(prpNames, bulkNames)) = bulkData(ismember(bulkNames, prpNames));
            switch obj.CardName
                case 'PBAR' 
                    prpData{ismember(prpNames, 'C')}   = vertcat(bulkData{ismember(bulkNames, {'C1', 'C2'})});
                    prpData{ismember(prpNames, 'D')}   = vertcat(bulkData{ismember(bulkNames, {'D1', 'D2'})});
                    prpData{ismember(prpNames, 'E')}   = vertcat(bulkData{ismember(bulkNames, {'E1', 'E2'})});
                    prpData{ismember(prpNames, 'F')}   = vertcat(bulkData{ismember(bulkNames, {'F1', 'F2'})});
                    prpData{ismember(prpNames, 'K')}   = vertcat(bulkData{ismember(bulkNames, {'K1', 'K2'})});
                case 'PBEAM'
                    %SO must be "YES" "YESA" or "NO"
                    %   - Assume true is "YES" and false is "NO"
                    idxSO = ismember(prpNames, 'SO');
                    prpData{idxSO} = prpData{idxSO}(1, :); %One value per beam
                    idxYES = prpData{idxSO} == 1;
                    prpData{idxSO} = num2cell(prpData{idxSO});
                    prpData{idxSO}(idxYES)  = {'YES'};
                    prpData{idxSO}(~idxYES) = {'NO'};
                    %Combine other terms
                    %   - TODO - Should be possible to parameterise this!
                    prpData{ismember(prpNames, 'A_A')}   = bulkData{ismember(bulkNames, 'A')}(1, :);
                    prpData{ismember(prpNames, 'I1_A')}  = bulkData{ismember(bulkNames, 'I1')}(1, :);
                    prpData{ismember(prpNames, 'I2_A')}  = bulkData{ismember(bulkNames, 'I2')}(1, :);
                    prpData{ismember(prpNames, 'I12_A')} = bulkData{ismember(bulkNames, 'I12')}(1, :);
                    prpData{ismember(prpNames, 'J_A')}   = bulkData{ismember(bulkNames, 'J')}(1, :);
                    prpData{ismember(prpNames, 'NSM_A')} = bulkData{ismember(bulkNames, 'NSM')}(1, :);
                    prpData{ismember(prpNames, 'C_A')}   =  ...
                        [bulkData{ismember(bulkNames, 'C1')}(1, :) ; bulkData{ismember(bulkNames, 'C2')}(1, :) ];
                    prpData{ismember(prpNames, 'D_A')}   =  ...
                        [bulkData{ismember(bulkNames, 'D1')}(1, :) ; bulkData{ismember(bulkNames, 'D2')}(1, :) ];
                    prpData{ismember(prpNames, 'E_A')}   =  ...
                        [bulkData{ismember(bulkNames, 'E1')}(1, :) ; bulkData{ismember(bulkNames, 'E2')}(1, :) ];
                    prpData{ismember(prpNames, 'F_A')}   =  ...
                        [bulkData{ismember(bulkNames, 'F1')}(1, :) ; bulkData{ismember(bulkNames, 'F2')}(1, :) ];
                    prpData{ismember(prpNames, 'X_XB')} = ones(1, obj.NumBulk);
                    prpData{ismember(prpNames, 'A_B')}   = bulkData{ismember(bulkNames, 'A')}(end, :);
                    prpData{ismember(prpNames, 'I1_B')}  = bulkData{ismember(bulkNames, 'I1')}(end, :);
                    prpData{ismember(prpNames, 'I2_B')}  = bulkData{ismember(bulkNames, 'I2')}(end, :);
                    prpData{ismember(prpNames, 'I12_B')} = bulkData{ismember(bulkNames, 'I12')}(end, :);
                    prpData{ismember(prpNames, 'J_B')}   = bulkData{ismember(bulkNames, 'J')}(end, :);
                    prpData{ismember(prpNames, 'NSM_B')} = bulkData{ismember(bulkNames, 'NSM')}(end, :);
                    prpData{ismember(prpNames, 'C_B')}   =  ...
                        [bulkData{ismember(bulkNames, 'C1')}(end, :) ; bulkData{ismember(bulkNames, 'C2')}(end, :) ];
                    prpData{ismember(prpNames, 'D_B')}   =  ...
                        [bulkData{ismember(bulkNames, 'D1')}(end, :) ; bulkData{ismember(bulkNames, 'D2')}(end, :) ];
                    prpData{ismember(prpNames, 'E_B')}   =  ...
                        [bulkData{ismember(bulkNames, 'E1')}(end, :) ; bulkData{ismember(bulkNames, 'E2')}(end, :) ];
                    prpData{ismember(prpNames, 'F_B')}   =  ...
                        [bulkData{ismember(bulkNames, 'F1')}(end, :) ; bulkData{ismember(bulkNames, 'F2')}(end, :) ];
                    prpData{ismember(prpNames, 'K')}   = vertcat(bulkData{ismember(bulkNames, {'K1', 'K2'})});
                    prpData{ismember(prpNames, 'S')}   = vertcat(bulkData{ismember(bulkNames, {'S1', 'S2'})});
                    prpData{ismember(prpNames, 'CW')}   = vertcat(bulkData{ismember(bulkNames, {'CWA', 'CWB'})});
                    prpData{ismember(prpNames, 'M_A')}  = vertcat(bulkData{ismember(bulkNames, {'M1A', 'M2A'})});
                    prpData{ismember(prpNames, 'M_B')}  = vertcat(bulkData{ismember(bulkNames, {'M1B', 'M2B'})});
                    prpData{ismember(prpNames, 'N_A')}  = vertcat(bulkData{ismember(bulkNames, {'N1A', 'N2A'})});
                    prpData{ismember(prpNames, 'N_B')}  = vertcat(bulkData{ismember(bulkNames, {'N1A', 'N2A'})});
            end
            assignH5BulkData@mni.bulk.BulkData(obj, prpNames, prpData)
        end
        function assignDimData(obj, propData, index, BulkMeta)
            %assignDimData PBARL / PBEAML: PID MID GROUP TYPE on line 1,
            %then a stream of fields (QRG PBARL / PBEAML format):
            %   PBARL : DIM1 ... DIMn NSM
            %   PBEAML: DIM1(A) .. DIMn(A) NSM(A), then per station
            %           SO X/XB DIM1 .. DIMn NSM (last station X/XB = 1 = B)
            % Blank dimensions of a station take the end A values.
            f = strtrim(reshape(propData, 1, []));
            f(end + 1 : 8) = {''};
            assignCardData(obj, f(1 : 4), index, struct('Names', {BulkMeta.Names}, ...
                'Format', BulkMeta.Format(1 : 4), 'Default', {BulkMeta.Default(1 : 4)}, ...
                'Bounds', BulkMeta.Bounds(:, 1 : 4), 'ListProp', {{}}));
            nd = mni.bulk.BeamProp.numDims(obj.TYPE{index});
            st = f(9 : end);
            st(end + 1 : nd + 1) = {''};
            dimA = str2double(st(1 : nd));
            nsmA = fieldValue(st{nd + 1}, 0);
            obj.DIM{index}  = dimA;
            obj.NSMA(index) = nsmA;
            stations = struct('SO', {}, 'X_XB', {}, 'DIM', {}, 'NSM', {});
            if strcmp(obj.CardName, 'PBEAML')
                k = nd + 2;
                while k <= numel(st) && any(~cellfun(@isempty, st(k : end)))
                    g = st(k : min(end, k + nd + 2));
                    g(end + 1 : nd + 3) = {''};
                    so = upper(g{1});
                    if isempty(so)
                        so = 'YES';
                    end
                    d = str2double(g(3 : nd + 2));
                    d(isnan(d)) = dimA(isnan(d));
                    stations(end + 1) = struct('SO', so, 'X_XB', fieldValue(g{2}, 1), ...
                        'DIM', d, 'NSM', fieldValue(g{nd + 3}, nsmA)); %#ok<AGROW>
                    k = k + nd + 3;
                end
            end
            obj.Stations{index} = stations;
        end
        function s = section(obj, index, where)
            %section Section properties (A, I1, I2, I12, J, NSM, NSI) of
            %entry 'index' at end 'A' or 'B' for every BeamProp type (NSI:
            %PBEAM nonstructural mass moment of inertia, 0 for the others).
            if nargin < 3
                where = 'A';
            end
            switch obj.CardName
                case 'PBAR'
                    s = struct('A', obj.A(index), 'I1', obj.I1(index), 'I2', obj.I2(index), ...
                        'I12', obj.I12(index), 'J', obj.J(index), 'NSM', obj.NSM(index));
                case 'PROD'
                    s = struct('A', obj.A(index), 'I1', 0, 'I2', 0, 'I12', 0, ...
                        'J', obj.J(index), 'NSM', obj.NSM(index));
                case 'PBEAM'
                    e = ['_', upper(where)];
                    s = struct('A', obj.(['A', e])(index), 'I1', obj.(['I1', e])(index), ...
                        'I2', obj.(['I2', e])(index), 'I12', obj.(['I12', e])(index), ...
                        'J', obj.(['J', e])(index), 'NSM', obj.(['NSM', e])(index));
                case {'PBARL', 'PBEAML'}
                    d = obj.DIM{index};  nsm = obj.NSMA(index);
                    st = obj.Stations{index};
                    if strcmpi(where, 'B') && ~isempty(st)
                        k = find(abs([st.X_XB] - 1) < 1e-9, 1);
                        if ~isempty(k)
                            d = st(k).DIM;  nsm = st(k).NSM;
                        end
                    end
                    q = mni.bulk.beamSection(obj.TYPE{index}, d);
                    s = struct('A', q.A, 'I1', q.I1, 'I2', q.I2, 'I12', q.I12, 'J', q.J, 'NSM', nsm);
            end
            s.NSI = 0;
            if strcmp(obj.CardName, 'PBEAM')
                s.NSI = obj.(['NSI', upper(where)])(index);
            end
        end
        function assignPBeamData(obj, propData, index, ~)
            %assignPBeamData Assigns the data of one PBEAM entry following
            %the continuation rules of the QRG (PBEAM remarks 4 to 7):
            %
            %   line 1          : PID MID A I1 I2 I12 J NSM        (end A)
            %   [line 2]        : C1 C2 D1 D2 E1 E2 F1 F2          (end A)
            %                     omitted when the next line starts with SO
            %   station pairs   : SO X/XB A I1 I2 I12 J NSM
            %                     [C1 .. F2] only when SO = 'YES'
            %   [K line]        : K1 K2 S1 S2 NSI(A) NSI(B) CW(A) CW(B)
            %   [M/N line]      : M1(A) M2(A) M1(B) M2(B) N1(A) N2(A) N1(B) N2(B)
            %
            % The station with X/XB = 1 is end B (blank properties take the
            % end A values). Without stations end B equals end A.
            % Intermediate stations are kept in 'Stations' (blank
            % properties interpolated between ends A and B).

            f = reshape(propData, 1, []);
            f(end + 1 : 8 * ceil(numel(f) / 8)) = {''};
            L = reshape(f, 8, [])';
            L = strtrim(L);
            while size(L, 1) > 1 && all(cellfun(@isempty, L(end, :)))
                L(end, :) = [];
            end
            nL    = size(L, 1);
            isSO  = @(s) any(strcmpi(s, {'YES', 'YESA', 'NO'}));
            num   = @(c, d) fieldValue(c, d);

            %End A
            assert(~isempty(L{1, 1}) && ~isempty(L{1, 2}), ...
                'PBEAM entry number %i: PID and MID are required.', index);
            pid = str2double(L{1, 1});
            mid = str2double(L{1, 2});
            pA  = num(L(1, 3 : 8), 0);       % A I1 I2 I12 J NSM
            r   = 2;
            cA  = zeros(1, 8);
            if r <= nL && ~isSO(L{r, 1})
                cA = num(L(r, :), 0);
                r  = r + 1;
            end

            %Stations
            st = struct('SO', {}, 'X', {}, 'P', {}, 'C', {});
            while r <= nL && isSO(L{r, 1})
                s.SO = upper(L{r, 1});
                s.X  = str2double(L{r, 2});
                s.P  = num(L(r, 3 : 8), NaN); % NaN = blank (filled below)
                r    = r + 1;
                s.C  = zeros(1, 8);
                if strcmp(s.SO, 'YES')
                    if r <= nL
                        s.C = num(L(r, :), 0);
                        r   = r + 1;
                    end
                elseif strcmp(s.SO, 'YESA')
                    s.C = cA;
                end
                st(end + 1) = s; %#ok<AGROW>
            end

            %Shear / warping / nonstructural mass lines
            kLine = num(repmat({''}, 1, 8), NaN);
            mLine = kLine;
            if r <= nL
                kLine = num(L(r, :), NaN);
                r = r + 1;
            end
            if r <= nL
                mLine = num(L(r, :), NaN);
                r = r + 1;
            end
            if r <= nL
                warning('mni:bulk:PBEAM', ...
                    'PBEAM %i: %i continuation line(s) after the M/N line ignored.', pid, nL - r + 1);
            end

            %End B
            if isempty(st)
                iB = [];
            else
                iB = find(abs([st.X] - 1) < 1e-9, 1);
                assert(~isempty(iB), ['PBEAM %i: station data given but no ', ...
                    'station with X/XB = 1.0 (end B), see QRG PBEAM remark 6.'], pid);
            end
            if isempty(iB)
                pB = pA; cB = cA; so = ''; 
            else
                pB = st(iB).P;
                pB(isnan(pB)) = pA(isnan(pB));
                cB = st(iB).C;
                so = st(iB).SO;
                st(iB) = [];
            end
            for i = 1 : numel(st) %intermediate stations: interpolate blanks
                p = st(i).P;
                p(isnan(p)) = pA(isnan(p)) + st(i).X * (pB(isnan(p)) - pA(isnan(p)));
                st(i).P = p;
            end

            K   = i_dflt(kLine(1 : 2), [1, 1]);
            S   = i_dflt(kLine(3 : 4), [0, 0]);
            nsi = i_dflt(kLine(5), 0);   nsi(2) = i_dflt(kLine(6), nsi(1));
            cw  = i_dflt(kLine(7), 0);   cw(2)  = i_dflt(kLine(8), cw(1));
            mA  = i_dflt(mLine(1 : 2), [0, 0]);
            mB  = i_dflt(mLine(3 : 4), mA);
            nA  = i_dflt(mLine(5 : 6), [0, 0]);
            nB  = i_dflt(mLine(7 : 8), nA);

            %Assign
            obj.PID(1, index)   = pid;
            obj.MID(1, index)   = mid;
            names = {'A', 'I1', 'I2', 'I12', 'J', 'NSM'};
            for i = 1 : 6
                obj.([names{i}, '_A'])(1, index) = pA(i);
                obj.([names{i}, '_B'])(1, index) = pB(i);
            end
            cdef = {'C', 'D', 'E', 'F'};
            for i = 1 : 4
                obj.([cdef{i}, '_A'])(:, index) = cA(2 * i - 1 : 2 * i)';
                obj.([cdef{i}, '_B'])(:, index) = cB(2 * i - 1 : 2 * i)';
            end
            obj.SO{1, index}     = so;
            obj.X_XB(1, index)   = 1;
            obj.K(:, index)      = K';
            obj.S(:, index)      = S';
            obj.NSIA(1, index)   = nsi(1);
            obj.NSIB(1, index)   = nsi(2);
            obj.CW(:, index)     = cw';
            obj.M_A(:, index)    = mA';
            obj.M_B(:, index)    = mB';
            obj.N_A(:, index)    = nA';
            obj.N_B(:, index)    = nB';
            if ~isempty(st)
                obj.Stations{index} = arrayfun(@(s) struct('SO', s.SO, 'X_XB', s.X, ...
                    'A', s.P(1), 'I1', s.P(2), 'I2', s.P(3), 'I12', s.P(4), 'J', s.P(5), ...
                    'NSM', s.P(6), 'C', s.C(1 : 2)', 'D', s.C(3 : 4)', 'E', s.C(5 : 6)', ...
                    'F', s.C(7 : 8)'), st);
            end

            function v = i_dflt(v, d)
                if numel(d) == 1 && numel(v) > 1
                    d = repmat(d, size(v));
                end
                v(isnan(v)) = d(isnan(v));
            end
        end
    end
    
end

