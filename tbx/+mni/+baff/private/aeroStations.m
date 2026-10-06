function [st, cs, mesh, notes] = aeroStations(M, panels, O, R, locus)
%aeroStations baff aero stations and control surfaces of one wing from its
%CAERO1 panels.
%
% Inputs:
%   M      - collected model (collectModel)
%   panels - indices into M.aero.caero owned by this wing
%   O, R   - wing frame (origin, axes) in basic
%   locus  - struct: Eta (1 x n), P (3 x n local positions), EtaLength
%
% Each spanwise panel edge (CAERO1 point 1 / chord X12, point 4 / X43)
% becomes an aero station. Twist comes from the W2GJ downwash (radians per
% box) and the lift slope from WKK (cl_alpha / 2 pi per box) when present.
% ADS (ads.fe.AeroSurface.Export) writes CAERO1 point 1 as
%   X1 = B + c (1/2 - BeamLoc) v - c/2 x_aero
% with B the locus point and v the twisted chord direction of the baff
% station (baff.station.Aero.GetPos), so the station eta / BeamLoc come
% from the point of the line (mid-chord + t v) closest to the locus:
% BeamLoc = 1/2 + t / c.

notes = {};
A = M.aero;
dirL = R' * A.aeroX;              %aero x (flow direction) in the wing frame
dirL = dirL / norm(dirL);
stDir = -dirL;                    %station direction: chord points forward
allBoxes = sort([A.caero.boxIds]);
%panels directly behind another one over the same span (control surfaces
%modelled as separate CAERO1 entries) form one strip with the summed chord
G = i_chordwiseGroups(A, panels);
front = unique(G.front(panels), 'stable');
edges = zeros(0, 7);              %[eta beamLoc chord resid panel isTip twist]
for p = front
    c = A.caero(p);
    [tw, n1] = i_panelTwist(A, c, allBoxes);
    notes = [notes, n1]; %#ok<AGROW>
    for side = 1 : 2
        if side == 1
            le = R' * (c.p1 - O); ch = G.chord(1, p);
        else
            le = R' * (c.p4 - O); ch = G.chord(2, p);
        end
        mid = le + ch / 2 * dirL;
        [eta, t, d] = i_closest(locus, mid, dirL);
        if tw(side) ~= 0
            for it = 1 : 3
                v = i_chordDir(stDir, i_locusDir(locus, eta), tw(side));
                [eta, t, d] = i_closest(locus, mid, v);
            end
        end
        edges(end + 1, :) = [eta, 1 / 2 + t / ch, ch, d, p, side == 2, tw(side)]; %#ok<AGROW>
    end
end
%round-off at the wing ends: baff interpolation (and ADS, which evaluates
%the aero stations at the end nodes of the beam) needs eta exactly 0 / 1
e = edges(:, 1);
e(abs(e) < 1e-9) = 0;
e(abs(e - 1) < 1e-9) = 1;
edges(:, 1) = e;
%sort by eta, merge coincident edges (shared by neighbouring panels)
[~, o] = sort(edges(:, 1));
edges = edges(o, :);
tol = 1e-8;
keep = [true; diff(edges(:, 1)) > tol];
for k = find(~keep)'
    a = edges(k - 1, :); b = edges(k, :);
    if abs(a(3) - b(3)) > 1e-6 * max(a(3), b(3)) || abs(a(2) - b(2)) > 1e-6
        notes{end + 1} = sprintf(['CAERO1 %d / %d: chord or chordwise position changes at a shared ', ...
            'edge (eta %.6g); baff aero stations are continuous, the inboard value is kept.'], ...
            A.caero(a(5)).eid, A.caero(b(5)).eid, a(1)); %#ok<AGROW>
    end
end
E = edges(keep, :);
resid = max(edges(:, 4));
if resid > 1e-6 * max(1, locus.EtaLength)
    notes{end + 1} = sprintf(['Aero panels are up to %.3g away from the wing reference line: baff ', ...
        'aero stations pass through the beam / hub line (ADS: mid-chord on the twisted chord ', ...
        'through the beam point), so the panels move by this distance.'], resid);
end
n = size(E, 1);
etas = E(:, 1)';

