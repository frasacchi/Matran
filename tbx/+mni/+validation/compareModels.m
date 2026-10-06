function C = compareModels(fem1, fem2, opts)
%compareModels Compares two imported bulk data models (original and round
%trip) by geometry: grids matched by position, card counts, constraints,
%concentrated masses and aerodynamic boxes.
%
% Syntax:
%   >> C = mni.validation.compareModels(fem, femRT, 'Dropped', info.Baff.Dropped);
%
% Output 'C' (struct):
%   Cards  - table (Card, Original, RoundTrip)
%   Grids  - N1, N2, Matched, Ambiguous, Unmatched (original grids not
%            found in the round trip model, dropped grids excluded), Map
%            (n x 2 [original, round trip] grid identifiers), Tol
%   Spc    - constrained original grids / DoFs found constrained in the
%            round trip model
%   Conm   - total CONM2 / CONM1 mass of both models
%   Aero   - box counts, total areas, centroid distances, W2GJ (original
%            boxes of the 'DroppedCaero' panels left out)
%   Beams  - table of the original beam elements whose end grids are
%            matched to a round trip beam: relative error of EA, EI1, EI2,
%            GJ (end A) and the dot product of the element y axes

arguments
    fem1
    fem2
    opts.Dropped = {}
    opts.DroppedCaero = []
    opts.Tol = []
end
geo1 = mni.util.Geometry(fem1);
geo2 = mni.util.Geometry(fem2);

%% card counts
n1 = i_counts(fem1); n2 = i_counts(fem2);
names = union(n1.keys, n2.keys);
cnt = zeros(numel(names), 2);
for i = 1 : numel(names)
    if isKey(n1, names{i}), cnt(i, 1) = n1(names{i}); end
    if isKey(n2, names{i}), cnt(i, 2) = n2(names{i}); end
end
C.Cards = table(names(:), cnt(:, 1), cnt(:, 2), 'VariableNames', {'Card', 'Original', 'RoundTrip'});

%% grids
X1 = geo1.X; X2 = geo2.X;
L = max(1, norm(max([X1, X2], [], 2) - min([X1, X2], [], 2)));
tol = opts.Tol;
if isempty(tol), tol = 1e-6 * L; end
[near, cnt2] = i_near(X1, X2, tol);
[~, cnt1] = i_near(X1, X1, tol);   %coincident original grids
[~, cntR] = i_near(X2, X1, tol);   %original grids at each round trip grid
ok = cnt2 == 1 & cnt1 == 1;
ok(ok) = cntR(near(ok)) == 1;
dropped = i_droppedIds(opts.Dropped);
C.Grids.N1 = numel(geo1.GID);
C.Grids.N2 = numel(geo2.GID);
C.Grids.Tol = tol;
C.Grids.Matched = nnz(ok);
C.Grids.Ambiguous = nnz(cnt2 > 0 & ~ok);
miss = geo1.GID(cnt2 == 0);
C.Grids.Unmatched = setdiff(miss(:), dropped(:))';
C.Grids.DroppedNotFound = intersect(miss(:), dropped(:))';
C.Grids.Map = [geo1.GID(ok)', geo2.GID(near(ok))'];

%% constraints (by position)
s1 = i_spc(fem1); s2 = i_spc(fem2);
C.Spc.Original = size(s1, 1);
C.Spc.RoundTrip = size(s2, 1);
found = 0; dofs = 0; dofsFound = 0;
for i = 1 : size(s1, 1)
    k = geo1.gridIndex(s1(i, 1));
    if isnan(k), continue, end
    d = vecnorm(X2 - X1(:, k));
    j = find(d < tol);
    c1 = i_dofs(s1(i, 2));
    dofs = dofs + numel(c1);
    if isempty(j), continue, end
    c2 = [];
    for jj = j(:)'
        r = s2(s2(:, 1) == geo2.GID(jj), 2);
        for q = r(:)', c2 = union(c2, i_dofs(q)); end
    end
    found = found + any(ismember(c1, c2));
    dofsFound = dofsFound + nnz(ismember(c1, c2));
end
C.Spc.GridsFound = found;
C.Spc.Dofs = dofs;
C.Spc.DofsFound = dofsFound;

