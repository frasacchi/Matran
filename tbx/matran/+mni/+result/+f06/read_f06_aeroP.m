function [ aeroP ] = read_f06_aeroP( dir_out, filename )
%READ_F06_AEROP : Reads the aerodynamic pressures from the .f06 file with
%the name 'filename' which is located in 'dir_out'
%
%   - May need to tweek the function to check for different strings
%     depending on the analysis that has been requested
%
%   # V1 : 1840_12/08/2016
%

resFile = fopen([dir_out filename '.f06'],'r');
readingFlag = 0;
ii = 1;    

while feof(resFile) ~= 1
    f06Line = fgets(resFile);
    
    if readingFlag == 0
        if ~isempty(strfind(f06Line,'AERODYNAMIC PRESSURES ON THE AERODYNAMIC ELEMENTS'))
            readingFlag = 1;
        end
    end
    
    if readingFlag == 1
        r = sscanf(f06Line,'%d %2s %f %f');
        if length(r) == 5
            PanelID(ii) = r(1);
            Label{ii}   = char([r(2),r(3)]);
            Cp(ii)      = r(4);
            AP(ii)      = r(5);
            ii = ii + 1;
        end
        % there can be multiple sets of aero panels (multiple segments) so
        % this term will keep the code looping through all of the segments
        if ~isempty(strfind(f06Line,'*** LABEL NOTATIONS:  LS = LIFTING SURFACE,   ZIB = Z INTERFERENCE BODY ELEMENT,  ZSB = Z SLENDER BODY ELEMENT,'))
            readingFlag = 0;            
        end
    end
    
    % premature terminating statement : The aero forces follow the
    % aerodynamic pressures, therefore if this line is found all of the
    % aerodynamic pressures must have been found!
    if ~isempty(strfind(f06Line,'AERODYNAMIC FORCES ON THE AERODYNAMIC ELEMENTS'))
        break
    end
    
end

fclose(resFile);

% format output structure
aeroP.PanelID = PanelID;
aeroP.Label   = Label;
aeroP.Cp      = Cp;
aeroP.AP      = AP;

end

