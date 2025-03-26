function [Modeshapes] = read_modal_force_CBUSH(obj)
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

meta = h5read(obj.filepath,'/INDEX/NASTRAN/RESULT/ELEMENTAL/ELEMENT_FORCE/BUSH');
data = h5read(obj.filepath,'/NASTRAN/RESULT/ELEMENTAL/ELEMENT_FORCE/BUSH');

modes = h5read(obj.filepath,'/NASTRAN/RESULT/SUMMARY/EIGENVALUE');

%extract mode freqs
Modeshapes = struct();
for i = 1:length(meta.DOMAIN_ID)
    Modeshapes(i).Mode          = modes.MODE(i);
    Modeshapes(i).order         = modes.ORDER(i);
    Modeshapes(i).eigenvalue    = modes.EIGEN(i);
    Modeshapes(i).radians       = modes.OMEGA(i);
    Modeshapes(i).cycles        = modes.FREQ(i);
    Modeshapes(i).gen_mass      = modes.MASS(i);
    Modeshapes(i).gen_stiff     = modes.STIFF(i);
end

% extract elemental forces
for i = 1:length(meta.DOMAIN_ID)
    idx = data.DOMAIN_ID == meta.DOMAIN_ID(i);
    Modeshapes(i).EIDs = data.EID(idx)';
    Modeshapes(i).Mx = data.MX(idx);
    Modeshapes(i).My = data.MY(idx);
    Modeshapes(i).Mz = data.MZ(idx);
    Modeshapes(i).Fx = data.FX(idx);
    Modeshapes(i).Fy = data.FY(idx);
    Modeshapes(i).Fz = data.FZ(idx);
end
end

