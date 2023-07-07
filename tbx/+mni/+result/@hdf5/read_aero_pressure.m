function [res] = read_aero_pressure(obj)
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
meta = h5read(obj.filepath,'/INDEX/NASTRAN/RESULT/AERODYNAMIC/PRESSURE');
press = h5read(obj.filepath,'/NASTRAN/RESULT/AERODYNAMIC/PRESSURE');
%convert to familar format
res = struct();
for i = 1:length(meta.DOMAIN_ID)
    idx = press.DOMAIN_ID == meta.DOMAIN_ID(i);
    res(i).PanelID  =  press.GRID(idx);   %   grid point IDs
    res(i).Label    =  press.LABEL(idx);  %
    res(i).Cp       =  press.COEF(idx);   %   deflections in XYZ
    res(i).Pressure =  press.VALUE(idx);  %
end
end