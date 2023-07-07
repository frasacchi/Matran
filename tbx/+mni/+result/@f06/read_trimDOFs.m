function [ Trim] = read_trimDOFs( obj )
%READ_F06_TRIMDOFS Reads the flutter data from the .f06 file
% Outputs :
%   - 'Data' : Structure containg all of the Trim Data. 
%                    Fields include:
%                       + ID        : Trim ID
%                       + LABEL     : Trim Label (e.g. ANGLEA)
%                       + TYPE      : Either rigid body or control surface
%                       + STATUS    : Free / fixed / locked
%                       + Value     : value
%                       + Units     : string describing units
% -------------------------------------------------------------------------
% Author: Fintan Healy
% Contact: fintan.healy@bristol.ac.uk
% Created: 12/05/2021
% Modified: 12/05/2021
%
% Change Log:
%   - 
% ======================================================================= 
resFile = fopen(obj.filepath,'r');
readingFlag = 0;
Trim = [];
ii = 1;
expr = '(\d+)\s+(\w*\w*)\s+(\w*\w*\s\w*\w*)\s+(\w*\w*)\s+(\S+)\s+(.*)\s*';
while feof(resFile) ~= 1
    f06Line = fgets(resFile);   % currrent line   
    % get trim data
    if readingFlag == 0
        if contains(f06Line,'AEROELASTIC TRIM VARIABLES')
            readingFlag = 1;
        end
    end    
    if readingFlag == 1
        [tok,match] = regexp(f06Line,expr,'tokens','match');
        if ~isempty(match)
            % now we have found a row of the table keep reading until we
            % get the the end of it
            while feof(resFile) ~= 1 && ~isempty(match)
                tok = tok{1};
                Trim(ii).ID = str2double(tok{1});
                Trim(ii).Label = tok{2};
                Trim(ii).Type = tok{3};
                Trim(ii).Status = tok{4};
                Trim(ii).Value = str2double(tok{5});
                Trim(ii).Units = tok{6};
                ii = ii + 1;
                f06Line = fgets(resFile);   % currrent line
                [tok,match] = regexp(f06Line,expr,'tokens','match');
            end
            break
        end     
    end    
end
fclose(resFile);
end


