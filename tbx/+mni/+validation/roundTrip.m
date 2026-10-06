function R = roundTrip(file, opts)
%roundTrip Verifies the bdf -> Matran -> baff -> ADS -> bdf round trip of
%a Nastran input file.
%
%   1. mni.import_matran(file, 'ToBaff', true)       -> fem, info, baff.Model
%   2. ads.baff.baff2fe + Export                     -> rt_model.bdf
%      (AERO / AEROS and the panel discretisation, which baff does not
%      hold, are re-applied from the conversion report)
%   3. re-import of rt_model.bdf (and its baff conversion)
%   4. mni.validation.compareModels (grids, constraints, masses, aero)
%   5. MSC Nastran on both models with the same PARAMs: SOL 103 (mass
%      properties from PARAM,GRDPNT, frequencies, MAC at the matched
%      grids) and, for constrained models, SOL 101 (gravity and the
%      original subcase loads mapped to the round trip grids)
%   6. report.md in the output folder
%
% Syntax:
%   >> R = mni.validation.roundTrip('Examples/example_1_semispan_model/data/model.bdf');
%   >> R = mni.validation.roundTrip(file, 'RunNastran', false, 'OutDir', tempname);
%
% Name-value options:
%   'Name'         - name of the case (default: file name)
%   'OutDir'       - output folder (default: <Matran>/validation/results/<Name>)
%   'RunNastran'   - (true) run the Nastran comparisons when Nastran is found
%   'Exe'          - Nastran executable (default mni.validation.nastranExe)
%   'NumModes'     - (10) elastic modes compared
%   'RigidFreq'    - (0.1) modes below this frequency [Hz] are rigid body modes
%   'MaxLoadCases' - (6) original subcases with LOAD mapped in SOL 101
%   'BaffOptions'  - cell of options for mni.baff.fromFEModel
%   'AdsOptions'   - cell of name-value pairs for ads.baff.BaffOpts

arguments
    file {mustBeTextScalar}
    opts.Name string = ""
    opts.OutDir = ''
    opts.RunNastran (1, 1) logical = true
    opts.Exe = ''
    opts.NumModes (1, 1) double = 10
    opts.RigidFreq (1, 1) double = 0.1
    opts.MaxLoadCases (1, 1) double = 6
    opts.BaffOptions cell = {}
    opts.AdsOptions cell = {}
    opts.Verbose (1, 1) logical = true
end
file = char(file);
[~, base] = fileparts(file);
name = char(opts.Name);
if isempty(name), name = base; end
out = char(opts.OutDir);
if isempty(out)
    root = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
    out = fullfile(root, 'validation', 'results', name);
end
if ~isfolder(out), mkdir(out); end
logf = @(varargin) i_log(opts.Verbose, varargin{:});
R = struct('Name', name, 'File', file, 'OutDir', out);
notes = {};

%% 1. import + baff conversion
logf('[%s] import + baff conversion', name);
ws = warning('off', 'all');
cw = onCleanup(@() warning(ws));
[fem, info, bm] = mni.import_matran(file, 'ToBaff', true, 'Verbose', false, ...
    'BaffOptions', opts.BaffOptions);
rep = info.Baff;
R.Info = info;
R.Baff = bm;
R.Conversion = rep;

%% 2. baff -> ADS -> bdf
logf('[%s] baff -> ADS -> rt_model.bdf', name);
[fe, notes] = i_toAds(bm, rep, fem, opts, notes);
fe.UpdateIDs();
rtFile = fullfile(out, 'rt_model.bdf');
fe.Export(rtFile);
R.Ads = fe;
R.RtFile = rtFile;

%% 3. re-import (+ second conversion)
logf('[%s] re-import of the round trip model', name);
[fem2, info2] = mni.import_matran(rtFile, 'Verbose', false);
R.RtInfo = info2;
R.Baff2 = [];
R.Conversion2 = [];
try
    [~, info3, bm2] = mni.import_matran(rtFile, 'Verbose', false, 'ToBaff', true);
    R.Baff2 = bm2;
    R.Conversion2 = info3.Baff;
catch err
    notes{end + 1} = ['Conversion of rt_model.bdf to baff failed: ', err.message];
end

%% 4. model comparison
logf('[%s] model comparison', name);
C = mni.validation.compareModels(fem, fem2, 'Dropped', rep.Dropped, ...
    'DroppedCaero', rep.DroppedCaero);
