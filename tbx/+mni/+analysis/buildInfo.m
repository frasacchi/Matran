function info = buildInfo(deck, fem)
%buildInfo Describes what an imported Nastran deck contains and which
%solution it runs: SOL, subcases, the bulk data each Case Control
%selection points to, parameters, and every bulk data entry type read.
%
% Syntax:
%   >> deck = mni.io.readDeck('sol101.bdf');
%   >> [fem, meta] = ...;          %see mni.import_matran
%   >> info = mni.analysis.buildInfo(deck, fem);
%   >> disp(info.Summary)
%
% Output 'info' (struct):
%   File, Files, Includes   - root file, all files read, INCLUDE statements
%   Sol                     - SOL statement (Number, Name, Description)
%   Exec, Nastran, FMS      - Executive Control / NASTRAN / FMS statements
%   CaseControl             - parsed Case Control (mni.io.parseCaseControl)
%   Subcases                - struct array: ID, Type, Title, Label,
%                             Selections (Command, ID, Cards, Found),
%                             Outputs (output requests), Commands
%   Params                  - PARAM / MDLPRM: Name, Values, Source
%   Cards                   - table of every bulk data entry type read:
%                             Card, Count, Category (mni.analysis.cardCategory),
%                             Class, Typed (false = stored as GenericCard)
%   SolutionCards           - entry types with Category 'solution'
%   Summary                 - text summary

info.File     = deck.File;
info.Files    = {deck.Files.File};
info.Includes = deck.Includes;
ec = mni.io.parseExecControl(deck.Exec);
info.Sol      = ec.Sol;
info.Exec     = ec.Statements;
info.Nastran  = deck.Nastran;
info.FMS      = deck.FMS;
cc = mni.io.parseCaseControl(deck.Case);
info.CaseControl = cc;
info.Warnings = deck.Warnings;

%Parameters (bulk PARAM / MDLPRM and Case Control PARAM)
P = struct('Name', {}, 'Values', {}, 'Source', {});
for b = deck.Bulk(strcmp({deck.Bulk.Name}, 'PARAM'))
    f = b.Fields;
    f(end + 1 : 3) = {''};
    v = f(2 : 3);
    v = v(~cellfun(@isempty, v));
    P(end + 1) = struct('Name', f{1}, 'Values', {v}, 'Source', 'bulk'); %#ok<AGROW>
end
for b = deck.Bulk(strcmp({deck.Bulk.Name}, 'MDLPRM'))
    f = b.Fields(~cellfun(@isempty, b.Fields));
    for k = 1 : 2 : numel(f) - 1
        P(end + 1) = struct('Name', f{k}, 'Values', {f(k + 1)}, 'Source', 'MDLPRM'); %#ok<AGROW>
    end
end
for p = cc.Params
    v = p.Values(~cellfun(@isempty, p.Values));
    P(end + 1) = struct('Name', p.Name, 'Values', {v}, 'Source', 'case'); %#ok<AGROW>
end
info.Params = P;

%Bulk data entry types
names = {deck.Bulk.Name};
[u, ~, j] = unique(names);
cnt = accumarray(j(:), 1);
cls = cell(numel(u), 1);
typed = false(numel(u), 1);
for k = 1 : numel(u)
    cls{k} = '';
    if ~isempty(fem) && isprop(fem, u{k})
        cls{k} = class(fem.(u{k}));
        typed(k) = ~isa(fem.(u{k}), 'mni.bulk.GenericCard');
    elseif any(strcmp(u{k}, {'PARAM', 'MDLPRM'}))
        cls{k} = 'Info.Params';
        typed(k) = true;
    end
end
cat = cellfun(@mni.analysis.cardCategory, u(:), 'UniformOutput', false);
info.Cards = table(u(:), cnt(:), cat, cls, typed, ...
    'VariableNames', {'Card', 'Count', 'Category', 'Class', 'Typed'});
info.SolutionCards = info.Cards(strcmp(info.Cards.Category, 'solution'), :);

%Subcases and the bulk data their selections point to
selMap = i_selectionMap();
S = struct('ID', {}, 'Type', {}, 'Title', {}, 'Label', {}, ...
    'Selections', {}, 'Outputs', {}, 'Commands', {});
for s = cc.Subcases
    sel = struct('Command', {}, 'ID', {}, 'Cards', {}, 'Found', {});
    out = {};
    for c = s.Effective
        k = find(strcmp(selMap(:, 1), c.Command), 1);
        if ~isempty(k) && ~isnan(c.Number)
            [cards, found] = i_resolve(fem, selMap{k, 2}, c.Number);
            sel(end + 1) = struct('Command', c.Command, 'ID', c.Number, ...
                'Cards', {cards}, 'Found', found); %#ok<AGROW>
        elseif i_isOutput(c.Command)
            out{end + 1} = c.Raw; %#ok<AGROW>
        end
    end
    S(end + 1) = struct('ID', s.ID, 'Type', s.Type, ...
        'Title', i_text(s.Effective, 'TITLE'), 'Label', i_text(s.Effective, 'LABEL'), ...
        'Selections', sel, 'Outputs', {out}, 'Commands', s.Effective); %#ok<AGROW>
end
info.Subcases = S;
info.Summary  = i_summary(info);
end

function t = i_text(cmds, name)
t = '';
k = find(strcmp({cmds.Command}, name), 1);
if ~isempty(k)
    t = cmds(k).Value;
end
end

