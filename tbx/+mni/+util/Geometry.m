classdef Geometry < handle
    %Geometry Resolves the coordinate systems and grid points of a model in
    %the basic system (QRG ch.9 CORD1R/C/S, CORD2R/C/S, GRID).
    %
    % Syntax:
    %   >> geo = mni.util.Geometry(fem);
    %   >> X   = geo.position([1001 1002]);     %basic positions (3 x n)
    %   >> [O, R] = geo.frame(102);              %origin, axes of CID 102
    %   >> T   = geo.dispFrame(1001);            %displacement axes of grid
    %   >> Xb  = geo.toBasic([1; 2; 3], 102);    %point given in CID 102
    %   >> Vb  = geo.vecToBasic([0; 0; 1], 102, Xb);
    %
    % Notes:
    %   - R holds the local axes as columns (x_basic = O + R * x_local for
    %     rectangular systems).
    %   - Cylindrical (R, THETA, Z) and spherical (R, THETA, PHI) input is
    %     converted with angles in degrees; their displacement axes depend
    %     on the location (QRG GRID remark: radial, tangential, axial).
    %   - Systems are resolved in dependency order (RID chains, CORD1x on
    %     grids); circular or missing references raise an error.

    properties (SetAccess = private)
        CID    = zeros(1, 0);  %coordinate system identifiers
        Type   = '';           %'R', 'C' or 'S' per system
        Origin = zeros(3, 0);  %origins in basic
        Axes   = zeros(3, 3, 0); %local axes (columns) in basic
        GID    = zeros(1, 0);  %grid identifiers
        X      = zeros(3, 0);  %grid positions in basic
        CP     = zeros(1, 0);
        CD     = zeros(1, 0);
    end

    methods
        function obj = Geometry(fem)
            if nargin == 0 || isempty(fem)
                return
            end
            %grids
            if isprop(fem, 'GRID')
                g = fem.GRID;
                obj.GID = double(g.GID);
                local   = double(g.X);
                obj.CP  = double(g.CP);
                obj.CD  = double(g.CD);
            else
                local = zeros(3, 0);
            end
            %coordinate system definitions
            defs = struct('CID', {}, 'Type', {}, 'Form', {}, 'RID', {}, 'ABC', {}, 'G', {});
            for t = {'CORD2R', 'CORD2C', 'CORD2S'}
                if ~isprop(fem, t{1}), continue, end
                c = fem.(t{1});
                for i = 1 : c.NumBulk
                    defs(end + 1) = struct('CID', c.CID(i), 'Type', t{1}(end), 'Form', 2, ...
                        'RID', c.RID(i), 'ABC', [c.A(:, i), c.B(:, i), c.C(:, i)], 'G', []); %#ok<AGROW>
                end
            end
            for t = {'CORD1R', 'CORD1C', 'CORD1S'}
                if ~isprop(fem, t{1}), continue, end
                c = fem.(t{1});
                for i = 1 : c.NumBulk
                    defs(end + 1) = struct('CID', c.CIDA(i), 'Type', t{1}(end), 'Form', 1, ...
                        'RID', 0, 'ABC', [], 'G', [c.G1A(i), c.G2A(i), c.G3A(i)]); %#ok<AGROW>
                    if c.CIDB(i) > 0
                        defs(end + 1) = struct('CID', c.CIDB(i), 'Type', t{1}(end), 'Form', 1, ...
                            'RID', 0, 'ABC', [], 'G', [c.G1B(i), c.G2B(i), c.G3B(i)]); %#ok<AGROW>
                    end
                end
            end
            obj.X = nan(size(local));
            done  = false(1, numel(defs));
            gDone = false(1, numel(obj.GID));
            %iterate: resolve grids whose CP is known, then systems whose
            %reference (RID or grids) is known
            for pass = 1 : numel(defs) + 2
                %grids
                for k = find(~gDone)
                    cp = obj.CP(k);
                    if cp == 0 || any(obj.CID == cp)
                        obj.X(:, k) = obj.toBasic(local(:, k), cp);
                        gDone(k) = true;
                    end
                end
                progress = false;
                for d = find(~done)
                    s = defs(d);
                    if s.Form == 2
                        if s.RID ~= 0 && ~any(obj.CID == s.RID)
                            continue
                        end
                        P = obj.toBasic(s.ABC, s.RID);
                    else
                        [kk, ok] = ismember(s.G, obj.GID);
                        if ~all(kk) || ~all(gDone(ok))
                            continue
                        end
                        P = obj.X(:, ok);
                    end
                    [o, R] = i_frame(P(:, 1), P(:, 2), P(:, 3));
                    obj.CID(end + 1) = s.CID;
                    obj.Type(end + 1) = s.Type;
                    obj.Origin(:, end + 1) = o;
                    obj.Axes(:, :, end + 1) = R;
                    done(d) = true;
                    progress = true;
                end
                if all(done) && all(gDone)
                    break
                end
                if ~progress && all(gDone(obj.CP == 0 | ismember(obj.CP, obj.CID)))
                    break
                end
            end
            if ~all(done)
                error('mni:util:Geometry', 'Unresolved coordinate systems: %s', ...
                    mat2str([defs(~done).CID]));
            end
            if ~all(gDone)
                error('mni:util:Geometry', 'Grids in undefined coordinate systems: %s', ...
                    mat2str(unique(obj.CP(~gDone))));
            end
        end
        function k = gridIndex(obj, ids)
            %gridIndex Index of the grid identifiers (NaN if unknown).
            [tf, k] = ismember(ids, obj.GID);
            k = double(k);
            k(~tf) = NaN;
        end
        function P = position(obj, ids)
            %position Basic positions (3 x n) of grids 'ids'.
            k = obj.gridIndex(ids);
            assert(~any(isnan(k(:))), 'mni:util:Geometry', 'Unknown grid(s) %s', ...
                mat2str(ids(isnan(k))));
            P = obj.X(:, k);
        end
        function [O, R, type] = frame(obj, cid)
            %frame Origin and axes (columns) of system 'cid' in basic.
            if cid == 0
                O = zeros(3, 1); R = eye(3); type = 'R';
                return
            end
            k = find(obj.CID == cid, 1);
            assert(~isempty(k), 'mni:util:Geometry', 'Unknown coordinate system %d', cid);
            O = obj.Origin(:, k); R = obj.Axes(:, :, k); type = obj.Type(k);
        end
        function P = toBasic(obj, L, cid)
            %toBasic Points given in system 'cid' (R/C/S coordinates) -> basic.
            if cid == 0
                P = L;
                return
            end
            [O, R, type] = obj.frame(cid);
            P = O + R * i_rect(L, type);
        end
        function L = toLocal(obj, P, cid)
            %toLocal Basic points -> rectangular coordinates of system 'cid'.
            [O, R] = obj.frame(cid);
            L = R' * (P - O);
        end
        function V = vecToBasic(obj, v, cid, at)
            %vecToBasic Vector components in system 'cid' -> basic. For C/S
            %systems the axes at basic location 'at' are used.
            if cid == 0
                V = v;
                return
            end
            V = obj.axesAt(cid, at) * v;
        end
        function T = axesAt(obj, cid, at)
            %axesAt Local displacement axes (columns, basic) of system 'cid'
            %at basic location 'at' (QRG: R - fixed; C - radial,
            %tangential, axial; S - radial, meridional, azimuthal).
            [O, R, type] = obj.frame(cid);
            switch type
                case 'R'
                    T = R;
                case 'C'
                    l = R' * (at - O);
                    th = atan2(l(2), l(1));
                    T = R * [cos(th), -sin(th), 0; sin(th), cos(th), 0; 0, 0, 1];
                case 'S'
                    l = R' * (at - O);
                    r = norm(l);
                    th = acos(max(-1, min(1, l(3) / max(r, eps))));
                    ph = atan2(l(2), l(1));
                    er = [sin(th) * cos(ph); sin(th) * sin(ph); cos(th)];
                    et = [cos(th) * cos(ph); cos(th) * sin(ph); -sin(th)];
                    ep = [-sin(ph); cos(ph); 0];
                    T = R * [er, et, ep];
            end
        end
        function T = dispFrame(obj, id)
            %dispFrame Displacement axes (columns, basic) of grid 'id' (CD).
            k = obj.gridIndex(id);
            assert(~isnan(k), 'mni:util:Geometry', 'Unknown grid %d', id);
            cd = obj.CD(k);
            if cd <= 0
                T = eye(3);
            else
                T = obj.axesAt(cd, obj.X(:, k));
            end
        end
    end
end

function [o, R] = i_frame(A, B, C)
%i_frame QRG CORD2x / CORD1x: origin A, z towards B, C in the x-z plane
ez = (B - A) / norm(B - A);
ey = cross(ez, C - A);
ey = ey / norm(ey);
ex = cross(ey, ez);
o = A;
R = [ex, ey, ez];
end

function L = i_rect(L, type)
%i_rect Cylindrical / spherical coordinates -> rectangular (angles in deg)
switch type
    case 'C'
        r = L(1, :); th = L(2, :); z = L(3, :);
        L = [r .* cosd(th); r .* sind(th); z];
    case 'S'
        r = L(1, :); th = L(2, :); ph = L(3, :);
        L = [r .* sind(th) .* cosd(ph); r .* sind(th) .* sind(ph); r .* cosd(th)];
end
end
