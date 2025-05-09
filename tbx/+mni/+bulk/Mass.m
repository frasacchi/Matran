classdef Mass < mni.bulk.BulkData
    %Mass Describes a mass element in the model which is associated with a
    %Node.
    %
    % Valid Bulk Data Types:
    %   - CONM1 
    %   - CONM2    
    properties(Hidden = true)
        plotobj_mass;
    end
    methods % construction
        function obj = Mass(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'CONM1' , ...
                'BulkProps'  , {'EID', 'G', 'CID', 'M1', 'M2', 'M3', 'M4', 'M5', 'M6'}, ...
                'PropTypes'  , {'i'  , 'i', 'i'  , 'r' , 'r' , 'r' , 'r' , 'r' , 'r'} , ...
                'PropDefault', {''   , '' , 0    , 0   , 0   , 0   , 0   , 0   , 0  } , ...
                'IDProp'     , 'EID', ...
                'PropMask'   , {'M2', 2, 'M3', 3, 'M4', 4, 'M5', 5, 'M6', 6}, ...
                'AttrList'   , {'M2', {'nrows', 2}, 'M3', {'nrows', 3}, ...
                'M4', {'nrows', 4}, 'M5', {'nrows', 5}, 'M6', {'nrows', 6}}, ...
                'Connections', {'G', 'mni.bulk.Node', 'Nodes', 'CID', 'mni.bulk.CoordSystem', 'CoordSys'}, ...
                'SetMethod',{'CID',@validateCID});  
            addBulkDataSet(obj, 'CONM2', ...
                'BulkProps'  , {'EID', 'G', 'CID', 'M', 'X',    'I1', 'I2', 'I3'}, ...
                'PropTypes'  , {'i'  , 'i', 'i'  , 'r', 'r','b', 'r' , 'r' , 'r' }, ...
                'PropDefault', {''   , '' , 0    , 0  , 0  , 0   , 0   , 0   }, ...
                'IDProp'     , 'EID', ...
                'PropMask'   , {'X', 3, 'I2', 2, 'I3', 3}, ...
                'AttrList'   , {'X', {'nrows', 3}, 'I2', {'nrows', 2}, 'I3', {'nrows', 3}}, ...
                'Connections', {'G', 'mni.bulk.Node', 'Nodes', 'CID', 'mni.bulk.CoordSystem', 'CoordSys'}, ...
                'SetMethod',{'CID',@validateCID});                        
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
    methods% assigning data during import
        function assignH5BulkData(obj, bulkNames, bulkData)
            %assignH5BulkData Assigns the object data during the import
            %from a .h5 file.
            
            prpNames   = obj.CurrentBulkDataProps;
            
            %Index of matching bulk data names
            [~, ind]  = ismember(bulkNames, prpNames);
            [~, ind_] = ismember(prpNames, bulkNames);
            
            %Build the prop data
            prpData  = cell(size(prpNames));
            prpData(ind(ind ~= 0)) = bulkData(ind_(ind_ ~= 0));            
            switch obj.CardName                
                case 'CONM2'
                     prpData{ismember(prpNames, 'X')} = ...
                         vertcat(bulkData{ismember(bulkNames, {'X1', 'X2', 'X3'})});                    
            end
            assignH5BulkData@mni.bulk.BulkData(obj, prpNames, prpData)
            
        end
    end
    
    methods % visualisation
        function coords = get_drawCoords(obj,varargin)
            p = obj.parseInput(varargin{:});
            coords = getDrawCoords(obj.Nodes,'Mode',p.Results.Mode,...
                'Scale',p.Results.Scale,'Phase',p.Results.Phase);
            if isempty(coords)
                return
            end
            coords = coords(:, obj.NodesIndex);
            for c_i = unique(obj.CID)
                idx = obj.CID==c_i;
                switch obj.CardName
                    case 'CONM1'
                        if c_i == -1
                            coords(:,idx) = [0;0;0];
                        end
                    case 'CONM2'
                        if c_i > 0
                            vector = obj.CoordSys.getVector(obj.X(:,idx),c_i);
                            coords(:,idx) = coords(:,idx) + vector;
                        elseif c_i == 0
                            coords(:,idx) = coords(:,idx) + obj.X(:,idx);
                        elseif c_i == -1
                            coords(:,idx) = obj.X(:,idx);
                        end
                    otherwise
                        error('Unknown Mass card of %s',obj.CardName);
                end
            end
        end
        
        function hg = drawElement(obj, ~, hAx, varargin)            
            hg = [];           
            if isempty(obj.Nodes)
                return
            end            
            coords = obj.get_drawCoords(varargin{:});            
            hg = drawNodes(coords, hAx, ...
                'Marker', '^', 'MarkerFaceColor', 'b', 'Tag', 'Mass',...
                'UserData',obj,'DeleteFcn',@obj.massDelete);
            obj.plotobj_mass = hg;
            
        end        
        function updateElement(obj,varargin)            
            if ~isempty(obj.plotobj_mass)
                coords = obj.get_drawCoords(varargin{:});  
                obj.plotobj_mass.XData = coords(1,:);
                obj.plotobj_mass.YData = coords(2,:);
                obj.plotobj_mass.ZData = coords(3,:);      
            end
        end
        end
    methods(Static,Hidden)
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
        function massDelete(~,~)
            h = gcbo;
            h.UserData.plotobj_mass = []; 
        end
    end
    
end

function validateCID(obj, val, prpName, varargin)    %validateID
    if isempty(val)
        return
    end
    if iscell(val)
        cellfun(@(x) validateID(obj, x, prpName), val)
        return
    end
    validateattributes(val, {'numeric'}, {'integer', '2d', ...
        'real', 'nonnan', '>=',-1}, class(obj), prpName);
end

