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

FID = fopen(obj.filepath,'r');
Data = [];
while(feof(FID)~=1)
    L = fgets(FID);
    if(contains(L,'COMPLEX EIGENVALUE = '))
        R = sscanf(strtrim(L),'COMPLEX EIGENVALUE = %f, %f');
        if length(R)~= 2
            continue
        end
        ev = complex(R(1),R(2));
        L = fgets(FID);
        if(contains(L,'C O M P L E X   E I G E N V E C T O R'))
            R = sscanf(strtrim(L),'C O M P L E X   E I G E N V E C T O R   NO. %f');
            num = R(1);
            for nn = 1:3 % skip lines
                fgets(FID);
            end
            IDs = [];
            vec = [];
            while true
                L1 = fgets(FID);
                L2 = fgets(FID);
                R1 = sscanf(strtrim(L1),'%f %f G %f %f %f %f %f %f');
                R2 = sscanf(strtrim(L2),'%f %f %f %f %f %f');
                if length(R1)~=8 || length(R2)~=6
                    break
                end
                IDs(end+1) = R1(2);
                vec(end+1,1:6)=0;
                for i = 1:6
                    vec(end,i) = complex(R1(2+i),R2(i));
                end
            end
            if ~isempty(vec)
                Data(end+1).EigenValue = ev;
                Data(end).Num = num;
                Data(end).IDs = IDs(:);
                Data(end).EigenVector = vec;
            end
        end
    end
end
fclose(FID);
end

