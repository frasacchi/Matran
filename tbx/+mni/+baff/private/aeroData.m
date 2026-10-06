function A = aeroData(fem, geo)
%aeroData Aerodynamic model of the FEModel in the basic system: CAERO1
%panels (corners, box layout), splines with their structural grids,
%control surfaces (AESURF / AELIST / AELINK), reference data (AERO /
%AEROS) and the DMI downwash / weighting matrices W2GJ / WKK.

A.acsid = 0; A.aeroX = [1; 0; 0];
A.refc = NaN; A.refb = NaN; A.refs = NaN; A.rhoref = NaN; A.velocity = NaN;
A.symxz = 0; A.symxy = 0; A.rcsid = 0;
if isprop(fem, 'AEROS')
    a = fem.AEROS;
    A.acsid = a.ACSID(1); A.rcsid = a.RCSID(1);
    A.refc = a.REFC(1); A.refb = a.REFB(1); A.refs = a.REFS(1);
    A.symxz = a.SYMXZ(1); A.symxy = a.SYMXY(1);
end
if isprop(fem, 'AERO')
    a = fem.AERO;
    if ~isprop(fem, 'AEROS')
        A.acsid = a.ACSID(1);
        A.symxz = a.SYMXZ(1); A.symxy = a.SYMXY(1);
    end
    A.refc = i_pick(A.refc, a.REFC(1));
    A.rhoref = a.RHOREF(1); A.velocity = a.VELOCITY(1);
end
[~, R] = geo.frame(A.acsid);
A.aeroX = R(:, 1);

%AEFACT / AELIST / SET1 lookup
fact = containers.Map('KeyType', 'double', 'ValueType', 'any');
if isprop(fem, 'AEFACT')
    f = fem.AEFACT;
    for i = 1 : f.NumBulk, fact(f.SID(i)) = f.Di{i}; end
end
alist = containers.Map('KeyType', 'double', 'ValueType', 'any');
if isprop(fem, 'AELIST')
    f = fem.AELIST;
    for i = 1 : f.NumBulk, alist(f.SID(i)) = f.E{i}; end
end
sets = containers.Map('KeyType', 'double', 'ValueType', 'any');
if isprop(fem, 'SET1')
    f = fem.SET1;
    for i = 1 : f.NumBulk, sets(f.SID(i)) = f.Gi{i}; end
end
A.fact = fact; A.alist = alist; A.sets = sets;

%CAERO1 panels
A.caero = struct('eid', {}, 'pid', {}, 'cp', {}, 'nspan', {}, 'nchord', {}, 'lspan', {}, ...
    'lchord', {}, 'p1', {}, 'p4', {}, 'c1', {}, 'c4', {}, 'etaChord', {}, 'etaSpan', {}, ...
    'boxIds', {});
if isprop(fem, 'CAERO1')
    c = fem.CAERO1;
    for i = 1 : c.NumBulk
        cp = c.CP(i);
        p1 = geo.toBasic(c.X1(:, i), cp);
        p4 = geo.toBasic(c.X4(:, i), cp);
        ns = c.NSPAN(i); nc = c.NCHORD(i);
        etaS = []; etaC = [];
        if c.LSPAN(i) > 0 && isKey(fact, c.LSPAN(i)), etaS = fact(c.LSPAN(i)); end
        if c.LCHORD(i) > 0 && isKey(fact, c.LCHORD(i)), etaC = fact(c.LCHORD(i)); end
        if isempty(etaS), etaS = linspace(0, 1, ns + 1); end
        if isempty(etaC), etaC = linspace(0, 1, nc + 1); end
        ns = numel(etaS) - 1; nc = numel(etaC) - 1;
        A.caero(end + 1) = struct('eid', c.EID(i), 'pid', c.PID(i), 'cp', cp, 'nspan', ns, ...
            'nchord', nc, 'lspan', c.LSPAN(i), 'lchord', c.LCHORD(i), 'p1', p1, 'p4', p4, ...
            'c1', c.X12(i), 'c4', c.X43(i), 'etaChord', etaC(:)', 'etaSpan', etaS(:)', ...
            'boxIds', c.EID(i) + (0 : ns * nc - 1));
    end
