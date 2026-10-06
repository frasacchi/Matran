function ec = parseExecControl(lines)
%parseExecControl Parses Executive Control statements (QRG ch.4).
%
% Syntax:
%   >> ec = mni.io.parseExecControl({'SOL 101', 'TIME 600', 'CEND'})
%
% Output 'ec' (struct):
%   Sol        - struct (Number, Name, Description, Raw); empty Number if
%                there is no SOL statement
%   Statements - struct array (Keyword, Value, Raw), one per statement
%   Alters     - DMAP blocks (ALTER/MALTER/COMPILE ... ENDALTER) as text

if nargin < 1
    lines = {};
end
ec.Sol = struct('Number', [], 'Name', '', 'Description', '', 'Raw', '');
ec.Statements = struct('Keyword', {}, 'Value', {}, 'Raw', {});
ec.Alters = {};

inAlter = false;
for i = 1 : numel(lines)
    raw = strtrim(lines{i});
    if isempty(raw)
        continue
    end
    up  = upper(raw);
    kw  = regexp(up, '^[A-Z_]+', 'match', 'once');
    val = strtrim(raw(numel(kw) + 1 : end));
    val = regexprep(val, '^=\s*', '');
    if inAlter
        ec.Alters{end}{end + 1} = raw;
        if strcmp(kw, 'ENDALTER')
            inAlter = false;
        end
        continue
    end
    if any(strcmp(kw, {'ALTER', 'MALTER', 'COMPILE'}))
        inAlter = true;
        ec.Alters{end + 1} = {raw};
    end
    ec.Statements(end + 1) = struct('Keyword', kw, 'Value', val, 'Raw', raw);
    if strcmp(kw, 'SOL')
        ec.Sol = i_sol(val, raw);
    end
end
end

function s = i_sol(val, raw)
s = struct('Number', [], 'Name', '', 'Description', '', 'Raw', raw);
tok = upper(strtrim(strtok(val, ', ')));
t = mni.analysis.solTable();
num = str2double(tok);
if ~isnan(num)
    idx = [t.Number] == num;
    s.Number = num;
else
    idx = strcmp({t.Name}, tok);
    s.Name = tok;
end
if any(idx)
    k = find(idx, 1);
    s.Number = t(k).Number;
    s.Name = t(k).Name;
    s.Description = t(k).Description;
end
end
