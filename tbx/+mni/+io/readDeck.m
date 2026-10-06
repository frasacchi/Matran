function deck = readDeck(filename, opts)
%readDeck Reads a Nastran input file, expands INCLUDE statements and
%splits the input into its sections (QRG ch.1-5, 9).
%
% Syntax:
%   >> deck = mni.io.readDeck('model.bdf');
%   >> deck = mni.io.readDeck('sol101.bdf', 'ExpandInclude', false);
%
% Output 'deck' (struct):
%   File      - full path of the root file
%   Files     - struct array (File, Parent, Depth) of every file read
%   Nastran   - NASTRAN statements                  (cellstr)
%   FMS       - File Management statements          (cellstr)
%   Exec      - Executive Control statements        (cellstr)
%   Case      - Case Control lines                  (cellstr)
%   Bulk      - struct array of bulk data entries, see mni.io.tokenizeBulk
%   BulkLines - raw bulk data lines of the root file (INCLUDEs unexpanded)
%   Includes  - struct array (File, Section, Parent) of INCLUDE statements
%   HasExec / HasCase / HasBulk - section markers found (CEND, BEGIN BULK)
%   Warnings  - cellstr
%
% Rules:
%   - '$' starts a comment; tabs advance to the next multiple of 8.
%   - CEND ends the Executive Control, BEGIN BULK (or BEGIN SUPER/...)
%     starts the Bulk Data, ENDDATA ends the input. A file without CEND
%     and BEGIN BULK is read as Bulk Data.
%   - INCLUDE 'file' may span several lines (QRG INCLUDE remark 2).
%     Relative paths are resolved against the folder of the including
%     file, then the current folder. A missing absolute path is retried
%     with its trailing folders below the including file's folder (decks
%     moved to another location, e.g. Examples/bwb).

arguments
    filename {mustBeTextScalar}
    opts.ExpandInclude (1, 1) logical = true
    opts.LogFcn = []
end
filename = char(filename);
if isempty(opts.LogFcn)
    logfcn = @(varargin) [];
else
    logfcn = opts.LogFcn;
end
filename = i_fullpath(filename);
assert(isfile(filename), 'mni:io:readDeck:missing', ...
    'File ''%s'' does not exist.', filename);

deck = struct('File', filename, ...
    'Files', struct('File', filename, 'Parent', '', 'Depth', 0), ...
    'Nastran', {{}}, 'FMS', {{}}, 'Exec', {{}}, 'Case', {{}}, ...
    'Bulk', [], 'BulkLines', {{}}, ...
    'Includes', struct('File', {}, 'Section', {}, 'Parent', {}), ...
    'HasExec', false, 'HasCase', false, 'HasBulk', false, 'Warnings', {{}});

[lines, ~] = i_readLines(filename);
%Section markers of the root file decide where the reading starts
up = upper(strtrim(lines));
deck.HasExec = any(~cellfun(@isempty, regexp(up, '^CEND\>', 'once')));
deck.HasBulk = any(~cellfun(@isempty, regexp(up, ...
    '^BEGIN\s+(BULK|SUPER|AUXMODEL|ARBMODEL|PART|MODULE)', 'once')));
deck.HasCase = deck.HasExec;
if deck.HasExec
    state = 'pre';
elseif deck.HasBulk
    state = 'pre';
else
    state = 'bulk';
end

bulkLines = {};
bulkSrc   = zeros(0, 2); %[file index, line]
execStarted = false;
stack = {};      %file stack for the INCLUDE depth check
i_process(filename, lines, 0);