R.Compare = C;
R.Mass = struct('Baff', bm.GetMass(), 'Ads', sum(fe.GetMass()), 'Baff2', NaN);
if ~isempty(R.Baff2), R.Mass.Baff2 = R.Baff2.GetMass(); end

%% 5. Nastran
R.Nastran = [];
exe = char(opts.Exe);
if isempty(exe), exe = mni.validation.nastranExe(); end
if opts.RunNastran && ~isempty(exe)
    [R.Nastran, notes] = i_nastran(file, fem, fem2, info, rep, C, out, exe, opts, logf, notes);
elseif opts.RunNastran
    notes{end + 1} = 'MSC Nastran not found: analyses skipped.';
end
R.Notes = notes';

%% 6. report
R.Report = fullfile(out, 'report.md');
i_report(R);
logf('[%s] report: %s', name, R.Report);
end

%% ======================================================================
function [fe, notes] = i_toAds(bm, rep, fem, opts, notes)
hasAero = ~isempty(fieldnames(rep.AeroMesh));
bo = ads.baff.BaffOpts('SplitBeamsAtChildren', false, 'GenerateAeroPanels', hasAero, ...
    opts.AdsOptions{:});
fe = ads.baff.baff2fe(bm, bo);
if ~hasAero || isempty(fe.AeroSurfaces)
    return
end
A = rep.AeroSettings;
geo = mni.util.Geometry(fem);
acs = i_adsFrame(geo, A.acsid);
if A.acsid ~= 0, fe.CoordSys(end + 1) = acs; end
if A.rcsid == A.acsid
    rcs = acs;
else
    rcs = i_adsFrame(geo, A.rcsid);
    if A.rcsid ~= 0, fe.CoordSys(end + 1) = rcs; end
end
fe.AeroSettings = ads.fe.AeroSettings(i_def(A.refc, 1), i_def(A.rhoref, 1.225), ...
    i_def(A.refb, 1), i_def(A.refs, 1), Velocity = i_def(A.velocity, 1), ...
    ACSID = acs, RCSID = rcs, SymXZ = A.symxz, SymXY = A.symxy);
%panel discretisation of the original CAERO1 entries
m = struct2cell(rep.AeroMesh);
m = [m{:}];
for i = 1 : numel(fe.AeroSurfaces)
    s = fe.AeroSurfaces(i);
    s.AeroCoordSys = acs;
    [X1, X4] = i_surfEdge(s);
    d = arrayfun(@(p) i_segDist(X1, p.p1, p.p4) + i_segDist(X4, p.p1, p.p4), m);
    [dk, k] = min(d);
    p = m(k);
    L = norm(p.p4 - p.p1);
    if dk > 1e-3 * L
        notes{end + 1} = sprintf(['ADS aero surface %d: leading edge %.3g off the leading ', ...
            'edge of CAERO1 %d.'], i, dk, p.eid); %#ok<AGROW>
    end
    s.nSpan = max(1, round(p.nspan * norm(X4 - X1) / L));
    s.nChord = p.nchord;
    if max(abs(diff(p.etaSpan, 2))) > 1e-6
        notes{end + 1} = sprintf(['CAERO1 %d: non-uniform spanwise division (LSPAN) ', ...
            'written as uniform NSPAN.'], p.eid); %#ok<AGROW>
    end
    if isnan(s.HingeEta) && max(abs(diff(p.etaChord, 2))) > 1e-6
        notes{end + 1} = sprintf(['CAERO1 %d: non-uniform chordwise division (LCHORD) ', ...
            'written as uniform NCHORD.'], p.eid); %#ok<AGROW>
    end
    fe.AeroSurfaces(i) = s;
end
end

function cs = i_adsFrame(geo, cid)
if cid == 0
    cs = ads.fe.BaseCoordSys.get;
else
    [O, Rr] = geo.frame(cid);
    cs = ads.fe.CoordSys(Origin = O, A = Rr);
end
end

function v = i_def(v, d)
if isempty(v) || isnan(v), v = d; end
end

function [X1, X4] = i_surfEdge(s)
%leading edge points of an ADS aero surface as ads.fe.AeroSurface.Export
%writes them, in basic
xg = s.AeroCoordSys.getAglobal() * [1; 0; 0];
xl = s.CoordSys.getAglobal()' * xg;
P1 = s.Points(:, 1) + s.ChordVecs(:, 1) .* s.Chords(1) .* (s.CrossEta - s.ChordwisePos(1));
P2 = s.Points(:, 2) + s.ChordVecs(:, 2) .* s.Chords(2) .* (s.CrossEta - s.ChordwisePos(2));
X1 = s.CoordSys.getPointGlobal(P1 - s.Chords(1) * xl * s.CrossEta);
X4 = s.CoordSys.getPointGlobal(P2 - s.Chords(2) * xl * s.CrossEta);
end

