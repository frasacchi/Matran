function [res] = read_force_QUAD4(obj)
%READ_FORCE_QUAD4 Reads QUAD4 elemental forces from the .h5 file.

% Outputs :
%   - 'res' : Structure array containing the force data for the found
%             element type. The structure of 'res' depends on the
%             element type read.
% -------------------------------------------------------------------------
% Author: Francesco Sacchi
% Contact: vm19436@bristol.ac.uk
% Created: 12/10/2025

meta = h5read(obj.filepath,'/INDEX/NASTRAN/RESULT/ELEMENTAL/ELEMENT_FORCE/QUAD4');
data = h5read(obj.filepath,'/NASTRAN/RESULT/ELEMENTAL/ELEMENT_FORCE/QUAD4');
% extract elemental forces
res = struct();
for i = 1:length(meta.DOMAIN_ID)
    idx = data.DOMAIN_ID == meta.DOMAIN_ID(i);
    res(i).EIDs = data.EID(idx)'; % EIDs as a row vector
    res(i).Mx = data.BMX([1,end],idx); % Bending Moment X
    res(i).My = data.BMY([1,end],idx); % Bending Moment Y
    res(i).Mxy = data.BMXY([1,end],idx); % Torsional Moment
    res(i).Fx = data.TX([1,end],idx); % Shear Force X
    res(i).Fy = data.TY([1,end],idx); % Shear Force Y
    res(i).Nx = data.MX([1,end],idx);
    res(i).Ny = data.MY([1,end],idx);
    res(i).Nxy = data.MXY([1,end],idx);
end
end
