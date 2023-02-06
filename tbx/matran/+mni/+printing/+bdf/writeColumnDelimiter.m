function writeColumnDelimiter(fid, fieldType)
arguments
    fid
    fieldType string {mustBeMember(fieldType,["long","short","large", "normal", "8", "16"])} = "short"
end
    %writeColumnDelimiter Writes a string into the file with
    %identifier 'fid' which shows the column width based on the
    %value of 'fieldType'.
    switch fieldType
        case {"long","large", "16"}
            fprintf(fid, '$.1.....2...............3...............4...............5...............6.......\r\n');
        case {"short","normal", "8"}
            fprintf(fid, '$.1.....2.......3.......4.......5.......6.......7.......8.......9.......10......\r\n');
    end
end

