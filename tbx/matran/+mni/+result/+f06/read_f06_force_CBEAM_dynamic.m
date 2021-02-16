function force = read_f06_force_CBEAM_dynamic(dir_out, filename)
%read_f06_force_CBEAM_dynamic : Reads the element forces for every time
%step from the .f06 file with the name 'filename' which is located in
%'dir_out'
%
%   - May need to tweek the function to check for different strings
%     depending on the analysis that has been requested
%   - Valid only for models using CBEAM elements
%
%   # V1 : 1130_27/09/2016
%
% ======================================================================= %

resFile = fopen([dir_out filename '.f06'],'r');
readingFlag = 0;
ii = 0; % data counter
jj = 1; % grid point counter
kk = 1; % element counter

while feof(resFile) ~= 1
    f06Line = fgets(resFile);
    
    % find first grid point ID
    if readingFlag == 0
        if ~isempty(strfind(f06Line, 'ELEMENT-ID ='))
            % extract GID of current grid point
            f06Split = strsplit(f06Line, '=');
            EID(jj) = str2double(f06Split{2});
        end
    end
    
    if readingFlag == 0
        if ~isempty(strfind(f06Line,'F O R C E S   I N   B E A M   E L E M E N T S        ( C B E A M )'))
            readingFlag = 1;
        end
    end
    
    if readingFlag == 1
        % check to see if we have moved onto a new element
        if ~isempty(strfind(f06Line, 'ELEMENT-ID ='))
            f06Split = strsplit(f06Line, '=');
            elementID = str2double(f06Split{2});
            if elementID ~= EID(jj)
                % update flags & counters and return to top of while loop
                readingFlag = 0;
                ii = 1;
                kk = kk + 1;
                jj = jj + 1;
                EID(kk) = elementID;
                continue
            end
        else
            % scan the line looking for the results
            [r, n] = sscanf(f06Line, '%f');
            lineFormat = isstrprop(f06Line, 'alpha');
            if n == 1 && ~any(lineFormat(13:end)) % <-- check if the line contains any letters as well
                % adjust counters
                ii = ii + 1;
                kk = 1;
                % save time to vector
                t(ii) = r;
                if ii > 46001
                    disp('HELP');
                end
            else
                [r, n] = sscanf(f06Line,'%i %f %f %f %f %f %f %f %f');
                if n == 2
                    error('Write code');
                    %             EID(jj:jj+1) = [r(2),r(2)];
                    %             jj = jj + 2;
                elseif n == 9
                    GID(ii  , jj, kk) = r(1);
                    x_L(ii  , jj, kk) = r(2);
                    BM_P1(ii, jj, kk) = r(3);
                    BM_P2(ii, jj, kk) = r(4);
                    SF_P1(ii, jj, kk) = r(5);
                    SF_P2(ii, jj, kk) = r(6);
                    AxF(ii  , jj, kk) = r(7);
                    Tor(ii  , jj, kk) = r(8);
                    WTor(ii , jj, kk) = r(9);   % WARPING TORQUE
                    kk = kk + 1;
                end
            end
            if ~isempty(strfind(f06Line,'S T R A I N S    I N   B E A M   E L E M E N T S        ( C B E A M )')) || ...
                    ~isempty(strfind(f06Line, '* * * *  A N A L Y S I S  S U M M A R Y  T A B L E  * * * *'))
                break
            end
        end
    end
end

fclose(resFile);

% format output structure
force.t     = t;
force.EID   = EID;      % element ID
force.GID   = GID;      % grid point ID
force.x_L   = x_L;      % distance along beam element of intermediate point
force.BM_P1 = BM_P1;    % bending moment
force.BM_P2 = BM_P2;    % bending moment
force.SF_P1 = SF_P1;    % shear force
force.SF_P2 = SF_P2;    % shear force
force.AxF   = AxF;      % axial force
force.Tor   = Tor;      % torque
force.WTor  = WTor;     % warping torque
end