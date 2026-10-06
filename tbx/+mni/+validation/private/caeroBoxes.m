function B = caeroBoxes(fem, geo)
%caeroBoxes Aerodynamic boxes of every CAERO1 entry in the basic system.
%
% Output 'B' (struct): ID (1 x n box identifiers), Panel (CAERO1 EID of
% each box), Centroid (3 x n), Area (1 x n), Normal (3 x n),
% Corners (3 x 4 x n; 1-2 inboard edge LE->TE, 4-3 outboard edge).

B = struct('ID', zeros(1, 0), 'Panel', zeros(1, 0), 'Centroid', zeros(3, 0), ...
    'Area', zeros(1, 0), 'Normal', zeros(3, 0), 'Corners', zeros(3, 4, 0));
if ~isprop(fem, 'CAERO1')
    return
end
acsid = 0;
if isprop(fem, 'AEROS'), acsid = fem.AEROS.ACSID(1);
elseif isprop(fem, 'AERO'), acsid = fem.AERO.ACSID(1);
end
[~, R] = geo.frame(acsid);
ax = R(:, 1);
fact = containers.Map('KeyType', 'double', 'ValueType', 'any');
if isprop(fem, 'AEFACT')
    f = fem.AEFACT;
    for i = 1 : f.NumBulk, fact(f.SID(i)) = f.Di{i}; end
end
c = fem.CAERO1;
for i = 1 : c.NumBulk
    p1 = geo.toBasic(c.X1(:, i), c.CP(i));
    p4 = geo.toBasic(c.X4(:, i), c.CP(i));
    p2 = p1 + c.X12(i) * ax;
    p3 = p4 + c.X43(i) * ax;
    es = linspace(0, 1, c.NSPAN(i) + 1);
    ec = linspace(0, 1, c.NCHORD(i) + 1);
    if c.LSPAN(i) > 0 && isKey(fact, c.LSPAN(i)), es = fact(c.LSPAN(i)); end
    if c.LCHORD(i) > 0 && isKey(fact, c.LCHORD(i)), ec = fact(c.LCHORD(i)); end
    id = c.EID(i);
    for j = 1 : numel(es) - 1
        le = p1 + (p4 - p1) * es([j, j + 1]);
        te = p2 + (p3 - p2) * es([j, j + 1]);
        for k = 1 : numel(ec) - 1
            a = le + (te - le) * ec(k);
            b = le + (te - le) * ec(k + 1);
            X = [a(:, 1), b(:, 1), b(:, 2), a(:, 2)];
            n = cross(X(:, 3) - X(:, 1), X(:, 4) - X(:, 2)) / 2;
            B.ID(end + 1) = id;
            B.Panel(end + 1) = c.EID(i);
            B.Centroid(:, end + 1) = mean(X, 2);
            B.Area(end + 1) = norm(n);
            B.Normal(:, end + 1) = n / max(norm(n), eps);
            B.Corners(:, :, end + 1) = X;
            id = id + 1;
        end
    end
end
end
