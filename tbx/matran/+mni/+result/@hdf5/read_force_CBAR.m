function [res] = read_force_CBAR(obj)
%read_modal_force_CBEAM Reads the modeshapes from the .h5 file 

% Outputs :
%   - 'Modeshapes' : Structure containg all of the Modeshape data. 
%                    Fields include:
%                       + Mode - Mode number
%                       + order - Order of the mode
%                       + eigenvalue - Eigenvalue of the mode
%                       + radians - Radians of the mode
%                       + cycles - Frequency of the mode
%                       + gen_mass - Generalised mass of the mode
%                       + gen_stiff - Generalised stiffness of the mode
%                       + EIDs - Element IDs
%                       + Mx - Moment about the x-axis (at each end of beam)
%                       + My - Moment about the y-axis (at each end of beam)
%                       + Mz - Moment about the z-axis (at each end of beam)
%                       + Fx - Force in the x-axis (at each end of beam)
%                       + Fy - Force in the y-axis (at each end of beam)
%                       + Fz - Force in the z-axis (at each end of beam)
% -------------------------------------------------------------------------
% Author: Fintan Healy
% Contact: fintan.healy@bristol.ac.uk
% Created: 06/03/2023
% Modified: 06/03/2023
%
% Change Log:
%   - 
% ======================================================================= %

meta = h5read(obj.filepath,'/INDEX/NASTRAN/RESULT/ELEMENTAL/ELEMENT_FORCE/BAR');
data = h5read(obj.filepath,'/NASTRAN/RESULT/ELEMENTAL/ELEMENT_FORCE/BAR');
% extract elemental forces
res = struct();
for i = 1:length(meta.DOMAIN_ID)
    idx = data.DOMAIN_ID == meta.DOMAIN_ID(i);
    res(i).EIDs = data.EID(idx);
%     res(i).GIDs = data.GRID(idx);
    res(i).Mx = data.TRQ(idx);
    res(i).Mz = data.BM1A(idx);
    res(i).My = data.BM2A(idx);
    res(i).Fx = data.AF(idx);
    res(i).Fz = data.TS2(idx);
    res(i).Fy = data.TS1(idx);
end
end

