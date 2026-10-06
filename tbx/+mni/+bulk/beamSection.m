function s = beamSection(type, dim)
%beamSection Section properties of the PBARL / PBEAML cross-section types.
%
% Syntax:
%   >> s = mni.bulk.beamSection('BAR', [0.03, 0.005])
%
% Output 's' (struct): A, I1, I2, I12, J, plus 'Exact' (false where the
% torsion constant is a thin-walled / Saint-Venant approximation).
%
% Axes of the QRG PBARL / PBEAML figures: the horizontal axis is z_elem, the
% vertical axis is y_elem (BAR: DIM1 along z_elem, DIM2 along y_elem). I1 is
% the moment of area for bending in plane 1 (= int y^2 dA), I2 for plane 2
% (= int z^2 dA), I12 = int y z dA, all about the centroid. Checked against
% MSC Nastran 2023.2 (cantilever CBEAM, PBEAML vs the equivalent PBEAM):
% mass and bending rotations equal for every type. J differs from
% Nastran's by < 2.5% for ROD, TUBE, TUBE2, BAR, L, T, I, CHAN, by about
% 6% for BOX, 8% for CROSS and 23% for H (thick-walled approximations).
%
% Supported TYPE (DIMi as in the QRG figures): ROD, TUBE, TUBE2, BAR, BOX,
% I, T, L, CHAN, H, CROSS. Built-up sections are summed from rectangles.
%
% Nastran computes the PBARL / PBEAML equivalent PBAR / PBEAM itself (QRG
% PBARL remark 7, PBEAML); small differences in J (and in the shear /
% warping terms, which are not returned) are expected for open sections.

dim = reshape(double(dim), 1, []);
type = upper(strtrim(type));
s = struct('A', NaN, 'I1', NaN, 'I2', NaN, 'I12', 0, 'J', NaN, 'Exact', true);
switch type
    case 'ROD'
        r = dim(1);
        s.A = pi * r^2;  s.I1 = pi * r^4 / 4;  s.I2 = s.I1;  s.J = pi * r^4 / 2;
    case {'TUBE', 'TUBE2'}
        ro = dim(1);
        if strcmp(type, 'TUBE')
            ri = dim(2);
        else
            ri = dim(1) - dim(2); %TUBE2: DIM2 = wall thickness
        end
        s.A = pi * (ro^2 - ri^2);  s.I1 = pi * (ro^4 - ri^4) / 4;  s.I2 = s.I1;
        s.J = pi * (ro^4 - ri^4) / 2;
    case 'BAR'
        b = dim(1);  h = dim(2);  %b along z_elem, h along y_elem
        s.A  = b * h;
        s.I1 = b * h^3 / 12;
        s.I2 = h * b^3 / 12;
        s.J  = i_rectJ(b, h);
    case 'BOX'
        %DIM3: horizontal (top / bottom) walls, DIM4: vertical walls
        b = dim(1); h = dim(2); th = dim(3); tv = dim(4);
        s.A  = b * h - (b - 2 * tv) * (h - 2 * th);
        s.I1 = (b * h^3 - (b - 2 * tv) * (h - 2 * th)^3) / 12;
        s.I2 = (h * b^3 - (h - 2 * th) * (b - 2 * tv)^3) / 12;
        s.J  = 2 * tv * th * (b - tv)^2 * (h - th)^2 / (tv * (b - tv) + th * (h - th));
        s.Exact = false;
    otherwise
        R = i_rectangles(type, dim); %[z0 z1 y0 y1] rows (figure: horizontal, vertical)
        s = i_built(R);
end
end

function J = i_rectJ(a, b)
%Saint-Venant torsion constant of a solid rectangle (series approximation)
L = max(a, b);  t = min(a, b);
J = L * t^3 * (1/3 - 0.21 * (t / L) * (1 - t^4 / (12 * L^4)));
end

function R = i_rectangles(type, d)
switch type
    case 'I'   %DIM1 height, DIM2 bottom flange, DIM3 top flange, DIM4 web, DIM5 bottom, DIM6 top thickness
        h = d(1); bb = d(2); bt = d(3); tw = d(4); tb = d(5); tt = d(6);
        R = [-bb/2, bb/2, 0, tb; -tw/2, tw/2, tb, h - tt; -bt/2, bt/2, h - tt, h];
    case 'T'   %DIM1 flange width, DIM2 height, DIM3 flange thickness, DIM4 web thickness
        b = d(1); h = d(2); tf = d(3); tw = d(4);
        R = [-b/2, b/2, h - tf, h; -tw/2, tw/2, 0, h - tf];
    case 'L'   %DIM1 width, DIM2 height, DIM3 horizontal leg thickness, DIM4 vertical leg thickness
        b = d(1); h = d(2); t1 = d(3); t2 = d(4);
        R = [0, b, 0, t1; 0, t2, t1, h];
    case 'CHAN' %DIM1 width, DIM2 height, DIM3 web thickness, DIM4 flange thickness
        b = d(1); h = d(2); tw = d(3); tf = d(4);
        R = [0, tw, 0, h; tw, b, 0, tf; tw, b, h - tf, h];
    case 'H'   %DIM1 web gap, DIM2 sum of the two flange widths, DIM3 height, DIM4 web thickness
        a = d(1); b = d(2) / 2; h = d(3); tw = d(4);
        R = [-a/2 - b, -a/2, -h/2, h/2; a/2, a/2 + b, -h/2, h/2; -a/2, a/2, -tw/2, tw/2];
    case 'CROSS' %DIM1 sum of the two arm lengths, DIM2 web thickness, DIM3 height, DIM4 arm thickness
        b = d(1) / 2; tw = d(2); h = d(3); ta = d(4);
        R = [-tw/2, tw/2, -h/2, h/2; -tw/2 - b, -tw/2, -ta/2, ta/2; tw/2, tw/2 + b, -ta/2, ta/2];
    otherwise
        error('mni:bulk:beamSection', 'Cross-section type ''%s'' is not supported.', type);
end
end

function s = i_built(R)
%R rows [z0 z1 y0 y1]: b along z_elem, h along y_elem
z0 = R(:, 1); z1 = R(:, 2); y0 = R(:, 3); y1 = R(:, 4);
b = z1 - z0;  h = y1 - y0;  a = b .* h;
zc = (z0 + z1) / 2;  yc = (y0 + y1) / 2;
A  = sum(a);
Z  = sum(a .* zc) / A;  Y = sum(a .* yc) / A;
I1 = sum(b .* h.^3 / 12 + a .* (yc - Y).^2);   %int y^2 dA
I2 = sum(h .* b.^3 / 12 + a .* (zc - Z).^2);   %int z^2 dA
I12 = sum(a .* (yc - Y) .* (zc - Z));
J = sum(max(b, h) .* min(b, h).^3 / 3);   %open thin-walled approximation
s = struct('A', A, 'I1', I1, 'I2', I2, 'I12', I12, 'J', J, 'Exact', false);
end
