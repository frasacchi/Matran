classdef AeroPanel < mni.bulk.BulkData
    %AeroPanel Describes a collection of aerodynamic panels.
    %
    % The definition of the 'AeroPanel' object matches that of the CAERO1
    % bulk data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'CAERO1'
    properties
        PanelPressure;
        PanelForce;
    end
    properties(Hidden = true)    
        plotobj_patch;
        plotobj_quiver;
    end
    
    methods % construction
        function obj = AeroPanel(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'CAERO1', ...
                'BulkProps'  , {'EID', 'PID', 'CP', 'NSPAN', 'NCHORD', 'LSPAN', 'LCHORD', 'IGID', 'X1', 'X12', 'X4', 'X43'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'i' , 'i'    , 'i'     , 'i'    , 'i'     , 'i'   , 'r' , 'r'  , 'r' , 'r'}  , ...
                'PropDefault', {''   , 1453   , 0   , 0      , 0       , 0      , 0       , 0     , ''  , 0    , ''  , 0}    , ...
                'IDProp'     , 'EID', ...
                'PropMask'   , {'X1', 3, 'X4', 3} , ...
                'Connections', { ...
                'PID'   , 'PAERO1', 'AeroBody', ...
                'LSPAN' , 'AEFACT', 'SpanDivision', ...
                'LCHORD', 'AEFACT', 'ChordDivision', ...
                'CP', 'mni.bulk.CoordSystem', 'InputCoordSys'}, ...
                'AttrList'   , {'X1', {'nrows', 3}, 'X4', {'nrows', 3}});            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
        end
    end
    
    methods % assigning data during import
        function assignH5BulkData(obj, bulkNames, bulkData)
            %assignH5BulkData Assigns the object data during the import
            %from a .h5 file.
            
            if ~strcmp(obj.CardName, 'CAERO1')
                error('Update code');
            end
            
            prpNames   = obj.CurrentBulkDataProps;
            
            %Build the prop data 
            prpData       = cell(size(prpNames));            
            prpData(ismember(prpNames, bulkNames)) = bulkData(ismember(bulkNames, prpNames));
            prpData{ismember(prpNames, 'X1')}   = vertcat(bulkData{ismember(bulkNames, {'X1', 'Y1', 'Z1'})});
            prpData{ismember(prpNames, 'X4')}   = vertcat(bulkData{ismember(bulkNames, {'X4', 'Y4', 'Z4'})});
            
            assignH5BulkData@mni.bulk.BulkData(obj, prpNames, prpData)
        end
    end
    
    methods % visualisation
        function hg = drawElement(obj, hAx, varargin)
            %drawElement Draws the AeroPanel object as a single patch
            %object and returns a single graphics handle for all AeroPanels
            %in the collection.
                        
            obj.plotobj_patch = [];
            obj.plotobj_quiver = [];
            
            %Grab the panel data      
            PanelData = getPanelData(obj);             
            if isempty(PanelData) || any(cellfun(@isempty, {PanelData.Coords}))
                return
            end
            if isempty(obj.PanelPressure)
                obj.PanelPressure = zeros(size(PanelData.IDs));
            end
            if isempty(obj.PanelForce)
                obj.PanelForce = zeros(size(PanelData.IDs,1),6);
            end
            %Arrange vertex coordinates for vectorised plotting
            x = PanelData.Coords(:, 1 : 4, 1)';
            y = PanelData.Coords(:, 1 : 4, 2)';
            z = PanelData.Coords(:, 1 : 4, 3)';
            
            % plot patch       
            c = obj.pressure2color(obj.PanelPressure);                       
            obj.plotobj_patch = patch(hAx,'XData', x,'YData', y,'ZData', z, ...
                'Tag'      , 'Aero Panels', ...
                'CData', c,'FaceColor','flat','UserData',obj,...
                'DeleteFcn',@obj.patchDelete);            
            hg = obj.plotobj_patch;
            
            % plot quiver
%             if any(obj.PanelForce)
                vec = bsxfun(@times,obj.PanelForce(:,3),PanelData.Norms);
                obj.plotobj_quiver = quiver3(hAx,PanelData.Centre(:,1),...
                    PanelData.Centre(:,2),PanelData.Centre(:,3),...
                    vec(:,1),vec(:,2),vec(:,3),'r','Tag','Aero Force',...
                'DeleteFcn',@obj.quiverDelete,'UserData',obj);            
