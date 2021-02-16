function [ trimDOFS] = read_f06_trimDOFs( dir_out, filename )
%READ_F06_TRIMDOFS Reads the values of the trim DOFs from the .f06 file 
%with the name 'filename' which is located in 'dir_out'
%
%   - May need to tweek the function to check for different strings 
%     depending on the analysis that has been requested
%
%   # V1 : 1810_12/08/2016 -- THIS FUNCTION COULD BE IMPROVED ALOT, AT THE
%   MOMENT IT DOES THE JOB IT NEEDS TO DO HOWEVER ONCE MORE TRIM VARIABLES
%   ARE ADDED IN THERE MAY BE A MORE ELEGANT WAY OF OBTAINING ALL OF THE
%   TRIM VARIABLES AT ONCE
%

resFile = fopen([dir_out filename '.f06'],'r');
readingFlag = 0;

while feof(resFile) ~= 1
    f06Line = fgets(resFile);   % currrent line
    
    % get angle of attack
    if readingFlag == 0
        if ~isempty(strfind(f06Line,'AEROELASTIC TRIM VARIABLES'))
            readingFlag = 1;
        end
    end
    
    if readingFlag == 1
        if ~isempty(strfind(f06Line,'ANGLEA'))
            % remove spaces
            f06Line(strfind(f06Line,' ')) = [];
            % find AoA (1st number immediately after 'ANGLEOFATTACK')
            Key = 'FREE';  Index = strfind(f06Line,Key);
            AoA   = sscanf(f06Line(Index(1)+length(Key):end),'%g',1); %[rad]            
            break
        end        
    end
    
%     % get angle of attack
%     if ~isempty(strfind(f06Line,'ANGLE OF ATTACK'))        
%         % remove spaces and special characters
%         f06Line(strfind(f06Line,' ')) = [];
%         f06Line(strfind(f06Line,'=')) = [];
%         % find AoA (1st number immediately after 'ANGLEOFATTACK')
%         Key = 'ANGLEOFATTACK';  Index = strfind(f06Line,Key);
%         AoA   = sscanf(f06Line(Index(1)+length(Key):end),'%g',1); %[rad]
%     end
%     
%     % get angle of sideslip
%     if ~isempty(strfind(f06Line,'ANGLE OF SIDESLIP'))        
%         % remove spaces and special characters
%         f06Line(strfind(f06Line,' ')) = [];
%         f06Line(strfind(f06Line,'=')) = [];
%         % find AoA (1st number immediately after 'ANGLEOFATTACK')
%         Key = 'ANGLEOFSIDESLIP';  Index = strfind(f06Line,Key);
%         sideSlip = sscanf(f06Line(Index(1)+length(Key):end),'%g',1); %[rad]
%     end
    
end

fclose(resFile);

% define output structure
trimDOFS.ANGLEA = AoA;  % [rad]

end