deck.Bulk = mni.io.tokenizeBulk(bulkLines, bulkSrc, {deck.Files.File});
logfcn(sprintf('Read %i bulk data entries from %i file(s).', numel(deck.Bulk), numel(deck.Files)));

    function i_process(file, lines, depth)
        stack{end + 1} = file;
        fileIdx = find(strcmp({deck.Files.File}, file), 1);
        k = 0;
        while k < numel(lines)
            k = k + 1;
            if strcmp(state, 'end')
                break
            end
            ln  = lines{k};
            txt = strtrim(ln);
            if isempty(txt)
                if strcmp(state, 'bulk')
                    bulkLines{end + 1} = ''; %#ok<AGROW> %keeps entry separation
                    bulkSrc(end + 1, :) = [fileIdx, k];  %#ok<AGROW>
                end
                continue
            end
            utxt = upper(txt);
            %INCLUDE (any section)
            if ~isempty(regexp(utxt, '^INCLUDE\>', 'once'))
                [incFile, k] = i_includeName(lines, k);
                resolved = i_resolve(incFile, fileparts(file));
                if depth == 0 && strcmp(state, 'bulk')
                    %absolute path: the bulk lines may be reused elsewhere
                    deck.BulkLines{end + 1} = sprintf('INCLUDE ''%s''', resolved);
                end
                deck.Includes(end + 1) = struct('File', resolved, 'Section', state, 'Parent', file);
                if isempty(resolved)
                    error('mni:io:readDeck:include', ['INCLUDE file ''%s'' (in %s) not ', ...
                        'found next to the including file or in the current folder.'], incFile, file);
                end
                if opts.ExpandInclude
                    assert(depth < 10, 'mni:io:readDeck:depth', ...
                        'INCLUDE nested more than 10 levels (QRG INCLUDE remark 1): %s', resolved);
                    assert(~any(strcmp(stack, resolved)), 'mni:io:readDeck:recursive', ...
                        'Recursive INCLUDE of ''%s''.', resolved);
                    deck.Files(end + 1) = struct('File', resolved, 'Parent', file, 'Depth', depth + 1);
                    logfcn(sprintf('Reading INCLUDE file ''%s''', resolved));
                    i_process(resolved, i_readLines(resolved), depth + 1);
                end
                continue
            end
            switch state
                case 'pre'
                    if ~isempty(regexp(utxt, '^CEND\>', 'once'))
                        state = 'case';
                    elseif ~isempty(regexp(utxt, '^BEGIN\s+(BULK|SUPER|AUXMODEL|ARBMODEL|PART|MODULE)', 'once'))
                        state = 'bulk';
                    elseif startsWith(utxt, 'NASTRAN')
                        deck.Nastran{end + 1} = txt;
                    else
                        if ~execStarted && ~isempty(regexp(utxt, ['^(SOL|ID|TIME|DIAG|ECHOON|ECHOOFF|', ...
                                'GEOMCHECK|COMPILE|COMPILER|ALTER|MALTER|LINK|APP|DOMAINSOLVER|', ...
                                'SPARSESOLVER|MODEL_CHECK|CEND)\>'], 'once'))
                            execStarted = true;
                        end
                        if execStarted
                            deck.Exec{end + 1} = txt;
                        else
                            deck.FMS{end + 1} = txt;
                        end
                    end
                case 'case'
                    if ~isempty(regexp(utxt, '^BEGIN\s+(BULK|SUPER|AUXMODEL|ARBMODEL|PART|MODULE)', 'once'))
                        state = 'bulk';
                    else
                        deck.Case{end + 1} = txt;
                    end
                case 'bulk'
                    if ~isempty(regexp(utxt, '^ENDDATA\>', 'once'))
                        state = 'end';
                    elseif ~isempty(regexp(utxt, '^BEGIN\s+', 'once'))
                        deck.Warnings{end + 1} = sprintf('%s line %i: ''%s'' read as Bulk Data.', file, k, txt);
                    else
                        bulkLines{end + 1} = ln; %#ok<AGROW>
                        bulkSrc(end + 1, :) = [fileIdx, k]; %#ok<AGROW>
                        if depth == 0
                            deck.BulkLines{end + 1} = ln;
                        end
                    end
            end
        end
        stack(end) = [];
    end

    function [name, k] = i_includeName(lines, k)
        %Filename between quotes, possibly continued on the next lines
        txt = strtrim(lines{k});
        rest = strtrim(txt(8 : end));
        q = regexp(rest, '[''"]', 'match', 'once');
        if isempty(q) %unquoted
            name = strtrim(strtok(rest));
            return
        end
        rest = rest(find(rest == q, 1) + 1 : end);
        while ~any(rest == q) && k < numel(lines)
            k = k + 1;
            rest = [rest, strtrim(lines{k})]; %#ok<AGROW>
        end
        name = strtrim(rest(1 : find([rest, q] == q, 1) - 1));
    end
end

function f = i_fullpath(f)
if ~isempty(f) && ~i_isAbsolute(f)
    f = fullfile(pwd, f);
end
f = char(java.io.File(f).getCanonicalPath());
end

function tf = i_isAbsolute(f)
tf = startsWith(f, {'/', '\'}) || (numel(f) > 2 && f(2) == ':');
end

function f = i_resolve(name, baseDir)
%i_resolve Locates an INCLUDE file (see the help of readDeck).
f = '';
name = strrep(name, '\', filesep);
name = strrep(name, '/', filesep);
cand = {};
if i_isAbsolute(name)
    cand{end + 1} = name;
else
    cand{end + 1} = fullfile(baseDir, name);
    cand{end + 1} = fullfile(pwd, name);
end
for i = 1 : numel(cand)
    if isfile(cand{i})
        f = i_fullpath(cand{i});
        return
    end
end
%Moved deck: try the trailing folders of the path below 'baseDir' and its
%parents (e.g. ...\Source\Model\model.bdf -> <baseDir>\Model\model.bdf)
parts = strsplit(name, filesep);
parts = parts(~cellfun(@isempty, parts));
dirs  = {baseDir};
for up = 1 : 3
    dirs{end + 1} = fileparts(dirs{end}); %#ok<AGROW>
end
for n = numel(parts) - 1 : -1 : 1
    tail = fullfile(parts{end - n + 1 : end});
    for d = dirs
        if isfile(fullfile(d{1}, tail))
            f = i_fullpath(fullfile(d{1}, tail));
            return
        end
    end
end
end

function [lines, n] = i_readLines(file)
%i_readLines Lines of a text file: comments ('$') removed, tabs expanded.
txt = fileread(file);
lines = regexp(txt, '\r?\n', 'split');
if ~isempty(lines) && isempty(lines{end})
    lines(end) = [];
end
n = numel(lines);
for i = 1 : n
    ln = lines{i};
    d = find(ln == '$', 1);
    if ~isempty(d)
        ln = ln(1 : d - 1);
    end
    if any(ln == sprintf('\t'))
        ln = i_expandTabs(ln);
    end
    lines{i} = deblank(ln);
end
end

function out = i_expandTabs(ln)
out = '';
for c = ln
    if c == sprintf('\t')
        out = [out, repmat(' ', 1, 8 - mod(numel(out), 8))]; %#ok<AGROW>
    else
        out(end + 1) = c; %#ok<AGROW>
    end
end
end
