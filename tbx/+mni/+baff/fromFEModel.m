function [model, report] = fromFEModel(fem, info, opts)
%fromFEModel Builds a baff.Model from an imported Nastran bulk data model
%using only the bulk data (no other metadata).
%
% Syntax:
%   >> [fem, info] = mni.import_matran('model.bdf');
%   >> [model, report] = mni.baff.fromFEModel(fem, info);
%   >> [~, ~, model] = mni.import_matran('model.bdf', 'ToBaff', true);
%
% Mapping (see docs/bdf2baff/PROGRESS.md for the details):
%   - chains of CBEAM / CBAR / CROD between junctions (or property /
%     material / coordinate system changes) -> baff.Beam, or baff.Wing when
%     an aero panel is splined to it (stations at every grid, StationDir =
%     beam orientation vector, PBEAM / PBAR / PROD / PBEAML / PBARL ->
%     A, I, J)
%   - connected CQUAD4 / CTRIA3 surfaces -> baff.Wing with a ShellStation
%     (RBE3 rib centres -> SecondaryEta / SecondaryNodes, RBE2 stations ->
%     ConstrainedEta / ConstrainedNodes, spline grids -> SplineNodes)
%   - CAERO1 + splines + W2GJ / WKK -> AeroStations; AESURF / AELIST /
%     LCHORD -> ControlSurfaces; AELINK -> LinkedSurface
%   - CONM2 / CONM1 -> baff.Mass, SPC / SPC1 of the selected set ->
%     baff.Constraint (or Beam.ConstraintDoFs), RJOINT / CBUSH with one
%     free rotation -> baff.Hinge, grids with their own frame or a load ->
%     baff.Point
%   - frames: a component whose grids share one rectangular CP keeps that
%     system's axes (CORD2R written by ADS = baff element frame); otherwise
%     x runs along the component (root to tip), y is the beam orientation
%     vector (wings: forward, against the aero x axis), z = x cross y. The
%     tree follows the connections (shared grids, RBE2, joints) from the
%     constrained component; child A / Eta / Offset reproduce the global
%     geometry exactly.
% Loads, SPC set selection, aero reference data (AERO / AEROS), panel
% discretisation and solution settings stay in 'info' / 'report'.
%
% Outputs:
%   model  - baff.Model
%   report - struct: Components (table), Notes (approximations),
%            Dropped (grids / elements not carried over), DroppedCaero
%            (EIDs of the CAERO1 entries not converted), AeroMesh,
%            AeroSettings, Loads, NodeMap (grid -> component)
%
% Name-value options:
%   'Name'           model name
%   'SpcSet'         SPC set to convert (default: SPC of the first subcase)
%   'KeepFrames'     (true) reuse a common rectangular CP as element frame
%   'RigidStiffness' (1e8) bush stiffness treated as rigid

arguments
    fem
    info = []
    opts.Name string = ""
    opts.SpcSet = []
    opts.KeepFrames (1, 1) logical = true
    opts.RigidStiffness (1, 1) double = 1e8
end

geo = mni.util.Geometry(fem);
M = collectModel(fem, geo, info, opts);
S = analyseStructure(M, opts);
nC = numel(S.comp);
notes = S.notes;

%% aero ownership (via the spline grids)
owner = zeros(1, numel(M.aero.caero));
for p = 1 : numel(M.aero.caero)
    c = M.aero.caero(p);
    votes = [];
    for s = M.aero.spline
        if any(ismember(s.boxes, c.boxIds)) || (~isnan(s.caero) && s.caero == c.eid)
            k = geo.gridIndex(s.nodes);
            k = k(~isnan(k));
            cc = S.nodeComp(k);
            %leaf grids: component of their rigid cluster
            for j = find(cc == 0)
                mem = find(S.cluster == S.cluster(k(j)) & S.isAttach);
                if ~isempty(mem), cc(j) = S.nodeComp(mem(1)); end
            end
            votes = [votes, cc(cc > 0)]; %#ok<AGROW>
        end
    end
    if isempty(votes)
        %nearest component to the panel mid-chord points
        mid = (c.p1 + c.p4) / 2 + M.aero.aeroX * (c.c1 + c.c4) / 4;
        d = vecnorm(M.node.X - mid);
        d(S.nodeComp == 0) = inf;
        [~, k] = min(d);
        owner(p) = S.nodeComp(k);
        notes{end + 1} = sprintf('CAERO1 %d has no spline: assigned to the nearest component.', c.eid); %#ok<AGROW>
    else
        owner(p) = mode(votes);
    end