%twist (W2GJ) and lift slope (WKK) per station, from the box rows
twistE = E(:, 7)';
slope = 2 * pi * ones(1, n);
for p = front
    c = A.caero(p);
    [~, rows] = ismember(c.boxIds, allBoxes);
    i1 = find(abs(etas - i_etaOf(edges, p, 0)) < tol, 1);
    i2 = find(abs(etas - i_etaOf(edges, p, 1)) < tol, 1);
    if ~isempty(A.wkk) && numel(A.wkk) >= 2 * max(rows)
        cl = A.wkk(2 * rows - 1);
        slope(i1) = 2 * pi * mean(cl);
        if i2 == n
            slope(i2) = slope(i1);
        end
    end
end

%station directions: chord points forward (against the flow)
etaDir = zeros(3, n);
for k = 1 : n
    etaDir(:, k) = i_locusDir(locus, etas(k));
end
st = baff.station.Aero(etas, E(:, 3)', E(:, 2)', Twist = twistE, ...
    StationDir = repmat(stDir, 1, n), EtaDir = etaDir, LiftCurveSlope = slope, ...
    ThicknessRatio = 0.12);

%mesh data for re-applying the panel discretisation (not part of baff)
mesh = struct('eid', {}, 'nspan', {}, 'nchord', {}, 'etaChord', {}, 'etaSpan', {}, ...
    'eta', {}, 'p1', {}, 'p4', {}, 'c1', {}, 'c4', {});
for p = front
    c = A.caero(p);
    mesh(end + 1) = struct('eid', c.eid, 'nspan', c.nspan, 'nchord', c.nchord, ...
        'etaChord', c.etaChord, 'etaSpan', c.etaSpan, ...
        'eta', [i_etaOf(edges, p, 0), i_etaOf(edges, p, 1)], 'p1', c.p1, 'p4', c.p4, ...
        'c1', G.chord(1, p), 'c4', G.chord(2, p)); %#ok<AGROW>
end

%control surfaces
cs = baff.ControlSurface.empty;
for s = 1 : numel(A.aesurf)
    a = A.aesurf(s);
    hinge = []; spanEta = [];
    for p = panels(:)'
        c = A.caero(p);
        [tf, k] = ismember(a.boxes, c.boxIds);
        if ~any(tf), continue, end
        k = k(tf) - 1;                      %0-based box index in the panel
        ic = mod(k, c.nchord);  is = floor(k / c.nchord);
        %hinge as a fraction of the strip chord (root and tip edge)
        f = G.front(p);
        x = c.etaChord(min(ic) + 1);
        hinge(end + (1 : 2)) = (G.off(:, p) + x * [c.c1; c.c4]) ./ G.chord(:, f); %#ok<AGROW>
        e = [i_etaOf(edges, f, 0), i_etaOf(edges, f, 1)];
        spanEta = [spanEta, e(1) + diff(e) * c.etaSpan([min(is) + 1, max(is) + 2])]; %#ok<AGROW>
    end
    if isempty(hinge)
        continue
    end
    if max(hinge) - min(hinge) > 1e-3
        notes{end + 1} = sprintf(['AESURF %s: hinge line at %s of the chord; baff needs a constant ', ...
            'chord fraction, the mean is used.'], a.label, mat2str(unique(hinge), 4)); %#ok<AGROW>
    end
    pc = 1 - mean(hinge);
    cs(end + 1) = baff.ControlSurface(string(a.label), [min(spanEta); max(spanEta)], [pc; pc]); %#ok<AGROW>
    if ~isempty(a.boxes2)
        notes{end + 1} = sprintf('AESURF %s: second component (CID2 / ALID2) not carried into baff.', a.label); %#ok<AGROW>
    end
end
for l = 1 : numel(A.aelink)
    L = A.aelink(l);
    i = find(strcmp([cs.Name], L.dep), 1);
    j = find(strcmp([cs.Name], L.labels{1}), 1);
    if isempty(i) || isempty(j)
        continue
    end
    cs(i).LinkedSurface = cs(j);
    cs(i).LinkedCoefficent = L.coeffs(1);
    if numel(L.labels) > 1 || L.id ~= 0
        notes{end + 1} = sprintf('AELINK %s: only the first independent surface (ID ALWAYS) is kept.', L.dep); %#ok<AGROW>
    end
end
end

function [tw, notes] = i_panelTwist(A, c, allBoxes)
%twist [deg] at the inboard / outboard edge of a panel: W2GJ is the
%angle at the box centres (ADS: linear between the edges), extrapolated
%half a strip to the edges
tw = [0, 0];
notes = {};
[~, rows] = ismember(c.boxIds, allBoxes);
if isempty(A.w2gj) || numel(A.w2gj) < max(rows)
    return
