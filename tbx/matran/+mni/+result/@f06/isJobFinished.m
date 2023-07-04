function res = isJobFinished(obj)
    %CHECK_F06 : Checks if an NASTRAN job is complete in the .f06 file with the name
    %'filename' which is located in 'dir_out'
    %
    %   - Scans through line by line searching for the work
    %   - If '* * * END OF JOB * * *' it throws out a true message
    %
    %   # V1 : 0930_10/08/2016 
    
    % Get file, got file?
    FID = fopen(obj.filepath,'r');
    
    % Get First line of FILENAME
    tline = fgets(FID);
    
    % ---------------------------------------------------------- %
    % While there is a next line to read
    while ischar(tline)    % Identify FATAL error  
        EOJ_ID = strfind(tline,'* * * END OF JOB * * *');          % Search line for end of job
        if EOJ_ID > 0
            fclose(FID);
            res = true;
            return
        end    
        % Get Next line
        tline = fgetl(FID);    
    end
    % Close the file
    fclose(FID);
    res = false;
end