end
isWing = false(1, nC);
isWing(unique(owner(owner > 0))) = true;
isWing(strcmp({S.comp.kind}, 'shell')) = true;

%% tree
[T, S, notes] = i_tree(M, S, notes);
nC = numel(S.comp);
isWing(end + 1 : nC) = false;

%% frames and locus of every component
Fc = cell(1, nC);
for c = 1 : nC
    Fc{c} = i_frame(M, S.comp(c), isWing(c), opts);
end
F = [Fc{:}];
notes = [notes, {F(~cellfun(@isempty, {F.note})).note}];

%% baff elements
elems = cell(1, nC);
mats = containers.Map('KeyType', 'double', 'ValueType', 'any');
compTable = table('Size', [nC, 7], 'VariableTypes', {'string', 'string', 'string', 'double', ...
    'double', 'string', 'string'}, 'VariableNames', {'Name', 'Kind', 'Parent', 'Grids', ...
    'Elements', 'Frame', 'Link'});
droppedCaero = zeros(1, 0);
for c = 1 : nC
    comp = S.comp(c);
    panels = find(owner == c);
    aero = [];
    if isWing(c) && ~isempty(panels)
        [st, cs, mesh, n3] = aeroStations(M, panels, F(c).O, F(c).R, F(c).locus);
        if numel(unique(round(st.Eta, 9))) < 2
            %panels spanning across the component (e.g. fuselage body
            %plates normal to the fuselage beam) all fall on one eta: a
            %baff wing cannot hold them
            notes{end + 1} = sprintf(['%s: CAERO1 %s span across the component (all at eta %.4g); ', ...
                'baff aero stations run along it, so these panels are not converted.'], comp.name, ...
                i_idList([M.aero.caero(panels).eid]), st.Eta(1)); %#ok<AGROW>
            S.dropped{end + 1} = sprintf('CAERO1 %s: aero panels across %s', ...
                i_idList([M.aero.caero(panels).eid]), comp.name);
            droppedCaero = [droppedCaero, M.aero.caero(panels).eid]; %#ok<AGROW>
            isWing(c) = strcmp(comp.kind, 'shell');
        else
            aero = struct('st', st, 'cs', cs, 'mesh', mesh);
            notes = [notes, n3]; %#ok<AGROW>
        end
    end
    switch comp.kind
        case 'beam'
            [elems{c}, n2] = i_beamElement(M, comp, F(c), isWing(c), mats);
        case 'shell'
            [elems{c}, n2] = i_shellElement(M, comp, F(c), mats);
    end
    notes = [notes, n2]; %#ok<AGROW>
    if ~isempty(aero)
        elems{c}.AeroStations = aero.st;
        elems{c}.ControlSurfaces = aero.cs;
        report.AeroMesh.(matlab.lang.makeValidName(comp.name)) = aero.mesh;
    elseif isWing(c) && strcmp(comp.kind, 'shell')
        elems{c}.Meta.ads.GenerateAeroPanels = false;
    end
    elems{c}.Name = comp.name;
    frameTxt = 'derived';
    if F(c).keptCP, frameTxt = sprintf('CP %d', comp.cp); end
    compTable(c, :) = {string(comp.name), string(comp.kind), "", numel(comp.nodes), ...
        numel(comp.elems), string(frameTxt), ""};
end

%% tree assembly
model = baff.Model();
model.Name = opts.Name;
for c = T.order
    p = T.parent(c);
    e = elems{c};
    if p == 0
        e.A = F(c).R;
        e.Offset = F(c).O;
        e.Eta = 0;
        model.AddElement(e);   %added after the children are attached (handles)
        continue
    end
    lk = T.link(c);
    if strcmp(lk.kind, 'hinge')
        [h, Rh, Xh] = i_hinge(M, lk, F(p));
        elems{p}.add(h);
        h.add(e);
        e.A = Rh' * F(c).R;
        e.Eta = 0;
        e.Offset = Rh' * (F(c).O - Xh);
        compTable.Link(c) = "hinge";
    else
        [eta, X0] = i_attach(F(p), T.pnode(c), geo);
        e.A = F(p).R' * F(c).R;
        e.Eta = eta;
        e.Offset = F(p).R' * (F(c).O - X0);
        elems{p}.add(e);
        compTable.Link(c) = string(lk.kind);
    end
    compTable.Parent(c) = string(S.comp(p).name);
