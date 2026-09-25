% classdef Shell < mni.bulk.BulkData
%     %Shell Describes a 2D or 3D element connected to an arbitrary number of
%     %Nodes.
%     %
%     % The definition of the 'Shell' object matches that of the CQUAD4 bulk
%     % data type (and other similar types) from MSC.Nastran.
%     %
%     % Valid Bulk Data Types:
%     %   - 'CPENTA'  -> TODO
%     %   - 'CQUAD'   -> TODO
%     %   - 'CQUAD4'
%     %   - 'CQUAD8'  -> TODO
%     %   - 'CQUADR'  -> TODO
%     %   - 'CQUADX'  -> TODO
%     %   - 'CRAC2D'  -> TODO
%     %   - 'CRAC3D'  -> TODO
%     %   - 'CTETRA'  -> TODO
%     %   - 'CTRIA3'
%     %   - 'CTRIA6'  -> TODO
%     %   - 'CTRIAR'  -> TODO
%     %   - 'CTRIAX'  -> TODO
%     %   - 'CTRIAX6' -> TODO
    
%     methods % construction
%         function obj = Shell(varargin)
            
%             %Initialise the bulk data sets
%             addBulkDataSet(obj, 'CQUAD4', ...
%                 'BulkProps'  , {'EID', 'PID', 'G', 'THETA', 'ZOFFS' , 'TFLAG', 'T'}, ...
%                 'PropTypes'  , {'i'  , 'i'  , 'i', 'r'    , 'r'   , 'b', 'i'    , 'r'}, ...
%                 'PropDefault', {''   , ''   , '' , 0      , 0          , 0      , 0  }, ...
%                 'IDProp'     , 'EID', ...
%                 'PropMask'   , {'G', 4, 'T', 4}, ...
%                 'Connections', {'G', 'mni.bulk.Node', 'Nodes', 'PID', 'mni.bulk.Property', 'Prop'}     , ...
%                 'AttrList'   , {'G', {'nrows', 4}, 'T', {'nrows', 4}});

%             addBulkDataSet(obj, 'CTRIA3', ...
%                 'BulkProps'  , {'EID', 'PID', 'G', 'THETA', 'ZOFFS'     , 'TFLAG', 'T'}, ...
%                 'PropTypes'  , {'i'  , 'i'  , 'i', 'r'    , 'r'    , 'b', 'i'    , 'r'}, ...
%                 'PropDefault', {''   , ''   , '' , 0      , 0          , 0      , 0  }, ...
%                 'IDProp'     , 'EID', ...
%                 'PropMask'   , {'G', 3, 'T', 3}, ...
%                 'Connections', {'G', 'mni.bulk.Node', 'Nodes', 'PID', 'mni.bulk.Property', 'Prop'}     , ...
%                 'AttrList'   , {'G', {'nrows', 3}, 'T', {'nrows', 3}});

%             varargin = parse(obj, varargin{:});
%             preallocate(obj);
            
%         end
%     end
    
%     methods % visualisation
%         function hg = drawElement(obj, ~, hAx, varargin)
%             %drawElement Draws the Shell objects as a patch object between
%             %the nodes and returns a single handle for all the patches in
%             %the collection.
            
%             hg = [];
                
%             if isempty(obj.Nodes)
%                 return
%             end
            
%             % Filter out elements (columns) with invalid node indices (NaN)
%             validIdx = ~any(isnan(obj.NodesIndex), 1);
%             index = obj.NodesIndex(:, validIdx);

%             if isempty(index)
%                 return
%             end

%             coords = obj.Nodes.getDrawCoords('Mode', 'undeformed');
%             coords = arrayfun(@(ii) coords(:, index(ii, :)), 1 : size(index, 1), 'Unif', false);
%             coords = permute(cat(3, coords{:}), [3, 2, 1]);
            
%             hg = patch(hAx, ...
%                 'XData'    , coords(:, :, 1), ...
%                 'YData'    , coords(:, :, 2), ...
%                 'ZData'    , coords(:, :, 3), ...
%                 'FaceColor', 'none', ...
%                 'EdgeColor', 'k'   , ...
%                 'Tag'      , ['Shell Elements (', obj.CardName, ')']);
            
%         end
%     end
    
% end

