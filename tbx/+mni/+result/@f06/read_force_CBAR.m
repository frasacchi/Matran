function [force] = read_force_CBAR(dir_out, filename)
%READ_F06_force_CBAR : Reads the element forces from the .f06 file with the
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
ii = 1;

% preallocate
EID=[];     AxF=[];     Tor=[];
BM_P1=[];   BM_P2=[];
SF_P1=[];   SF_P2=[];

while feof(resFile) ~= 1
    f06Line = fgets(resFile);
    
    if readingFlag == 0
        if ~isempty(strfind(f06Line,'F O R C E   D I S T R I B U T I O N   I N   B A R   E L E M E N T S          ( C B A R )'))||...
                ~isempty(strfind(f06Line,'F O R C E S   I N   B A R   E L E M E N T S         ( C B A R )'))
            readingFlag = 1;
        end
    end
    
    if readingFlag == 1
        r = sscanf(f06Line,'%d %f %f %f %f %f %f %f');
        if length(r) == 8
            EID(ii) = r(1);
            BM_P1(ii) = r(3);
            BM_P2(ii) = r(4);
            SF_P1(ii) = r(5);
            SF_P2(ii) = r(6);
            AxF(ii) = r(7);
            Tor(ii) = r(8);
            ii = ii + 1;
        elseif length(r) == 10
            r = sscanf(f06Line,'%d %f %f %f %f %f %f %f %f ');
            EID = [EID,r(1),r(1)];
            BM_P1 = [BM_P1,r(2),r(4)];
            BM_P2 = [BM_P2,r(3),r(5)];
            SF_P1 = [SF_P1,r(6),r(6)];
            SF_P2 = [SF_P2,r(7),r(7)];
            AxF = [AxF,r(8),r(8)];
            Tor = [Tor,r(9),r(9)];
        end
        if ~isempty(strfind(f06Line,'S T R A I N   D I S T R I B U T I O N   I N   B A R   E L E M E N T S       ( C B A R )'))|| ...
                ~isempty(strfind(f06Line,'S T R A I N S    I N   B A R   E L E M E N T S          ( C B A R )'))
            break
        end
    end
end

fclose(resFile);

% format output structure
force.EID   = EID;      %   element ID
force.BM_P1 = BM_P1;    %
force.BM_P2 = BM_P2;    %
force.SF_P1 = SF_P1;    %
force.SF_P2 = SF_P2;    %
force.AxF   = AxF;      %
force.Tor   = Tor;      %
end