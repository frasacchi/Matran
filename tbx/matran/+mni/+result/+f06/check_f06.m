function check_f06(dir_out,filename)
%CHECK_F06 : Checks for a fatal error in the .f06 file with the name
%'filename' which is located in 'dir_out'
%
%   - Scans through line by line searching for the work 'FATAL'
%   - If 'FATAL' is found it throws out an error message and
%     terminates the invoking matlab function
%
%   # V1 : 0930_10/08/2016 

% Get file, got file?
check = 0;
while check == 0;
    FID = fopen([dir_out filename '.f06'],'r'); if FID > 0 ; check = 1; end
end

% Get First line of FILENAME
tline = fgets(FID);

% ---------------------------------------------------------- %
% While there is a next line to read
while ischar(tline)    % Identify FATAL error
    
    FATAL_ID = strfind(tline,'FATAL');          % Search line for word FATAL
    if FATAL_ID > 0;
        fclose(FID);
        error('*** FATAL ERROR HAS OCCCURED -> TERMINATING SCRIPT ***')
    end
    
    % Get Next line
    tline = fgetl(FID);
    
end

% Close the file
fclose(FID);

end