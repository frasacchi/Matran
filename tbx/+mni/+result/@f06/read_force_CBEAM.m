function [ force ] = read_force_CBEAM(obj)
%READ_F06_FORCE_CBEAM : Reads the element forces from the .f06 file with the
%name 'filename' which is located in 'dir_out'
%
%   - May need to tweek the function to check for different strings 
%     depending on the analysis that has been requested
%   - Valid only for models using CBEAM elements
%
%   # V1 : 1130_27/09/2016 
%

resFile = fopen(obj.filepath,'r');
readingFlag = 0;
ii = 1;     jj = 1;

while feof(resFile) ~= 1
    f06Line = fgets(resFile);
    
    if readingFlag == 0
        if ~isempty(strfind(f06Line,'F O R C E S   I N   B E A M   E L E M E N T S        ( C B E A M )'))
            readingFlag = 1;
        end
    end
    
    if readingFlag == 1
        r = sscanf(f06Line,'%i %f %f %f %f %f %f %f %f');
        if length(r) == 2
            EID(jj:jj+1) = [r(2),r(2)];
            jj = jj + 2;
        elseif length(r) == 9
            GID(ii) = r(1);
            x_L(ii) = r(2);
            BM_P1(ii) = r(3);
            BM_P2(ii) = r(4);
            SF_P1(ii) = r(5);
            SF_P2(ii) = r(6);
            AxF(ii)   = r(7);
            Tor(ii)   = r(8);
            WTor(ii)  = r(9);   % WARPING TORQUE
            ii = ii + 1;
        end
        if ~isempty(strfind(f06Line,'S T R A I N S    I N   B E A M   E L E M E N T S        ( C B E A M )'))
            break
        end
    end
end

fclose(resFile);

% format output structure
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