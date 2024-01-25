function [res] = read_displacements(obj)
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
meta = h5read(obj.filepath,'/INDEX/NASTRAN/RESULT/NODAL/DISPLACEMENT');
disp = h5read(obj.filepath,'/NASTRAN/RESULT/NODAL/DISPLACEMENT');
%convert to familar format
res = struct();
for i = 1:length(meta.DOMAIN_ID)
    idx = disp.DOMAIN_ID == meta.DOMAIN_ID(i);
    res(i).GID =  disp.ID(idx);       %   grid point IDs
    res(i).X =    disp.X(idx);   %
    res(i).Y =    disp.Y(idx);   %   deflections in XYZ
    res(i).Z =    disp.Z(idx);   %
    res(i).RX =   disp.RX(idx); %
    res(i).RY =   disp.RY(idx); %   rotations in XYZ
    res(i).RZ =   disp.RZ(idx); %
end
end