end

%% satellites
nSat = struct('mass', 0, 'constraint', 0, 'point', 0);
for k = 1 : numel(S.sats)
    s = S.sats(k);
    c = s.comp;
    [eta, X0] = i_attach(F(c), s.attach, geo);
    switch s.kind
        case 'mass'
            [el, n4] = i_mass(s.data, geo, F(c), eta, X0);
            notes = [notes, n4]; %#ok<AGROW>
        case 'constraint'
            el = baff.Constraint(Name = sprintf("SPC_%d", s.node), ComponentNums = s.data.c);
            el.Eta = eta;
            el.Offset = F(c).R' * (geo.position(s.node) - X0);
            if geo.CD(geo.gridIndex(s.node)) ~= 0 && s.data.c ~= 123456
                notes{end + 1} = sprintf(['SPC on grid %d (components %d) is in the displacement ', ...
                    'system CD %d; baff / ADS constraints use the basic system.'], s.node, s.data.c, ...
                    geo.CD(geo.gridIndex(s.node))); %#ok<AGROW>
            end
        case 'point'
            el = baff.Point(Name = sprintf("Point_%d", s.node));
            Rp = eye(3);
            if s.data.cp ~= 0
                [~, Rp] = geo.frame(s.data.cp);
            end
            el.A = F(c).R' * Rp;
            el.Eta = eta;
            el.Offset = F(c).R' * (geo.position(s.node) - X0);
    end
    if ~strcmp(s.kind, 'mass')
        el.Meta.bdf = struct('Grid', s.node);
    end
    elems{c}.add(el);
    nSat.(s.kind) = nSat.(s.kind) + 1;
end
model = model.Rebuild();
model.Name = opts.Name;

%% report
report.Components = compTable;
report.Satellites = nSat;
report.Notes = unique(notes, 'stable')';
report.Dropped = S.dropped';
report.DroppedCaero = droppedCaero;
report.AeroSettings = rmfield(M.aero, {'caero', 'spline', 'aesurf', 'aelink', 'fact', ...
    'alist', 'sets', 'w2gj', 'wkk'});
report.Loads = M.load;
report.Spc = M.spc;
report.NodeMap = table(M.node.id(:), S.nodeComp(:), 'VariableNames', {'Grid', 'Component'});
if ~isfield(report, 'AeroMesh')
    report.AeroMesh = struct();
end
end

