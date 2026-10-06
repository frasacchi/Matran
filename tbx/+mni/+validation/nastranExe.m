function exe = nastranExe()
%nastranExe Path of the MSC Nastran executable ('' if none is found).
exe = '';
if ispref('ADS_Nastran', 'nastran_exe')
    exe = strrep(getpref('ADS_Nastran', 'nastran_exe'), '"', '');
    if endsWith(exe, 'w.exe') %non-blocking variant
        exe = [exe(1 : end - 5), '.exe'];
    end
    if isfile(exe)
        return
    end
end
root = fullfile('C:\Program Files', 'MSC.Software', 'MSC_Nastran');
if ~isfolder(root)
    exe = '';
    return
end
d = dir(root);
d = d([d.isdir] & ~startsWith({d.name}, '.'));
for i = numel(d) : -1 : 1
    f = fullfile(root, d(i).name, 'bin', 'nastran.exe');
    if isfile(f)
        exe = f;
        return
    end
end
exe = '';
end
