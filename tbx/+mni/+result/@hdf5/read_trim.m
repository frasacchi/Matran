function [res] = read_trim(obj)
%READ_DISPLACEMENTS Reads the displacements from the .h5 file 
% Author: Fintan Healy
% Contact: fintan.healy@bristol.ac.uk
% Created: 06/03/2023
% Modified: 06/03/2023
%
% Change Log:
%   - 
% ======================================================================= %

% get eigenvalues
meta = h5read(obj.filepath,'/INDEX/NASTRAN/RESULT/AERODYNAMIC/VARIABLE');
data = h5read(obj.filepath,'/NASTRAN/RESULT/AERODYNAMIC/VARIABLE');
%convert to familar format
res = struct();
for i = 1:length(meta.DOMAIN_ID)
    idx = find(data.DOMAIN_ID == meta.DOMAIN_ID(i));
    for j = 1:length(idx)
        res(i).(strtrim(string(data.LABEL(:,idx(j))'))) = data.VALUE(idx(j));
    end
end
end