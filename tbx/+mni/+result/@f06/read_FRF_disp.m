function [ Displacements, freq ]  = read_FRF_disp(obj)
%read_f06_FRF_disp : Reads displacements from the f06 file with the name
%'filename' which is located in 'dir_out'. These results have been
%generated using the Case Control 'FRF' and so only a unit load has been
%applied in 1 DOF at a time, this produces a very large set of results.
%
%   - Searches .f06 file line-by-line until it finds a set of results
%           -> Reads which component is being loaded
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
freqNo = 1;
compNo = 1;
gidNo  = 1;

while feof(resFile) ~= 1
    f06Line = fgets(resFile);
    
    % ... find load GID and component number
    if readingFlag == 0
        if ~isempty(strfind(f06Line, 'UNIT LOAD ON GRID POINT'))
            % extract GID and component number 
             [GID(gidNo), comp(compNo)] = extract_component_and_GID_numbers(f06Line);
        end        
    end
    
    % ... find frequency for this set of results
    if readingFlag == 0
        if ~isempty(strfind(f06Line,'C O M P L E X   D I S P L A C E M E N T   V E C T O R'))
            freq(freqNo) = extract_number_from_string(f06Line_prev);
            readingFlag = 1;
        end
    end
    
    if readingFlag == 1
%         r = sscanf(f06Line,'%d %s %f %f %f %f %f %f');
        [str,count] = sscanf(f06Line,'%d %d %s %f %f %f %f %f %f %d');   % -> in case there is a column of zeros on the LHS
        if count == 9
            real.GP(freqNo, ii, compNo)  = str(2);  %  grid point IDs
            real.dX(freqNo, ii, compNo)  = str(4);  %
            real.dY(freqNo, ii, compNo)  = str(5);  %  deflections in XYZ
            real.dZ(freqNo, ii, compNo)  = str(6);  %
            real.thX(freqNo, ii, compNo) = str(7);  %
            real.thY(freqNo, ii, compNo) = str(8);  %  rotations in XYZ
            real.thZ(freqNo, ii, compNo) = str(9);  %
            ii = ii + 1;
        else
            [str,count] = sscanf(f06Line,'%f %f %f %f %f %f');
            if count == 7
                complex.GP(freqNo, ii - 1, compNo)  = real.GP(freqNo, ii - 1);   % GID is the same as the GP of the real displacments
                complex.dX(freqNo, ii - 1, compNo)  = str(1);  %
                complex.dY(freqNo, ii - 1, compNo)  = str(2);  %  deflections in XYZ
                complex.dZ(freqNo, ii - 1, compNo)  = str(3);  %
                complex.thX(freqNo, ii - 1, compNo) = str(4);  %
                complex.thY(freqNo, ii - 1, compNo) = str(5);  %  rotations in XYZ
                complex.thZ(freqNo, ii - 1, compNo) = str(6);  %
                complex.CID(freqNo, ii - 1, compNo) = str(7);  %  output coord system ID
                real.CID(freqNo   , ii - 1, compNo) = str(7);  %  output coord system ID
            end 
        end
        
        % ... search for next component number
        if ~isempty(strfind(f06Line, 'UNIT LOAD ON GRID POINT'))
            % extract GID and component number 
             [GID(gidNo), compTemp] = extract_component_and_GID_numbers(f06Line);
             if ~isequal(comp(compNo), compTemp)
                 compNo = compNo + 1;
                 comp(compNo) = compTemp;
                 ii = 1;
                 freqNo = 1;
             end
        end        
        
        % ... search for next frequency set
        if ~isempty(strfind(f06Line,'C O M P L E X   D I S P L A C E M E N T   V E C T O R')) 
            freqTemp = extract_number_from_string(f06Line_prev);
            if ~isequal(freq(freqNo),freqTemp)
            freqNo = freqNo + 1;    % increase mode counter
            freq(freqNo) = freqTemp;
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
Displacements.real    = real;    
Displacements.complex = complex;
Displacements.GID     = GID;
Displacements.comp    = comp;

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

function [GID, comp] = extract_component_and_GID_numbers(f06Line)
%extract_component_and_GID_numbers : Extracts the numbers relating to the
%GID that the load is applied to and which component the load is applied
%in. It does this by searching for the key expressions 
%'UNIT LOAD ON GRID POINT' and 'COMPONENT'

% extract GID
[startID, ~]  = regexp(f06Line, '-');
[~, endID]    = regexp(f06Line, 'UNIT LOAD ON GRID POINT');
GIDStr        = f06Line(endID + 1 : startID - 1);
GIDStrNoSpace = strrep(GIDStr,' ','');
GID   = str2double(GIDStrNoSpace);

% extract load component
[~, endID]    = regexp(f06Line, 'COMPONENT ');
compID        = f06Line(endID : endID + 10);
compIDNoSpace = strrep(compID, ' ', '');
comp = str2double(compIDNoSpace);

end

