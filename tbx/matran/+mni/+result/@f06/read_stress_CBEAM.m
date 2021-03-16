function [stress] = read_stress_CBEAM(obj)
%READ_F06_force : Reads the element stresses from the .f06 file with the 
%name 'filename' which is located in 'dir_out'
%
%   - May need to tweek the function to check for different strings 
%     depending on the analysis that has been requested
%   - Valid only for models using CBAR elements
%
%   # V1 : 0930_10/08/2016 
%

resFile = fopen(obj.filepath,'r');
readingFlag = 0;
ii = 1;     jj = 1;

while feof(resFile) ~= 1
    f06Line = fgets(resFile);
    
    if readingFlag == 0
        if ~isempty(strfind(f06Line,'S T R E S S E S   I N   B E A M   E L E M E N T S        ( C B E A M )'))
            readingFlag = 1;
        end
    end
    
    if readingFlag == 1
        r = sscanf(f06Line,'%i %f %f %f %f %f %f %f');
        if length(r) == 2
            EID(jj:jj+1) = [r(2),r(2)];
            jj = jj + 2;
        elseif length(r) == 8
            GID(ii)   = r(1);
            x_L(ii)   = r(2);
            SXC(ii)   = r(3);
            SXD(ii)   = r(4);
            SXE(ii)   = r(5);
            SXF(ii)   = r(6);
            S_MAX(ii) = r(7);
            S_MIN(ii) = r(8);
            ii = ii + 1;
        end
        if ~isempty(strfind(f06Line,'* * * *  A N A L Y S I S  S U M M A R Y  T A B L E  * * * *'))
            break
        end
    end
end

fclose(resFile);

% format output structure
stress.EID   = EID;
stress.GID   = GID;
stress.x_L   = x_L;
stress.SXC   = SXC;
stress.SXD   = SXD;
stress.SXE   = SXE;
stress.SXF   = SXF;
stress.S_MAX = S_MAX;
stress.S_MIN = S_MIN;

end