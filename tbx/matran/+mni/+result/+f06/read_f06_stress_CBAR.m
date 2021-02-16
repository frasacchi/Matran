function [stress] = read_f06_stress_CBAR(dir_out, filename)
%READ_F06_force : Reads the element stresses from the .f06 file with the 
%name 'filename' which is located in 'dir_out'
%
%   - May need to tweek the function to check for different strings 
%     depending on the analysis that has been requested
%   - Valid only for models using CBAR elements
%
%   # V1 : 0930_10/08/2016 
%

resFile = fopen([dir_out filename '.f06'],'r');
readingFlag = 0;
ii = 1;

while feof(resFile) ~= 1
    f06Line = fgets(resFile);
    
    if readingFlag == 0
        if ~isempty(strfind(f06Line,'S T R E S S   D I S T R I B U T I O N   I N   B A R   E L E M E N T S       ( C B A R )'))|| ...
                ~isempty(strfind(f06Line,'S T R E S S E S   I N   B A R   E L E M E N T S          ( C B A R )'))
            readingFlag = 1;
        end
    end
    
    if readingFlag == 1
        if mod(ii,2) == 0
            r = sscanf(f06Line,'%f %f %f %f %f %f %f');
        else
            r = sscanf(f06Line,'%d %d %f %f %f %f %f %f %f');
        end
        if length(r) == 9
            EID(ii)    = r(2);
            SA1(ii)    = r(3);
            SA2(ii)    = r(4);
            SA3(ii)    = r(5);
            SA4(ii)    = r(6);
            AXST(ii)   = r(7);
            SA_MAX(ii) = r(8);
            SA_MIN(ii) = r(9);
            ii = ii + 1;
        elseif length(r) == 6
            EID(ii)    = EID(ii-1);
            SA1(ii)    = r(1);
            SA2(ii)    = r(2);
            SA3(ii)    = r(3);
            SA4(ii)    = r(4);
            AXST(ii)   = AXST(ii-1);
            SA_MAX(ii) = r(5);
            SA_MIN(ii) = r(6);
            ii = ii + 1;
        end
        if ~isempty(strfind(f06Line,'* * * *  A N A L Y S I S  S U M M A R Y  T A B L E  * * * *'))
            break
        end
    end
end

fclose(resFile);


% stress.EID      = EID_st;   %
% stress.E_end    = E_end;    %
% stress.SXC      = SXC;      %
% stress.SXD      = SXD;      %
% stress.SXE      = SXE;      %
% stress.SXF      = SXF;      %
% stress.AxStress = AxSt;     %
% stress.S_max    = S_max;    %
% stress.S_min    = S_min;    %

% format output structure
stress.EID    = EID;
stress.SA1    = SA1;
stress.SA2    = SA2;
stress.SA3    = SA3;
stress.SA4    = SA4;
stress.AXST   = AXST;
stress.SA_MAX = SA_MAX;
stress.SA_MIN = SA_MIN;

end