function cards = tokenizeBulk(lines, src, files)
%tokenizeBulk Splits Bulk Data lines into entries following QRG ch.9
%"Format of Bulk Data Entries" and "Continuations".
%
% Syntax:
%   >> cards = mni.io.tokenizeBulk(lines)
%   >> cards = mni.io.tokenizeBulk(lines, src, files)
%
% Inputs:
%   lines - cellstr of bulk data lines (comments already removed)
%   src   - [n x 2] source of each line: [file index, line number]
%   files - cellstr of file names indexed by src(:, 1)
%
% Output 'cards' (struct array):
%   Name   - entry name (upper case, '*' of large field removed)
%   Fields - cellstr of the data fields as Nastran reads them: fields
%            2..9 of the parent line followed by fields 2..9 of every
%            continuation line (8 fields per logical line). Field 10
%            (continuation identifier) is dropped.
%   File, Line - source of the parent line
%
% Supported input:
%   - small field (8 columns), large field ('*' after the name, 16
%     column fields, continuation lines starting with '*'), free field
%     (commas; '*' for large free field; more than 10 fields on a line
%     continue on the next logical line; a trailing comma joins the next
%     line)
%   - continuation lines: field 1 blank, '+...' or '*...' (explicit
%     identifiers are not matched, continuations must follow the parent)
%   - Nastran reals without 'E' (7.0+1, 1.5-6) and with 'D' exponents
%     are rewritten as MATLAB readable reals; character data is upper case
%   - replication (QRG "Replication"): '=', '==', '*x' / '*(x)' fields,
%     '=' / '=n' / '=(n)' in field 1. Delayed replication '=(D)' errors.

