function v = fieldValue(c, d)
%fieldValue Numeric value of bulk data field text (char or cellstr), with
%the default 'd' (scalar, or one per field) where a field is blank.
%
% Syntax:
%   >> v = fieldValue('1.5', 0)          % 1.5
%   >> v = fieldValue({'', '2.'}, 7)     % [7, 2]

if ischar(c) || isstring(c)
    c = cellstr(c);
end
v = str2double(c);
blank = cellfun(@(x) isempty(strtrim(x)), c);
if isscalar(d)
    v(blank) = d;
else
    v(blank) = d(blank);
end
end
