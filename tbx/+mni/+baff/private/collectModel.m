function M = collectModel(fem, geo, info, opts)
%collectModel Plain arrays of everything the baff conversion needs, with
%positions and vectors in the basic system.

M.geo = geo;
M.node.id  = geo.GID;
M.node.X   = geo.X;
M.node.CP  = geo.CP;
M.node.CD  = geo.CD;

%% Materials
M.mat = struct('mid', {}, 'E', {}, 'G', {}, 'nu', {}, 'rho', {}, 'card', {}, 'raw', {});
if isprop(fem, 'MAT1')
    m = fem.MAT1;
    for i = 1 : m.NumBulk
        [E, G, nu] = i_mat1(m.E(i), m.G(i), m.NU(i));
        M.mat(end + 1) = struct('mid', m.MID(i), 'E', E, 'G', G, 'nu', nu, ...
            'rho', m.RHO(i), 'card', 'MAT1', 'raw', []);
    end
end
if isprop(fem, 'MAT8')
    m = fem.MAT8;
    for i = 1 : m.NumBulk
        raw = struct('E1', m.E1(i), 'E2', m.E2(i), 'NU12', m.NU12(i), 'G12', m.G12(i), ...
            'G1Z', m.G1Z(i), 'G2Z', m.G2Z(i));
        M.mat(end + 1) = struct('mid', m.MID(i), 'E', m.E1(i), 'G', m.G12(i), 'nu', m.NU12(i), ...
            'rho', m.RHO(i), 'card', 'MAT8', 'raw', raw);
    end
end

%% Beam elements (orientation vector in basic, section at both ends)
B = struct('eid', {}, 'type', {}, 'pid', {}, 'ga', {}, 'gb', {}, 'v', {}, 'g0', {}, ...
    'offt', {}, 'wa', {}, 'wb', {}, 'secA', {}, 'secB', {}, 'mid', {}, 'K', {}, 'pcard', {});
props = i_beamProps(fem);
for t = {'CBEAM', 'CBAR', 'CROD'}
    if ~isprop(fem, t{1}), continue, end
    b = fem.(t{1});
    for i = 1 : b.NumBulk
        ga = b.GA_GB(1, i); gb = b.GA_GB(2, i);
        e = struct('eid', b.EID(i), 'type', t{1}, 'pid', b.PID(i), 'ga', ga, 'gb', gb, ...
            'v', nan(3, 1), 'g0', NaN, 'offt', 'GGG', 'wa', zeros(3, 1), 'wb', zeros(3, 1), ...
            'secA', [], 'secB', [], 'mid', NaN, 'K', [NaN, NaN], 'pcard', '');
        if ~strcmp(t{1}, 'CROD')
            e.offt = b.OFFT{i};
            if isprop(b, 'G0') && ~isnan(b.G0(i))
                e.g0 = b.G0(i);
                e.v  = geo.position(e.g0) - geo.position(ga);
            else
                x = b.X(:, i);
                if e.offt(1) == 'B'
                    e.v = x;
                else
                    e.v = geo.dispFrame(ga) * x;
                end
            end
            wa = b.WA(:, i); wb = b.WB(:, i);
            if e.offt(2) == 'B', e.wa = wa; else, e.wa = geo.dispFrame(ga) * wa; end
            if e.offt(3) == 'B', e.wb = wb; else, e.wb = geo.dispFrame(gb) * wb; end
        end
        k = find([props.pid] == e.pid, 1);
        if isempty(k)
            error('mni:baff:property', '%s %d: property %d not found.', t{1}, e.eid, e.pid);
        end
        e.secA = props(k).secA; e.secB = props(k).secB;
        e.mid = props(k).mid; e.K = props(k).K; e.pcard = props(k).card;
        B(end + 1) = e; %#ok<AGROW>
    end
end
M.beam = B;

%% Shell elements
S = struct('eid', {}, 'pid', {}, 'g', {}, 'T', {}, 'mid', {}, 'mid2', {}, 'mid3', {}, ...
    'BK', {}, 'TST', {}, 'NSM', {}, 'pcard', {}, 'ply', {});
sp = i_shellProps(fem);
for t = {'CQUAD4', 'CTRIA3'}
    if ~isprop(fem, t{1}), continue, end
    s = fem.(t{1});
    for i = 1 : s.NumBulk
        g = s.G(:, i);
        g(end + 1 : 4) = NaN; %CTRIA3: 4th grid NaN
        k = find([sp.pid] == s.PID(i), 1);
        if isempty(k)
            error('mni:baff:property', '%s %d: property %d not found.', t{1}, s.EID(i), s.PID(i));
        end
        p = sp(k);
        S(end + 1) = struct('eid', s.EID(i), 'pid', s.PID(i), 'g', g(:), 'T', p.T, ...
            'mid', p.mid, 'mid2', p.mid2, 'mid3', p.mid3, 'BK', p.BK, 'TST', p.TST, ...
            'NSM', p.NSM, 'pcard', p.card, 'ply', p.ply); %#ok<AGROW>
    end
