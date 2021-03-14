function [displacements] = read_f06_disp(dir_out, filename)
%READ_F06_DISP : Reads the displacements from the .f06 file with the name
%'filename' which is located in 'dir_out'
%
%   - May need to tweek the function to check for different strings 
%     depending on the analysis that has been requested
%
%   # V1 : 0930_10/08/2016 
%

resFile = fopen([dir_out filename '.f06'],'r');
readingFlag = 0;
ii = 0;

while feof(resFile) ~= 1
    f06Line = fgets(resFile);
    
    if readingFlag == 0
        if ~isempty(strfind(f06Line,'D I S P L A C E M E N T   V E C T O R'))
            readingFlag = 1;
        end
    end
    
    if readingFlag == 1
        r = sscanf(f06Line,'%d %s %f %f %f %f %f %f');
        if any(8:9==length(r))
            ii = ii + 1;
            GP(ii) = r(1);
            x_defl(ii) = r(3);
            y_defl(ii) = r(4);
            z_defl(ii) = r(5);
            theta_x(ii) = r(6);
            theta_y(ii) = r(7);
            theta_z(ii) = r(8);
            if length(r) == 8         
                OCS_ID(ii)  = 0;
            elseif length(r) == 9
                OCS_ID(ii)  = r(9);            
            end
        end
        if ~isempty(strfind(f06Line,'F O R C E S   I N   B A R   E L E M E N T S         ( C B A R )')) || ...
                ~isempty(strfind(f06Line,'F O R C E S   I N   B E A M   E L E M E N T S        ( C B E A M )')) || ...
                ~isempty(strfind(f06Line,'F O R C E S   O F   S I N G L E - P O I N T   C O N S T R A I N T'))
            break
        end
    end
end

fclose(resFile);
if ii == 0
    error(['No displacement data found in file: ' dir_out filename '.f06'])
end
% format output structure
displacements.GP = GP;       %   grid point IDs
displacements.dX = x_defl;   %
displacements.dY = y_defl;   %   deflections in XYZ
displacements.dZ = z_defl;   %
displacements.thX = theta_x; %
displacements.thY = theta_y; %   rotations in XYZ
displacements.thZ = theta_z; %
displacements.OCS = OCS_ID;  %   output coordinate system
end
