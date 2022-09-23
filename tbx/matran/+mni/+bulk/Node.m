classdef Node < mni.bulk.BulkData
    %Node Describes a point in 3D-space for use in a finite element model.
    %
    % The definition of the 'Node' object matches that of the GRID bulk
    % data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'GRID'
    %   - 'SPOINT'
    %   - 'EPOINT'
    
    %Store results data
    properties 
        Deformation = [];
    end
    
    %Visualisation
    properties (Hidden= true)
        plotobj_nodes;
        DisplacementScale = 1;
    end
    
    methods % construction
        function obj = Node(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'GRID', ...
                'BulkProps'  , {'GID', 'CP', 'X', 'CD', 'PS', 'SEID'}, ...
                'PropTypes'  , {'i'  , 'i' , 'r', 'i' , 'c' , 'i'}   , ...
                'PropDefault', {''   , 0   , 0  , 0   , ''  , 0 }    , ...
                'IDProp'     , 'GID', ...
                'Connections', { ...
                'CP', 'mni.bulk.CoordSystem', 'InputCoordSys', ...
                'CD', 'mni.bulk.CoordSystem', 'OutputCoordSys'}, ...
                'PropMask'   , {'X', 3}, ...
                'AttrList'   , {'X', {'nrows', 3}}, ...
                'SetMethod'  , {'PS', @validateDOF});
            addBulkDataSet(obj, 'SPOINT', ...
                'BulkProps'  , {'IDi'}, ...
                'PropType'   , {'i'}  , ...
                'PropDefault', {''}   , ...
                'IDProp'     , 'IDi'  , ...
                'ListProp'   , {'IDi'});
            addBulkDataSet(obj, 'EPOINT', ...
                'BulkProps'  , {'IDi'}, ...
                'PropType'   , {'i'}  , ...
                'PropDefault', {''}   , ...
                'IDProp'     , 'IDi'  , ...
                'ListProp'   , {'IDi'});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
    methods % assigning data during import
        function assignListCardData(obj, propData, index, BulkMeta)
            %assignListCardData 
            
            assignListCardData@mni.bulk.BulkData(obj, propData, index, BulkMeta)
            
            %Stack all ID numbers for 'SPOINT' or 'EPOINT'
            %   - Cell notation for list bulk data doers not work with the
            %    'makeIndices' function for the 'mni.bulk.FEModel' class.
            obj.IDi = horzcat(obj.IDi{:});
        end
    end
    
    methods % visualisation
        function hg = drawElement(obj, ~, hAx, varargin)
            %drawElement Draws the node objects as a discrete marker and
            %returns a single graphics handle for all the nodes in the
            %collection.            
            coords = getDrawCoords(obj, varargin{:});
            obj.plotobj_nodes = drawNodes(coords, hAx,'DeleteFcn',...
                @obj.nodeDelete,'UserData',obj);
            hg = obj.plotobj_nodes;           
        end        
        function nodeDelete(~,~,~)
            h = gcbo;
            h.UserData.plotobj_nodes = [];
        end
        function updateElement(obj, varargin)
            %drawElement Draws the node objects as a discrete marker and
            %returns a single graphics handle for all the nodes in the
            %collection.            
            if ~isempty(obj.plotobj_nodes)
                coords = getDrawCoords(obj, varargin{:});
                obj.plotobj_nodes.XData = coords(1,:);
                obj.plotobj_nodes.YData = coords(2,:);
                obj.plotobj_nodes.ZData = coords(3,:);              
            end            
        end
        function X = getDrawCoords(obj, varargin)
            %getDrawCoords Returns the coordinates of the node in the
            %global (MSC.Nastran Basic) coordinate system based on the
            %current 'DrawMode' of the object.
            %
            % Accepts object arrays.
            expectedModes = {'undeformed','deformed'};
            p = inputParser;
            addParameter(p,'Mode','deformed',...
                @(x)any(validatestring(x,expectedModes)));
            addParameter(p,'Scale',1);
            addParameter(p,'Phase',0);
            p.parse(varargin{:})
            
            %Assume the worst
            X = nan(3, numel(obj));
            
            %Check if the object has any undeformed data
            if isprop(obj, 'X')
                X_  = obj.X;
            else
                %EPOINT and SPOINT are set to the origin coordinates
                X_ = zeros(3, obj.NumBulk);
            end
            
            % convert into the global refernce frame
            for c_i = unique(obj.CP)
                if c_i > 0
                    X_(:,obj.CP==c_i) = obj.InputCoordSys.getPosition(X_(:,obj.CP==c_i),c_i); 
                end
            end
            
            idx = cellfun(@isempty, {X_});
            if any(idx)
                warning(['Some ''awi.fe.Node'' objects do not have '   , ...
                    'any coordinate data. Update these objects before ', ...
                    'attempting to draw the model.']);
                return
            end
            X = horzcat(X_);
            
            %If the user wants the undeformed model then there is nothing
            %else to do
            if strcmp(p.Results.Mode, 'undeformed')
                return
            end
            
            %If we get this far then we need to add the displacements...
            
            % - Legacy code from Chris not really sure what it did
            % idx = ismember(get(obj, {'DrawMode'}), 'deformed');
            
            %Check displacements have been defined
            dT  = {obj.Deformation};
            if isempty(dT) || any(cellfun(@isempty, dT))
                if strcmp(p.Results.Mode, 'deformed')
                    warning(['Some ''awi.fe.Node'' objects do not have '   , ...
                        'any deformation data, returning undeformed model.', ...
                        'Update these objects before attempting to draw '  , ...
                        'the model.']);
                end
                return
            end
            if size(dT{:},1) == 3
                dT = dT{:}*p.Results.Scale;
            elseif size(dT{:},1) ~= 3 && size(dT{:},2) == 3
                dT = dT{:}'*p.Results.Scale;           
            else
                error('deformation data must have one dimension of length 3')
            end
                
            dT = abs(dT).*cos(angle(dT)+p.Results.Phase);
            
%             dT = horzcat(dT{:})*p.Results.Scale;
            
            % convert into the global refernce frame
            for c_i = unique(obj.CD)
               dT(:,obj.CD==c_i) = obj.OutputCoordSys...
                   .getVector(dT(:,obj.CD==c_i),c_i); 
            end
            
            %Simple
            X(:, :) = X(:, :) + dT;
            
        end
    end
    
end
