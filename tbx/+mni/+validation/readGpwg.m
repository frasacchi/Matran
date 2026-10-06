function g = readGpwg(f06)
%readGpwg Reads the first Grid Point Weight Generator table of an .f06
%file (PARAM,GRDPNT).
%
% Output 'g' (struct, empty if no table): Mass (x, y, z directions),
% CG (3 x 3, row = direction, columns = x, y, z of the mass axis system),
% I_S (3 x 3, inertia about the CG in the S axes), I_Q (principal
% inertias), Q (principal directions), S (mass axis system).

g = struct([]);
txt = fileread(f06);
k = strfind(txt, 'O U T P U T   F R O M   G R I D   P O I N T   W E I G H T');
if isempty(k)
    return
end
t = txt(k(1) : min(end, k(1) + 6000));
num = '([-+]?\d*\.?\d+(?:[EeDd][-+]?\d+)?)';
s = strfind(t, 'MASS AXIS SYSTEM (S)');
if isempty(s), return, end
u = t(s(1) : end);
rows = regexp(u, ['\n\s*([XYZ])\s+', num, '\s+', num, '\s+', num, '\s+', num], 'tokens');
if numel(rows) < 3, return, end
g = struct('Mass', zeros(1, 3), 'CG', zeros(3), 'I_S', nan(3), 'I_Q', nan(3, 1), ...
    'Q', nan(3), 'S', nan(3));
for i = 1 : 3
    v = str2double(rows{i}(2 : 5));
    g.Mass(i) = v(1);
    g.CG(i, :) = v(2 : 4);
end
r = i_block(u, 'I(S)');
if numel(r) == 9, g.I_S = reshape(r, 3, 3)'; end
r = i_block(u, 'I(Q)');
if numel(r) == 3, g.I_Q = r(:); end
r = i_block(u, 'Q');
if numel(r) == 9, g.Q = reshape(r, 3, 3)'; end
r = i_block(t(1 : s(1)), 'S');
if numel(r) == 9, g.S = reshape(r, 3, 3)'; end
end

function v = i_block(t, label)
%numbers of the 3 rows "* ... *" following the line holding 'label'
v = [];
k = regexp(t, ['\n\s*', regexptranslate('escape', label), '\s*\n'], 'end', 'once');
if isempty(k), return, end
rows = regexp(t(k + 1 : end), '[^\n]*', 'match');
for i = 1 : min(3, numel(rows))
    b = regexp(rows{i}, '\*(.*)\*', 'tokens', 'once');
    if isempty(b), v = []; return, end
    v = [v, sscanf(strrep(upper(b{1}), 'D', 'E'), '%f')']; %#ok<AGROW>
end
end
