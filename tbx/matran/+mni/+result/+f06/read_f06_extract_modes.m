function Modes = read_f06_extract_modes(dir_out, filename)
%read_f06_extract_modes : Reads the mode data from the .f06 file with the
%name 'filename' which is located in 'dir_out'
%
% Inputs :
%   - 'dir_out'  : Folder path of the folder containing the .f06 file
%   - 'filename' : Name of the .f06 file (without file extension)
%
% Outputs :
%   - 'Modes' : Structure containg all of the mode data. Fields include:
%                   + modeNo     : mode number
%                   + order      : order of extraction
%                   + eigenvalue : eigen value
%                   + radians    : circular frequency [rad/s] --> sqrt(eig)
%                   + cycles     : frequency [Hz] --> w/(2*pi)
%                   + gen_mass   : modal mass
%                   + gen_stiff  : modal stiffness
% -------------------------------------------------------------------------
%
%   - May need to tweek the function to check for different strings 
%     depending on the analysis that has been requested
%
%   # V1 : 1200_10/10/2016 
%
% ======================================================================= %

resFile = fopen([dir_out filename '.f06'],'r');
readingFlag = 0;
ii = 1;

while feof(resFile) ~= 1
    f06Line = fgets(resFile);
    
    if readingFlag == 0
        if ~isempty(strfind(f06Line,'R E A L   E I G E N V A L U E S'))
            readingFlag = 1;
        end
    end
    
    if readingFlag == 1
        r = sscanf(f06Line,'%d %d %f %f %f %f %f');
        if length(r) == 7
            modeNo(ii)     = r(1);
            order(ii)      = r(2);
            eigenvalue(ii) = r(3);
            radians(ii)    = r(4);
            cycles(ii)     = r(5);
            gen_mass(ii)   = r(6);
            gen_stiff(ii)  = r(7);
            ii = ii + 1;
        end
        if ~isempty(strfind(f06Line,'R E A L   E I G E N V E C T O R   N O .          1'))                
            break
        end
    end
end

fclose(resFile);

% format output structure
Modes.modeNo     = modeNo;      % mode number
Modes.order      = order;       % extraction order
Modes.eigenvalue = eigenvalue;  % deflections in XYZ
Modes.radians    = radians;     % circular frequency [rad/s] -- > sqrt(eig)
Modes.cycles     = cycles;      % frequency [Hz] --> w/2*pi
Modes.gen_mass   = gen_mass;    % modal mass
Modes.gen_stiff  = gen_stiff;   % modal stiffness
end
