function res = runNastran(deckFile, opts)
%runNastran Runs MSC Nastran on a deck and reports the output files.
%
% Syntax:
%   >> res = mni.validation.runNastran('C:\work\sol103.bdf');
%
% Output 'res' (struct): OK (no fatal message), F06, H5, Log (console
% output), Fatal (lines with FATAL), Seconds.
%
% The executable is taken from 'Exe', else from the ADS preference
% getpref('ADS_Nastran', 'nastran_exe'), else from the newest
% C:\Program Files\MSC.Software\MSC_Nastran\*\bin\nastran.exe.

arguments
    deckFile {mustBeTextScalar}
    opts.Exe = ''
    opts.Memory = ''
end
deckFile = char(deckFile);
exe = char(opts.Exe);
if isempty(exe)
    exe = mni.validation.nastranExe();
end
exe = strrep(exe, '"', '');
assert(~isempty(exe) && isfile(exe), 'mni:validation:nastran', ...
    'MSC Nastran executable not found (set ''Exe'' or the ADS_Nastran preference).');
[d, n, e] = fileparts(deckFile);
args = 'scr=yes old=no news=no batch=no';
if ~isempty(opts.Memory)
    args = [args, ' memory=', opts.Memory];
end
cmd = sprintf('cd /d "%s" && "%s" "%s%s" %s', d, exe, n, e, args);
t = tic;
[~, out] = system(cmd);
res.Seconds = toc(t);
res.Log = out;
res.F06 = fullfile(d, [lower(n), '.f06']);
if ~isfile(res.F06)
    res.F06 = fullfile(d, [n, '.f06']);
end
res.H5 = fullfile(d, [lower(n), '.h5']);
if ~isfile(res.H5)
    res.H5 = fullfile(d, [n, '.h5']);
end
res.Fatal = {};
res.OK = isfile(res.F06);
if res.OK
    txt = fileread(res.F06);
    lines = regexp(txt, '[^\n]*FATAL[^\n]*', 'match');
    res.Fatal = strtrim(lines);
    res.OK = isempty(lines);
end
end
