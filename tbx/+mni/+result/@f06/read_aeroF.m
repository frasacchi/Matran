function [ aeroF ] = read_aeroF( obj )
%READ_F06_AEROF : Reads the aerodynamic forces from the .f06 file with the 
%name 'filename' which is located in 'dir_out'
%
%   - May need to tweek the function to check for different strings 
%     depending on the analysis that has been requested
%
%   # V1 : 1849_12/08/2016 
%

FID = fopen(obj.filepath,'r');
readingFlag = 0;
ii = 1;    

while feof(FID) ~= 1
    f06Line = fgets(FID);
    
    if readingFlag == 0
        if contains(f06Line,'AERODYNAMIC FORCES ON THE AERODYNAMIC ELEMENTS')
            readingFlag = 1;
        end
    end
    
    if readingFlag == 1
        r = sscanf(f06Line,'%d %d %2s %f %f %f %f %f %f');
        if length(r) == 10
            aeroGrp(ii) = r(1);
            PanelID(ii) = r(2);
            Label{ii}   = char([r(3),r(4)]);
            aeroFx(ii)  = r(5);
            aeroFy(ii)  = r(6);
            aeroFz(ii)  = r(7);
            aeroMx(ii)  = r(8);
            aeroMy(ii)  = r(9);
            aeroMz(ii)  = r(10);
            ii = ii + 1;
        end
        % there can be multiple sets of aero panels (multiple segments) so
        % this term will keep the code looping through all of the segments
        if contains(f06Line,'*** LABEL NOTATIONS:  LS = LIFTING SURFACE,   ZIB = Z INTERFERENCE BODY ELEMENT,  ZSB = Z SLENDER BODY ELEMENT,')
            readingFlag = 0;            
        end
    end
    
    % premature terminating statement : The aero forces follow the
    % aerodynamic pressures, therefore if this line is found all of the
    % aerodynamic pressures must have been found!
    if contains(f06Line,'S T R U C T U R A L   M O N I T O R   P O I N T   I N T E G R A T E D   L O A D S')
        break
    end
    
end

fclose(FID);

% format output structure
aeroF.aeroGrp   = aeroGrp;
aeroF.PanelID   = PanelID;
aeroF.Label{ii} = Label;
aeroF.aeroFx    = aeroFx;
aeroF.aeroFy    = aeroFy;
aeroF.aeroFz    = aeroFz;
aeroF.aeroMx    = aeroMx;
aeroF.aeroMy    = aeroMy;
aeroF.aeroMz    = aeroMz;

end