if nargin < 2 || isempty(src)
    src = [ones(numel(lines), 1), (1 : numel(lines))'];
end
if nargin < 3 || isempty(files)
    files = {''};
end

cards = struct('Name', {}, 'Fields', {}, 'File', {}, 'Line', {});
cur   = [];         %entry being assembled
prev  = [];         %previous complete entry (replication)
incr  = {};         %increments of the previous replicated entry
n     = numel(lines);
i     = 0;
while i < n
    i  = i + 1;
    ln = lines{i};
    if isempty(strtrim(ln))
        continue
    end
    isFree = any(ln == ',');
    if isFree
        %trailing comma: the free field data continues on the next line
        while endsWith(strtrim(ln), ',') && i < n && i_joins(lines{i + 1})
            i  = i + 1;
            ln = [strtrim(ln), strtrim(lines{i})];
        end
    end
    [f1, data, isLarge] = i_splitLine(ln, isFree);
    uf1 = upper(f1);

    %Replication of the previous entry: '=', '=n', '=(n)'
    rep = regexp(uf1, '^=\(?(\d*|D)\)?$', 'tokens', 'once');
    if ~isempty(rep)
        i_close();
        assert(~isempty(prev), 'mni:io:tokenizeBulk:replication', ...
            '%s line %i: replication without a previous entry.', files{src(i, 1)}, src(i, 2));
        assert(~strcmp(rep{1}, 'D'), 'mni:io:tokenizeBulk:replication', ...
            '%s line %i: delayed replication =(D) is not supported.', files{src(i, 1)}, src(i, 2));
        if isempty(rep{1}) %'=' in field 1: same name, fields with replication codes
            [fields, incr] = i_replicate(prev.Fields, data, incr);
            cur = struct('Name', prev.Name, 'Fields', {fields}, ...
                'File', files{src(i, 1)}, 'Line', src(i, 2), 'Half', false);
        else              %'=n': n images with the previous increments
            for r = 1 : str2double(rep{1})
                fields = prev.Fields;
                for k = 1 : min(numel(incr), numel(fields))
                    if ~isempty(incr{k})
                        fields{k} = i_add(fields{k}, incr{k});
                    end
                end
                cards(end + 1) = struct('Name', prev.Name, 'Fields', {fields}, ...
                    'File', files{src(i, 1)}, 'Line', src(i, 2)); %#ok<AGROW>
                prev = cards(end);
            end
        end
        continue
    end

    isCont = isempty(f1) || f1(1) == '+' || f1(1) == '*';
    if ~isCont
        i_close();
        name = regexprep(uf1, '\*$', '');
        cur  = struct('Name', name, 'Fields', {{}}, ...
            'File', files{src(i, 1)}, 'Line', src(i, 2), 'Half', false);
        incr = {};
    elseif isempty(cur)
        warning('mni:io:tokenizeBulk:orphan', ...
            '%s line %i: continuation line without a parent entry ignored.', ...
            files{src(i, 1)}, src(i, 2));
        continue
    end
    %replication codes inside an entry that follows the same card
    if ~isempty(prev) && strcmp(cur.Name, prev.Name) && any(startsWith(data, {'=', '*'}))
        k0 = numel(cur.Fields);
        prevF = prev.Fields(k0 + 1 : min(end, k0 + numel(data)));
        [data, inc] = i_replicate(prevF, data, {});
        incr(k0 + 1 : k0 + numel(inc)) = inc;
    end
    %Append the data of this physical line. A new line starts a new
    %logical line unless it is the 2nd half of a large field line.
    if ~(isLarge && cur.Half)
        cur.Fields(end + 1 : 8 * ceil(numel(cur.Fields) / 8)) = {''};
        cur.Half = false;
    end
    cur.Fields = [cur.Fields, data];
    if isLarge
        cur.Half = ~cur.Half;
    end
end
i_close();

    function i_close()
        if isempty(cur)
            return
        end
        f = cur.Fields;
        f(end + 1 : 8 * ceil(numel(f) / 8)) = {''};
        cards(end + 1) = struct('Name', cur.Name, 'Fields', {f}, ...
            'File', cur.File, 'Line', cur.Line);
        prev = cards(end);
        cur  = [];
    end
end

function tf = i_joins(next)
%i_joins True if 'next' continues a free field line ending with a comma.
next = strtrim(next);
tf = ~isempty(next) && ~any(next(1) == ',+*');
end

function [f1, data, isLarge] = i_splitLine(ln, isFree)
%i_splitLine Field 1 and the data fields of one physical line.
if isFree
    tok = strtrim(strsplit(ln, ',', 'CollapseDelimiters', false));
    f1  = tok{1};
    isLarge = endsWith(f1, '*') || startsWith(f1, '*');
    per = 8 - 4 * isLarge;
    data = tok(2 : end);
    if numel(data) <= per + 1   %last field is the continuation field
        data = data(1 : min(per, numel(data)));
        data(end + 1 : per) = {''};
    end
else
    f1 = strtrim(ln(1 : min(8, numel(ln))));
    isLarge = endsWith(f1, '*') || startsWith(f1, '*');
    w = 8 + 8 * isLarge;
    nF = 8 - 4 * isLarge;
    data = cell(1, nF);
    for k = 1 : nF
        a = 9 + (k - 1) * w;
        b = min(a + w - 1, numel(ln));
        if a > numel(ln)
            data{k} = '';
        else
            data{k} = strtrim(ln(a : b));
        end
    end
end
data = cellfun(@i_normalise, data, 'UniformOutput', false);
end

function s = i_normalise(s)
%i_normalise Upper case; Nastran reals (1.5-6, 7.+1, 1.0D2) -> 1.5E-6 ...
s = upper(strtrim(s));
if isempty(s) || ~any(s(1) == '+-.0123456789')
    return
end
if ~isempty(regexp(s, '^[+-]?(\d+\.\d*|\.\d+)[+-]\d+$', 'once'))
    s = regexprep(s, '^([+-]?(?:\d+\.\d*|\.\d+))([+-]\d+)$', '$1E$2');
elseif ~isempty(regexp(s, '^[+-]?(\d+\.?\d*|\.\d+)D[+-]?\d+$', 'once'))
    s = strrep(s, 'D', 'E');
end
if numel(s) > 1 && s(1) == '+' && any(s(2) == '.0123456789')
    s = s(2 : end); %'+.95' -> '.95'
end
end

function [fields, inc] = i_replicate(prevFields, data, ~)
%i_replicate Applies '=', '==' and '*x' codes against the previous entry.
fields = data;
inc    = cell(1, numel(data));
k = 0;
while k < numel(data)
    k = k + 1;
    d = data{k};
    p = '';
    if k <= numel(prevFields)
        p = prevFields{k};
    end
    if strcmp(d, '==')
        fields(k : numel(data)) = prevFields(k : min(end, numel(data)));
        fields(end + 1 : numel(data)) = {''};
        return
    elseif strcmp(d, '=')
        fields{k} = p;
    elseif ~isempty(d) && d(1) == '*'
        x = regexprep(d(2 : end), '[()]', '');
        fields{k} = i_add(p, x);
        inc{k} = x;
    end
end
end

function s = i_add(s, x)
%i_add Increments the numeric field 's' by the text increment 'x'.
v = str2double(s) + str2double(x);
if contains(s, '.') || contains(x, '.') || contains(upper(s), 'E')
    s = num2str(v, 15);
    if ~contains(s, '.') && ~contains(upper(s), 'E')
        s = [s, '.'];
    end
else
    s = sprintf('%d', round(v));
end
end
