function ElementStrainEnergy = read_f06_element_strain_energy(dir_out, filename)
%read_f06_element_strain_energy : Reads the element strain energy from the 
%.f06 file with the name 'filename' which is located in 'dir_out'
%
% Inputs :
%   - 'dir_out'  : Folder path of the folder containing the .f06 file
%   - 'filename' : Name of the .f06 file (without file extension)
%
% Outputs :
%   - 'ElementStrainEnergy' : Structure containg all of the modeshape data. 
%                             Fields include:
%                               + ID            : element ID
%                               + strainEnergy  : displacements in X
%                               + percOfTotal   : displacements in Y
%                               + energyDensity : displacements in Z
% -------------------------------------------------------------------------
%
%   - May need to tweek the function to check for different strings 
%     depending on the analysis that has been requested
%
%   # V1 : 1630_16/03/2017 
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
        if ~isempty(strfind(f06Line,'E L E M E N T   S T R A I N   E N E R G I E S'));
            readingFlag = 1;
        end
    end
    
    % find table containing strain energy
    if readingFlag == 1
        r = sscanf(f06Line,'%d %f %f %f');
        if length(r) == 4
            ID(modeNo, ii)            = r(1);         
            strainEnergy(modeNo, ii)  = r(2);
            percOfTotal(modeNo, ii)   = r(3);
            energyDensity(modeNo, ii) = r(4);
            ii = ii + 1;
        end
        
        if ~isempty(strfind(f06Line,sprintf('MODE               %i', modeNo + 1))) || ...  % single digit
           ~isempty(strfind(f06Line,sprintf('MODE              %i', modeNo + 1)))          % double digit
            modeNo = modeNo + 1;    % increase mode counter
            ii = 1;                 % reset grid point counter
        elseif ~isempty(strfind(f06Line,'G R I D   P O I N T   K I N E T I C   E N E R G Y   (  P E R C E N T  )')) || ...
                ~isempty(strfind(f06Line,'* * * *  A N A L Y S I S  S U M M A R Y  T A B L E  * * * *')) 
            break
        end
    end
end

fclose(resFile);

% format output structure
ElementStrainEnergy.ID            = ID;            % element ID
ElementStrainEnergy.strainEnergy  = strainEnergy;  % element strain energy
ElementStrainEnergy.percOfTotal   = percOfTotal;   % percentage of total strain energy in mode
ElementStrainEnergy.energyDensity = energyDensity; % density of the strain energy

end