%% beam elements (stiffness and orientation)
C.Beams = i_beams(fem1, fem2, geo1, geo2, C.Grids.Map);

%% concentrated masses
C.Conm.Original = i_conm(fem1);
C.Conm.RoundTrip = i_conm(fem2);

%% aero boxes
b1 = caeroBoxes(fem1, geo1); b2 = caeroBoxes(fem2, geo2);
keep = ~ismember(b1.Panel, opts.DroppedCaero);
C.Aero.DroppedBoxes = nnz(~keep);
for f = {'ID', 'Panel', 'Centroid', 'Area', 'Normal'}
    b1.(f{1}) = b1.(f{1})(:, keep);
end
b1.Corners = b1.Corners(:, :, keep);
C.Aero.Boxes = [numel(b1.ID), numel(b2.ID)];
C.Aero.Area = [sum(b1.Area), sum(b2.Area)];
C.Aero.CentroidDist = [NaN, NaN];
C.Aero.NormalDot = NaN;
C.Aero.W2GJ = [NaN, NaN];
if ~isempty(b1.ID) && ~isempty(b2.ID)
    [d, j] = i_nearest(b1.Centroid, b2.Centroid);
    C.Aero.CentroidDist = [max(d), mean(d)];
    C.Aero.NormalDot = min(abs(sum(b1.Normal .* b2.Normal(:, j), 1)));
    w1 = i_w2gj(fem1, b1); w2 = i_w2gj(fem2, b2);
    if ~isempty(w1) && ~isempty(w2)
        %[max |difference|, max |original|] in degrees at the nearest boxes
        C.Aero.W2GJ = rad2deg([max(abs(w2(j) - w1)), max(abs(w1))]);
    end
end
C.Aero.Boxes1 = b1;
C.Aero.Boxes2 = b2;
end

function m = i_counts(fem)
m = containers.Map();
nm = fem.BulkDataNames;
for i = 1 : numel(nm)
    b = fem.(nm{i});
    if b.NumBulk > 0
        if isKey(m, b.CardName)
            m(b.CardName) = m(b.CardName) + b.NumBulk;
        else
            m(b.CardName) = b.NumBulk;
        end
    end
end
end

function [idx, cnt] = i_near(A, B, tol)
%for every column of A: index of the nearest column of B and number of
%columns of B within tol
n = size(A, 2);
idx = zeros(1, n); cnt = zeros(1, n);
blk = 500;
for s = 1 : blk : n
    e = min(n, s + blk - 1);
    D = sqrt(max(0, sum(A(:, s : e).^2, 1)' + sum(B.^2, 1) - 2 * (A(:, s : e)' * B)));
    [~, idx(s : e)] = min(D, [], 2);
    cnt(s : e) = sum(D < tol, 2);
end
end

function T = i_beams(fem1, fem2, geo1, geo2, map)
B1 = i_beamList(fem1, geo1); B2 = i_beamList(fem2, geo2);
T = table('Size', [0, 9], 'VariableTypes', repmat({'double'}, 1, 9), 'VariableNames', ...
    {'EID', 'EID_rt', 'GA', 'GB', 'ErrEA', 'ErrEI1', 'ErrEI2', 'ErrGJ', 'yDot'});
if isempty(B1) || isempty(B2) || isempty(map), return, end
key2 = [B2.ga; B2.gb];
for e = B1
    [ta, ka] = ismember(e.ga, map(:, 1)); [tb, kb] = ismember(e.gb, map(:, 1));
    if ~(ta && tb), continue, end
    a = map(ka, 2); b = map(kb, 2);
    j = find((key2(1, :) == a & key2(2, :) == b) | (key2(1, :) == b & key2(2, :) == a), 1);
    if isempty(j), continue, end
    f = B2(j);
    r = @(x, y) (y - x) / max(abs(x), eps);
    T(end + 1, :) = {e.eid, f.eid, e.ga, e.gb, r(e.E * e.s.A, f.E * f.s.A), ...
        r(e.E * e.s.I1, f.E * f.s.I1), r(e.E * e.s.I2, f.E * f.s.I2), ...
        r(e.G * e.s.J, f.G * f.s.J), dot(e.y, f.y)}; %#ok<AGROW>
end
end

