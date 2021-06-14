function [Data] = read_flutter(obj)
%READ_F06_FLUTTER : Reads the flutter data from the .f06 file
%
% Parameters :
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
% Created: 22 Nov 2020
% Modified: 02 Feb 2021
%
% Change Log:
%   - 03/02/2021 - copied from local function
%   - 12/05/2021 - added additional switch to check for end of array
%   - 09/06/2021 - added switch to detect the flutter method used and
%                   extract the data accordingly
% ======================================================================= %

FID = fopen(obj.filepath,'r');
SW = 0;
Data = [];
while(feof(FID)~=1)
    L = fgets(FID);
    if(SW==0)
        if(contains(L,'FLUTTER  SUMMARY'))
            SW = 1;
            for nn = 1:2 % skip lines
                L = fgets(FID);
            end
            % get method
            Meth = regexp(L,'METHOD = (\w*)','tokens');
            Meth = Meth{1}{1};
            switch Meth
                case 'PK'
                    Q = sscanf(strtrim(L), ...
                        'POINT = %f MACH NUMBER = %f DENSITY RATIO = %f ')';
                    Data(end+1).MODE = round(Q(1));
                    Data(end).M = Q(2);
                    Data(end).RHO_RATIO = Q(3);
                case 'PKNL'
                    Q = sscanf(strtrim(L), ...
                        'POINT = %f ')';
                    Data(end+1).MODE = round(Q(1));
                otherwise
                    error('Flutter method "%s" is currently unsupported for f06 extraction',Meth)
            end
            for nn = 1:3 % skip lines
                fgets(FID);
            end
            ii = 0; % init velocity point counter
        end
    elseif(contains(L,'PAGE')||(contains(L,'USER WARNING MESSAGE')))
        SW = 0;
    else
        switch Meth
            case 'PK'
                if(contains(L,'********'))
                    P = sscanf(strtrim(L),'******** %f %f %f %f %f %f')';
                    R = [1.0/P(1),P];
                else
                    R = sscanf(strtrim(L),'%f %f %f %f %f %f %f')';
                end
                if isempty(R) || length(R)~=7
                    SW = 0;
                else
                    ii = ii+1;
                    Data(end).KF(ii) = R(1);
                    Data(end).V(ii) = R(3);
                    Data(end).D(ii) = R(4);
                    Data(end).F(ii) = R(5);
                    Data(end).CMPLX(ii,:) = R(6:7);
                end
            case 'PKNL'
                if(contains(L,'********'))
                    error('Currently unsure when this is encountered / what the table format is')
                else
                    R = sscanf(strtrim(L),repmat('%f ',1,9))';
                end
                if isempty(R) || length(R)~=9
                    SW = 0;
                else
                    ii = ii+1;
                    Data(end).KF(ii) = R(1);
                    Data(end).RHO_RATIO(ii) = R(3);
                    Data(end).M(ii) = R(4);
                    Data(end).V(ii) = R(5);
                    Data(end).D(ii) = R(6);
                    Data(end).F(ii) = R(7);
                    Data(end).CMPLX(ii,:) = R(8:9);
                end
        end
    end
end
fclose(FID);
end

