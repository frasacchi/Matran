classdef CoordSystem < mni.bulk.BulkData
    %CoordSystem Describes coordinate systems.
    %
    % Valid Bulk Data Types:
    %   - 'CORD2R', 'CORD2C', 'CORD2S' : CID RID A1-A3 B1-B3 C1-C3
    %   - 'CORD1R', 'CORD1C', 'CORD1S' : CIDA G1A G2A G3A CIDB G1B G2B G3B
    %     (blank second system: CIDB = 0)
    %
    % The methods getRotationMatrix / getPosition / getVector use the CORD2x
    % entries, or for CORD1x the frames resolved at import (resolveFrames).
    % They treat local coordinates as rectangular; mni.util.Geometry also
    % converts cylindrical / spherical coordinates.

    methods % construction
        function obj = CoordSystem(varargin)

            %Initialise the bulk data sets
            for t = {'CORD2R', 'CORD2C', 'CORD2S'}
                addBulkDataSet(obj, t{1}, ...
                    'BulkProps'  , {'CID', 'RID', 'A', 'B', 'C'}, ...
                    'PropTypes'  , {'i'  , 'i'  , 'r', 'r', 'r'}, ...
                    'PropDefault', {''   , 0    , 0  , 0  , 0  }, ...
                    'IDProp'     , 'CID', ...
                    'Connections', {'RID', 'mni.bulk.CoordSystem', 'InputCoordSys'}, ...
                    'PropMask'   , {'A', 3, 'B', 3, 'C', 3}, ...
                    'AttrList'   , {'A', {'nrows', 3}, 'B', {'nrows', 3}, 'C', {'nrows', 3}});
            end
            for t = {'CORD1R', 'CORD1C', 'CORD1S'}
                addBulkDataSet(obj, t{1}, ...
                    'BulkProps'  , {'CIDA', 'G1A', 'G2A', 'G3A', 'CIDB', 'G1B', 'G2B', 'G3B'}, ...
                    'PropTypes'  , {'i'   , 'i'  , 'i'  , 'i'  , 'i'   , 'i'  , 'i'  , 'i'  }, ...
                    'PropDefault', {''    , ''   , ''   , ''   , 0     , 0    , 0    , 0    }, ...
                    'IDProp'     , 'CIDA');
            end
            
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
    
    properties (Hidden)
        %CORD1x frames in basic (CID, origin O, axes R), filled after the
        %import by resolveFrames (CORD1x need the grid positions)
        Resolved = struct('CID', zeros(1, 0), 'O', zeros(3, 0), 'R', zeros(3, 3, 0));
    end

    methods (Sealed)
        function resolveFrames(obj, geo)
            %resolveFrames Stores the CORD1x systems of this object in basic
            %(mni.util.Geometry resolves the grid / system chains).
            if isprop(obj, 'CID')
                return %CORD2x: defined by the entry itself
            end
            cids = unique([obj.CIDA, obj.CIDB(obj.CIDB > 0)]);
            R = struct('CID', zeros(1, 0), 'O', zeros(3, 0), 'R', zeros(3, 3, 0));
            for c = cids
                [O, A] = geo.frame(c);
                R.CID(end + 1) = c;  R.O(:, end + 1) = O;  R.R(:, :, end + 1) = A;
            end
            obj.Resolved = R;
        end
        function rMatrix = getRotationMatrix(obj,cid)
            %getRotationMatrix Calculates the 3x3 rotation matrix for each
            %coordinate system.
            
            %return identity matrix for base coordinate system
            rMatrix = eye(3);
            if cid == 0
                return
            end
            [~, rMatrix] = frameData(obj, cid);
        end
        function originCoords = getOrigin(obj,cid)
            %getOrigin Calculates the (x,y,z) coordinates of the origin of
            %the coordinates system in the local frame.
            if cid == 0
                originCoords = zeros(3,1);
                return
            end
            originCoords = frameData(obj, cid);
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
            % get rotation matrix and origin in refrence frame
            [o, r, rid] = frameData(obj, cid);
            o = repmat(o,1,size(X,2));
            
            % calc position in reference frame
            pos = o+r*X;
            % if the reference frame is not the global frame recurisvely
            % call this function
            if rid ~= 0 && p.Results.Recursive
                pos = obj.getPosition(pos,rid);
            end         
        end
        function vec = getVector(obj,X,cid)
            %GETVECTOR returns the orientation of vector X (
            %defined in the local coordinate system cid) in the global
            %coordinate system
            if isempty(obj) || cid == 0
               vec = X;
               return
            end
            % get rotation matrix in refrence frame
            [~, r, rid] = frameData(obj, cid);
            
            % calc position in reference frame
            vec = r*X;
            % if the reference frame is not the global frame recurisvely
            % call this function
            if rid ~= 0
                vec = obj.getVector(vec,rid);
            end         
        end
    end

    methods (Access = private)
        function [o, r, rid] = frameData(obj, cid)
            %frameData Origin, axes and reference system of system 'cid':
            %CORD2x from the entry (in RID), CORD1x from 'Resolved' (basic)
            if isprop(obj, 'CID')
                c_index = find(obj.CID==cid,1);
                if isempty(c_index)
                    error('Coord System with CID %d is unkown',cid)
                end
                a = obj.A(:,c_index);
                %QRG CORD2R: z along A->B, C lies in the x-z plane (x is
                %the component of C-A normal to z)
                eZ = obj.B(:,c_index) - a;
                eZ = eZ./sqrt(sum(eZ.^2));
                eY = cross(eZ, obj.C(:,c_index) - a);
                eY = eY./sqrt(sum(eY.^2));
                eX = cross(eY, eZ);
                o = a;  r = [eX,eY,eZ];  rid = obj.RID(c_index);
            else
                k = find(obj.Resolved.CID == cid, 1);
                if isempty(k)
                    error(['Coord System with CID %d is unkown (%s systems are resolved at ', ...
                        'import, see resolveFrames)'], cid, obj.CardName)
                end
                o = obj.Resolved.O(:, k);  r = obj.Resolved.R(:, :, k);  rid = 0;
            end
        end
    end
    
    methods % visualiation
        function hg = drawElement(obj, ~,hAx, varargin)

            hg = [];
            if ~isprop(obj, 'CID') %CORD1x: positions need the grids
                return
            end

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

