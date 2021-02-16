function GridPointKineticEnergy = read_f06_gridpoint_kinetic_energy(dir_out, filename)
%read_f06_gridpoint_kinetic_energy : Reads the grid point kinetic energy
%from the .f06 file with the name 'filename' which is located in 'dir_out'
%
% Inputs :
%   - 'dir_out'  : Folder path of the folder containing the .f06 file
%   - 'filename' : Name of the .f06 file (without file extension)
%
% Outputs :
%   - 'GridPointKineticEnergy' : Structure containg all GPKE data
%                                Fields include:
%                                   + ID            : element ID
%                                   + strainEnergy  : displacements in X
%                                   + percOfTotal   : displacements in Y
%                                   + energyDensity : displacements in Z
% -------------------------------------------------------------------------
%
%   - May need to tweek the function to check for different strings 
%     depending on the analysis that has been requested
%
%   # V1 : 0955_17/03/2017 
%
% ======================================================================= %

resFile = fopen([dir_out filename '.f06'],'r');
readingFlag = 0;

% counters
ii = 1;
modeNo = 1;

while feof(resFile) ~= 1    
    % grab next line
    f06Line = fgets(resFile);
    
    % find start of element strain energy output
    if readingFlag == 0
        if ~isempty(strfind(f06Line,'G R I D   P O I N T   K I N E T I C   E N E R G Y   (  P E R C E N T  )'));
            readingFlag = 1;
        end
    end
    
    % find table containing strain energy
    if readingFlag == 1
        r = sscanf(f06Line,'%f %s %f %f %f %f %f %f');
        if length(r) == 8
            GID(modeNo, ii) = r(1);         
            T1(modeNo, ii)  = r(3);
            T2(modeNo, ii)  = r(4);
            T3(modeNo, ii)  = r(5);
            T4(modeNo, ii)  = r(6);
            T5(modeNo, ii)  = r(7);
            T6(modeNo, ii)  = r(8);
            ii = ii + 1;
        end

        if ~isempty(strfind(f06Line,sprintf('MODE NUMBER =        %i', modeNo + 1))) || ...  % single digit
           ~isempty(strfind(f06Line,sprintf('MODE NUMBER =       %i', modeNo + 1)))          % double digit
            modeNo = modeNo + 1;    % increase mode counter
            ii = 1;                 % reset grid point counter
        elseif ~isempty(strfind(f06Line , 'E L E M E N T   S T R A I N   E N E R G I E S')) || ...
                ~isempty(strfind(f06Line, '* * * *  A N A L Y S I S  S U M M A R Y  T A B L E  * * * *')) 
            break
        end
    end
end

fclose(resFile);

% format output structure
GridPointKineticEnergy.GID = GID; % grid point ID
GridPointKineticEnergy.T1  = T1;  % kinetic energy in DOF1 (x)
GridPointKineticEnergy.T2  = T2;  % kinetic energy in DOF2 (y)
GridPointKineticEnergy.T3  = T3;  % kinetic energy in DOF3 (z) 
GridPointKineticEnergy.T4  = T4;  % kinetic energy in DOF4 (theta_x)
GridPointKineticEnergy.T5  = T5;  % kinetic energy in DOF5 (theta_y)
GridPointKineticEnergy.T6  = T6;  % kinetic energy in DOF6 (theta_z)

end