%% ===================================================================== tree
function [T, S, notes] = i_tree(M, S, notes)
for iter = 1 : 20
    nC = numel(S.comp);
    %root: most constrained grids, then most elements
    nSpc = zeros(1, nC);
    for s = S.sats(strcmp({S.sats.kind}, 'constraint'))
        nSpc(s.comp) = nSpc(s.comp) + 1;
    end
    nEl = arrayfun(@(c) numel(c.elems), S.comp);
    T.parent = zeros(1, nC); T.pnode = nan(1, nC); T.cnode = nan(1, nC);
    T.link = repmat(struct('compA', 0, 'nodeA', NaN, 'compB', 0, 'nodeB', NaN, 'kind', '', ...
        'hinge', []), 1, nC);
    T.order = [];
    seen = false(1, nC);
    used = false(1, numel(S.links));
    while ~all(seen)
        cand = find(~seen);
        [~, k] = max(nSpc(cand) * 1e9 + nEl(cand));
        r = cand(k);
        seen(r) = true;
        queue = r;
        T.order(end + 1) = r;
        while ~isempty(queue)
            p = queue(1); queue(1) = [];
            for l = 1 : numel(S.links)
                L = S.links(l);
                if used(l), continue, end
                if L.compA == p, c = L.compB; pn = L.nodeA; cn = L.nodeB;
                elseif L.compB == p, c = L.compA; pn = L.nodeB; cn = L.nodeA;
                    if strcmp(L.kind, 'hinge') %hinge seen from the other side
                        L.hinge = i_flipHinge(L.hinge);
                    end
                else, continue
                end
                used(l) = true;
                if seen(c)
                    if c ~= p
                        notes{end + 1} = sprintf(['Closed loop: %s link between %s (grid %d) and %s ', ...
                            '(grid %d) dropped (baff is a tree).'], L.kind, S.comp(p).name, pn, ...
                            S.comp(c).name, cn); %#ok<AGROW>
                    end
                    continue
                end
                seen(c) = true;
                T.parent(c) = p; T.pnode(c) = pn; T.cnode(c) = cn;
                L.compA = p; L.nodeA = pn; L.compB = c; L.nodeB = cn;
                T.link(c) = L;
                T.order(end + 1) = c;
                queue(end + 1) = c; %#ok<AGROW>
            end
        end
    end
    %beam chains must start at their attachment grid
    split = false;
    for c = 1 : nC
        comp = S.comp(c);
        if ~strcmp(comp.kind, 'beam'), continue, end
        if T.parent(c) == 0
            %root: start at the constrained end if there is one
            cons = [S.sats(strcmp({S.sats.kind}, 'constraint') & [S.sats.comp] == c).node];
            if any(cons == comp.nodes(end)) && ~any(cons == comp.nodes(1))
                S.comp(c) = i_reverse(comp);
            end
            continue
        end
        a = T.cnode(c);
        if comp.nodes(1) == a, continue, end
        if comp.nodes(end) == a
            S.comp(c) = i_reverse(comp);
        else
            k = find(comp.nodes == a, 1);
            if isempty(k), continue, end
            [S, notes] = i_split(S, c, k, notes);
            split = true;
            break
        end
    end
    if ~split
        return
    end
end
end

function comp = i_reverse(comp)
comp.nodes = fliplr(comp.nodes);
comp.elems = fliplr(comp.elems);
comp.rev = ~fliplr(comp.rev);
end

function [S, notes] = i_split(S, c, k, notes)
%split beam chain c at its k-th grid (a child attached mid-chain)
comp = S.comp(c);
a = comp; b = comp;
a.nodes = comp.nodes(1 : k); a.elems = comp.elems(1 : k - 1); a.rev = comp.rev(1 : k - 1);
b.nodes = comp.nodes(k : end); b.elems = comp.elems(k : end); b.rev = comp.rev(k : end);
a = i_reverse(a);
b.name = sprintf('%s_b', comp.name);
S.comp(c) = a;
S.comp(end + 1) = b;
g = comp.nodes(k);
S.links(end + 1) = struct('compA', c, 'nodeA', g, 'compB', numel(S.comp), 'nodeB', g, ...
    'kind', 'shared', 'hinge', []);
[tf, j] = ismember(b.nodes(2 : end), S.nodeId);
S.nodeComp(j(tf)) = numel(S.comp);
for s = 1 : numel(S.sats)
    if S.sats(s).comp == c && any(b.nodes(2 : end) == S.sats(s).attach)
        S.sats(s).comp = numel(S.comp);
    end
end
for l = 1 : numel(S.links) - 1
    L = S.links(l);
    if L.compA == c && any(b.nodes(2 : end) == L.nodeA), S.links(l).compA = numel(S.comp); end
    if L.compB == c && any(b.nodes(2 : end) == L.nodeB), S.links(l).compB = numel(S.comp); end
end
notes{end + 1} = sprintf('%s split at grid %d (a component is attached there).', comp.name, g);
end

function H = i_flipHinge(H)
[H.ga, H.gb] = deal(H.gb, H.ga);
end

%% =================================================================== frames
function F = i_frame(M, comp, isWing, opts)
geo = M.geo;
F.keptCP = false;
F.note = '';
X = geo.position(comp.nodes);
Rcp = eye(3);
keep = opts.KeepFrames && ~isnan(comp.cp) && comp.cp ~= 0;
if keep
    [~, Rcp, type] = geo.frame(comp.cp);
    keep = type == 'R';