function B = i_beamList(fem, geo)
%CBEAM / CBAR: end grids, section at end A, E, G and the element y axis
%(orientation vector normal to the axis) in basic
B = struct('eid', {}, 'ga', {}, 'gb', {}, 's', {}, 'E', {}, 'G', {}, 'y', {});
props = {};
for t = {'PBEAM', 'PBAR', 'PBEAML', 'PBARL'}
    if isprop(fem, t{1}), props{end + 1} = fem.(t{1}); end %#ok<AGROW>
end
for t = {'CBEAM', 'CBAR'}
    if ~isprop(fem, t{1}), continue, end
    b = fem.(t{1});
    for i = 1 : b.NumBulk
        ga = b.GA_GB(1, i); gb = b.GA_GB(2, i);
        s = []; mid = NaN;
        for p = props
            k = find(p{1}.PID == b.PID(i), 1);
            if ~isempty(k), s = p{1}.section(k, 'A'); mid = p{1}.MID(k); break, end
        end
        if isempty(s), continue, end
        [E, G] = i_mat(fem, mid);
        if isprop(b, 'G0') && ~isnan(b.G0(i))
            v = geo.position(b.G0(i)) - geo.position(ga);
        elseif b.OFFT{i}(1) == 'B'
            v = b.X(:, i);
        else
            v = geo.dispFrame(ga) * b.X(:, i);
        end
        x = geo.position(gb) - geo.position(ga); x = x / norm(x);
        y = v - dot(v, x) * x; y = y / norm(y);
        B(end + 1) = struct('eid', b.EID(i), 'ga', ga, 'gb', gb, 's', s, 'E', E, 'G', G, ...
            'y', y); %#ok<AGROW>
    end
end
end

function [E, G] = i_mat(fem, mid)
E = NaN; G = NaN;
if ~isprop(fem, 'MAT1'), return, end
m = fem.MAT1;
k = find(m.MID == mid, 1);
if isempty(k), return, end
E = m.E(k); G = m.G(k); nu = m.NU(k);
if isnan(G) && ~isnan(nu), G = E / (2 * (1 + nu)); end
if isnan(E) && ~isnan(nu), E = 2 * G * (1 + nu); end
end

function w = i_w2gj(fem, b)
%W2GJ value of every box of 'b' (rows of W2GJ: boxes in ascending order)
w = [];
if ~isprop(fem, 'DMI'), return, end
m = matrices(fem.DMI);
k = find(strcmp({m.Name}, 'W2GJ'), 1);
if isempty(k), return, end
[~, r] = ismember(b.ID, sort(b.ID));
x = m(k).Data(:, 1);
if numel(x) < max(r), return, end
w = x(r)';
end

function [d, j] = i_nearest(A, B)
n = size(A, 2);
d = zeros(1, n); j = zeros(1, n);
for i = 1 : n
    [d(i), j(i)] = min(vecnorm(B - A(:, i)));
end
end

function ids = i_droppedIds(dropped)
ids = [];
for i = 1 : numel(dropped)
    t = regexpi(dropped{i}, '^grid\s+(\d+)', 'tokens', 'once');
    if ~isempty(t), ids(end + 1) = str2double(t{1}); end %#ok<AGROW>
end
end

function s = i_spc(fem)
%[grid, components] of every SPC / SPC1 entry
s = zeros(0, 2);
if isprop(fem, 'SPC1')
    b = fem.SPC1;
    for i = 1 : b.NumBulk
        g = b.G{i};
        s = [s; g(:), repmat(str2double(b.C{i}), numel(g), 1)]; %#ok<AGROW>
    end
end
if isprop(fem, 'SPC')
    b = fem.SPC;
    for i = 1 : b.NumBulk
        g = b.G{i}; c = b.C{i};
        s = [s; g(:), c(:)]; %#ok<AGROW>
    end
end
end

function d = i_dofs(c)
d = unique(num2str(c) - '0');
d = d(d >= 1 & d <= 6);
end

function m = i_conm(fem)
m = 0;
if isprop(fem, 'CONM2'), m = m + sum(fem.CONM2.M); end
if isprop(fem, 'CONM1')
    b = fem.CONM1;
    m = m + sum(b.M1);
end
end