function d = i_segDist(x, a, b)
t = max(0, min(1, dot(x - a, b - a) / max(dot(b - a, b - a), eps)));
d = norm(x - (a + t * (b - a)));
end

%% ====================================================================== Nastran
function [N, notes] = i_nastran(file, fem, fem2, info, rep, C, out, exe, opts, logf, notes)
deck = mni.io.readDeck(file);
names = {deck.Bulk.Name};
%PARAMs shared by both models (output requests replaced)
P = deck.Bulk(strcmp(names, 'PARAM'));
keep = arrayfun(@(p) ~isempty(p.Fields) && ~ismember(upper(strtrim(p.Fields{1})), ...
    {'POST', 'GRDPNT', 'PATVER', 'OGEOM', 'AUTOSPC'}), P);
P = P(keep);
if any(strcmp(names, 'MDLPRM'))
    notes{end + 1} = 'Original MDLPRM entries replaced by MDLPRM,HDF5,1 in both analyses.';
end
excl = {'PARAM', 'MDLPRM', 'SUPORT', 'SUPORT1'};
if any(ismember(names, {'SUPORT', 'SUPORT1'}))
    notes{end + 1} = 'SUPORT / SUPORT1 left out of both analyses.';
end
fid = fopen(fullfile(out, 'orig_bulk.bdf'), 'w');
mni.validation.writeBulk(fid, deck.Bulk, 'Exclude', excl);
fclose(fid);

%constraint sets
sid1 = unique([rep.Spc.sid]);
sid2 = [];
if isprop(fem2, 'SPC1'), sid2 = [sid2, fem2.SPC1.SID]; end
if isprop(fem2, 'SPC'), sid2 = [sid2, fem2.SPC.SID]; end
sid2 = unique(sid2);
hasSpc = ~isempty(sid1);
geo1 = mni.util.Geometry(fem);
geo2 = mni.util.Geometry(fem2);
map = C.Grids.Map;

%% SOL 103
nd = opts.NumModes + 6;
base = [i_card('MDLPRM', 'HDF5', 1), i_card('PARAM', 'GRDPNT', 0), ...
    i_card('EIGRL', 999901, [], [], nd), P];
cc = {'METHOD = 999901', 'DISP(PLOT) = ALL'};
if hasSpc, cc{end + 1} = 'SPC = 999902'; end
i_deck(fullfile(out, 'orig_sol103.bdf'), 103, 'ORIGINAL', 'orig_bulk.bdf', cc, ...
    [base, i_spcadd(sid1)]);
i_deck(fullfile(out, 'rt_sol103.bdf'), 103, 'ROUND TRIP', 'rt_model.bdf', cc, ...
    [base, i_spcadd(sid2)]);
logf('    SOL 103 original');
r1 = mni.validation.runNastran(fullfile(out, 'orig_sol103.bdf'), 'Exe', exe);
logf('    SOL 103 round trip');
r2 = mni.validation.runNastran(fullfile(out, 'rt_sol103.bdf'), 'Exe', exe);
N.Sol103 = struct('Original', r1, 'RoundTrip', r2, 'Gpwg', [], 'Modes', []);
if r1.OK && r2.OK
    N.Sol103.Gpwg = [mni.validation.readGpwg(r1.F06), mni.validation.readGpwg(r2.F06)];
    N.Sol103.Modes = i_modes(r1.H5, r2.H5, map, geo1, geo2, opts);
else
    notes{end + 1} = sprintf('SOL 103 failed: %s', strjoin([r1.Fatal, r2.Fatal], ' | '));
end

%% SOL 101
N.Sol101 = [];
if ~hasSpc
    notes{end + 1} = 'Unconstrained model: SOL 101 skipped.';
    return
