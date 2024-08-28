function [force] = read_force_CBUSH(obj)
%READ_F06_force_CBAR : Reads the element forces from the .f06 file with the
%name 'filename' which is located in 'dir_out'
%
%   - May need to tweek the function to check for different strings 
%     depending on the analysis that has been requested
%   - Valid only for models using CBUSH elements
%
%   # V1 : 0930_10/08/2016 
%

resFile = fopen(obj.filepath,'r');
readingFlag = 0;
ii = 1;

% preallocate
EID=[];     Fx=[];     Fy=[];
Fz=[];   Mx=[];
My=[];   Mz=[];

while feof(resFile) ~= 1
    f06Line = fgets(resFile);
    
    if readingFlag == 0
        if ~isempty(strfind(f06Line,'F O R C E S   I N   B U S H   E L E M E N T S        ( C B U S H )'))
            readingFlag = 1;
        end
    else
        if ~isempty(strfind(f06Line,'* * * *  A N A L Y S I S  S U M M A R Y  T A B L E  * * * *'))
            break
        end
        r = sscanf(f06Line,'%d %d %f %f %f %f %f %f');
        if length(r) == 8
            EID(ii) = r(2);
            Fx(ii) = r(3);
            Fy(ii) = r(4);
            Fz(ii) = r(5);
            Mx(ii) = r(6);
            My(ii) = r(7);
            Mz(ii) = r(8);
            ii = ii + 1;
        end
    end
end

fclose(resFile);

% format output structure
force.EID = EID;  %   element ID
force.Fx = Fx;    %
force.Fy = Fy;    %
force.Fz = Fz;    %
force.Mx = Mx;    %
force.My = My;    %
force.Mz = Mz;    %
end