function tf = i_isOutput(cmd)
tf = any(strcmp(cmd, {'DISPLACEMENT', 'VECTOR', 'FORCE', 'STRESS', 'STRAIN', ...
    'SPCFORCES', 'MPCFORCES', 'OLOAD', 'AEROF', 'APRESSURE', 'ESE', 'EKE', 'EDE', ...
    'GPKE', 'GPFORCE', 'GPSTRESS', 'MEFFMASS', 'VELOCITY', 'ACCELERATION', ...
    'MONITOR', 'TRIMF', 'ELSUM', 'GROUNDCHECK', 'WEIGHTCHECK', 'SVECTOR', ...
    'SDISPLACEMENT', 'NLSTRESS', 'ECHO'}));
end

function m = i_selectionMap()
m = { ...
    'SPC'        , {'SPC', 'SPC1', 'SPCADD', 'GMSPC'}; ...
    'MPC'        , {'MPC', 'MPCADD'}; ...
    'LOAD'       , {'LOAD', 'FORCE', 'FORCE1', 'FORCE2', 'MOMENT', 'MOMENT1', 'MOMENT2', ...
                    'GRAV', 'PLOAD', 'PLOAD1', 'PLOAD2', 'PLOAD4', 'RFORCE', 'ACCEL', ...
                    'ACCEL1', 'SPCD', 'SLOAD'}; ...
    'METHOD'     , {'EIGR', 'EIGRL', 'EIGB'}; ...
    'CMETHOD'    , {'EIGC'}; ...
    'FMETHOD'    , {'FLUTTER'}; ...
    'TRIM'       , {'TRIM', 'TRIM2'}; ...
    'DIVERG'     , {'DIVERG'}; ...
    'GUST'       , {'GUST', 'GUST2'}; ...
    'DLOAD'      , {'DLOAD', 'TLOAD1', 'TLOAD2', 'RLOAD1', 'RLOAD2', 'ACSRCE'}; ...
    'FREQUENCY'  , {'FREQ', 'FREQ1', 'FREQ2', 'FREQ3', 'FREQ4', 'FREQ5'}; ...
    'TSTEP'      , {'TSTEP'}; ...
    'TSTEPNL'    , {'TSTEPNL'}; ...
    'SDAMPING'   , {'TABDMP1'}; ...
    'RANDOM'     , {'RANDPS', 'RANDT1'}; ...
    'NLPARM'     , {'NLPARM'}; ...
    'SUPORT1'    , {'SUPORT1'}; ...
    'TEMPERATURE', {'TEMP', 'TEMPD'}; ...
    'DEFORM'     , {'DEFORM'}};
end

function [cards, found] = i_resolve(fem, candidates, id)
%i_resolve Entries with set identification 'id' (and, for SPCADD /
%MPCADD / LOAD / DLOAD, the sets they combine).
cards = struct('Card', {}, 'ID', {}, 'Count', {});
found = false;
if isempty(fem)
    return
end
todo = id;
done = [];
while ~isempty(todo)
    sid  = todo(1);
    todo(1) = [];
    if any(done == sid)
        continue
    end
    done(end + 1) = sid; %#ok<AGROW>
    for k = 1 : numel(candidates)
        c = candidates{k};
        if ~isprop(fem, c)
            continue
        end
        ids = mni.analysis.entryIds(fem.(c));
        idx = find(ids == sid);
        if isempty(idx)
            continue
        end
        found = true;
        cards(end + 1) = struct('Card', c, 'ID', sid, 'Count', numel(idx)); %#ok<AGROW>
        %combination entries: follow the referenced sets
        sub = mni.analysis.combinedSets(fem.(c), idx);
        todo = [todo, sub(:)']; %#ok<AGROW>
    end
end
end

function s = i_summary(info)
lines = {};
if isempty(info.Sol.Number)
    lines{end + 1} = 'No SOL statement (bulk data only).';
else
    lines{end + 1} = sprintf('SOL %d (%s): %s', info.Sol.Number, info.Sol.Name, info.Sol.Description);
end
for s = info.Subcases
    parts = arrayfun(@(x) sprintf('%s=%g%s', x.Command, x.ID, ...
        i_found(x)), s.Selections, 'UniformOutput', false);
    lines{end + 1} = sprintf('  %s %d: %s', s.Type, s.ID, strjoin(parts, ', ')); %#ok<AGROW>
end
if ~isempty(info.Params)
    lines{end + 1} = ['  Parameters: ', strjoin(arrayfun(@(p) sprintf('%s=%s', p.Name, ...
        strjoin(p.Values, ',')), info.Params, 'UniformOutput', false), ', ')];
end
if height(info.SolutionCards) > 0
    lines{end + 1} = ['  Solution entries: ', strjoin(strcat(info.SolutionCards.Card, ...
        '(', cellfun(@num2str, num2cell(info.SolutionCards.Count), 'UniformOutput', false), ')'), ', ')];
end
s = strjoin(lines, newline);

    function t = i_found(x)
        if ~x.Found
            t = ' [not found]';
            return
        end
        %one item per entry type: "SPC1 x28" or "GRAV 74"
        [u, ~, j] = unique({x.Cards.Card}, 'stable');
        items = cell(1, numel(u));
        for q = 1 : numel(u)
            c = x.Cards(j == q);
            n = sum([c.Count]);
            if numel(c) == 1 && n == 1
                items{q} = sprintf('%s %g', u{q}, c.ID);
            else
                items{q} = sprintf('%s x%d', u{q}, n);
            end
        end
        t = [' -> ', strjoin(items, ', ')];
    end
end
