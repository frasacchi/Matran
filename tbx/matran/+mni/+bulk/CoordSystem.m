classdef CoordSystem < mni.bulk.BulkData
    %CoordSystem Describes a rectangular coordinate system.
    %
    % The definition of the 'CoordSys' object matches that of the CORD2R
    % bulk data type from MSC.Nastran.
    %
    % Valid Bulk Data Types:
    %   - 'CORD1R' TODO
    %   - 'CORD2R'
    
    methods % construction
        function obj = CoordSystem(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'CORD2R', ...
                'BulkProps'  , {'CID', 'RID', 'A', 'B', 'C'}, ...
                'PropTypes'  , {'i'  , 'i'  , 'r', 'r', 'r'}, ...
                'PropDefault', {''   , 0    , 0  , 0  , 0  }, ...
                'IDProp'     , 'CID', ...
                'Connections', {'RID', 'mni.bulk.CoordSystem', 'InputCoordSys'}, ...
                'PropMask'   , {'A', 3, 'B', 3, 'C', 3}, ...
                'AttrList'   , {'A', {'nrows', 3}, 'B', {'nrows', 3}, 'C', {'nrows', 3}});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
    methods % assigning data during import
        function assignH5BulkData(obj, bulkNames, bulkData)
            %assignH5BulkData Assigns the object data during the import
            %from a .h5 file.
            
            if ~strcmp(obj.CardName, 'CORD2R')
                error('Update code');
            end
            
            prpNames   = obj.CurrentBulkDataProps;
            
            %Build the prop data 
            prpData       = cell(size(prpNames));            
            prpData(ismember(prpNames, bulkNames)) = bulkData(ismember(bulkNames, prpNames));
            prpData{ismember(prpNames, 'A')}   = vertcat(bulkData{ismember(bulkNames, {'A1', 'A2', 'A3'})});
            prpData{ismember(prpNames, 'B')}   = vertcat(bulkData{ismember(bulkNames, {'B1', 'B2', 'B3'})});
            prpData{ismember(prpNames, 'C')}   = vertcat(bulkData{ismember(bulkNames, {'C1', 'C2', 'C3'})});
            
            assignH5BulkData@mni.bulk.BulkData(obj, prpNames, prpData)
        end
    end
    
    methods (Sealed)
        function rMatrix = getRotationMatrix(obj,cid)
            %getRotationMatrix Calculates the 3x3 rotation matrix for each
            %coordinate system.
            
            %return identity matrix for base coordinate system
            rMatrix = eye(3);
            if cid == 0
                return
            end
            
            switch obj.CardName
                case 'CORD2R'
                    if ~any(obj.CID==cid)
                        error('Coord System with CID %d is unkown',cid)
                    end
                    c_index = find(obj.CID==cid,1);
                        
                    a = obj.A(:,c_index);
                    b = obj.B(:,c_index);
                    c = obj.C(:,c_index);
                    
                    eZ = b - a;
                    eX = c - a;                    
                    eY = cross(eZ, eX);
                    
                    %Ensure unit vectors
                    eX = eX./sqrt(sum(eX.^2));
                    eY = eY./sqrt(sum(eY.^2));
                    eZ = eZ./sqrt(sum(eZ.^2));
                                       
                    rMatrix = [eX,eY,eZ];
                    
                otherwise
                    warning('Update code for new coordinate system type.');
            end
            
        end
        function originCoords = getOrigin(obj,cid)
            %getOrigin Calculates the (x,y,z) coordinates of the origin of
            %the coordinates system in the local frame.
            if cid == 0
                originCoords = zeros(3,1);
                return
            elseif ~any(obj.CID==cid)
                error('Coord System with CID %d is unkown',cid)
            end
            c_index = find(obj.CID==cid,1);
            
            originCoords = obj.A(:,c_index);         
        end
        function pos = getPosition(obj,X,cid,varargin)
            %GETPOSITION returns the {x,y,z} location of position X (
            %defined in the local coordinate system cid) in the global
            %coordinate system
            p = inputParser();
            p.addParameter('Recursive',true)
            p.parse(varargin{:})
            if cid == 0
               pos = X;
               return
            end
            if ~any(obj.CID==cid)
                error('Coord System with CID %d is unkown',cid)
            end
            c_index = find(obj.CID==cid,1);
            
            % get rotation matrix and origin in refrence frame
            r = obj.getRotationMatrix(cid);
            o = obj.getOrigin(cid);
            o = repmat(o,1,size(X,2));
            
            % calc position in reference frame
            pos = o+r*X;
            % if the reference frame is not the global frame recurisvely
            % call this function
            if obj.RID(c_index) ~= 0 || ~p.Results.Recursive
                pos = obj.getPosition(pos,obj.RID(c_index));
            end         
        end
        function vec = getVector(obj,X,cid)
            %GETVECTOR returns the orientation of vector X (
            %defined in the local coordinate system cid) in the global
            %coordinate system
            if cid == 0
               vec = X;
               return
            end
            if ~any(obj.CID==cid)
                error('Coord System with CID %d is unkown',cid)
            end
            c_index = find(obj.CID==cid,1);
            % get rotation matrix and origin in refrence frame
            r = obj.getRotationMatrix(cid);
            
            % calc position in reference frame
            vec = r*X;
            % if the reference frame is not the global frame recurisvely
            % call this function
            if obj.RID(c_index) ~= 0
                vec = obj.getVector(vec,obj.RID(c_index));
            end         
        end
    end
    
    methods % visualiation
        function hg = drawElement(obj, ~,hAx, varargin)
            
            hg = [];
            
            cids = unique(obj.CID);
            [o,oX,oY,oZ] = deal(zeros(3,length(cids)));
            for i = 1:length(cids)
                o(:,i) = obj.getPosition([0;0;0],cids(i));
                eX = obj.getVector([1;0;0],cids(i));
                eY = obj.getVector([0;1;0],cids(i));
                eZ = obj.getVector([0;0;1],cids(i));
                
                oX(:,i) = o(:,i) + eX;
                oY(:,i) = o(:,i) + eY;
                oZ(:,i) = o(:,i) + eZ;
            end                        
            %Plot
            %hg    = gobjects(1, 3);
            hg(1) = drawLines(o, oX, hAx, 'Color', [0, 1, 0], 'LineWidth', 2, 'Tag', 'Coord Systems');
            hg(2) = drawLines(o, oY, hAx, 'Color', [0, 0, 1], 'LineWidth', 2, 'Tag', 'Coord Systems');
            hg(3) = drawLines(o, oZ, hAx, 'Color', [1, 0, 0], 'LineWidth', 2, 'Tag', 'Coord Systems');
                             
            if obj.NumBulk > 20
                return
            end
            
            %Add text annotation for CID numbers            
            text(o(1, :), o(2, :), o(3, :), ...
                strtrim(cellstr(num2str([obj.CID]'))'), ...
                'Color'   , 'black', ...
                'FontSize', 12     , ...
                'Parent'  , hAx, ...
                'Tag', 'Coord Systems');
            
            %Add text labels for x,y,z axes            
            text(oX(1, :), oX(2, :), oX(3, :), 'X', ...
                'Parent'  , hAx    , ...
                'Color'   , get(hg(1), 'Color'), ...
                'FontSize', 12, ...
                'Tag', 'Coord Systems');
            text(oY(1, :), oY(2, :), oY(3, :), 'Y', ...
                'Parent'  , hAx   , ...
                'Color'   , get(hg(2), 'Color'), ...
                'FontSize', 12, ...
                'Tag', 'Coord Systems');
            text(oZ(1, :), oZ(2, :), oZ(3, :), 'Z', ...
                'Parent'  , hAx   , ...
                'Color'   , get(hg(3), 'Color'), ...
                'FontSize', 12, ...
                'Tag', 'Coord Systems');
            hg = hg(1);
            
        end
    end
    
end