end
switch comp.kind
    case 'beam'
        O = X(:, 1);
        x = X(:, end) - X(:, 1);
        if norm(x) < 1e-12 * max(1, norm(X(:, 1))), x = X(:, 2) - X(:, 1); end
        x = x / norm(x);
        [keep, F.note] = i_wingFrameOk(keep, isWing, comp, Rcp, x, M);
        if keep
            R = Rcp; F.keptCP = true;
        else
            b = M.beam(comp.elems(1));
            if isWing
                y = -M.aero.aeroX;
            else
                y = b.v;
            end
            R = i_triad(x, y);
        end
        L = R' * (X - O);
        seg = vecnorm(diff(L, 1, 2));
        len = sum(seg);
        eta = [0, cumsum(seg)] / len;
        F.locus = struct('Eta', eta, 'P', L, 'EtaLength', len, 'Grids', comp.nodes);
    case 'shell'
        hubs = i_shellHubs(M, comp);
        if numel(hubs) >= 2
            H = geo.position(hubs);
            D = sqrt(max(0, sum(H.^2, 1)' + sum(H.^2, 1) - 2 * (H' * H))); %pairwise distances
            [~, k] = max(D(:)); [i1, i2] = ind2sub(size(D), k);
            x = H(:, i2) - H(:, i1);
        else
            C = X - mean(X, 2);
            [U, ~, ~] = svd(C, 'econ');
            x = U(:, 1);
        end
        x = x / norm(x);
        [keep, F.note] = i_wingFrameOk(keep, isWing, comp, Rcp, x, M);
        if keep
            R = Rcp; F.keptCP = true;
        else
            if isWing
                y = -M.aero.aeroX;
            else
                C = X - mean(X, 2);
                [U, ~, ~] = svd(C, 'econ');
                y = U(:, 2);
            end
            R = i_triad(x, y);
        end
        if isempty(hubs)
            L = R' * (X - X(:, 1));
            span = [min(L(1, :)), max(L(1, :))];
            O = X(:, 1) + R(:, 1) * span(1);
            P = [0, 0; 0, 0; 0, 0]; P(1, 2) = diff(span);
            F.locus = struct('Eta', [0, 1], 'P', P, 'EtaLength', diff(span), 'Grids', []);
        else
            H = geo.position(hubs);
            Lh = R' * H;
            [~, o] = sort(Lh(1, :));
            hubs = hubs(o);
            H = H(:, o);
            O = H(:, 1);
            P = R' * (H - O);
            seg = vecnorm(diff(P, 1, 2));
            len = sum(seg);
            F.locus = struct('Eta', [0, cumsum(seg)] / len, 'P', P, 'EtaLength', len, 'Grids', hubs);
        end
end
F.O = O; F.R = R;
end

function s = i_idList(ids)
%short text of an id list
if numel(ids) <= 4
    s = strjoin(compose('%d', ids), ', ');
else
    s = sprintf('%d, %d, ..., %d (%d entries)', ids(1), ids(2), ids(end), numel(ids));
end
end

function hubs = i_shellHubs(M, comp)
hubs = [comp.hubs, arrayfun(@(r) M.rbe2(r).gn, comp.conHubs)];
end

function [keep, note] = i_wingFrameOk(keep, isWing, comp, Rcp, x, M)
%A wing keeps its CP only if the axes follow the baff / ADS wing convention
%(x along the span, y forward): ADS derives the W2GJ sign and the aero
%geometry from the wing frame.
note = '';
if ~keep || ~isWing
    return
end
if dot(Rcp(:, 1), x) < cos(pi / 4) || dot(Rcp(:, 2), -M.aero.aeroX) <= 0
    keep = false;
    note = sprintf(['%s: CP %d axes do not follow the wing convention (x span, y forward); ', ...
        'a derived frame is used.'], comp.name, comp.cp);
end
end

