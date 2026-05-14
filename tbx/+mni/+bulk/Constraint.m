classdef Constraint < mni.bulk.BulkData
    %Constraint Describes a constraint applied to a node.
    %
    % The definition of the 'Constraint' object matches that of the SPC1
    % bulk data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'SPC'
    %   - 'SPC1'
    %   - 'RBE2'
    %   - 'RBE3'

    methods % construction
        function obj = Constraint(varargin)

            %Initialise the bulk data sets
            addBulkDataSet(obj, 'SPC', ...
                'BulkProps'  , {'SID', 'G' , 'C', 'D'}   , ...
                'PropTypes'  , {'i'  , 'i' , 'i' , 'r' }, ...
                'PropDefault', {0    , 0   , 0   , 0   }, ...
                'IDProp'     , 'SID', ...
                'ListProp'   , {'G', 'C', 'D'}, ...
                'Connections', {'G', 'mni.bulk.Node', 'Nodes'});
            addBulkDataSet(obj, 'SPC1', ...
                'BulkProps'  , {'SID', 'C', 'G'}, ...
                'PropTypes'  , {'i'  , 'c', 'i'}, ...
                'PropDefault', {''   , '' ,''}  , ...
                'IDProp'     , 'SID' , ...
                'ListProp'   , {'G'} , ...
                'H5ListName' , {'ID'}, ...
                'Connections', {'G', 'mni.bulk.Node', 'Nodes'}, ...
                'SetMethod'  , {'C', @validateDOF});
            addBulkDataSet(obj, 'RBE2', ...
                'BulkProps'  , {'EID', 'GN', 'CM', 'GMi', 'ALPHA'}, ...
                'PropTypes'  , {'i'  , 'i',  'i',  'i',   'r'} , ...
                'PropDefault', {''   , '',   '',   '',    '' } , ...
                'IDProp'     , 'EID', ...
                'ListProp'   , {'GMi'}, ...
                'H5ListName' , {'GM'}, ...
                'Connections', {'GN', 'mni.bulk.Node', 'IndepNode', 'GMi', 'mni.bulk.Node', 'DepNodes'});
            addBulkDataSet(obj, 'RBE3', ...
                'BulkProps'  , {'EID', 'b', 'REFGRID', 'REFC', 'WTi', 'Ci', 'Gij'}, ...
                'PropTypes'  , {'i'  , 'c'    , 'i'      , 'i'   , 'r'  , 'i' , 'i'}  , ...
                'PropDefault', {''   , ''     , ''       , 0     , []   , []  , []}   , ...
                'IDProp'     , 'EID', ...
                'ListProp'   , {'WTi', 'Ci', 'Gij'}, ...
                'Connections', {'REFGRID', 'mni.bulk.Node', 'RefNode', 'Gij', 'mni.bulk.Node', 'DepNodes'});

            varargin = parse(obj, varargin{:});
            preallocate(obj);

        end
    end

    methods % assigning data during import
        function [bulkNames, bulkData] = parseH5DataGroup(obj, h5Struct)
            %parseH5DataGroup Parse the data in the h5 data group
            %'h5Struct' and return the bulk names and data.
            %
            % The list data can be specified in the 'G' field or in the
            % 'IDENTITY' field using the "THRU" notation.

            fNames = fieldnames(h5Struct);
            if ~any(ismember(fNames, {'SPC1_THRU', 'SPC1_G'}))
                error('Update code for new format.');
            end
            if numel(h5Struct.SPC1_G.IDENTITY.SID) > 1
                error('Update code to handle multiple datasets.');
            end

            nGrps = numel(fNames);
            bn = cell(1, nGrps);
            bd = cell(1, nGrps);
            for ii = 1 : nGrps
                [bn{ii}, bd{ii}] = parseH5DataGroup@mni.bulk.BulkData( ...
                    obj, h5Struct.(fNames{ii}));
            end
            bd = vertcat(bd{:});
            bulkNames = bn{1};
            bulkData  = arrayfun(@(ii) horzcat(bd{:, ii}), ...
                1 : numel(bulkNames), 'Unif', false);

        end
    end

    methods % visualisation
        function hg = drawElement(obj, ~, hAx, varargin)
            %drawElement Draws the constraint objects.
            hg = [];
            %Check for nodes - exit if none are present
            if (~isprop(obj, 'Nodes') || isempty(obj.Nodes)) && ...
                    (~isprop(obj, 'IndepNode') || isempty(obj.IndepNode)) && ...
                    (~isprop(obj, 'RefNode') || isempty(obj.RefNode))
                return
            end
            p = parseInput(varargin{:});

            switch obj.CardName
                case {'SPC', 'SPC1'}
                    if isempty(obj.Nodes)
                        return
                    end
                    % This section was already correct
                    coords = getDrawCoords(obj.Nodes,'Mode',p.Results.Mode,...
                        'Scale',p.Results.Scale,'Phase',p.Results.Phase);

                    % Flatten node indices if they are in a cell array
                    if iscell(obj.NodesIndex)
                        node_indices = horzcat(obj.NodesIndex{:});
                    else
                        node_indices = obj.NodesIndex;
                    end

                    %Filter out invalid nodes
                    valid_idx = ~isnan(node_indices);
                    if ~any(valid_idx)
                        return
                    end
                    coords = coords(:, node_indices(valid_idx));
                    if isempty(coords)
                        return
                    end
                    switch obj.CardName
                        case 'SPC'
                            txt = obj.C(valid_idx);
                        case 'SPC1'
                            txt = arrayfun(@(ii) repmat(obj.C(ii), [1, numel(obj.G{ii})]), ...
                                1 : numel(obj.C), 'Unif', false);
                            txt = horzcat(txt{:});
                            txt = txt(valid_idx);
                    end
                    h  = line(hAx, ...
                        'XData', coords(1, :), ...
                        'YData', coords(2, :), ...
                        'ZData', coords(3, :), ...
                        'LineStyle'      , 'none' , ...
                        'Marker'         , '^'    , ...
                        'MarkerFaceColor', 'c'    , ...
                        'MarkerEdgeColor', 'k'    , ...
                        'Tag'            , 'Constraints', ...
                        'SelectionHighlight', 'off');
                    if numel(txt) < 50 && ~isempty(txt)
                        if isnumeric(txt)
                            txt = cellstr(num2str(txt'));
                        end
                        h_txt = text(hAx, ...
                            coords(1, :), coords(2, :), coords(3, :), txt, ...
                            'Color'              , h.MarkerFaceColor, ...
                            'VerticalAlignment'  , 'top', ...
                            'HorizontalAlignment', 'left', ...
                            'Tag'                , 'Constraint DOFs');

                        h_all = hggroup(hAx, 'Tag', 'Constraints');
                        set([h, h_txt], 'Parent', h_all);
                        set([h_txt], 'HandleVisibility', 'off');
                        hg = h_all;
                    else
                        hg = h;
                    end
                case 'RBE2'
                    % RBE2: Draw lines from independent node to dependent nodes
                    if isempty(obj.IndepNode) || isempty(obj.DepNodes)
                        return
                    end

                    % --- EDIT START ---
                    % Get all node coordinates in the global system first
                    % by calling the Node's getDrawCoords method.
                    AllIndepCoords = getDrawCoords(obj.IndepNode, 'Mode', p.Results.Mode, 'Scale', p.Results.Scale, 'Phase', p.Results.Phase);
                    AllDepCoords   = getDrawCoords(obj.DepNodes, 'Mode', p.Results.Mode, 'Scale', p.Results.Scale, 'Phase', p.Results.Phase);
                    % --- EDIT END ---

                    %Ensure 'DepNodesIndex' is a cell
                    if ~iscell(obj.DepNodesIndex)
                        obj.DepNodesIndex = {obj.DepNodesIndex};
                    end

                    x_coords = [];
                    y_coords = [];
                    z_coords = [];

                    all_dep_indices = [];
                    valid_indep_indices = [];

                    nBulk = obj.NumBulk;
                    if nBulk > numel(obj.IndepNodeIndex) || nBulk > numel(obj.DepNodesIndex)
                        warning('Inconsistent number of RBE2 elements and node indices. Plotting may be incomplete.');
                        nBulk = min([numel(obj.IndepNodeIndex), numel(obj.DepNodesIndex), nBulk]);
                    end
                    for i = 1:nBulk

                        indep_idx = obj.IndepNodeIndex(i);
                        if isnan(indep_idx)
                            continue;
                        end

                        dep_idx = obj.DepNodesIndex{i};
                        if any(isnan(dep_idx))
                            continue;
                        end

                        % Use the correctly transformed coordinates
                        indep_coord = AllIndepCoords(:, indep_idx);
                        dep_coords = AllDepCoords(:, dep_idx);

                        nDep = size(dep_coords, 2);
                        x_coords = [x_coords, [repmat(indep_coord(1), [1, nDep]) ; dep_coords(1, :); nan(1, nDep)]]; %#ok<AGROW>
                        y_coords = [y_coords, [repmat(indep_coord(2), [1, nDep]) ; dep_coords(2, :); nan(1, nDep)]]; %#ok<AGROW>
                        z_coords = [z_coords, [repmat(indep_coord(3), [1, nDep]) ; dep_coords(3, :); nan(1, nDep)]]; %#ok<AGROW>
                        all_dep_indices = [all_dep_indices, dep_idx]; %#ok<AGROW>
                        valid_indep_indices = [valid_indep_indices, indep_idx]; %#ok<AGROW>
                    end

                    if isempty(x_coords)
                        return;
                    end
                    % Plot the lines
                    h_lines = plot3(hAx, x_coords(:), y_coords(:), z_coords(:), 'm', 'Tag', 'RBE2');

                    % Plot the markers using the transformed coordinates
                    plot_dep_coords   = AllDepCoords(:, horzcat(all_dep_indices));
                    plot_indep_coords = AllIndepCoords(:, valid_indep_indices);
                    h_dep = line(hAx, plot_dep_coords(1,:), plot_dep_coords(2,:), plot_dep_coords(3,:), ...
                        'Marker', 'o', 'MarkerFaceColor', 'k', 'LineStyle', 'none', 'Tag', 'RBE2','HandleVisibility','off','MarkerEdgeColor','m');
                    h_indep = line(hAx, plot_indep_coords(1,:), plot_indep_coords(2,:), plot_indep_coords(3,:), ...
                        'Marker', 's', 'MarkerFaceColor', 'm', 'LineStyle', 'none', 'Tag', 'RBE2','HandleVisibility','off','MarkerEdgeColor','c');
                    % hg = h_lines;

                    h_all = hggroup(hAx, 'Tag', 'RBE2');
                    set([h_lines, h_dep, h_indep], 'Parent', h_all);
                    set([h_dep, h_indep], 'HandleVisibility', 'off');
                    hg = h_all;
                case 'RBE3'
                    % RBE3: Draw lines from reference node to dependent nodes
                    if isempty(obj.RefNode) || isempty(obj.DepNodes)
                        return
                    end

                    % Get all node coordinates in the global system first
                    AllRefCoords = getDrawCoords(obj.RefNode, 'Mode', p.Results.Mode, 'Scale', p.Results.Scale, 'Phase', p.Results.Phase);
                    AllDepCoords = getDrawCoords(obj.DepNodes, 'Mode', p.Results.Mode, 'Scale', p.Results.Scale, 'Phase', p.Results.Phase);

                    %Ensure 'DepNodesIndex' is a cell
                    if ~iscell(obj.DepNodesIndex)
                        obj.DepNodesIndex = {obj.DepNodesIndex};
                    end

                    x_coords = [];
                    y_coords = [];
                    z_coords = [];

                    all_dep_indices = [];
                    valid_ref_indices = [];

                    nBulk = obj.NumBulk;
                    if nBulk > numel(obj.RefNodeIndex) || nBulk > numel(obj.DepNodesIndex)
                        warning('Inconsistent number of RBE3 elements and node indices. Plotting may be incomplete.');
                        nBulk = min([numel(obj.RefNodeIndex), numel(obj.DepNodesIndex), nBulk]);
                    end
                    for i = 1:nBulk

                        ref_idx = obj.RefNodeIndex(i);
                        if isnan(ref_idx)
                            continue;
                        end

                        dep_idx = obj.DepNodesIndex{i};
                        if any(isnan(dep_idx))
                            continue;
                        end

                        % Use the correctly transformed coordinates
                        ref_coord = AllRefCoords(:, ref_idx);
                        dep_coords = AllDepCoords(:, dep_idx);

                        nDep = size(dep_coords, 2);
                        x_coords = [x_coords, [repmat(ref_coord(1), [1, nDep]) ; dep_coords(1, :); nan(1, nDep)]]; %#ok<AGROW>
                        y_coords = [y_coords, [repmat(ref_coord(2), [1, nDep]) ; dep_coords(2, :); nan(1, nDep)]]; %#ok<AGROW>
                        z_coords = [z_coords, [repmat(ref_coord(3), [1, nDep]) ; dep_coords(3, :); nan(1, nDep)]]; %#ok<AGROW>
                        all_dep_indices = [all_dep_indices, dep_idx]; %#ok<AGROW>
                        valid_ref_indices = [valid_ref_indices, ref_idx]; %#ok<AGROW>
                    end

                    if isempty(x_coords)
                        return;
                    end
                    % Plot the lines
                    h_lines = plot3(hAx, x_coords(:), y_coords(:), z_coords(:), 'r', 'Tag', 'RBE3');

                    % Plot the markers using the transformed coordinates
                    plot_dep_coords   = AllDepCoords(:, horzcat(all_dep_indices));
                    plot_indep_coords = AllRefCoords(:, valid_ref_indices);
                    h_dep = line(hAx, plot_dep_coords(1,:), plot_dep_coords(2,:), plot_dep_coords(3,:), ...
                        'Marker', 'o', 'MarkerFaceColor', 'k', 'LineStyle', 'none', 'Tag', 'RBE3','HandleVisibility','off','MarkerEdgeColor','r');
                    h_indep = line(hAx, plot_indep_coords(1,:), plot_indep_coords(2,:), plot_indep_coords(3,:), ...
                        'Marker', 's', 'MarkerFaceColor', 'r', 'LineStyle', 'none', 'Tag', 'RBE3','HandleVisibility','off','MarkerEdgeColor','c');
                        
                    h_all = hggroup(hAx, 'Tag', 'RBE3');
                    set([h_lines, h_dep, h_indep], 'Parent', h_all);
                    set([h_dep, h_indep], 'HandleVisibility', 'off');
                    hg = h_all;

            end
        end
    end
end

function p = parseInput(varargin)
expectedModes = {'undeformed','deformed'};
p = inputParser;
addParameter(p, 'AddOffset', true, @(x)validateattributes(x, {'logical'}, {'scalar'}));
addParameter(p,'Mode','deformed',...
    @(x)any(validatestring(x,expectedModes)));
addParameter(p,'Scale',1);
addParameter(p,'Phase',0);
parse(p, varargin{:});
end