function S = analyseStructure(M, opts)
%analyseStructure Splits the FE model into components (beam chains, shell
%surfaces), finds how they are connected (shared grids, rigid elements,
%joints) and what hangs on them (masses, constraints, points).
%
% Output S:
%   comp      - struct array of components (see i_newComp)
%   clusters  - rigid clusters (grids joined by RBE2 / rigid joints)
%   links     - component connections: compA, nodeA, compB, nodeB, kind
%               ('shared' | 'rigid' | 'hinge'), hinge data
%   sats      - satellites: kind ('mass' | 'constraint' | 'point'), node,
%               anchor node, component, data
%   dropped   - text of grids / elements not carried into baff
%   notes     - approximation notes

S.notes   = {};
S.dropped = {};
nodeId = M.node.id;
N = numel(nodeId);
idx = @(ids) M.geo.gridIndex(ids);

%% Beam chains
S.comp = struct('kind', {}, 'nodes', {}, 'elems', {}, 'rev', {}, 'hubs', {}, ...
    'hubRbe', {}, 'conHubs', {}, 'cp', {}, 'name', {});
if ~isempty(M.beam)
    S.comp = [S.comp, i_beamChains(M, idx)];
end

%% Shell surfaces
if ~isempty(M.shell)
    S.comp = [S.comp, i_shellComps(M, idx)];
end

%Component of each structural grid (first component wins for shared grids)
nodeComp = zeros(1, N);
shared   = cell(1, N);
for c = 1 : numel(S.comp)
    k = idx(S.comp(c).nodes);
    for j = k(:)'
        if nodeComp(j) == 0
            nodeComp(j) = c;
        else
            shared{j}(end + 1) = c;
        end
    end
end

%% Hubs of shell surfaces (RBE3 rib centres, RBE2 constrained stations)
isStruct = nodeComp > 0;
used3 = false(1, numel(M.rbe3));
for r = 1 : numel(M.rbe3)
    e = M.rbe3(r);
    gi = idx([e.g{:}]);
    kr = idx(e.ref);
    if isStruct(kr) || any(isnan(gi)) || ~all(isStruct(gi))
        continue
    end
    c = unique(nodeComp(gi));
    if numel(c) == 1 && strcmp(S.comp(c).kind, 'shell')
        S.comp(c).hubs(end + 1) = e.ref;
        S.comp(c).hubRbe(end + 1) = r;
        nodeComp(kr) = c;
        used3(r) = true;
    end
end
used2 = false(1, numel(M.rbe2));
for r = 1 : numel(M.rbe2)
    e = M.rbe2(r);
    kn = idx(e.gn);
    km = idx(e.gm);
    if isStruct(kn) || numel(km) < 2 || ~all(isStruct(km))
        continue
    end
    c = unique(nodeComp(km));
    if numel(c) == 1 && strcmp(S.comp(c).kind, 'shell')
        S.comp(c).conHubs(end + 1) = r;
        nodeComp(kn) = c;
        used2(r) = true;
    end
end
isAttach = nodeComp > 0;          %structural grids and hubs

%% Joints: hinges and rigid joints
hinge = false(1, numel(M.joint));
hingeData = struct('ga', {}, 'gb', {}, 'axis', {}, 'K', {}, 'C', {}, 'frame', {}, 'eids', {});
rigidPairs = zeros(0, 2);
for j = 1 : numel(M.joint)
    J = M.joint(j);
    if isnan(J.gb)
        S.dropped{end + 1} = sprintf('%s %d: grounded bush (no baff element)', J.type, J.eid);
        continue
    end
    switch J.type
        case 'RJOINT'
            cb = J.cb;
            free = setdiff('123456', cb);
            if isempty(free)
                rigidPairs(end + 1, :) = [J.ga, J.gb]; %#ok<AGROW>
            elseif numel(free) == 1 && any(free == '456')
                r = free - '3';
                %stiffness / damping from a CBUSH between the same grids
                k = find(strcmp({M.joint.type}, 'CBUSH') & [M.joint.ga] == J.ga & [M.joint.gb] == J.gb, 1);
                K = 0; C = 0; eids = J.eid;
                if ~isempty(k)
                    K = M.joint(k).K(r + 3); C = M.joint(k).B(r + 3);
                    hinge(k) = true; eids(end + 1) = M.joint(k).eid; %#ok<AGROW>
                end
                T = M.geo.dispFrame(J.gb);
                hingeData(end + 1) = struct('ga', J.ga, 'gb', J.gb, 'axis', r, 'K', K, ...
                    'C', C, 'frame', T, 'eids', eids); %#ok<AGROW>
                hinge(j) = true;
            else
                rigidPairs(end + 1, :) = [J.ga, J.gb]; %#ok<AGROW>
                S.notes{end + 1} = sprintf('RJOINT %d: released DOFs %s not a single rotation, made rigid.', ...
                    J.eid, free);
            end
    end