end

%Splines
A.spline = struct('eid', {}, 'card', {}, 'caero', {}, 'boxes', {}, 'nodes', {});
for t = {'SPLINE1', 'SPLINE2', 'SPLINE3', 'SPLINE4', 'SPLINE5', 'SPLINE6', 'SPLINE7'}
    if ~isprop(fem, t{1}), continue, end
    s = fem.(t{1});
    for i = 1 : s.NumBulk
        switch t{1}
            case 'SPLINE1', boxes = s.BOX1(i) : s.BOX2(i);
            case 'SPLINE2', boxes = s.ID1(i) : s.ID2(i);
            case 'SPLINE3', boxes = s.BOXID(i);
            otherwise
                boxes = [];
                if isKey(alist, s.AELIST(i)), boxes = alist(s.AELIST(i)); end
        end
        nodes = [];
        if strcmp(t{1}, 'SPLINE3')
            nodes = [s.G1(i), s.Gi{i}];
        elseif isKey(sets, s.SETG(i))
            nodes = sets(s.SETG(i));
        end
        if strcmp(t{1}, 'SPLINE5')
            eid = s.SID(i);
        else
            eid = s.EID(i);
        end
        A.spline(end + 1) = struct('eid', eid, 'card', t{1}, 'caero', s.CAERO(i), ...
            'boxes', boxes(:)', 'nodes', nodes(:)');
    end
end

%Control surfaces
A.aesurf = struct('id', {}, 'label', {}, 'cid1', {}, 'boxes', {}, 'crefc', {}, ...
    'crefs', {}, 'pllim', {}, 'pulim', {}, 'cid2', {}, 'boxes2', {});
if isprop(fem, 'AESURF')
    s = fem.AESURF;
    for i = 1 : s.NumBulk
        b1 = []; b2 = [];
        if isKey(alist, s.ALID1(i)), b1 = alist(s.ALID1(i)); end
        if ~isnan(s.ALID2(i)) && isKey(alist, s.ALID2(i)), b2 = alist(s.ALID2(i)); end
        A.aesurf(end + 1) = struct('id', s.AEID(i), 'label', s.LABEL{i}, 'cid1', s.CID1(i), ...
            'boxes', b1(:)', 'crefc', s.CREFC(i), 'crefs', s.CREFS(i), 'pllim', s.PLLIM(i), ...
            'pulim', s.PULIM(i), 'cid2', s.CID2(i), 'boxes2', b2(:)');
    end
end
A.aelink = struct('id', {}, 'dep', {}, 'labels', {}, 'coeffs', {});
if isprop(fem, 'AELINK')
    s = fem.AELINK;
    for i = 1 : s.NumBulk
        A.aelink(end + 1) = struct('id', s.AEID(i), 'dep', s.LABLD{i}, ...
            'labels', {s.LinkLabels{i}}, 'coeffs', s.LinkCoeffs{i});
    end
end

%Downwash (W2GJ) / weighting (WKK) DMIs, rows = boxes in ascending ID order
A.w2gj = []; A.wkk = [];
if isprop(fem, 'DMI')
    m = matrices(fem.DMI);
    k = find(strcmp({m.Name}, 'W2GJ'), 1);
    if ~isempty(k), A.w2gj = m(k).Data(:, 1); end
    k = find(strcmp({m.Name}, 'WKK'), 1);
    if ~isempty(k)
        if size(m(k).Data, 2) == 1 %FORM 3 (diagonal) given as one column
            A.wkk = m(k).Data(:, 1);
        else
            A.wkk = diag(m(k).Data);
        end
    end
end
end

function v = i_pick(v, w)
if isnan(v) || v == 0
    v = w;
end
end
