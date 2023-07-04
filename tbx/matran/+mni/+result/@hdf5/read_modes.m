function [Modes] = read_modes(obj)
%READ_MODES Reads the modes from the .h5 file 

% Outputs :
%   - 'Modes' : Structure containg all of the Modeshape data. 
%                    Fields include:
%                       + Mode - Mode number
%                       + order - Order of the mode
%                       + eigenvalue - Eigenvalue of the mode
%                       + radians - Radians of the mode
%                       + cycles - Frequency of the mode
%                       + gen_mass - Generalised mass of the mode
%                       + gen_stiff - Generalised stiffness of the mode
% -------------------------------------------------------------------------
% Author: Fintan Healy
% Contact: fintan.healy@bristol.ac.uk
% Created: 06/03/2023
% Modified: 06/03/2023
%
% Change Log:
%   - 
% ======================================================================= %

% get eigenvalues
modes = h5read(obj.filepath,'/NASTRAN/RESULT/SUMMARY/EIGENVALUE');
%convert to familar format
Modes = struct();
for i = 1:length(modes.MODE)
    Modes(i).Mode          = modes.MODE(i);
    Modes(i).order         = modes.ORDER(i);
    Modes(i).EigenValue    = modes.EIGEN(i);
    Modes(i).radians       = modes.OMEGA(i);
    Modes(i).cycles        = modes.FREQ(i);
    Modes(i).gen_mass      = modes.MASS(i);
    Modes(i).gen_stiff     = modes.STIFF(i);
end
end

