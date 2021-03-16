function ModeShapes = read_modeshapes(obj)
%read_f06_extract_modeshapes : Reads the mode data from the .f06 file with 
%the name 'filename' which is located in 'dir_out'
%
% Inputs :
%   - 'dir_out'  : Folder path of the folder containing the .f06 file
%   - 'filename' : Name of the .f06 file (without file extension)
%
% Outputs :
%   - 'ModeShapes' : Structure containg all of the modeshape data. 
%                    Fields include:
%                       + GP      : grid point ID
%                       + dX      : displacements in X
%                       + dY      : displacements in Y
%                       + dZ      : displacements in Z
%                       + theta_x : rotation about X-axis
%                       + theta_y : rotation about Y-axis
%                       + theta_z : rotation about Z-axis
% -------------------------------------------------------------------------
%
%   - May need to tweek the function to check for different strings 
%     depending on the analysis that has been requested
%
%   # V1 : 1200_10/10/2016 
%
%   Change Log:
%
%   - 27/10/2016 - Added an additional string for when the mode number
%                  reaches double digits
% ======================================================================= %

resFile = fopen(obj.filepath,'r');
readingFlag = 0;

% counters
ii = 0;
modeNo = 0;

while feof(resFile) ~= 1
    f06Line = fgets(resFile);
    
    if readingFlag == 0
        if contains(f06Line,sprintf('R E A L   E I G E N V E C T O R   N O .          %i', modeNo+1))
            readingFlag = 1;
            modeNo = modeNo + 1;
        end
    end
    
    if readingFlag == 1
        r = sscanf(f06Line,'%d %s %f %f %f %f %f %f %f');
        if any(8:9==length(r))
            ii = ii + 1;
            GID(modeNo, ii)     = r(1);
            x_defl(modeNo, ii)  = r(3);
            y_defl(modeNo, ii)  = r(4);
            z_defl(modeNo, ii)  = r(5);
            theta_x(modeNo, ii) = r(6);
            theta_y(modeNo, ii) = r(7);
            theta_z(modeNo, ii) = r(8);
            if length(r) == 8            
                OCS_ID(modeNo, ii)  = 0;    % assume global coordinate system 
            elseif length(r) == 9
                OCS_ID(modeNo, ii)  = r(9);    
            end
        end
        
        
        if contains(f06Line,sprintf('R E A L   E I G E N V E C T O R   N O .          %i',modeNo + 1)) || ...  % single digit
           contains(f06Line,sprintf('R E A L   E I G E N V E C T O R   N O .         %i',modeNo + 1))          % double digit
            ii = 0; % reset grid point counter
            modeNo = modeNo + 1;
        elseif contains(f06Line,'G R I D   P O I N T   K I N E T I C   E N E R G Y   (  P E R C E N T  )') || ...
                contains(f06Line,'* * * *  A N A L Y S I S  S U M M A R Y  T A B L E  * * * *') 
            break
        end
    end
end

if modeNo == 0
   error(['No modeshapes found in file: ' dir_out filename '.f06']) 
end

fclose(resFile);

% format output structure
ModeShapes.GID = GID;         % grid point IDs
ModeShapes.T1  = x_defl;     %
ModeShapes.T2  = y_defl;     % deflections in XYZ
ModeShapes.T3  = z_defl;     %
ModeShapes.R1  = theta_x;   %
ModeShapes.R2  = theta_y;   % rotations in XYZ
ModeShapes.R3  = theta_z;   %
ModeShapes.OCS = OCS_ID;    % output coordinate system  
end
