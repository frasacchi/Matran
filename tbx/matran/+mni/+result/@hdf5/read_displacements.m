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
    res.GID =  disp.ID(idx);       %   grid point IDs
    res.X =    disp.X(idx);   %
    res.Y =    disp.Y(idx);   %   deflections in XYZ
    res.Z =    disp.Z(idx);   %
    res.RX =   disp.RX(idx); %
    res.RY =   disp.RY(idx); %   rotations in XYZ
    res.RZ =   disp.RZ(idx); %
end
end

