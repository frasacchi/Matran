function cc = parseCaseControl(lines)
%parseCaseControl Parses the Case Control Section (QRG ch.5).
%
% Syntax:
%   >> cc = mni.io.parseCaseControl({'SPC = 1', 'SUBCASE 1', 'LOAD = 2'})
%
% Output 'cc' (struct):
%   Global   - commands above the first subcase (struct array, see below)
%   Subcases - struct array: ID, Type ('SUBCASE', 'SUBCOM', 'SYM', ...),
%              Commands (given in the subcase) and Effective (global
%              commands overridden by the subcase ones). Without SUBCASE
%              commands there is one subcase (ID 1) holding the globals.
%   Sets     - struct array: ID, Values (numbers; 'ALL' -> Inf), Raw
%   Output   - struct array of OUTPUT(...) blocks: Type, Lines
%   Params   - PARAM commands: Name, Values
%
% Command struct: Name (as written), Command (full QRG name, the first
% four characters are enough), Describers (cellstr, e.g. {'SORT1','REAL'}),
% Value (text), Number (value as a number, NaN otherwise), Raw.
%
% Rules: '$' comments are removed beforehand; a line ending with ',' is
% continued on the next line; TITLE / SUBTITLE / LABEL keep their text.

if nargin < 1
    lines = {};
end
cmdNames = mni.analysis.caseCommands();
blank = struct('Name', {}, 'Command', {}, 'Describers', {}, 'Value', {}, ...
    'Number', {}, 'Raw', {});
cc.Global   = blank;
cc.Subcases = struct('ID', {}, 'Type', {}, 'Commands', {}, 'Effective', {});
cc.Sets     = struct('ID', {}, 'Values', {}, 'Raw', {});
cc.Output   = struct('Type', {}, 'Lines', {});
cc.Params   = struct('Name', {}, 'Values', {});

%join continuation lines (trailing comma)
L = {};
for i = 1 : numel(lines)
    t = strtrim(lines{i});
    if isempty(t)
        continue
    end
    if ~isempty(L) && endsWith(L{end}, ',')
        L{end} = [L{end}, ' ', t];
    else
        L{end + 1} = t; %#ok<AGROW>
    end
end

current = 0;   %0 = global, else index into cc.Subcases
outBlock = 0;
for i = 1 : numel(L)
    raw = L{i};
    up  = upper(raw);
    %subcase delimiters
    tok = regexp(up, '^(SUBCASE|SUBCOM|SYMCOM|SYMSEQ|SYM|REPCASE)\s*=?\s*(\d+)', 'tokens', 'once');
    if ~isempty(tok)
        cc.Subcases(end + 1) = struct('ID', str2double(tok{2}), 'Type', tok{1}, ...
            'Commands', blank, 'Effective', blank);
        current = numel(cc.Subcases);
        outBlock = 0;
        continue
    end
    if ~isempty(regexp(up, '^BEGIN\s+BULK', 'once'))
        break
    end
    tok = regexp(up, '^OUTPUT\s*\(\s*([A-Z0-9]+)\s*\)', 'tokens', 'once');
    if ~isempty(tok)
        cc.Output(end + 1) = struct('Type', tok{1}, 'Lines', {{}});
        outBlock = numel(cc.Output);
        continue
    end
    if outBlock > 0 && isempty(regexp(up, '^(SET\s+\d+|SUBCASE|SUBCOM)', 'once'))
        cc.Output(outBlock).Lines{end + 1} = raw;   %plotter commands
        continue
    end
    %SET n = list
    tok = regexp(up, '^SET\s+(\d+)\s*=\s*(.*)$', 'tokens', 'once');
    if ~isempty(tok)
        cc.Sets(end + 1) = struct('ID', str2double(tok{1}), ...
            'Values', i_setValues(tok{2}), 'Raw', raw);
        continue
    end
    %PARAM,NAME,V1[,V2]
    if ~isempty(regexp(up, '^PARAM\s*,', 'once'))
        p = strtrim(strsplit(up, ','));
        p(end + 1 : 3) = {''};
        cc.Params(end + 1) = struct('Name', p{2}, 'Values', {p(3 : end)});
        continue
    end
    c = i_command(raw, cmdNames);
    if isempty(c)
        continue
    end
    if current == 0
        cc.Global(end + 1) = c;
    else
        cc.Subcases(current).Commands(end + 1) = c;
    end
end

if isempty(cc.Subcases)
    cc.Subcases = struct('ID', 1, 'Type', 'SUBCASE', 'Commands', blank, 'Effective', blank);
end
for s = 1 : numel(cc.Subcases)
    eff = cc.Global;
    for c = cc.Subcases(s).Commands
        k = find(strcmp({eff.Command}, c.Command), 1);
        if isempty(k)
            eff(end + 1) = c; %#ok<AGROW>
        else
            eff(k) = c;
        end
    end
    cc.Subcases(s).Effective = eff;
end
end

function c = i_command(raw, cmdNames)
%i_command NAME[(describers)] [= value]
c = [];
tok = regexp(raw, '^\s*(?<name>[A-Za-z][A-Za-z0-9_]*)\s*(?<par>\([^)]*\))?\s*(?<val>=.*)?$', ...
    'names', 'once');
if isempty(tok)
    return
end
name = upper(tok.name);
full = i_expand(name, cmdNames);
val  = strtrim(regexprep(tok.val, '^=\s*', ''));
if ~any(strcmp(full, {'TITLE', 'SUBTITLE', 'LABEL'}))
    val = upper(val);                %TITLE / SUBTITLE / LABEL keep their text
end
desc = strtrim(strsplit(upper(regexprep(tok.par, '[()]', '')), ','));
desc = desc(~cellfun(@isempty, desc));
c = struct('Name', name, 'Command', full, 'Describers', {desc}, ...
    'Value', val, 'Number', str2double(val), 'Raw', raw);
end

function full = i_expand(name, cmdNames)
%i_expand Full QRG command name (abbreviations of 4+ characters).
full = name;
if any(strcmp(cmdNames, name)) || numel(name) < 4
    return
end
k = find(startsWith(cmdNames, name));
if numel(k) == 1
    full = cmdNames{k};
elseif numel(k) > 1
    [~, j] = min(cellfun(@numel, cmdNames(k)));
    full = cmdNames{k(j)};
end
end

function v = i_setValues(str)
%i_setValues Numbers of a SET definition (THRU, EXCEPT, BY, ALL).
str = strtrim(regexprep(upper(str), ',\s*$', ''));
if strcmp(str, 'ALL')
    v = Inf;
    return
end
tok = strtrim(strsplit(str, {',', ' '}));
tok = tok(~cellfun(@isempty, tok));
v = [];
except = false;
i = 0;
while i < numel(tok)
    i = i + 1;
    t = tok{i};
    if strcmp(t, 'EXCEPT')
        except = true;
        continue
    end
    if i + 2 <= numel(tok) && strcmp(tok{i + 1}, 'THRU')
        a = str2double(t); b = str2double(tok{i + 2});
        step = 1;
        i = i + 2;
        if i + 2 <= numel(tok) && strcmp(tok{i + 1}, 'BY')
            step = str2double(tok{i + 2});
            i = i + 2;
        end
        r = a : step : b;
    else
        r = str2double(t);
    end
    if except
        v = setdiff(v, r, 'stable');
    else
        v = [v, r]; %#ok<AGROW>
    end
end
end
