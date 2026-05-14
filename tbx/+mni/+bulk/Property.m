classdef Property < mni.bulk.BulkData
    %Property Describes the properties of a bulk data element.
    %
    % Valid Bulk Data Types:
    %   - PSHELL
    %

    methods % constructor
        function obj = Property(varargin)

            %Initialise the bulk data sets
            addBulkDataSet(obj, 'PSHELL'   , ...
                'BulkProps'  , {'PID', 'MID1', 'T', 'MID2', 'BK', 'MID3', 'TS', 'NSM', 'Z1', 'Z2', 'MID4'}, ...
                'PropTypes'  , {'i'  , 'i'   , 'r', 'i'   , 'r'     , 'i'   , 'r'   , 'r'  , 'r' , 'r' , 'i'   }, ...
                'PropDefault', {''   , ''    , 0  , 0     , 1       , 0     , .8333 , 0    , 0   , 0   , 0     }, ...
                'IDProp'     , 'PID');

            addBulkDataSet(obj, 'PCOMP'   , ...
                'BulkProps'  , {'PID', 'Z0', 'NSM', 'SB', 'FT', 'TREF', 'GE', 'LAM', 'MIDi', 'Ti', 'THETAi', 'SOUTi'}, ...
                'PropTypes'  , {'i'  , 'r' , 'r'  , 'r' , 'c' , 'r'   , 'r' , 'c'  , 'i'   , 'r' , 'r'     , 'c'    }, ...
                'PropDefault', {''   , -0.5, 0    , 0   , ''  , 0     , 0   , ''   , []    , []  , []      , {} }, ...
                'IDProp'     , 'PID', ...
                'ListProp'   , {'MIDi', 'Ti', 'THETAi', 'SOUTi'});

            varargin = parse(obj, varargin{:});
            preallocate(obj);

        end
    end

    methods % visualisation
        function hg = drawElement(obj, FEModel, hAx, varargin)
            % Parse inputs
            p = inputParser;
            addParameter(p, 'DrawEdge', false, @(x)validateattributes(x, {'logical'}, {'scalar'}));
            parse(p, varargin{:});
            hg = gobjects(0);

            % Get shell objects from the model
            bulkNames = FEModel.BulkDataNames;
            bulkData = get(FEModel, bulkNames);
            isShell = cellfun(@(x)isa(x, 'mni.bulk.Shell'), bulkData);
            if ~any(isShell)
                return
            end
            shellObjs = bulkData(isShell);
            prp_obj = obj;

            % --- MODIFICATION 1: Use a single, global source for vertices ---
            % All node indices refer to the main grid object in the FEModel.
            if isempty(FEModel.GRID)
                return % No nodes to plot
            end
            all_vertices = FEModel.GRID.getDrawCoords('Mode', 'undeformed')';

            % --- MODIFICATION 2: Data storage for different element shapes ---
            % Create sub-fields to store triangular and quadrilateral faces separately.
            face_data = struct('PSHELL', struct('Tri', [], 'Quad', []), ...
                'PCOMP',  struct('Tri', [], 'Quad', []));

            for i_shl = 1:numel(shellObjs)
                shell_obj = shellObjs{i_shl};
                if isempty(shell_obj) || shell_obj.NumBulk == 0
                    continue
                end

                [used_pids, ~, shell_idx_map] = unique(shell_obj.PID);

                for i_pid = 1:numel(used_pids)
                    pid = used_pids(i_pid);
                    if isnan(pid) || pid == 0
                        continue;
                    end

                    prp_idx = find(prp_obj.PID == pid, 1);
                    if isempty(prp_idx)
                        continue;
                    end

                    prpCardName = prp_obj.CardName;
                    if ~isfield(face_data, prpCardName)
                        continue
                    end

                    shl_indices = find(shell_idx_map == i_pid);
                    node_indices = shell_obj.NodesIndex(:, shl_indices)';

                    if isempty(node_indices)
                        continue;
                    end

                    [n_rows, n_cols] = size(node_indices);

                    if n_cols == 3
                        is_tri = true(n_rows, 1);
                        
                    elseif n_cols == 4
                        is_tri = isnan(node_indices(:, 4)) | (node_indices(:, 4) == 0);
                        
                    else
                        continue;
                    end

                    % Use the logical vector to partition the faces
                    tri_faces = node_indices(is_tri, 1:3);
                    quad_faces = node_indices(~is_tri, :); % Explicitly take 4 nodes

                    % % Identify triangles: 4th node ID is NaN
                    % is_tri = length(node_indices(1,:))<4;
                    % 
                    % tri_faces = node_indices(is_tri, 1:3);
                    % quad_faces = node_indices(~is_tri, :);

                    % Append faces to the correct storage location
                    face_data.(prpCardName).Tri = [face_data.(prpCardName).Tri; tri_faces];
                    face_data.(prpCardName).Quad = [face_data.(prpCardName).Quad; quad_faces];
                end
            end

            patch_props = struct(...
                'PSHELL', struct('FaceColor', [0.9290, 0.6940, 0.1250], 'Tag', 'PSHELL Elements'), ...
                'PCOMP',  struct('FaceColor', [1 0 0],     'Tag', 'PCOMP Elements'));

            if p.Results.DrawEdge
                ec = 'k';
            else
                ec = 'none';
            end

            card_types = fieldnames(face_data);
            for i = 1:numel(card_types)
                type = card_types{i};
                props = patch_props.(type);

                % Plot all quadrilateral faces for this property type
                faces_quad = face_data.(type).Quad;
                if ~isempty(faces_quad)
                    hg(end + 1) = patch(hAx, 'Faces', faces_quad, 'Vertices', all_vertices, ...
                        'FaceColor', props.FaceColor, 'EdgeColor', ec, 'Tag', [props.Tag,' (CQUAD4)']);
                end

                % Plot all triangular faces for this property type
                faces_tri = face_data.(type).Tri;
                if ~isempty(faces_tri)
                    hg(end + 1) = patch(hAx, 'Faces', faces_tri, 'Vertices', all_vertices, ...
                        'FaceColor', props.FaceColor, 'EdgeColor', ec, 'Tag', [props.Tag,' (CTRIA3)']);
                end

            end
        end
    end
end