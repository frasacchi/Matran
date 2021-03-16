function Displacements = read_disp_dynamic(obj)
%read_f06_disp_dynamic : Reads the displacements at each timestep from the 
%.f06 file with the name 'filename' which is located in 'dir_out'
%
%   - May need to tweek the function to check for different strings 
%     depending on the analysis that has been requested
%
%   # V1 : 2311_13/03/2016 
%
% ======================================================================= %

resFile = fopen(obj.filepath,'r');
readingFlag = 0;
ii = 1; % data counter
jj = 1; % grid point counter
kk = 1; % grid point counter

while feof(resFile) ~= 1
    f06Line = fgets(resFile);
    
    % find first grid point ID
    if readingFlag == 0
        if ~isempty(strfind(f06Line, 'POINT-ID ='))
            % extract GID of current grid point
            f06Split = strsplit(f06Line, '=');
            GID(kk) = str2double(f06Split{2});            
        end
    end
    
    % find list of displacements for this grid point
    if readingFlag == 0
        if ~isempty(strfind(f06Line,'D I S P L A C E M E N T   V E C T O R'))
            readingFlag = 1;
        end
    end
    
    if readingFlag == 1 
        % check to see if we have moved onto a new grid point
        if ~isempty(strfind(f06Line, 'POINT-ID ='))
            
            f06Split = strsplit(f06Line, '=');
            gridPoint = str2double(f06Split{2});
            
            if gridPoint ~= GID(kk)
                % update flags & counters and return to top of while loop
                readingFlag = 0;
                ii = 1;
                kk = kk + 1;
                jj = jj + 1;
                GID(kk) = gridPoint;
                continue
            end
        else
            % scan current line for formatted string
            r = sscanf(f06Line,'%f %s %f %f %f %f %f %f %i');
        end
       
        if length(r) == 9
            t(ii, jj) = r(1);
            x_defl(ii, jj) = r(3);
            y_defl(ii, jj) = r(4);
            z_defl(ii, jj) = r(5);
            theta_x(ii, jj) = r(6);
            theta_y(ii, jj) = r(7);
            theta_z(ii, jj) = r(8);
            OCS_ID(ii, jj)  = r(9);
            ii = ii + 1;            
        end
        
        % check for statements that are known to terminate the displacment section
        if ~isempty(strfind(f06Line, 'F O R C E S   I N   B A R   E L E M E N T S         ( C B A R )'))         || ...
                ~isempty(strfind(f06Line, 'F O R C E S   I N   B E A M   E L E M E N T S        ( C B E A M )')) || ...
                ~isempty(strfind(f06Line, 'F O R C E S   O F   S I N G L E - P O I N T   C O N S T R A I N T'))  || ...
                ~isempty(strfind(f06Line, '* * * *  A N A L Y S I S  S U M M A R Y  T A B L E  * * * *'))
            break
        end
        
    end
end

fclose(resFile);

% format output structure
Displacements.t   = t;       % time
Displacements.GP  = GID;     % grid point IDs
Displacements.dX  = x_defl;  %
Displacements.dY  = y_defl;  % deflections in XYZ
Displacements.dZ  = z_defl;  %
Displacements.thX = theta_x; %
Displacements.thY = theta_y; % rotations in XYZ
Displacements.thZ = theta_z; %
Displacements.OCS = OCS_ID;  % output coordinate system
end
