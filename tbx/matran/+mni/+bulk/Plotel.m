classdef Plotel < mni.bulk.BulkData
    %PLOTEL Describes a 1D element between 2 Nodes. To Aid plotting
    %
    % The definition of the 'plotel' object matches that of the PLOTEL bulk
    % data type from MSC.Nastran.
    properties(Hidden = true)
        plotobj_plotel;
    end
    methods % construction
        function obj = Plotel(varargin)
                        
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'PLOTEL', ...
                'BulkProps'  , {'EID', 'GA_GB'}, ...
                'PropTypes'  , {'i'  , 'i'    }, ...
                'PropDefault', {''   , ''     }, ...
                'IDProp'     , 'EID', ...
                'PropMask'   , {'GA_GB', 2}, ...
                'Connections', {'GA_GB', 'mni.bulk.Node', 'Nodes'}, ...
                'AttrList'   , {'GA_GB', {'nrows', 2}});
            varargin = parse(obj, varargin{:});
            preallocate(obj);
                        
        end
    end
    
    methods % assigning data during import
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
            prpData{ismember(prpNames, 'GA_GB')}   = vertcat(bulkData{ismember(bulkNames, {'GA', 'GB'})});      
            
            assignH5BulkData@mni.bulk.BulkData(obj, prpNames, prpData)
        end
    end
    
    methods % visualisation
        function hg = drawElement(obj, hAx)
            %drawElement Draws the beam objects as a line object between
            %the nodes and returns a single handle for all the beams in the
            %collection.
            
            hg = [];
            
            if isempty(obj.Nodes)
                return
            end
            
            coords = getDrawCoords(obj.Nodes);            
            xA     = coords(:, obj.NodesIndex(1, :));
            xB     = coords(:, obj.NodesIndex(2, :));  
            
            hg = drawLines(xA, xB, hAx,'Tag','Plotel','Color','c',...
                'UserData',obj,'DeleteFcn',@obj.plotelDelete);
            obj.plotobj_plotel = hg;            
        end
        function plotelDelete(~,~,~)
            h = gcbo;
            h.UserData.plotobj_plotel = []; 
        end
        function updateElement(obj,~)
            if ~isempty(obj.plotobj_plotel)
                coords = getDrawCoords(obj.Nodes);            
                xA     = coords(:, obj.NodesIndex(1, :));
                xB     = coords(:, obj.NodesIndex(2, :));

                x  = padCoordsWithNaN([xA(1, :) ; xB(1, :)]);
                y  = padCoordsWithNaN([xA(2, :) ; xB(2, :)]);
                z  = padCoordsWithNaN([xA(3, :) ; xB(3, :)]);

                plotobj_plotel.XData = x;
                plotobj_plotel.YData = y;
                plotobj_plotel.ZData = z; 
            end
        end
    end
    
end