%             end
            hg(2) = obj.plotobj_quiver;
        end
        function updateElement(obj,varargin)
            PanelData = getPanelData(obj);
            %Arrange vertex coordinates for vectorised plotting
            x = PanelData.Coords(:, 1 : 4, 1)';
            y = PanelData.Coords(:, 1 : 4, 2)';
            z = PanelData.Coords(:, 1 : 4, 3)';
            %update patch
            if ~isempty(obj.plotobj_patch)
                obj.plotobj_patch.XData = x;
                obj.plotobj_patch.YData = y;
                obj.plotobj_patch.ZData = z;
                obj.plotobj_patch.CData = obj.pressure2color(obj.PanelPressure);
            end
            %update quivers
            if ~isempty(obj.plotobj_quiver)
                vec = bsxfun(@times,obj.PanelForce(:,3),PanelData.Norms);
                obj.plotobj_quiver.XData = PanelData.Centre(:,1);
                obj.plotobj_quiver.YData = PanelData.Centre(:,2);
                obj.plotobj_quiver.ZData = PanelData.Centre(:,3);
                obj.plotobj_quiver.UData = vec(:,1);
                obj.plotobj_quiver.VData = vec(:,2);
                obj.plotobj_quiver.WData = vec(:,3);
            end
        end
        function quiverDelete(obj,~,~)
            h = gcbo;
            h.UserData.plotobj_quiver = [];
        end
        function patchDelete(obj,~,~)
            h = gcbo;
            h.UserData.plotobj_patch = [];
        end
    end
    
    methods % helper functions 
        function PanelData = getPanelData(obj)
            %getPanelData Calculates the panel coordinates.                                 
            PanelData = repmat(struct('Coords', [], 'Centre', []), [1, obj.NumBulk]);
            
            if isempty(PanelData)
                return
            end
            
            %Parse
            if any(cellfun(@isempty, get(obj, {'X1', 'X12', 'X4', 'X43'})))
                warning('Panel vertices could not be defined.');
                return
            end
            if any(all([obj.NSPAN == 0 ; obj.LSPAN == 0]))
                warning(['Panel increments in spanwise direction ', ...
                    'could not be defined.']);
                return
            end
            if any(all([obj.NCHORD == 0 ; obj.LCHORD == 0]))
                warning(['Panel increments in chordwise direction ', ...
                    'could not be defined.']);
                return
            end
            if any(obj.LSPAN ~= 0) && isempty(obj.SpanDivision)
                warning('FLFACT entry not referenced in AeroPanel object. Check ''makeIndices'' function.');
                return
            end
            if any(obj.LCHORD ~= 0) && isempty(obj.ChordDivision)
                warning('FLFACT entry not referenced in AeroPanel object. Check ''makeIndices'' function.');
                return
            end
            
            % loop through aero panels in the same order as Nastran (by
            % EID) to ensure matrices are in the same order as result
            % matrices
            [~,eid_order] = sort (obj.EID); 
            
            %Loop through the data and generate panel coordinates
            for ii = 1:obj.NumBulk
                obj_i = eid_order(ii);
                %convert corners to global coordinate system
                if isempty(obj.InputCoordSysIndex)
                    X1 = obj.X1(:,obj_i);
                    X4 = obj.X4(:,obj_i);
                else
                    X1 = obj.InputCoordSys.getPosition(obj.X1(:,obj_i),obj.CP(obj_i));
                    X4 = obj.InputCoordSys.getPosition(obj.X4(:,obj_i),obj.CP(obj_i));
                end
                v_norm = cross([1 0 0]',X4-X1);
                v_norm = v_norm / norm(v_norm);
                %Get the corner coordinates
                xC = [ ...
                    [X1(1) ; X1(1) + obj.X12(obj_i)], ...
                    [X4(1) ; X4(1) + obj.X43(obj_i)]];
                yC = [ ...
                    [X1(2) ; X1(2)], ...
                    [X4(2) ; X4(2)]];
                zC = [ ...
                    [X1(3) ; X1(3)], ...
                    [X4(3) ; X4(3)]];  
                
                %Get the panel divisions
                if obj.LSPAN(obj_i) == 0
                    dSpan   = 1 / obj.NSPAN(obj_i);
                    etaSpan = unique([0 : dSpan :  1, 1]);
                else
                    etaSpan = obj.SpanDivision.Di{obj.SpanDivisionIndex(obj_i)};
                end                
                if obj.LCHORD(obj_i)== 0
                    dChord   = 1 / obj.NCHORD(obj_i);
                    etaChord = unique([0 : dChord : 1, 1]);                   
                else
                    etaChord = obj.ChordDivision.Di{obj.ChordDivisionIndex(obj_i)};
                end                                
                if iscolumn(etaSpan) || iscolumn(etaChord)
                    error('Why is this happening?'); %TODO remove this once we know this will never happen                   
                end
                
                % Number of Panels
                num_panel = (length(etaSpan)-1) * (length(etaChord)-1);
                                
                %Panel coordinates
                [xDat, yDat, zDat] = i_chordwisePanelCoords(xC, yC, zC, etaSpan, etaChord);
                
                %Define panels [5, nPanel, 3]
                PanelData(ii).Coords = i_panelVerticies(xDat, yDat, zDat, etaChord, etaSpan);
                
                %Calculate centre of panel
                PanelData(ii).Centre  = permute(mean(PanelData(ii).Coords(:, 1 : 4, :), 2), [1, 3, 2]);
                
                % calculate ID's
                PanelData(ii).IDs = [obj.EID(obj_i):obj.EID(obj_i)+num_panel-1]';
                
                % calculate Panel Norms
                PanelData(ii).Norms = repmat(v_norm',num_panel,1);
                
            end
                        
            function [xDat, yDat, zDat] = i_chordwisePanelCoords(x, y, z, etaSpan, etaChord)
                %i_chordwisePanelCoords : Defines the (x,y,z) coordinates
                %of each panel corner. Should return 3 matricies (X,Y,Z) of
                %size [2, nSpanPanels + 1]
                
                nSpanPoints  = numel(etaSpan);
                nChordPoints = numel(etaChord);
                
                %Difference in x & y & z across panel
                dX = diff(x, [], 2);
                dY = diff(y, [], 2);
                dZ = diff(z, [], 2);
                
                %Chordwise lines -- plotted at intermediate locations,
                %therefore new x and z values are required!
                X = repmat(x(:, 1), [1, nSpanPoints]) + dX * etaSpan;
                Y = repmat(y(:, 1), [1, nSpanPoints]) + dY * etaSpan;
                Z = repmat(z(:, 1), [1, nSpanPoints]) + dZ * etaSpan;
                
                %Coordinates of each panel vertex
                xDat = X(1, :) + (diff(X)' * etaChord)';
                yDat = repmat(Y(1, :), [nChordPoints, 1]);
                zDat = repmat(Z(1, :), [nChordPoints, 1]);
                
            end
          
            function panel = i_panelVerticies(xDat, yDat, zDat, etaChord, etaSpan)
                %TODO - Vectorise this!
                
                nChord = numel(etaChord) - 1; 
                nSpan  = numel(etaSpan) - 1;
                
                %Preallocate
                panel = zeros(5, nChord * nSpan, 3);
                
                k = 1;                  % counter for the panel ID
                for j = 1 : nSpan       % <-- loop through spanwise points
                    for i = 1 : nChord  % <-- loop through chordwise points
                        % panel x-coordinates
                        panel(1, k, 1) = xDat(i    , j);
                        panel(2, k, 1) = xDat(i + 1, j);
                        panel(3, k, 1) = xDat(i + 1, j + 1);
                        panel(4, k, 1) = xDat(i    , j + 1);
                        panel(5, k, 1) = xDat(i    , j);
                        % panel y-coordinates
                        panel(1, k, 2) = yDat(i    , j);
                        panel(2, k, 2) = yDat(i + 1, j);
                        panel(3, k, 2) = yDat(i + 1, j + 1);
                        panel(4, k, 2) = yDat(i    , j + 1);
                        panel(5, k, 2) = yDat(i    , j);
                        % panel z-coordinates
                        panel(1, k, 3) = zDat(i    , j);
                        panel(2, k, 3) = zDat(i + 1, j);
                        panel(3, k, 3) = zDat(i + 1, j + 1);
                        panel(4, k, 3) = zDat(i    , j + 1);
                        panel(5, k, 3) = zDat(i    , j);
                        % next counter
                        k = k + 1;
                    end
                end
                
                panel = permute(panel, [2, 1, 3]);
                
            end
            
            %Combine into a single set 
            PanelData = struct( ...
                'Coords', vertcat(PanelData.Coords), ...
                'Centre', vertcat(PanelData.Centre), ...
                'IDs'   , vertcat(PanelData.IDs), ...
                'Norms' , vertcat(PanelData.Norms));
                                
        end
    end
    
    methods(Static) % static helper functions
        function c = pressure2color(p)
            if ~any(p)
                c = repmat([201]/255,length(p),3);
                c = reshape(c,length(p),1,3);
            else
                c = p;
            end
        end
    end
    
end

