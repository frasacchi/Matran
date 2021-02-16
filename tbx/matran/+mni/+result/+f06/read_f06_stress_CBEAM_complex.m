function [ stress, freq ] = read_f06_stress_CBEAM_complex(dir_out, filename)
%READ_F06_STRESS_CBEAM_COMPLEX: Reads the element stresses from the .f06 
%file with then name 'filename' which is located in 'dir_out'
%
%   - Searches .f06 file line-by-line until it finds a set of results
%           -> Reads the frequency at which the results have been generated
%           -> Reads element stresses (real and complex) for all elements            
%   
%   - Finds the next set of results and repeats the process
%
%   - Continues to scan the .f06 file until the terminating string has been
%     found
%           -> May need to tweek the terminating string depending on what
%              other results have been requested
%
%
%   # V1 : 2219_31/10/2016
%

resFile = fopen([dir_out filename '.f06'],'r');
readingFlag = 0;

% counters
ii     = 1; % grid point counter
jj     = 1; % element counter
dataNo = 1;

while feof(resFile) ~= 1
    f06Line = fgets(resFile);
    
    if readingFlag == 0
        if ~isempty(strfind(f06Line,'C O M P L E X   S T R E S S E S   I N   B E A M   E L E M E N T S   ( C B E A M )'))
            freq(dataNo) = extract_number_from_string(f06Line_prev);
            readingFlag = 1;
        end
    end
    
    if readingFlag == 1
        [str,count] = sscanf(f06Line,'%i %i %f %f %f %f %f %f %f %f');
        if count == 2
            real.EID{dataNo}(jj:jj+1) = [str(2),str(2)]; % element ID
            jj = jj + 2;
        elseif count == 7
            real.GID{dataNo}(ii) = str(2);      % grid point ID
            real.x_L{dataNo}(ii) = str(3);      % distance along beam element of intermediate point
            real.DirectStress_C{dataNo}(ii) = str(4);    % direct stress at stress recovery position C
            real.DirectStress_D{dataNo}(ii) = str(5);    % direct stress at stress recovery position D
            real.DirectStress_E{dataNo}(ii) = str(6);    % direct stress at stress recovery position E
            real.DirectStress_F{dataNo}(ii) = str(7);    % direct stress at stress recovery position F
            ii = ii + 1;
        else
            [str,count] = sscanf(f06Line,'%f %f %f %f %f %f %f');
            if count == 4
                complex.EID{dataNo}(jj-2:jj-1) = real.EID{dataNo}(jj-2:jj-1);
                complex.GID{dataNo}(ii-1) = real.GID{dataNo}(ii-1);      % grid point ID
                complex.x_L{dataNo}(ii-1) = real.x_L{dataNo}(ii-1);      % distance along beam element of intermediate point
                complex.DirectStress_C{dataNo}(ii-1) = str(1);    % direct stress at stress recovery position C
                complex.DirectStress_D{dataNo}(ii-1) = str(2);    % direct stress at stress recovery position D
                complex.DirectStress_E{dataNo}(ii-1) = str(3);    % direct stress at stress recovery position E
                complex.DirectStress_F{dataNo}(ii-1) = str(4);    % direct stress at stress recovery position F
            end
        end
        
        if ~isempty(strfind(f06Line,'C O M P L E X   S T R E S S E S   I N   B E A M   E L E M E N T S   ( C B E A M )'))
            freqTemp = extract_number_from_string(f06Line_prev);
            if ~isequal(freq(dataNo),freqTemp)
                dataNo = dataNo + 1;    % increase mode counter
                freq(dataNo) = freqTemp;
                ii = 1;     jj = 1;     % reset element counters
            end
        elseif ~isempty(strfind(f06Line,'* * * *  A N A L Y S I S  S U M M A R Y  T A B L E  * * * *'))
            break
        end
    end
    f06Line_prev = f06Line;
end

fclose(resFile);

% format output structure
stress.real    = real;
stress.complex = complex;

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