end
M.shell = S;

%% Rigid elements
M.rbe2 = struct('eid', {}, 'gn', {}, 'cm', {}, 'gm', {});
if isprop(fem, 'RBE2')
    r = fem.RBE2;
    for i = 1 : r.NumBulk
        M.rbe2(end + 1) = struct('eid', r.EID(i), 'gn', r.GN(i), 'cm', r.CM(i), 'gm', r.GMi{i});
    end
end
M.rbe3 = struct('eid', {}, 'ref', {}, 'refc', {}, 'wt', {}, 'c', {}, 'g', {});
if isprop(fem, 'RBE3')
    r = fem.RBE3;
    for i = 1 : r.NumBulk
        M.rbe3(end + 1) = struct('eid', r.EID(i), 'ref', r.REFGRID(i), 'refc', r.REFC(i), ...
            'wt', r.WTi{i}, 'c', r.Ci{i}, 'g', {r.Gij{i}});
    end
end

%% Joints: RJOINT, CBUSH (+PBUSH)
M.joint = struct('eid', {}, 'type', {}, 'ga', {}, 'gb', {}, 'cb', {}, 'cid', {}, 'K', {}, 'B', {});
if isprop(fem, 'RJOINT')
    r = fem.RJOINT;
    for i = 1 : r.NumBulk
        M.joint(end + 1) = struct('eid', r.EID(i), 'type', 'RJOINT', 'ga', r.GA(i), ...
            'gb', r.GB(i), 'cb', r.CB{i}, 'cid', NaN, 'K', [], 'B', []);
    end
end
if isprop(fem, 'CBUSH')
    c = fem.CBUSH;
    pb = [];
    if isprop(fem, 'PBUSH'), pb = fem.PBUSH; end
    for i = 1 : c.NumBulk
        K = zeros(6, 1); Bd = zeros(6, 1);
        if ~isempty(pb)
            k = find(pb.PID == c.PID(i), 1);
            if ~isempty(k), K = pb.K(:, k); Bd = pb.B(:, k); end
        end
        M.joint(end + 1) = struct('eid', c.EID(i), 'type', 'CBUSH', 'ga', c.GA(i), ...
            'gb', c.GB(i), 'cb', '', 'cid', c.CID(i), 'K', K, 'B', Bd);
    end
end

%% Masses
M.mass = struct('eid', {}, 'g', {}, 'cid', {}, 'm', {}, 'x', {}, 'I', {}, 'card', {});
if isprop(fem, 'CONM2')
    c = fem.CONM2;
    for i = 1 : c.NumBulk
        I = [c.I1(i), c.I2(1, i), c.I2(2, i), c.I3(1, i), c.I3(2, i), c.I3(3, i)];
        M.mass(end + 1) = struct('eid', c.EID(i), 'g', c.G(i), 'cid', c.CID(i), 'm', c.M(i), ...
            'x', c.X(:, i), 'I', I, 'card', 'CONM2');
    end
end
if isprop(fem, 'CONM1')
    c = fem.CONM1;
    for i = 1 : c.NumBulk
        Mm = zeros(6);
        Mm(1, 1) = c.M1(i);
        Mm(2, 1 : 2) = c.M2(:, i)';
        Mm(3, 1 : 3) = c.M3(:, i)';
        Mm(4, 1 : 4) = c.M4(:, i)';
        Mm(5, 1 : 5) = c.M5(:, i)';
        Mm(6, 1 : 6) = c.M6(:, i)';
        Mm = Mm + tril(Mm, -1)';
        M.mass(end + 1) = struct('eid', c.EID(i), 'g', c.G(i), 'cid', c.CID(i), 'm', Mm(1, 1), ...
            'x', zeros(3, 1), 'I', Mm, 'card', 'CONM1');
    end
end

%% Single point constraints of the selected set
M.spc = i_spcSet(fem, info, opts.SpcSet);

%% Loads (kept for the report / harness, not converted)
M.load = struct('card', {}, 'sid', {}, 'g', {}, 'v', {});
for t = {'FORCE', 'MOMENT'}
    if ~isprop(fem, t{1}), continue, end
    f = fem.(t{1});
    V = vectors(f);
    for i = 1 : f.NumBulk
        cid = f.CID(i);
        at = geo.position(f.G(i));
        M.load(end + 1) = struct('card', t{1}, 'sid', f.SID(i), 'g', f.G(i), ...
            'v', geo.vecToBasic(V(:, i), cid, at));
    end
end