function R = i_triad(x, y)
y = y - (y' * x) * x;
if norm(y) < 1e-9
    t = eye(3);
    [~, k] = min(abs(x));
    y = t(:, k) - (t(:, k)' * x) * x;
end
y = y / norm(y);
z = cross(x, y);
R = [x, y, z];
end

function [eta, X0] = i_attach(F, grid, ~)
%eta of grid 'grid' on the locus of a component and the locus point there
%(grids off the locus attach at eta 0, the offset carries the position)
k = find(F.locus.Grids == grid, 1);
if isempty(k)
    eta = 0;
    X0 = F.O;
else
    eta = F.locus.Eta(k);
    X0 = F.O + F.R * F.locus.P(:, k);
end
end

%% ================================================================ elements
function [el, notes] = i_beamElement(M, comp, F, isWing, mats)
notes = {};
L = F.locus;
n = numel(comp.nodes);
eta = L.Eta;
etaDir = zeros(3, n);
for k = 1 : n - 1
    etaDir(:, k) = (L.P(:, k + 1) - L.P(:, k)) / (L.EtaLength * (eta(k + 1) - eta(k)));
end
etaDir(:, n) = etaDir(:, n - 1);
stDir = zeros(3, n); A = zeros(1, n); I = zeros(3, 3, n); J = zeros(1, n); nsm = zeros(1, n);
nsi = zeros(1, n);
for k = 1 : n
    e = M.beam(comp.elems(min(k, n - 1)));
    rev = comp.rev(min(k, n - 1));
    if k < n
        if rev, s = e.secB; else, s = e.secA; end
    else
        if rev, s = e.secA; else, s = e.secB; end
    end
    v = e.v;
    if any(isnan(v)), v = [0; 0; 1]; end
    sd = F.R' * v;
    stDir(:, k) = sd / norm(sd);
    A(k) = s.A; J(k) = s.J; nsm(k) = s.NSM; nsi(k) = s.NSI;
    I(:, :, k) = [s.I1 + s.I2, 0, 0; 0, s.I2, -s.I12; 0, -s.I12, s.I1];
end
b = M.beam(comp.elems(1));
mat = i_material(M, b.mid, mats);
st = baff.station.Beam(eta, EtaDir = etaDir, StationDir = stDir, A = A, I = I, J = J, Mat = mat, ...
    NSM = nsm);
if isWing
    el = baff.Wing(baff.station.Aero([0, 1], 1, 0.25), BeamStations = st, EtaLength = L.EtaLength);
else
    el = baff.Beam(Stations = st, EtaLength = L.EtaLength);
end
el.Meta.bdf = struct('Grids', comp.nodes, 'EIDs', [M.beam(comp.elems).eid], 'CP', comp.cp);
%section data baff stations do not hold, passed to ADS (beam2fe
%applyBeamSection) per station: shear factors K (PBEAM K blank = 1, the ADS
%default; PBAR K blank = no shear flexibility) and the PBEAM nonstructural
%mass moment of inertia NSI
bs = struct('Eta', eta);
K = b.K;
if strcmp(b.pcard, 'PBAR') && all(isnan(K))
    bs.K = zeros(2, n);
elseif ~all(isnan(K)) && any(abs(K(~isnan(K)) - 1) > 1e-12)
    K(isnan(K)) = 1;
    bs.K = repmat(K(:), 1, n);
end
if any(nsi ~= 0)
    bs.NSI = nsi;
end
if numel(fieldnames(bs)) > 1
    el.Meta.ads.BeamSection = bs;
end
if any(strcmp(b.pcard, {'PBEAML', 'PBARL'}))
    notes{end + 1} = sprintf(['%s: %s cross-section converted to A, I, J (mni.bulk.beamSection); ', ...
        'Nastran''s own shear / warping terms of the dimensions are not kept.'], comp.name, b.pcard);
end
for e = comp.elems
    if any(M.beam(e).wa ~= 0) || any(M.beam(e).wb ~= 0)
        notes{end + 1} = sprintf('%s: CBEAM / CBAR offsets (WA / WB) not carried into baff.', comp.name); %#ok<AGROW>
        break
    end
end
end

function [el, notes] = i_shellElement(M, comp, F, mats)
notes = {};
geo = M.geo;
X = geo.position(comp.nodes);
nodesL = (F.R' * (X - F.O))';
[~, gIdx] = ismember([M.shell(comp.elems).g], comp.nodes);
gIdx = reshape(gIdx, size([M.shell(comp.elems).g]));
sh = baff.station.ShellStation.Shell.empty;
for k = 1 : numel(comp.elems)
    s = M.shell(comp.elems(k));
    g = gIdx(:, k);
    if numel(g) < 4 || any(g == 0)
        g(4) = g(3);
        notes{end + 1} = sprintf('%s: CTRIA3 written as a degenerate quad.', comp.name); %#ok<AGROW>
    end
    mat = i_material(M, s.mid, mats);
    bk = s.BK; if isnan(bk), bk = 1; end
    nsm = s.NSM; if isnan(nsm), nsm = 0; end
    if strcmp(s.pcard, 'PCOMP')
        p = s.ply;
        ply = baff.station.ShellStation.Ply(p.Z0, p.NSM, p.SB, string(p.FT), p.TREF, p.GE, ...
            string(p.LAM), p.MIDi(:), p.Ti(:), p.THETAi(:));
        sh(end + 1, 1) = baff.station.ShellStation.Shell(g(1 : 4), mat, s.T, "PCOMP", ply = ply); %#ok<AGROW>
    else
        sh(end + 1, 1) = baff.station.ShellStation.Shell(g(1 : 4), mat, s.T, "PSHELL", ...
            BendRatio = bk, NSM = nsm); %#ok<AGROW>
        if ~isnan(s.TST) && abs(s.TST - 0.833333) > 1e-3
            notes{end + 1} = sprintf('%s: PSHELL TS/T = %g not kept (baff Shell has no TS/T).', comp.name, s.TST); %#ok<AGROW>
        end
    end
end
%stations along the hub line
L = F.locus;
hubs = L.Grids;
n = numel(L.Eta);
etaDir = zeros(3, n);
for k = 1 : n - 1
    etaDir(:, k) = (L.P(:, k + 1) - L.P(:, k)) / (L.EtaLength * (L.Eta(k + 1) - L.Eta(k)));
end
if n > 1, etaDir(:, n) = etaDir(:, n - 1); end
sec = []; secEta = []; con = []; conEta = [];
for r = comp.hubRbe
    e = M.rbe3(r);
    [~, k] = ismember([e.g{:}], comp.nodes);
    sec{end + 1} = k; %#ok<AGROW>
    secEta(end + 1) = L.Eta(hubs == e.ref); %#ok<AGROW>
    if any(e.c ~= 123) || e.refc ~= 123456
        notes{end + 1} = sprintf(['RBE3 %d: REFC %d / Ci %s; ADS rib hubs use REFC 123456, Ci 123 ', ...
            'and equal weights.'], e.eid, e.refc, mat2str(e.c)); %#ok<AGROW>
    end
end
for r = comp.conHubs
    e = M.rbe2(r);
    [~, k] = ismember(e.gm, comp.nodes);
    con{end + 1} = k; %#ok<AGROW>
    conEta(end + 1) = L.Eta(hubs == e.gn); %#ok<AGROW>
end
[secEta, o] = sort(secEta); sec = sec(o);
[conEta, o] = sort(conEta); con = con(o);
secNodes = i_rows(sec);
conNodes = zeros(0, numel(con));
if ~isempty(con)
    m = max(cellfun(@numel, con));
    conNodes = zeros(m, numel(con));
    for j = 1 : numel(con)
        c = con{j}; c(end + 1 : m) = c(end);
        conNodes(:, j) = c(:);
    end
end
%spline grids on this surface
spl = [M.aero.spline.nodes];
[tf, k] = ismember(spl, comp.nodes);
splineNodes = unique(k(tf))';
mat = i_material(M, M.shell(comp.elems(1)).mid, mats);
ss = baff.station.ShellStation.ShellStation(L.Eta, EtaDir = etaDir, Mat = mat, ...
    Nodes = nodesL, Shell = sh, SecondaryEta = secEta, SecondaryNodes = secNodes, ...
    ConstrainedEta = conEta, ConstrainedNodes = conNodes, SplineNodes = splineNodes(:));
el = baff.Wing(baff.station.Aero([0, 1], 1, 0.25), ShellStations = ss, EtaLength = L.EtaLength);
el.Meta.bdf = struct('Grids', comp.nodes, 'Hubs', hubs, 'EIDs', [M.shell(comp.elems).eid], 'CP', comp.cp);
end

function R = i_rows(groups)
%rows of 4 node indices per rib, every rib padded to the same row count
if isempty(groups)
    R = zeros(0, 4);
    return
end
nr = max(cellfun(@(g) ceil(numel(g) / 4), groups));
R = zeros(nr * numel(groups), 4);
for j = 1 : numel(groups)
    g = groups{j};
    g(end + 1 : nr * 4) = g(end);
    R((j - 1) * nr + (1 : nr), :) = reshape(g, 4, nr)';
end
end

function mat = i_material(M, mid, mats)
if isKey(mats, mid)
    mat = mats(mid);
    return
end
k = find([M.mat.mid] == mid, 1);
assert(~isempty(k), 'mni:baff:material', 'Material %d not found.', mid);
m = M.mat(k);
mat = baff.Material(m.E, m.nu, m.rho, sprintf("MAT%d", mid), G = m.G);
if strcmp(m.card, 'MAT8')
    mat.MAT = "MAT8";
    mat.E1 = m.raw.E1; mat.E2 = m.raw.E2; mat.NU12 = m.raw.NU12; mat.G12 = m.raw.G12;
    mat.G1Z = m.raw.G1Z; mat.G2Z = m.raw.G2Z;
end
mats(mid) = mat; %#ok<NASGU>
end

function [el, notes] = i_mass(d, geo, F, eta, X0)
notes = {};
Xg = geo.position(d.g);
if strcmp(d.card, 'CONM2')
    switch true
        case d.cid == -1
            cg = d.x; Rm = eye(3);
        case d.cid == 0
            cg = Xg + d.x; Rm = eye(3);
        otherwise
            Rm = geo.axesAt(d.cid, Xg);
            cg = Xg + Rm * d.x;
    end
    I = d.I; %I11 I21 I22 I31 I32 I33 as written on the entry (ADS writes them back as-is)
    el = baff.Mass(d.m, Ixx = I(1), Iyy = I(3), Izz = I(6), Ixy = I(2), Ixz = I(4), Iyz = I(5), ...
        Name = sprintf("CONM2_%d", d.eid));
else %CONM1: rigid-body split of the 6 x 6 matrix
    M6 = d.I;
    if d.cid > 0, Rm = geo.axesAt(d.cid, Xg); else, Rm = eye(3); end
    m = M6(1, 1);
    if any(abs(diag(M6(1 : 3, 1 : 3)) - m) > 1e-9 * max(abs(m), 1)) || m <= 0
        notes{end + 1} = sprintf('CONM1 %d: translational mass not isotropic (added mass?), M11 used.', d.eid);
    end
    Sk = M6(4 : 6, 1 : 3) / max(m, eps);
    dd = [Sk(3, 2); Sk(1, 3); Sk(2, 1)];
    Jc = M6(4 : 6, 4 : 6) - m * ((dd' * dd) * eye(3) - dd * dd');
    cg = Xg + Rm * dd;
    el = baff.Mass(m, Ixx = Jc(1, 1), Iyy = Jc(2, 2), Izz = Jc(3, 3), Ixy = -Jc(2, 1), ...
        Ixz = -Jc(3, 1), Iyz = -Jc(3, 2), Name = sprintf("CONM1_%d", d.eid));
end
el.A = F.R' * Rm;
el.Eta = eta;
el.Offset = F.R' * (cg - X0);
el.Meta.bdf = struct('EID', d.eid, 'Grid', d.g, 'CID', d.cid);
end

function [h, Rh, Xh] = i_hinge(M, lk, Fp)
%baff.Hinge on the parent: x axis = released rotation of the joint
H = lk.hinge;
geo = M.geo;
T = H.frame;
r = H.axis;
Rh = [T(:, r), T(:, mod(r, 3) + 1), T(:, mod(r + 1, 3) + 1)];
Xh = geo.position(H.ga);
h = baff.Hinge(Name = sprintf("Hinge_%d", H.eids(1)), HingeVector = [1; 0; 0], ...
    K = H.K, C = H.C, Rotation = 0);
[eta, X0] = i_attach(Fp, lk.nodeA, geo);
h.A = Fp.R' * Rh;
h.Eta = eta;
h.Offset = Fp.R' * (Xh - X0);
h.Meta.bdf = struct('EIDs', H.eids, 'GA', H.ga, 'GB', H.gb);
end
