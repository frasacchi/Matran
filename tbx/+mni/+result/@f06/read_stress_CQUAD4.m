function [stress] = read_stress_CQUAD4(obj)
    %READ_STRESS_CQUAD4 : Reads the CQUAD4 element stresses from the .f06 file 
    %
    %   - Designed to handle the multi-line fiber distance output format
    %   - Extracts data for both centroids ('CEN/4') and corner nodes
    %   - Assumes 'obj.filepath' contains the full path to the .f06 file
    %
    
    resFile = fopen(obj.filepath, 'r');
    if resFile == -1
        error('Cannot open file: %s', obj.filepath);
    end
    
    readingFlag = 0;
    ii = 1;
    
    % Initialize output arrays
    EID_out = [];
    GRID_out = {}; % Cell array because GRID can be 'CEN/4' or a number
    FDIST_out = [];
    SX_out = [];
    SY_out = [];
    TXY_out = [];
    ANG_out = [];
    MAJOR_out = [];
    MINOR_out = [];
    VM_out = [];
    
    % State variables to remember the current Element ID and Grid ID across lines
    current_EID = NaN;
    current_GRID = '';
    
    while feof(resFile) ~= 1
        f06Line = strtrim(fgets(resFile));
        
        % Check for the start of the CQUAD4 stress block
        if readingFlag == 0
            if contains(f06Line, 'S T R E S S E S   I N   Q U A D R I L A T E R A L   E L E M E N T S   ( Q U A D 4 )')
                readingFlag = 1;
            end
            continue;
        end
        
        if readingFlag == 1
            % Stop reading if we hit the Analysis Summary Table (or another section)
            if contains(f06Line, '* * * * A N A L Y S I S  S U M M A R Y  T A B L E  * * * *') || ...
               contains(f06Line, 'S T R E S S E S   I N   T R I A N G U L A R')
                break
            end
            
            % Tokenize the line based on whitespace
            tokens = strsplit(f06Line);
            
            % Filter out empty lines, headers, and page breaks
            if length(tokens) < 8 || any(contains(tokens, {'ELEMENT', 'ID', 'FIBER', 'DISTANCE', 'NORMAL-X', 'PAGE', 'SUBCASE', 'FORCEFIXSTATICRHS'}))
                continue;
            end
            
            % Because Nastran shifts columns when EID or GRID is implied, 
            % the last 8 columns are always consistent: 
            % [FDIST, NORMAL-X, NORMAL-Y, SHEAR-XY, ANGLE, MAJOR, MINOR, VON MISES]
            val_fdist = str2double(tokens{end-7});
            val_sx    = str2double(tokens{end-6});
            val_sy    = str2double(tokens{end-5});
            val_txy   = str2double(tokens{end-4});
            val_ang   = str2double(tokens{end-3});
            val_maj   = str2double(tokens{end-2});
            val_min   = str2double(tokens{end-1});
            val_vm    = str2double(tokens{end});
            
            % Determine EID and GRID based on how many tokens exist on the line
            if length(tokens) == 11
                % Has formatting '0', EID, and GRID (e.g., "0 234647 CEN/4 ...")
                current_EID = str2double(tokens{2});
                current_GRID = tokens{3};
            elseif length(tokens) == 10
                % Has EID and GRID, but missing the leading '0'
                current_EID = str2double(tokens{1});
                current_GRID = tokens{2};
            elseif length(tokens) == 9
                % Has GRID only (e.g., "241379 -3.738893E+00 ...") - uses previous EID
                current_GRID = tokens{1};
            elseif length(tokens) == 8
                % Second fiber line (e.g., "3.738893E+00 -5.576920E+00 ...") 
                % EID and GRID remain the same as the line immediately prior
            end
            
            % Append to output arrays
            EID_out(ii, 1)   = current_EID;
            GRID_out{ii, 1}  = current_GRID;
            FDIST_out(ii, 1) = val_fdist;
            SX_out(ii, 1)    = val_sx;
            SY_out(ii, 1)    = val_sy;
            TXY_out(ii, 1)   = val_txy;
            ANG_out(ii, 1)   = val_ang;
            MAJOR_out(ii, 1) = val_maj;
            MINOR_out(ii, 1) = val_min;
            VM_out(ii, 1)    = val_vm;
            
            ii = ii + 1;
        end
    end
    
    fclose(resFile);
    
    % Format output structure
    stress.EID   = EID_out;
    stress.GRID  = GRID_out;
    stress.FDIST = FDIST_out;
    stress.SX    = SX_out;
    stress.SY    = SY_out;
    stress.TXY   = TXY_out;
    stress.ANGLE = ANG_out;
    stress.MAJOR = MAJOR_out;
    stress.MINOR = MINOR_out;
    stress.VONMISES = VM_out;
    
    end