function [Data] = read_flutter(obj)
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
% Author: Ronald Cheung
% Contact: r.c.m.cheung@bristol.ac.uk
% Created: 22 Nov 2020
% Modified: 02 Feb 2021
%
% Change Log:
%   - 03/02/2021 - copied from local function
% ======================================================================= %

FID = fopen(obj.filepath,'r');
SW = 0;
jj = 0;
Data = [];
while(feof(FID)~=1)
    L = fgets(FID);
    if(SW==0)
        if(contains(L,'FLUTTER  SUMMARY'))
            SW = 1;
            for nn = 1:2 % skip lines
                L = fgets(FID);
            end
            Q = sscanf(strtrim(L), ...
                'POINT = %f MACH NUMBER = %f DENSITY RATIO = %f ')';
            jj = jj+1;
            Data(jj).MODE = round(Q(1));
            Data(jj).M = Q(2);
            Data(jj).RHO_RATIO = Q(3);
            for nn = 1:3 % skip lines
                L = fgets(FID);
            end
            ii = 0; % init velocity point counter
        end
    elseif(contains(L,'PAGE')||(contains(L,'USER WARNING MESSAGE')))
        SW = 0;
    else
        if(contains(L,'********'))
            P = sscanf(strtrim(L),'******** %f %f %f %f %f %f')';
            R = [1.0/P(1),P];
        else
            R = sscanf(strtrim(L),'%f %f %f %f %f %f %f')';
        end
        if isempty(R)
            SW = 0;
        else
            ii = ii+1;
            Data(jj).KF(ii) = R(1);
            Data(jj).V(ii) = R(3);
            Data(jj).D(ii) = R(4);
            Data(jj).F(ii) = R(5);
            Data(jj).CMPLX(ii,:) = R(6:7);
        end
    end
end
fclose(FID);
end