end
lc = struct('Label', 'GRAVITY -Z 9.81', 'Orig', 999903, 'Rt', 999903, 'Note', '');
grav = i_card('GRAV', 999903, 0, i_real(9.81), i_real(0), i_real(0), i_real(-1));
extra2 = grav;
for s = info.Subcases
    if numel(lc) > opts.MaxLoadCases, break, end
    k = find(strcmp({s.Selections.Command}, 'LOAD'), 1);
    if isempty(k), continue, end
    id = s.Selections(k).ID;
    if any([lc.Orig] == id), continue, end
    [cards, note] = i_mapLoad(fem, geo1, geo2, id, 999910 + 10 * numel(lc), map, C.Grids.Tol);
    lc(end + 1) = struct('Label', sprintf('SUBCASE %d: LOAD = %d', s.ID, id), 'Orig', id, ...
        'Rt', 999910 + 10 * (numel(lc)), 'Note', note); %#ok<AGROW>
    extra2 = [extra2, cards]; %#ok<AGROW>
end
cc1 = {'SPC = 999902', 'DISP(PLOT) = ALL'};
cc2 = cc1;
for k = 1 : numel(lc)
    cc1 = [cc1, {sprintf('SUBCASE %d', k), sprintf('  LABEL = %s', lc(k).Label), ...
        sprintf('  LOAD = %d', lc(k).Orig)}]; %#ok<AGROW>
    cc2 = [cc2, {sprintf('SUBCASE %d', k), sprintf('  LABEL = %s', lc(k).Label), ...
        sprintf('  LOAD = %d', lc(k).Rt)}]; %#ok<AGROW>
end
base = [i_card('MDLPRM', 'HDF5', 1), P];
i_deck(fullfile(out, 'orig_sol101.bdf'), 101, 'ORIGINAL', 'orig_bulk.bdf', cc1, ...
    [base, grav, i_spcadd(sid1)]);
i_deck(fullfile(out, 'rt_sol101.bdf'), 101, 'ROUND TRIP', 'rt_model.bdf', cc2, ...
    [base, extra2, i_spcadd(sid2)]);
logf('    SOL 101 original');
r1 = mni.validation.runNastran(fullfile(out, 'orig_sol101.bdf'), 'Exe', exe);
logf('    SOL 101 round trip');
r2 = mni.validation.runNastran(fullfile(out, 'rt_sol101.bdf'), 'Exe', exe);
N.Sol101 = struct('Original', r1, 'RoundTrip', r2, 'Cases', lc, 'Static', []);
if r1.OK && r2.OK
    N.Sol101.Static = i_static(r1.H5, r2.H5, map, geo1, geo2, lc);
else
    notes{end + 1} = sprintf('SOL 101 failed: %s', strjoin([r1.Fatal, r2.Fatal], ' | '));
end
end

function c = i_card(name, varargin)
%bulk entry from values: integers -> integer fields, other numbers -> real
%fields, text as given (use i_real for real fields holding integer values)
f = cell(1, numel(varargin));
for i = 1 : numel(varargin)
    v = varargin{i};
    if isempty(v)
        f{i} = '';
    elseif ischar(v) || isstring(v)
        f{i} = char(v);
    elseif v == round(v)
        f{i} = sprintf('%d', v);
    else
        f{i} = i_real(v);
    end
end
c = struct('Name', name, 'Fields', {f}, 'File', '', 'Line', 0);
end

function s = i_real(v)
s = upper(sprintf('%.9G', v));
if ~contains(s, '.')
    e = strfind(s, 'E');
    if isempty(e), s = [s, '.']; else, s = [s(1 : e - 1), '.', s(e : end)]; end
end
end

function c = i_spcadd(sids)
if isempty(sids)
    c = struct('Name', {}, 'Fields', {}, 'File', {}, 'Line', {});
