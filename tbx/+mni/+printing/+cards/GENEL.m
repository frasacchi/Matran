classdef GENEL < mni.printing.cards.BaseCard
    %GENEL Defines a general element (GENEL) card for NASTRAN.
    %   The required input is the UI list and the lower triangular portion of [K] or [Z].
    %   Optional input includes the UD list and [S].
    
    properties
        EID;          % Unique element identification number
        UI_List;      % Nx2 matrix of [GridID, ComponentID] for independent DoFs
        KZ_Matrix;    % NxN Stiffness (K) or Flexibility (Z) matrix
        MatrixType;   % Character 'K' or 'Z'
        UD_List;      % Mx2 matrix of [GridID, ComponentID] for dependent DoFs (Optional)
        S_Matrix;     % MxN matrix (Optional)
    end
    
    methods
        function obj = GENEL(EID, UI_List, MatrixType, KZ_Matrix, opts)
            arguments
                EID (1,1) double {mustBeInteger, mustBePositive}
                UI_List (:,2) double {mustBeInteger, mustBeNonnegative}
                MatrixType (1,1) char {mustBeMember(MatrixType, {'K', 'Z'})}
                KZ_Matrix (:,:) double {mustBeReal}
                opts.UD_List (:,2) double {mustBeInteger, mustBeNonnegative} = [];
                opts.S_Matrix (:,:) double {mustBeReal} = [];
            end
            
            %GENEL Construct an instance of this class
            %   Required inputs:
            %   EID        - Element ID
            %   UI_List    - Nx2 Matrix of [Grid_ID, Component_ID]
            %   KZ_Matrix  - NxN Matrix (Full or Lower Triangular). 
            %                Note: Only the lower triangle is written to the file.
            %   MatrixType - 'K' for Stiffness, 'Z' for Flexibility
            %
            %   Optional Name-Value pairs:
            %   UD_List    - Mx2 Matrix of [Grid_ID, Component_ID] (Dependent)
            %   S_Matrix   - MxN Matrix relating UD to UI
            
            % --- Validation ---
            numUI = numel(num2str(UI_List(:,2)));
            
            % Check KZ dimensions
            if size(KZ_Matrix, 1) ~= numUI || size(KZ_Matrix, 2) ~= numUI
                error('GENEL:DimensionMismatch', ...
                    'KZ_Matrix must be square and its dimensions must match the number of rows in UI_List (%d).', numUI);
            end
            
            % Check S and UD consistency
            if ~isempty(opts.S_Matrix)
                if isempty(opts.UD_List)
                    error('GENEL:MissingDependency', ...
                        'UD_List must be provided if S_Matrix is provided.');
                end
                numUD = size(opts.UD_List, 1);
                if size(opts.S_Matrix, 1) ~= numUD || size(opts.S_Matrix, 2) ~= numUI
                    error('GENEL:DimensionMismatch', ...
                        'S_Matrix dimensions (%dx%d) must match Rows of UD_List (%d) and Rows of UI_List (%d).', ...
                        size(opts.S_Matrix, 1), size(opts.S_Matrix, 2), numUD, numUI);
                end
            end
            
            % Assign properties
            obj.EID = EID;
            obj.UI_List = UI_List;
            obj.KZ_Matrix = KZ_Matrix;
            obj.MatrixType = MatrixType;
            obj.UD_List = opts.UD_List;
            obj.S_Matrix = opts.S_Matrix;
            obj.Name = 'GENEL';
        end
        
        function writeToFile(obj, fid, varargin)
            %writeToFile print GENEL entry to file
            writeToFile@mni.printing.cards.BaseCard(obj, fid, varargin{:});
            
            % --- 1. Header and EID ---
            data = {obj.EID};
            format = 'i';
            
            % --- 2. UI List ---
            % Format: Grid, Comp, Grid, Comp...
            ui_flat = reshape(obj.UI_List', 1, []);
            data = [data, num2cell(ui_flat)];
            format = [format, repmat('i', 1, length(ui_flat))];
            
            % --- 3. UD List (Optional) ---
            if ~isempty(obj.UD_List)
                data = [data, {'UD'}];
                format = [format, 's'];
                
                ud_flat = reshape(obj.UD_List', 1, []);
                data = [data, num2cell(ud_flat)];
                format = [format, repmat('i', 1, length(ud_flat))];
            end
            
            % --- 4. Matrix Marker (K or Z) ---
            data = [data, {obj.MatrixType}];
            format = [format, 's'];
            
            % --- 5. KZ Matrix Values ---
            % NASTRAN Requirement: "Values ... ordered by columns from the diagonal"
            % We iterate columns (j), then rows (i) starting from diagonal (i=j)
            kz_vals = [];
            N = size(obj.KZ_Matrix, 1);
            for j = 1:N
                for i = j:N
                    kz_vals(end+1) = obj.KZ_Matrix(i,j); %#ok<AGROW>
                end
            end
            
            data = [data, num2cell(kz_vals)];
            format = [format, repmat('r', 1, length(kz_vals))];
            
            % --- 6. S Matrix (Optional) ---
            if ~isempty(obj.S_Matrix)
                data = [data, {'S'}];
                format = [format, 's'];
                
                % NASTRAN Requirement: "Values ... ordered by rows"
                % Standard row-major flattening
                s_vals = reshape(obj.S_Matrix', 1, []);
                data = [data, num2cell(s_vals)];
                format = [format, repmat('r', 1, length(s_vals))];
            end
            
            % Print using the base class method
            obj.fprint_nas(fid, format, data);
        end
    end
end