end
w = reshape(A.w2gj(rows), c.nchord, c.nspan);   %boxes: chordwise first
t = rad2deg(mean(w, 1));
if max(abs(w - mean(w, 1)), [], 'all') > 1e-9
    notes{end + 1} = sprintf(['CAERO1 %d: W2GJ varies along the chord (camber / box ', ...
        'incidence); only the chordwise mean (twist) is kept.'], c.eid);
end
if numel(t) > 1
    tw = [t(1) - (t(2) - t(1)) / 2, t(end) + (t(end) - t(end - 1)) / 2];
else
    tw = [t, t];
end
end

function v = i_chordDir(stDir, etaDir, twist)
%leading to trailing edge direction of a twisted baff aero station
%(baff.station.Aero.GetPos)
z = cross(etaDir / norm(etaDir), stDir);
perp = cross(stDir, z);
v = -baff.util.Rodrigues(perp, deg2rad(twist)) * stDir;
v = v / norm(v);
end

function e = i_etaOf(edges, p, isTip)
k = find(edges(:, 5) == p & edges(:, 6) == isTip, 1);
e = edges(k, 1);
end

function d = i_locusDir(locus, eta)
k = find(locus.Eta <= eta, 1, 'last');
if isempty(k), k = 1; end
k = min(k, numel(locus.Eta) - 1);
d = (locus.P(:, k + 1) - locus.P(:, k)) / (locus.EtaLength * (locus.Eta(k + 1) - locus.Eta(k)));
end

function [eta, s, dist] = i_closest(locus, le, dir)
%Closest points between the line le + s*dir and the locus polyline (the
%first / last segments extend beyond the ends).
best = inf;
P = locus.P; n = size(P, 2);
for k = 1 : n - 1
    a = P(:, k); b = P(:, k + 1);
    u = b - a;
    %minimise |a + t*u - le - s*dir| over (t, s)
    Mx = [u, -dir];
    ts = Mx \ (le - a);
    t = ts(1);
    lo = 0; hi = 1;
    if k == 1, lo = -inf; end
    if k == n - 1, hi = inf; end
    t = min(max(t, lo), hi);
    s = dir' * (a + t * u - le) / (dir' * dir);
    d = norm(a + t * u - le - s * dir);
    if d < best - 1e-12
        best = d;
        eta = locus.Eta(k) + t * (locus.Eta(k + 1) - locus.Eta(k));
        sBest = s;
    end
end
s = sBest; dist = best;
end

function G = i_chordwiseGroups(A, panels)
%Chains of CAERO1 panels lying one behind the other over the same span:
%leading edge of the rear panel on the trailing edge of the front one at
%both side edges (same spanwise position, chordwise gap / overlap below 5 %
%of the larger chord: decks often round the coordinates). G.front(p): front panel
%of the chain of panel p; G.off(:, p): distance of the leading edge of p
%behind the front leading edge along the flow (root; tip); G.chord(:, f):
%chord of the whole chain of f (front leading edge to last trailing edge).
n = numel(A.caero);
x = A.aeroX / norm(A.aeroX);
G.front = 1 : n;
G.off = zeros(2, n);
G.chord = [[A.caero.c1]; [A.caero.c4]];
behind = zeros(1, n);                 %panel directly behind p
for p = panels(:)'
    a = A.caero(p);
    L = norm(a.p4 - a.p1);
    for q = panels(:)'
        b = A.caero(q);
        if q == p, continue, end
        d1 = b.p1 - (a.p1 + a.c1 * x); d4 = b.p4 - (a.p4 + a.c4 * x);
        ok = norm(d1 - (d1' * x) * x) < 1e-4 * L && abs(d1' * x) < 0.05 * max(a.c1, b.c1) && ...
            norm(d4 - (d4' * x) * x) < 1e-4 * L && abs(d4' * x) < 0.05 * max(a.c4, b.c4);
        if ok, behind(p) = q; end
    end
end
for p = panels(:)'
    if any(behind == p), continue, end  %not a front panel
    a = A.caero(p);
    q = p;
    while behind(q) > 0
        q = behind(q);
        b = A.caero(q);
        G.front(q) = p;
        G.off(:, q) = [(b.p1 - a.p1)' * x; (b.p4 - a.p4)' * x];
    end
    G.chord(:, p) = G.off(:, q) + [A.caero(q).c1; A.caero(q).c4];
end
end