else
    a = num2cell(sids(:)');
    c = i_card('SPCADD', 999902, a{:});
end
end

function i_deck(file, sol, title, include, cc, cards)
fid = fopen(file, 'w');
fprintf(fid, 'SOL %d\nCEND\nTITLE = %s\nECHO = NONE\n', sol, title);
fprintf(fid, '%s\n', cc{:});
fprintf(fid, 'BEGIN BULK\n');
mni.validation.writeBulk(fid, cards);
fprintf(fid, 'INCLUDE ''%s''\n', include);
fprintf(fid, 'ENDDATA\n');
fclose(fid);
end

function [cards, note] = i_mapLoad(fem, geo1, geo2, sid, newSid, map, tol)
%original load set 'sid' -> FORCE / MOMENT / GRAV entries in basic on the
%round trip grids at the same positions
L = struct('f', zeros(4, 0), 'm', zeros(4, 0), 'g', zeros(3, 1));
L = i_resolve(fem, geo1, sid, 1, L, 0);
cards = struct('Name', {}, 'Fields', {}, 'File', {}, 'Line', {});
moved = 0; lost = 0; dmax = 0;
hasF = ~isempty(L.f) || ~isempty(L.m);
hasG = any(L.g);
sF = newSid; sG = newSid;
if hasF && hasG
    sF = newSid + 1; sG = newSid + 2;
    cards(end + 1) = i_card('LOAD', newSid, i_real(1), i_real(1), sF, i_real(1), sG);
end
for t = {'f', 'm'}
    V = L.(t{1});
    for i = 1 : size(V, 2)
        g = V(1, i);
        k = find(map(:, 1) == g, 1);
        if ~isempty(k)
            g2 = map(k, 2);
        else
            d = vecnorm(geo2.X - geo1.position(g));
            [dd, j] = min(d);
            if isempty(j), lost = lost + 1; continue, end
            if dd > 100 * tol, moved = moved + 1; dmax = max(dmax, dd); end
            g2 = geo2.GID(j);
        end
        nm = 'FORCE';
        if t{1} == 'm', nm = 'MOMENT'; end
        cards(end + 1) = i_card(nm, sF, g2, 0, i_real(1), i_real(V(2, i)), i_real(V(3, i)), ...
            i_real(V(4, i))); %#ok<AGROW>
    end
end
if hasG
    a = norm(L.g);
    cards(end + 1) = i_card('GRAV', sG, 0, i_real(a), i_real(L.g(1) / a), i_real(L.g(2) / a), ...
        i_real(L.g(3) / a));
end
note = '';
if moved > 0
    note = sprintf('%d load(s) moved to the nearest round trip grid (up to %.3g).', moved, dmax);
end
if lost > 0
    note = [note, sprintf(' %d load(s) lost.', lost)];
end
end

function L = i_resolve(fem, geo, sid, scale, L, depth)
assert(depth < 10, 'mni:validation:roundTrip', 'LOAD recursion too deep.');
if isprop(fem, 'LOAD')
    k = find(fem.LOAD.SID == sid, 1);
    if ~isempty(k)
        Si = fem.LOAD.Si{k}; Li = fem.LOAD.Li{k};
        for q = 1 : numel(Li)
            L = i_resolve(fem, geo, Li(q), scale * fem.LOAD.S(k) * Si(q), L, depth + 1);
        end
        return
    end
end
for t = {'FORCE', 'MOMENT'}
    if ~isprop(fem, t{1}), continue, end
    b = fem.(t{1});
    V = b.vectors();
    for i = find(b.SID == sid)
        v = geo.vecToBasic(V(:, i), b.CID(i), geo.position(b.G(i)));
        col = [b.G(i); scale * v];
        if strcmp(t{1}, 'FORCE'), L.f(:, end + 1) = col; else, L.m(:, end + 1) = col; end
    end
end
if isprop(fem, 'GRAV')
    b = fem.GRAV;
    V = b.vectors();
    for i = find(b.SID == sid)
        [~, Rr] = geo.frame(b.CID(i));
        L.g = L.g + scale * Rr * V(:, i);
    end
end
end

function M = i_modes(h1, h2, map, geo1, geo2, opts)
m1 = mni.result.hdf5(h1).read_modeshapes();
m2 = mni.result.hdf5(h2).read_modeshapes();
f1 = [m1.cycles]; f2 = [m2.cycles];
e1 = find(f1 > opts.RigidFreq, opts.NumModes);
e2 = find(f2 > opts.RigidFreq, opts.NumModes + 6);
P1 = i_shapes(m1(e1), map(:, 1), geo1);
P2 = i_shapes(m2(e2), map(:, 2), geo2);
MAC = (abs(P1' * P2).^2) ./ (sum(P1.^2, 1)' * sum(P2.^2, 1));
n = numel(e1);
T = table('Size', [n, 6], 'VariableTypes', repmat({'double'}, 1, 6), 'VariableNames', ...
    {'Mode', 'F_orig', 'F_rt', 'ErrPct', 'MAC', 'RtMode'});
for i = 1 : n
    [mac, j] = max(MAC(i, :));
    T(i, :) = {i, f1(e1(i)), f2(e2(j)), 100 * (f2(e2(j)) / f1(e1(i)) - 1), mac, j};
end
M = struct('Table', T, 'MAC', MAC, 'F1', f1, 'F2', f2, 'Rigid', [nnz(f1 <= opts.RigidFreq), ...
    nnz(f2 <= opts.RigidFreq)], 'Grids', size(map, 1));
end

function P = i_shapes(m, ids, geo)
%translations (basic) of grids 'ids' for every mode, 3n x modes
P = zeros(3 * numel(ids), numel(m));
T = i_frames(geo, ids);
for i = 1 : numel(m)
    [tf, k] = ismember(ids, m(i).IDs);
    U = zeros(3, numel(ids));
    U(:, tf) = m(i).EigenVector(k(tf), 1 : 3)';
    for j = find(tf(:)')
        U(:, j) = T(:, :, j) * U(:, j);
    end
    P(:, i) = U(:);
end
end

function T = i_frames(geo, ids)
T = zeros(3, 3, numel(ids));
for j = 1 : numel(ids)
    T(:, :, j) = geo.dispFrame(ids(j));
end
end

function S = i_static(h1, h2, map, geo1, geo2, lc)
d1 = mni.result.hdf5(h1).read_displacements();
d2 = mni.result.hdf5(h2).read_displacements();
T1 = i_frames(geo1, map(:, 1));
T2 = i_frames(geo2, map(:, 2));
n = min([numel(d1), numel(d2), numel(lc)]);
S = table('Size', [n, 7], 'VariableTypes', {'string', 'double', 'double', 'double', 'double', ...
    'double', 'string'}, 'VariableNames', {'Case', 'MaxU_orig', 'MaxU_rt', 'ErrMaxPct', ...
    'RelErrNorm', 'Grid', 'Note'});
for k = 1 : n
    U1 = i_disp(d1(k), map(:, 1), T1);
    U2 = i_disp(d2(k), map(:, 2), T2);
    a1 = vecnorm(U1); a2 = vecnorm(U2);
    [m1, j] = max(a1);
    S(k, :) = {lc(k).Label, m1, a2(j), 100 * (a2(j) / m1 - 1), ...
        norm(U2(:) - U1(:)) / max(norm(U1(:)), eps), map(j, 1), lc(k).Note};
end
end

function U = i_disp(d, ids, T)
[tf, k] = ismember(ids, d.GID);
U = zeros(3, numel(ids));
U(:, tf) = [d.X(k(tf)), d.Y(k(tf)), d.Z(k(tf))]';
for j = find(tf(:)')
    U(:, j) = T(:, :, j) * U(:, j);
end
end

%% ====================================================================== report
function i_report(R)
fid = fopen(R.Report, 'w');
c = onCleanup(@() fclose(fid));
w = @(varargin) fprintf(fid, varargin{:});
w('# Round trip: %s\n\n', R.Name);
w('`%s` -> Matran -> baff -> ADS -> `rt_model.bdf` (generated by `mni.validation.roundTrip`, %s)\n\n', ...
    strrep(R.File, '\', '/'), char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm')));
w('## Analysis information (import)\n\n```\n%s\n```\n\n', strjoin(cellstr(R.Info.Summary), newline));
w('## baff model\n\n');
i_table(w, R.Conversion.Components);
s = R.Conversion.Satellites;
w('\nSatellites: %d masses, %d constraints, %d points. Dropped items: %d.\n\n', s.mass, ...
    s.constraint, s.point, numel(R.Conversion.Dropped));
if ~isempty(R.Conversion.Notes)
    w('Conversion notes:\n\n');
    w('- %s\n', R.Conversion.Notes{:});
    w('\n');
end
w('## Model comparison (original vs round trip)\n\n');
G = R.Compare.Grids;
w('- Grids: %d original, %d round trip; %d matched by position (tol %.3g), %d ambiguous ', ...
    G.N1, G.N2, G.Matched, G.Tol, G.Ambiguous);
w('(coincident grids), %d original grids not found', numel(G.Unmatched));
if ~isempty(G.Unmatched)
    w(' (%s%s)', mat2str(G.Unmatched(1 : min(10, end))), repmat(' ...', 1, numel(G.Unmatched) > 10));
end
w(', %d dropped by the conversion.\n', numel(G.DroppedNotFound));
S = R.Compare.Spc;
w('- SPC: %d original grid entries, %d found constrained (%d of %d DoFs).\n', S.Original, ...
    S.GridsFound, S.DofsFound, S.Dofs);
w('- Concentrated mass (CONM1/CONM2): %.6g original, %.6g round trip.\n', R.Compare.Conm.Original, ...
    R.Compare.Conm.RoundTrip);
w('- Total mass: baff %.6g, ADS %.6g, baff of the round trip model %.6g.\n', R.Mass.Baff, ...
    R.Mass.Ads, R.Mass.Baff2);
A = R.Compare.Aero;
if A.DroppedBoxes > 0
    w('- Aero boxes of the CAERO1 panels not converted to baff (left out below): %d.\n', ...
        A.DroppedBoxes);
end
if A.Boxes(1) > 0 || A.Boxes(2) > 0
    w(['- Aero boxes: %d / %d, area %.6g / %.6g, centroid distance max %.3g mean %.3g, ', ...
        'min |n1.n2| %.4f, W2GJ max difference %.4g deg (max |W2GJ| %.4g deg).\n'], ...
        A.Boxes, A.Area, A.CentroidDist, A.NormalDot, A.W2GJ);
end
Bt = R.Compare.Beams;
if height(Bt) > 0
    e = abs([Bt.ErrEA, Bt.ErrEI1, Bt.ErrEI2, Bt.ErrGJ]);
    w(['- Beam elements: %d matched; max relative error EA %.3g, EI1 %.3g, EI2 %.3g, GJ %.3g; ', ...
        'min y-axis dot product %.6f.\n'], height(Bt), max(e, [], 1), min(Bt.yDot));
    [~, o] = sort(max(e, [], 2) + (1 - Bt.yDot), 'descend');
    bad = o(max(e(o, :), [], 2) > 1e-4 | Bt.yDot(o) < 1 - 1e-6);
    if ~isempty(bad)
        w('\nWorst beam elements:\n\n');
        i_table(w, Bt(bad(1 : min(10, end)), :));
    end
end
w('\nCard counts:\n\n');
i_table(w, R.Compare.Cards);
if ~isempty(R.Nastran)
    w('\n## Nastran\n\n');
    N = R.Nastran;
    if ~isempty(N.Sol103.Gpwg) && numel(N.Sol103.Gpwg) == 2
        g = N.Sol103.Gpwg;
        cg = @(x) [x.CG(2, 1), x.CG(1, 2), x.CG(1, 3)];
        w('### Mass properties (GPWG, basic, about the CG)\n\n');
        w('| | Mass | CG x | CG y | CG z | Ixx | Iyy | Izz | Ixy | Ixz | Iyz |\n|---|---|---|---|---|---|---|---|---|---|---|\n');
        for k = 1 : 2
            x = g(k); c1 = cg(x); I = x.I_S;
            lbl = {'original', 'round trip'};
            w('| %s | %.6g | %.5g | %.5g | %.5g | %.5g | %.5g | %.5g | %.4g | %.4g | %.4g |\n', lbl{k}, ...
                x.Mass(1), c1, I(1, 1), I(2, 2), I(3, 3), I(1, 2), I(1, 3), I(2, 3));
        end
        w('\n');
    end
    if ~isempty(N.Sol103.Modes)
        M = N.Sol103.Modes;
        w('### SOL 103 (%d matched grids, rigid modes %d / %d)\n\n', M.Grids, M.Rigid);
        i_table(w, M.Table);
        w('\n');
    end
    if ~isempty(N.Sol101) && ~isempty(N.Sol101.Static)
        w('### SOL 101 (translations at the matched grids, basic)\n\n');
        i_table(w, N.Sol101.Static);
        w('\n');
    end
end
if ~isempty(R.Notes)
    w('## Harness notes\n\n');
    w('- %s\n', R.Notes{:});
end
end

function i_table(w, T)
v = T.Properties.VariableNames;
w('| %s |\n', strjoin(v, ' | '));
w('|%s\n', repmat('---|', 1, numel(v)));
for i = 1 : height(T)
    cells = cell(1, numel(v));
    for j = 1 : numel(v)
        x = T{i, j};
        if iscell(x), x = x{1}; end
        if isnumeric(x)
            if isscalar(x) && x == round(x) && abs(x) < 1e9
                cells{j} = sprintf('%d', x);
            else
                cells{j} = sprintf('%.5g', x);
            end
        else
            cells{j} = char(x);
        end
    end
    w('| %s |\n', strjoin(cells, ' | '));
end
end

function i_log(verbose, varargin)
if verbose
    fprintf([varargin{1}, '\n'], varargin{2 : end});
end
end
