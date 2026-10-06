function v = nasNum(str)
%nasNum Converts a Nastran field string to a number (NaN if not numeric).
%
% Independent of the Matran reader so it can be used to check it. Handles
% the Nastran real formats of QRG ch.9 "Real, Integer, and Character Input
% Data": 7.0, .7E1, 0.7+1, .70+1, 7.E+0, 70.-1, 1.0D2.
%
% Syntax:
%   >> nasNum('6.5-6')   % 6.5e-6
%   >> nasNum('3.+7')    % 3e7

if iscell(str)
    v = cellfun(@nasNum, str);
    return
end
s = strtrim(str);
v = NaN;
if isempty(s)
    return
end
tok = regexp(s, '^(?<m>[+-]?(?:\d+\.?\d*|\.\d+))(?<e>[EeDd]?)(?<x>(?:[+-]?\d+)?)$', 'names', 'once');
if isempty(tok)
    return
end
if isempty(tok.x)
    if isempty(tok.e)
        v = str2double(tok.m);
    end
elseif isempty(tok.e) && ~any(tok.x(1) == '+-')
    v = NaN; %digits after the mantissa without sign or E: not a number
else
    v = str2double([tok.m, 'E', tok.x]);
end
end