%% Aero
M.aero = aeroData(fem, geo);
end

function [E, G, nu] = i_mat1(E, G, nu)
%QRG MAT1 remark: two of E, G, NU define the third
if isnan(nu) && ~isnan(E) && ~isnan(G) && G ~= 0
    nu = E / (2 * G) - 1;
elseif isnan(G) && ~isnan(E) && ~isnan(nu)
    G = E / (2 * (1 + nu));
elseif isnan(E) && ~isnan(G) && ~isnan(nu)
    E = 2 * G * (1 + nu);
end
E(isnan(E)) = 0; G(isnan(G)) = 0; nu(isnan(nu)) = 0;
end

function P = i_beamProps(fem)
P = struct('pid', {}, 'mid', {}, 'secA', {}, 'secB', {}, 'K', {}, 'card', {});
for t = {'PBEAM', 'PBAR', 'PROD', 'PBEAML', 'PBARL'}
    if ~isprop(fem, t{1}), continue, end
    p = fem.(t{1});
    for i = 1 : p.NumBulk
        K = [NaN, NaN];
        switch t{1}
            case 'PBEAM', K = p.K(:, i)';
            case 'PBAR',  K = p.K(:, i)';
        end
        P(end + 1) = struct('pid', p.PID(i), 'mid', p.MID(i), 'secA', section(p, i, 'A'), ...
            'secB', section(p, i, 'B'), 'K', K, 'card', t{1}); %#ok<AGROW>
    end
end
end

function P = i_shellProps(fem)
P = struct('pid', {}, 'T', {}, 'mid', {}, 'mid2', {}, 'mid3', {}, 'BK', {}, 'TST', {}, ...
    'NSM', {}, 'card', {}, 'ply', {});
if isprop(fem, 'PSHELL')
    p = fem.PSHELL;
    for i = 1 : p.NumBulk
        P(end + 1) = struct('pid', p.PID(i), 'T', p.T(i), 'mid', p.MID1(i), 'mid2', p.MID2(i), ...
            'mid3', p.MID3(i), 'BK', p.BK(i), 'TST', p.TS(i), 'NSM', p.NSM(i), 'card', 'PSHELL', ...
            'ply', []); %#ok<AGROW>
    end
end
if isprop(fem, 'PCOMP')
    p = fem.PCOMP;
    for i = 1 : p.NumBulk
        ply = struct('Z0', p.Z0(i), 'NSM', p.NSM(i), 'SB', p.SB(i), 'FT', p.FT{i}, ...
            'TREF', p.TREF(i), 'GE', p.GE(i), 'LAM', p.LAM{i}, 'MIDi', p.MIDi{i}, ...
            'Ti', p.Ti{i}, 'THETAi', p.THETAi{i}, 'SOUTi', {p.SOUTi(i)});
        P(end + 1) = struct('pid', p.PID(i), 'T', sum(p.Ti{i}), 'mid', p.MIDi{i}(1), ...
            'mid2', NaN, 'mid3', NaN, 'BK', 1, 'TST', NaN, 'NSM', p.NSM(i), 'card', 'PCOMP', ...
            'ply', ply); %#ok<AGROW>
    end
end
end

function spc = i_spcSet(fem, info, sid)
%Constrained grid / components of SPC set 'sid' (default: the SPC
%selection of the first subcase; without Case Control every SPC/SPC1).
spc = struct('g', {}, 'c', {}, 'sid', {});
if isempty(sid) && ~isempty(info) && isfield(info, 'Subcases') && ~isempty(info.Subcases)
    sel = info.Subcases(1).Selections;
    k = find(strcmp({sel.Command}, 'SPC'), 1);
    if ~isempty(k)
        sid = sel(k).ID;
    end
end
sids = sid;
if ~isempty(sid) && isprop(fem, 'SPCADD')
    a = fem.SPCADD;
    k = find(a.SID == sid);
    for i = k(:)'
        sids = [sids, a.Si{i}]; %#ok<AGROW>
    end
end
if isprop(fem, 'SPC1')
    s = fem.SPC1;
    for i = 1 : s.NumBulk
        if isempty(sid) || any(sids == s.SID(i))
            g = s.G{i};
            for j = 1 : numel(g)
                spc(end + 1) = struct('g', g(j), 'c', str2double(s.C{i}), 'sid', s.SID(i)); %#ok<AGROW>
            end
        end
    end
end
if isprop(fem, 'SPC')
    s = fem.SPC;
    for i = 1 : s.NumBulk
        if isempty(sid) || any(sids == s.SID(i))
            g = s.G{i}; c = s.C{i};
            for j = 1 : numel(g)
                spc(end + 1) = struct('g', g(j), 'c', c(j), 'sid', s.SID(i)); %#ok<AGROW>
            end
        end
    end
end
end
