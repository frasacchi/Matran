function res = isEmpty(obj)
%CHECK_F06 : Checks for a fatal error in the .f06 file with the name
%'filename' which is located in 'dir_out'
%
%   - Scans through line by line searching for the work 'FATAL'
%   - If 'FATAL' is found it throws out an error message and
%     terminates the invoking matlab function
%
%   # V1 : 0930_10/08/2016 

% Get file, got file?
FID = fopen(obj.filepath,'r');
res =  fseek(FID, 1, 'bof') == -1;
fclose(FID);
end