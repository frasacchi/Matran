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
    %   - 'SPCADD'
    %   - 'SUPORT'
    %   - 'SUPORT1'

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
                'BulkProps'  , {'EID', 'GN', 'CM', 'GMi', 'ALPHA', 'TREF'}, ...
                'PropTypes'  , {'i'  , 'i',  'i',  'i',   'r'    , 'r'} , ...
                'PropDefault', {''   , '',   '',   '',    0      , 0  } , ...
                'IDProp'     , 'EID', ...
                'ListProp'   , {'GMi'}, ...
                'H5ListName' , {'GM'}, ...
                'Connections', {'GN', 'mni.bulk.Node', 'IndepNode', 'GMi', 'mni.bulk.Node', 'DepNodes'});
            addBulkDataSet(obj, 'RBE3', ...
                'BulkProps'  , {'EID', 'b', 'REFGRID', 'REFC', 'WTi', 'Ci', 'Gij', 'GMi', 'CMi', 'ALPHA', 'TREF'}, ...
                'PropTypes'  , {'i'  , 'c', 'i'      , 'i'   , 'r'  , 'i' , 'i'  , 'i'  , 'i'  , 'r'    , 'r'}   , ...
                'PropDefault', {''   , '' , ''       , 0     , []   , []  , []   , []   , []   , 0      , 0  }   , ...
                'IDProp'     , 'EID', ...
                'ListProp'   , {'WTi', 'Ci', 'Gij', 'GMi', 'CMi'}, ...
                'Connections', {'REFGRID', 'mni.bulk.Node', 'RefNode', 'Gij', 'mni.bulk.Node', 'DepNodes'});

            addBulkDataSet(obj, 'SPCADD', ...
                'BulkProps'  , {'SID', 'Si'}, ...
                'PropTypes'  , {'i'  , 'i' }, ...
                'PropDefault', {''   , []  }, ...
                'IDProp'     , 'SID', ...
                'ListProp'   , {'Si'});
            addBulkDataSet(obj, 'SUPORT', ...
                'BulkProps'  , {'IDi', 'Ci'}, ...
                'PropTypes'  , {'i'  , 'i' }, ...
                'PropDefault', {[]   , []  }, ...
                'ListProp'   , {'IDi', 'Ci'}, ...
                'Connections', {'IDi', 'mni.bulk.Node', 'Nodes'});
            addBulkDataSet(obj, 'SUPORT1', ...
                'BulkProps'  , {'SID', 'IDi', 'Ci'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'i' }, ...
                'PropDefault', {''   , []   , []  }, ...
                'IDProp'     , 'SID', ...
                'ListProp'   , {'IDi', 'Ci'}, ...
                'Connections', {'IDi', 'mni.bulk.Node', 'Nodes'});

            varargin = parse(obj, varargin{:});
            preallocate(obj);
            switch obj.CardName
                case 'RBE2'
                    obj.BulkAssignFunction = @assignRBE2Data;
                case 'RBE3'
                    obj.BulkAssignFunction = @assignRBE3Data;
            end

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

    methods % assigning data during import (rigid elements)
        function assignRBE2Data(obj, propData, index, ~)
            %assignRBE2Data RBE2: EID GN CM GM1 GM2 ... [ALPHA [TREF]].
            %
            % QRG: ALPHA and TREF follow the last GMi; they are the first
            % real numbers after the integer list of dependent grids.
            f = strtrim(reshape(propData, 1, []));
            f(end + 1 : 3) = {''};
            rest = f(4 : end);
            rest = rest(~cellfun(@isempty, rest));
            iReal = find(~cellfun(@isempty, regexp(rest, '[.eE]', 'once')), 1);
            if isempty(iReal)
                gm = rest; tail = {};
            else
                gm = rest(1 : iReal - 1); tail = rest(iReal : end);
            end
            tail(end + 1 : 2) = {''};
            obj.EID(index)   = str2double(f{1});
            obj.GN(index)    = str2double(f{2});
            obj.CM(index)    = str2double(f{3});
            obj.GMi{index}   = expandThru(gm, 'RBE2');
            obj.ALPHA(index) = fieldValue(tail{1}, 0);
            obj.TREF(index)  = fieldValue(tail{2}, 0);
        end
        function assignRBE3Data(obj, propData, index, ~)
            %assignRBE3Data RBE3: EID _ REFGRID REFC WT1 C1 G1,1 ... then
            %optional "UM" GM1 CM1 ... and "ALPHA" ALPHA TREF lines.
            f = strtrim(reshape(propData, 1, []));
            f(end + 1 : 4) = {''};
            rest = f(5 : end);
            iUM  = find(strcmpi(rest, 'UM'), 1);
            iAL  = find(strcmpi(rest, 'ALPHA'), 1);
            stop = min([iUM, iAL, numel(rest) + 1]);
            grp  = rest(1 : stop - 1);
            grp  = grp(~cellfun(@isempty, grp));
            %weighting groups: WT (real) C G G ...
            isReal = ~cellfun(@isempty, regexp(grp, '[.eE]', 'once'));
            iWT = find(isReal);
            wt = zeros(1, numel(iWT)); c = zeros(1, numel(iWT)); g = cell(1, numel(iWT));
            for i = 1 : numel(iWT)
                last = numel(grp);
                if i < numel(iWT)
                    last = iWT(i + 1) - 1;
                end
                assert(last >= iWT(i) + 2, 'RBE3 %s: weighting group %i has no grid point.', f{1}, i);
                wt(i) = str2double(grp{iWT(i)});
                c(i)  = str2double(grp{iWT(i) + 1});
                g{i}  = expandThru(grp(iWT(i) + 2 : last), 'RBE3');
            end
            um = {};
            if ~isempty(iUM)
                um = rest(iUM + 1 : min([iAL, numel(rest) + 1]) - 1);
                um = um(~cellfun(@isempty, um));
            end
            al = {'', ''};
            if ~isempty(iAL)
                al = rest(iAL + 1 : end);
                al(end + 1 : 2) = {''};
            end
            obj.EID(index)     = str2double(f{1});
            obj.REFGRID(index) = str2double(f{3});
            obj.REFC(index)    = fieldValue(f{4}, 0);
            obj.WTi{index}     = wt;
            obj.Ci{index}      = c;
            obj.Gij{index}     = g;
            obj.GMi{index}     = str2double(um(1 : 2 : end));
            obj.CMi{index}     = str2double(um(2 : 2 : end));
            obj.ALPHA(index)   = fieldValue(al{1}, 0);
            obj.TREF(index)    = fieldValue(al{2}, 0);
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
                        % set([h, h_txt], 'Parent', h_all);
                        % set([h_txt], 'HandleVisibility', 'off');
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

function ids = expandThru(tok, card)
%expandThru Integer list with optional "ID1 THRU ID2" ranges.
ids = zeros(1, 0);
i = 1;
while i <= numel(tok)
    if strcmpi(tok{i}, 'THRU')
        assert(i > 1 && i < numel(tok), '%s: misplaced THRU.', card);
        ids = [ids, ids(end) + 1 : str2double(tok{i + 1})]; %#ok<AGROW>
        i = i + 2;
    else
        ids(end + 1) = str2double(tok{i}); %#ok<AGROW>
        i = i + 1;
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