end
for j = find(strcmp({M.joint.type}, 'CBUSH') & ~hinge)
    J = M.joint(j);
    if isnan(J.gb) || any(any(rigidPairs == J.ga, 2) & any(rigidPairs == J.gb, 2))
        continue %grounded, or in parallel with a rigid RJOINT
    end
    K = J.K;
    big = K >= opts.RigidStiffness;
    if all(big)
        rigidPairs(end + 1, :) = [J.ga, J.gb]; %#ok<AGROW>
    elseif nnz(~big(4 : 6)) == 1 && all(big(1 : 3))
        r = find(~big(4 : 6));
        hingeData(end + 1) = struct('ga', J.ga, 'gb', J.gb, 'axis', r, 'K', K(r + 3), ...
            'C', J.B(r + 3), 'frame', M.geo.dispFrame(J.gb), 'eids', J.eid); %#ok<AGROW>
    else
        rigidPairs(end + 1, :) = [J.ga, J.gb]; %#ok<AGROW>
        S.notes{end + 1} = sprintf(['CBUSH %d: flexible bush (K = %s) has no baff element, ', ...
            'approximated as a rigid connection.'], J.eid, mat2str(K', 3));
    end
end

%% Rigid clusters (union-find over RBE2 and rigid joints)
parent = 1 : N;
    function r = i_find(a)
        r = a;
        while parent(r) ~= r
            parent(r) = parent(parent(r));
            r = parent(r);
        end
    end
    function i_union(a, b)
        ra = i_find(a); rb = i_find(b);
        if ra ~= rb, parent(rb) = ra; end
    end
rigidEdges = zeros(0, 2);
for r = find(~used2)
    e = M.rbe2(r);
    kn = idx(e.gn);
    for g = e.gm(:)'
        km = idx(g);
        i_union(kn, km);
        rigidEdges(end + 1, :) = [kn, km]; %#ok<AGROW>
    end
    if e.cm ~= 123456
        S.notes{end + 1} = sprintf('RBE2 %d: CM = %d (not all six DOFs), treated as rigid.', e.eid, e.cm);
    end
end
for p = 1 : size(rigidPairs, 1)
    a = idx(rigidPairs(p, 1)); b = idx(rigidPairs(p, 2));
    i_union(a, b);
    rigidEdges(end + 1, :) = [a, b]; %#ok<AGROW>
end
%RBE3 not used as shell hubs: reference grid joined to its first grid
%(splitting the reference grid masses over the independent grids by weight
%was tried on example_1: worse frequencies, spurious local modes)
for r = find(~used3)
    e = M.rbe3(r);
    gi = idx([e.g{:}]);
    kr = idx(e.ref);
    gs = gi(isAttach(gi));
    if isempty(gs), gs = gi; end
    %closest independent grid carries the reference point
    d = vecnorm(M.node.X(:, gs) - M.node.X(:, kr));
    [~, m] = min(d);
    i_union(gs(m), kr);
    rigidEdges(end + 1, :) = [gs(m), kr]; %#ok<AGROW>
    S.notes{end + 1} = sprintf(['RBE3 %d (%d grids) has no baff equivalent: its reference grid %d ', ...
        'is attached rigidly to the closest grid %d.'], e.eid, numel(gi), e.ref, nodeId(gs(m)));
end
root = arrayfun(@i_find, 1 : N);
S.cluster = root;

%% Component connections
S.links = struct('compA', {}, 'nodeA', {}, 'compB', {}, 'nodeB', {}, 'kind', {}, 'hinge', {});
%grids shared by several components (beam junctions, beams on shells)
for j = find(~cellfun(@isempty, shared))
    for c = shared{j}
        S.links(end + 1) = struct('compA', nodeComp(j), 'nodeA', nodeId(j), 'compB', c, ...
            'nodeB', nodeId(j), 'kind', 'shared', 'hinge', []);
    end
end
%rigid clusters holding attachment grids of several components
roots = unique(root);
for rr = roots
    mem = find(root == rr);
    att = mem(isAttach(mem));
    if numel(unique(nodeComp(att))) < 2
        continue
    end
    cs = unique(nodeComp(att), 'stable');
    a = att(find(nodeComp(att) == cs(1), 1));
    for c = cs(2 : end)
        b = att(find(nodeComp(att) == c, 1));
        S.links(end + 1) = struct('compA', cs(1), 'nodeA', nodeId(a), 'compB', c, ...
            'nodeB', nodeId(b), 'kind', 'rigid', 'hinge', []);
    end
end
%hinges between clusters
for h = 1 : numel(hingeData)
    H = hingeData(h);
    [ca, na] = i_clusterComp(idx(H.ga));
    [cb, nb] = i_clusterComp(idx(H.gb));
    if ca == 0 || cb == 0
        S.dropped{end + 1} = sprintf('Hinge %s: grids %d/%d not connected to the structure', ...
            mat2str(H.eids), H.ga, H.gb);
        continue
    end
    S.links(end + 1) = struct('compA', ca, 'nodeA', na, 'compB', cb, 'nodeB', nb, ...
        'kind', 'hinge', 'hinge', H);
end

%% Satellites: masses, constraints, points
S.sats = struct('kind', {}, 'node', {}, 'attach', {}, 'comp', {}, 'data', {});
hasMass = false(1, N);
for m = 1 : numel(M.mass)
    k = idx(M.mass(m).g);
    hasMass(k) = true;
    [c, a] = i_owner(k);
    if c == 0
        S.dropped{end + 1} = sprintf('%s %d on grid %d: not connected to the structure', ...
            M.mass(m).card, M.mass(m).eid, M.mass(m).g);
        continue
    end
    S.sats(end + 1) = struct('kind', 'mass', 'node', M.mass(m).g, 'attach', a, 'comp', c, ...
        'data', M.mass(m));
end
hasSpc = false(1, N);
%one constraint per grid: entries on the same grid (several SPC / SPC1 of
%the set) are merged (union of the components); two baff constraints on one
%grid would become two ADS rigid bars with the same dependent grid
spcGrids = reshape(unique([M.spc.g], 'stable'), 1, []);
for g = spcGrids
    e = M.spc([M.spc.g] == g);
    d = e(1);
    d.c = str2double(unique(sprintf('%d', e.c)));
    k = idx(g);
    hasSpc(k) = true;
    [c, a] = i_owner(k);
    if c == 0
        S.dropped{end + 1} = sprintf('SPC on grid %d: not connected to the structure', g);
        continue
    end
    S.sats(end + 1) = struct('kind', 'constraint', 'node', g, 'attach', a, 'comp', c, 'data', d);
end
%bare leaf grids: points when they define their own frame (CP) or carry loads
loadNodes = [M.load.g];
splineNodes = [M.aero.spline.nodes];
for k = find(~isAttach)
    if hasMass(k) || hasSpc(k)
        continue
    end
    id = nodeId(k);
    [c, a] = i_owner(k);
    inJoint = any([hingeData.ga, hingeData.gb] == id);
    if inJoint
        continue
    end
    ownCP = M.node.CP(k) ~= 0 && c > 0 && M.node.CP(k) ~= S.comp(c).cp;
    if c > 0 && (ownCP || any(loadNodes == id))
        S.sats(end + 1) = struct('kind', 'point', 'node', id, 'attach', a, 'comp', c, ...
            'data', struct('cp', M.node.CP(k))); %#ok<AGROW>
    elseif any(splineNodes == id)
        S.dropped{end + 1} = sprintf(['grid %d: spline-only grid (aero coupling nodes are ', ...
            'regenerated from the wing aero stations)'], id);
    else
        S.dropped{end + 1} = sprintf('grid %d: no element, mass, constraint or load', id);
    end
end
S.nodeComp = nodeComp;
S.nodeId   = nodeId;
S.isAttach = isAttach;
S.hinges = hingeData;

    function [c, n] = i_clusterComp(k)
        %component and attachment grid of the cluster of grid index k
        mem = find(root == root(k));
        att = mem(isAttach(mem));
        if isempty(att)
            c = 0; n = NaN;
            return
        end
        %closest attachment grid
        [~, m] = min(vecnorm(M.node.X(:, att) - M.node.X(:, k)));
        c = nodeComp(att(m)); n = nodeId(att(m));
    end
    function [c, n] = i_owner(k)
        %component and attachment grid that carry grid k
        if isAttach(k)
            c = nodeComp(k); n = nodeId(k);
            return
        end
        %nearest attachment grid along the rigid links (breadth first)
        seen = false(1, N); seen(k) = true;
        front = k;
        while ~isempty(front)
            nxt = [];
            for f = front
                nb = [rigidEdges(rigidEdges(:, 1) == f, 2); rigidEdges(rigidEdges(:, 2) == f, 1)]';
                nb = nb(~seen(nb));
                seen(nb) = true;
                hit = nb(isAttach(nb));
                if ~isempty(hit)
                    c = nodeComp(hit(1)); n = nodeId(hit(1));
                    return
                end
                nxt = [nxt, nb]; %#ok<AGROW>
            end
            front = nxt;
        end
        c = 0; n = NaN;
    end
end

%% ------------------------------------------------------------------ beams
function C = i_beamChains(M, idx)
B = M.beam;
ga = [B.ga]; gb = [B.gb];
nodes = unique([ga, gb]);
inc = containers.Map('KeyType', 'double', 'ValueType', 'any');
for e = 1 : numel(B)
    for g = [ga(e), gb(e)]
        if isKey(inc, g), inc(g) = [inc(g), e]; else, inc(g) = e; end
    end
end
isBreak = containers.Map('KeyType', 'double', 'ValueType', 'logical');
for g = nodes
    es = inc(g);
    if numel(es) ~= 2
        isBreak(g) = true;
    else
        isBreak(g) = ~i_compatible(B, es(1), es(2), g, M);
    end
end
visited = false(1, numel(B));
C = struct('kind', {}, 'nodes', {}, 'elems', {}, 'rev', {}, 'hubs', {}, ...
    'hubRbe', {}, 'conHubs', {}, 'cp', {}, 'name', {});
starts = nodes(cell2mat(values(isBreak, num2cell(nodes))));
for pass = 1 : 2
    if pass == 2
        starts = nodes; %closed loops
    end
    for s = starts
        for e0 = inc(s)
            if visited(e0), continue, end
            cur = s; e = e0;
            ch.nodes = s; ch.elems = []; ch.rev = [];
            while true
                visited(e) = true;
                rev = ga(e) ~= cur;
                if rev, nxt = ga(e); else, nxt = gb(e); end
                ch.nodes(end + 1) = nxt; ch.elems(end + 1) = e; ch.rev(end + 1) = rev;
                if isBreak(nxt) || nxt == s
                    break
                end
                es = inc(nxt);
                e = es(es ~= e);
                if isempty(e) || visited(e(1)), break, end
                e = e(1);
                cur = nxt;
            end
            cps = M.node.CP(idx(ch.nodes));
            cp = cps(1);
            if any(cps ~= cp), cp = NaN; end
            C(end + 1) = struct('kind', 'beam', 'nodes', ch.nodes, 'elems', ch.elems, ...
                'rev', ch.rev, 'hubs', [], 'hubRbe', [], 'conHubs', [], 'cp', cp, ...
                'name', sprintf('Beam_%d', B(ch.elems(1)).eid)); %#ok<AGROW>
        end
    end
end
end

function tf = i_compatible(B, e1, e2, g, M)
%Two beam elements continue one chain through grid g
tf = strcmp(B(e1).type, B(e2).type) && B(e1).mid == B(e2).mid && ...
    strcmp(B(e1).pcard, B(e2).pcard) && isequaln(B(e1).K, B(e2).K);
if ~tf, return, end
s1 = i_secAt(B(e1), g); s2 = i_secAt(B(e2), g);
f = {'A', 'I1', 'I2', 'I12', 'J', 'NSM'};
for k = 1 : numel(f)
    a = s1.(f{k}); b = s2.(f{k});
    if abs(a - b) > 1e-9 * max([abs(a), abs(b), 1e-30])
        tf = false;
        return
    end
end
%chains do not cross coordinate system boundaries
k = M.geo.gridIndex([B(e1).ga, B(e1).gb, B(e2).ga, B(e2).gb]);
tf = numel(unique(M.node.CP(k))) == 1;
end

function s = i_secAt(b, g)
if b.ga == g, s = b.secA; else, s = b.secB; end
end

%% ----------------------------------------------------------------- shells
function C = i_shellComps(M, idx)
Sh = M.shell;
n = numel(Sh);
lab = 1 : n;
owner = containers.Map('KeyType', 'double', 'ValueType', 'double');
    function r = f(a)
        r = a;
        while lab(r) ~= r, lab(r) = lab(lab(r)); r = lab(r); end
    end
for e = 1 : n
    for g = Sh(e).g(~isnan(Sh(e).g))'
        if isKey(owner, g)
            ra = f(owner(g)); rb = f(e);
            if ra ~= rb, lab(rb) = ra; end
        else
            owner(g) = e;
        end
    end
end
r = arrayfun(@f, 1 : n);
u = unique(r, 'stable');
C = struct('kind', {}, 'nodes', {}, 'elems', {}, 'rev', {}, 'hubs', {}, ...
    'hubRbe', {}, 'conHubs', {}, 'cp', {}, 'name', {});
for k = 1 : numel(u)
    el = find(r == u(k));
    g = [Sh(el).g];
    g = unique(g(~isnan(g)), 'stable');
    cps = M.node.CP(idx(g));
    cp = cps(1);
    if any(cps ~= cp), cp = NaN; end
    C(end + 1) = struct('kind', 'shell', 'nodes', g(:)', 'elems', el, 'rev', [], ...
        'hubs', [], 'hubRbe', [], 'conHubs', [], 'cp', cp, ...
        'name', sprintf('Shell_%d', Sh(el(1)).eid)); %#ok<AGROW>
end
end