classdef Shell < mni.bulk.BulkData
    %Shell Describes a 2D or 3D element connected to an arbitrary number of
    %Nodes.
    %
    % The definition of the 'Shell' object matches that of the CQUAD4 bulk
    % data type (and other similar types) from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'CPENTA'  -> TODO
    %   - 'CQUAD'   -> TODO
    %   - 'CQUAD4'
    %   - 'CQUAD8'  -> TODO
    %   - 'CQUADR'  -> TODO
    %   - 'CQUADX'  -> TODO
    %   - 'CRAC2D'  -> TODO
    %   - 'CRAC3D'  -> TODO
    %   - 'CTETRA'  -> TODO
    %   - 'CTRIA3'
    %   - 'CTRIA6'  -> TODO
    %   - 'CTRIAR'  -> TODO
    %   - 'CTRIAX'  -> TODO
    %   - 'CTRIAX6' -> TODO

    properties
        % ElementColor : (nEl x 1) scalar per element used to colour the
        %                element face. Leave empty for a wireframe-only
        %                view. Assign values (e.g. a moment-per-unit-length
        %                component from a QUAD4 force result) and the
        %                faces will be filled and shaded with the current
        %                colormap.
        ElementColor

        % ElementForce : (nEl x 3) force vector per element in the GLOBAL
        %                frame. Used to draw quiver arrows from each
        %                element centroid. Leave empty to skip.
        ElementForce

        % ColorLabel   : char vector. Optional label shown on the
        %                colorbar / referenced by the parent figure. e.g.
        %                'M_x [N\cdotm/m]'.
        ColorLabel = ''
    end

    properties(Hidden = true)
        plotobj_patch;
        plotobj_quiver;
    end

    methods % construction
        function obj = Shell(varargin)

            %Initialise the bulk data sets
            addBulkDataSet(obj, 'CQUAD4', ...
                'BulkProps'  , {'EID', 'PID', 'G', 'THETA', 'ZOFFS' , 'TFLAG', 'T'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'i', 'r'    , 'r'   , 'b', 'i'    , 'r'}, ...
                'PropDefault', {''   , ''   , '' , 0      , 0          , 0      , 0  }, ...
                'IDProp'     , 'EID', ...
                'PropMask'   , {'G', 4, 'T', 4}, ...
                'Connections', {'G', 'mni.bulk.Node', 'Nodes', 'PID', 'mni.bulk.Property', 'Prop'}     , ...
                'AttrList'   , {'G', {'nrows', 4}, 'T', {'nrows', 4}});

            addBulkDataSet(obj, 'CTRIA3', ...
                'BulkProps'  , {'EID', 'PID', 'G', 'THETA', 'ZOFFS'     , 'TFLAG', 'T'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'i', 'r'    , 'r'    , 'b', 'i'    , 'r'}, ...
                'PropDefault', {''   , ''   , '' , 0      , 0          , 0      , 0  }, ...
                'IDProp'     , 'EID', ...
                'PropMask'   , {'G', 3, 'T', 3}, ...
                'Connections', {'G', 'mni.bulk.Node', 'Nodes', 'PID', 'mni.bulk.Property', 'Prop'}     , ...
                'AttrList'   , {'G', {'nrows', 3}, 'T', {'nrows', 3}});

            varargin = parse(obj, varargin{:});
            preallocate(obj);

        end
    end

    methods % visualisation
        function hg = drawElement(obj, ~, hAx, varargin)
            %drawElement Draws the Shell objects as a patch object between
            %the nodes and returns one or two graphics handles for the
            %collection (patch, and optionally quiver).

            hg = [];
            obj.plotobj_patch  = [];
            obj.plotobj_quiver = [];

            if isempty(obj.Nodes)
                return
            end

            % Filter out elements (columns) with invalid node indices (NaN)
            validIdx = ~any(isnan(obj.NodesIndex), 1);
            index = obj.NodesIndex(:, validIdx);

            if isempty(index)
                return
            end

            coords = obj.Nodes.getDrawCoords('Mode', 'undeformed');
            coords = arrayfun(@(ii) coords(:, index(ii, :)), 1 : size(index, 1), 'Unif', false);
            coords = permute(cat(3, coords{:}), [3, 2, 1]);

            % decide on face colouring
            [faceColor, cData] = i_resolveFaceColor(obj, validIdx);

            patchArgs = { ...
                'XData', coords(:, :, 1), ...
                'YData', coords(:, :, 2), ...
                'ZData', coords(:, :, 3), ...
                'FaceColor', faceColor, ...
                'EdgeColor', 'k', ...
                'Tag'      , ['Shell Elements (', obj.CardName, ')'], ...
                'UserData' , obj, ...
                'DeleteFcn', @obj.patchDelete};
            if ~isempty(cData)
                patchArgs = [patchArgs, {'CData', cData}];
            end
            obj.plotobj_patch = patch(hAx, patchArgs{:});
            hg = obj.plotobj_patch;

            % quiver for element forces (optional)
            if ~isempty(obj.ElementForce)
                centres = obj.getElementCentres(coords);
                F = obj.ElementForce;
                F = F(validIdx, :);
                obj.plotobj_quiver = quiver3(hAx, ...
                    centres(:,1), centres(:,2), centres(:,3), ...
                    F(:,1), F(:,2), F(:,3), ...
                    'r', 'Tag', ['Shell Forces (', obj.CardName, ')'], ...
                    'UserData', obj, 'DeleteFcn', @obj.quiverDelete);
                hg(2) = obj.plotobj_quiver;
            end

            function [faceColor, cData] = i_resolveFaceColor(obj, validIdx)
                if isempty(obj.ElementColor)
                    faceColor = 'none';
                    cData     = [];
                else
                    ec = obj.ElementColor(:);
                    if numel(ec) ~= numel(validIdx)
                        % allow user to pass only the valid ones already
                        cData = ec;
                    else
                        cData = ec(validIdx);
                    end
                    faceColor = 'flat';
                end
            end
        end

        function updateElement(obj, varargin)
            %updateElement Refreshes the patch coordinates / face colours
            %and the quiver after the model state changes (e.g. after
            %assigning ElementColor / ElementForce / Deformation).

            if isempty(obj.Nodes)
                return
            end
            validIdx = ~any(isnan(obj.NodesIndex), 1);
            index = obj.NodesIndex(:, validIdx);
            if isempty(index)
                return
            end
            coords = obj.Nodes.getDrawCoords('Mode', 'undeformed');
            coords = arrayfun(@(ii) coords(:, index(ii, :)), 1 : size(index, 1), 'Unif', false);
            coords = permute(cat(3, coords{:}), [3, 2, 1]);

            % update patch
            if ~isempty(obj.plotobj_patch) && isvalid(obj.plotobj_patch)
                obj.plotobj_patch.XData = coords(:, :, 1);
                obj.plotobj_patch.YData = coords(:, :, 2);
                obj.plotobj_patch.ZData = coords(:, :, 3);
                if isempty(obj.ElementColor)
                    obj.plotobj_patch.FaceColor = 'none';
                else
                    ec = obj.ElementColor(:);
                    if numel(ec) == numel(validIdx)
                        ec = ec(validIdx);
                    end
                    obj.plotobj_patch.CData     = ec;
                    obj.plotobj_patch.FaceColor = 'flat';
                end
            end

            % update or create quiver
            if ~isempty(obj.ElementForce)
                centres = obj.getElementCentres(coords);
                F = obj.ElementForce;
                if size(F,1) == numel(validIdx)
                    F = F(validIdx, :);
                end
                if isempty(obj.plotobj_quiver) || ~isvalid(obj.plotobj_quiver)
                    hAx = ancestor(obj.plotobj_patch, 'axes');
                    obj.plotobj_quiver = quiver3(hAx, ...
                        centres(:,1), centres(:,2), centres(:,3), ...
                        F(:,1), F(:,2), F(:,3), ...
                        'r', 'Tag', ['Shell Forces (', obj.CardName, ')'], ...
                        'UserData', obj, 'DeleteFcn', @obj.quiverDelete);
                else
                    obj.plotobj_quiver.XData = centres(:,1);
                    obj.plotobj_quiver.YData = centres(:,2);
                    obj.plotobj_quiver.ZData = centres(:,3);
                    obj.plotobj_quiver.UData = F(:,1);
                    obj.plotobj_quiver.VData = F(:,2);
                    obj.plotobj_quiver.WData = F(:,3);
                end
            elseif ~isempty(obj.plotobj_quiver) && isvalid(obj.plotobj_quiver)
                delete(obj.plotobj_quiver);
                obj.plotobj_quiver = [];
            end
        end

        function patchDelete(~, ~, ~)
            h = gcbo;
            if isvalid(h) && ~isempty(h.UserData)
                h.UserData.plotobj_patch = [];
            end
        end

        function quiverDelete(~, ~, ~)
            h = gcbo;
            if isvalid(h) && ~isempty(h.UserData)
                h.UserData.plotobj_quiver = [];
            end
        end
    end

    methods % helpers
        function centres = getElementCentres(obj, coords)
            %getElementCentres Returns the centroid of each (valid)
            %element. `coords` is the (nEl x nNodesPerEl x 3) array as
            %assembled in drawElement/updateElement.
            centres = squeeze(mean(coords, 2));
            if size(centres,2) ~= 3
                centres = centres';
            end
        end
    end

end