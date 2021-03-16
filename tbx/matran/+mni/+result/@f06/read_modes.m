function Modes = read_modes(obj)
%read_f06_extract_modes : Reads the mode data from the .f06 file with the
%name 'filename' which is located in 'dir_out'
%
% Inputs :
%   - 'dir_out'  : Folder path of the folder containing the .f06 file
%   - 'filename' : Name of the .f06 file (without file extension)
%
% Outputs :
%   - 'Modes' : Structure containg all of the mode data. Fields include:
%                   + Mode       : Mode Number
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

Modes = [];
resFile = fopen(obj.filepath,'r');
readingFlag = 0;
ii = 1;

while feof(resFile) ~= 1
    f06Line = fgets(resFile);
    
    if readingFlag == 0
        if contains(f06Line,'R E A L   E I G E N V A L U E S')
            readingFlag = 1;
        end
    end
    
    if readingFlag == 1
        r = sscanf(f06Line,'%d %d %f %f %f %f %f');
        if length(r) == 7
            Modes(ii).Mode        = r(1);
            Modes(ii).order         = r(2);
            Modes(ii).eigenvalue    = r(3);
            Modes(ii).radians       = r(4);
            Modes(ii).cycles        = r(5);
            Modes(ii).gen_mass      = r(6);
            Modes(ii).gen_stiff     = r(7);
            ii = ii + 1;
        end
        if contains(f06Line,'R E A L   E I G E N V E C T O R   N O .          1')             
            break
        end
    end
end

fclose(resFile);
end
