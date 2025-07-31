function [ displacements, freq ] = read_disp_complex(obj)
%READ_F06_DISP_COMPLEX : Reads the complex displacements from the .f06 file
%with the name 'filename' which is located in 'dir_out'
%
%   - Searches .f06 file line-by-line until it finds a set of results
%           -> Reads the frequency at which the results have been generated
%           -> Reads displacements (real and complex) for all grid points             
%   
%   - Finds the next set of results and repeats the process
%
%   - Continues to scan the .f06 file until the terminating string has been
%     found
%           -> May need to tweek the terminating string depending on what
%              other results have been requested
%
%
%   # V1 : 2055_31/10/2016
%

resFile = fopen(obj.filepath,'r');
readingFlag = 0;

% counters
ii     = 1;
dataNo = 1;

while feof(resFile) ~= 1
    f06Line = fgets(resFile);
    
   if readingFlag == 0
%         if ~isempty(strfind(f06Line,'FREQUENCY ='))
        if ~isempty(strfind(f06Line,'C O M P L E X   D I S P L A C E M E N T   V E C T O R'))
            freq(dataNo) = extract_number_from_string(f06Line_prev);
            readingFlag = 1;
        end
    end
    
    if readingFlag == 1
%         r = sscanf(f06Line,'%d %s %f %f %f %f %f %f');
        [str,count] = sscanf(f06Line,'%d %d %s %f %f %f %f %f %f %d');   % -> in case there is a column of zeros on the LHS
        if count == 9
            real.GP(dataNo, ii)  = str(2);  %  grid point IDs
            real.dX(dataNo, ii)  = str(4);  %
            real.dY(dataNo, ii)  = str(5);  %  deflections in XYZ
            real.dZ(dataNo, ii)  = str(6);  %
            real.thX(dataNo, ii) = str(7);  %
            real.thY(dataNo, ii) = str(8);  %  rotations in XYZ
            real.thZ(dataNo, ii) = str(9);  %
            ii = ii + 1;
        else
            [str,count] = sscanf(f06Line,'%f %f %f %f %f %f');
            if count == 6
                complex.GP(dataNo, ii - 1)  = real.GP(dataNo, ii - 1);   % GID is the same as the GP of the real displacments
                complex.dX(dataNo, ii - 1)  = str(1);  %
                complex.dY(dataNo, ii - 1)  = str(2);  %  deflections in XYZ
                complex.dZ(dataNo, ii - 1)  = str(3);  %
                complex.thX(dataNo, ii - 1) = str(4);  %
                complex.thY(dataNo, ii - 1) = str(5);  %  rotations in XYZ
                complex.thZ(dataNo, ii - 1) = str(6);  %
            end 
        end
        
        if ~isempty(strfind(f06Line,'C O M P L E X   D I S P L A C E M E N T   V E C T O R')) 
            freqTemp = extract_number_from_string(f06Line_prev);
            if ~isequal(freq(dataNo),freqTemp)
            dataNo = dataNo + 1;    % increase mode counter
            freq(dataNo) = freqTemp;
            ii = 1;
            end
        elseif ~isempty(strfind(f06Line,'G R I D   P O I N T   K I N E T I C   E N E R G Y   (  P E R C E N T  )')) || ...
                ~isempty(strfind(f06Line,'* * * *  A N A L Y S I S  S U M M A R Y  T A B L E  * * * *')) 
            break
        end
    end
    f06Line_prev = f06Line;
end

fclose(resFile);

% check if there are any complex components to the results 
%(i.e. damping present)
if ~exist('complex', 'var')
    complex = struct();
end

% format output structure
displacements.real    = real;    
displacements.complex = complex;

end

% ... local functions
function number = extract_number_from_string(oldStr)
%EXTRACT_NUM_FROM_STRING : Extracts a number from a string, will only work
%for a very specific string format.
%
%   - Example: oldStr = 'FREQUENCY = 6.750000E+00'
%       -> This function will remove the 'FREQUENCY = ' string using sttrep
%       -> It will  then search for any blank spaces and remove them
%       -> Finally, it will use 'str2double' to convert char to a numeric

newStr = strrep(oldStr,'FREQUENCY = ','');
newStrNoSpace = strrep(newStr,' ','');
number = str2double(newStrNoSpace);

end



