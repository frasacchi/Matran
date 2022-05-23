function [Data] = read_flutter_eigenvector(obj)
%READ_F06_FLUTTER : Reads the flutter data from the .f06 file with 
%the name 'filename' which is located in 'dir_out'
%
% Inputs :
%   - 'dir_out'  : Folder path of the folder containing the .f06 file
%   - 'filename' : Name of the .f06 file (without file extension)
%
% Outputs :
%   - 'Data' : Structure containg all of the Flutter Data data. 
%                    Fields include:
%                       + Mode      : Mode Number
%                       + M         : Mach Number
%                       + RHO_RATIO : Density Ratio
%                       + KF        : Reduced Frequency
%                       + V         : Velocity
%                       + D         : Damping
%                       + F         : Frequency
%                       + CMPLX     : Complex Number of Mode
% -------------------------------------------------------------------------
% Author: Fintan Healy
% Contact: fintan.healy@bristol.ac.uk
% Created: 12/05/2021
% Modified: 12/05/2021
%
% Change Log:
%   - 
% ======================================================================= %

data = h5read(obj.filepath,'/NASTRAN/RESULT/NODAL/EIGENVECTOR_CPLX');
gps = unique(data.ID);
start_idx = find(data.ID == data.ID(1));
end_idx = find(data.ID == data.ID(length(gps)));

Data = struct();
for i = 1:length(start_idx)
    idx = start_idx(i):end_idx(i);
    Data(i).EigenValue = [];
    Data(i).Num = i;
    Data(i).IDs = data.ID(idx);
    Data(i).EigenVector = zeros(length(gps),6);
    Data(i).EigenVector(:,1) = complex(data.XR(idx),data.XI(idx));
    Data(i).EigenVector(:,2) = complex(data.YR(idx),data.YI(idx));
    Data(i).EigenVector(:,3) = complex(data.ZR(idx),data.ZI(idx));
    Data(i).EigenVector(:,4) = complex(data.RXR(idx),data.RXI(idx));
    Data(i).EigenVector(:,5) = complex(data.RYR(idx),data.RYI(idx));
    Data(i).EigenVector(:,6) = complex(data.RZR(idx),data.RZI(idx));
end
end

