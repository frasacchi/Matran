function [Modeshapes] = read_modeshapes(obj)
%READ_MODESHAPES Reads the modeshapes from the .h5 file 

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
%                       + ids - Node IDs
%                       + eigenVector - Eigenvector of the mode
% -------------------------------------------------------------------------
% Author: Fintan Healy
% Contact: fintan.healy@bristol.ac.uk
% Created: 06/03/2023
% Modified: 06/03/2023
%
% Change Log:
%   - 
% ======================================================================= %

meta = h5read(obj.filepath,'/INDEX/NASTRAN/RESULT/NODAL/EIGENVECTOR');
data = h5read(obj.filepath,'/NASTRAN/RESULT/NODAL/EIGENVECTOR');

Modeshapes = obj.read_modes();
for i = 1:length(meta.DOMAIN_ID)
    idx = data.DOMAIN_ID == meta.DOMAIN_ID(i);
    Modeshapes(i).IDs = data.ID(idx);
    Modeshapes(i).EigenVector = [data.X(idx),data.Y(idx),data.Z(idx),data.RX(idx),data.RY(idx),data.RZ(idx)];
end
end

