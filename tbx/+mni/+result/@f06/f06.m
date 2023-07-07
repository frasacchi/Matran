classdef f06
    %F06 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        filepath;
    end
    
    methods
        function obj = f06(filepath)
            %F06 Construct an instance of this class
            %   if filepathhas not been supplied it will open a filedialog
            
            if ~exist('filepath','var')
                [fname, pname, ~] = uigetfile('*.f06',...
                'Select the f06 output file from a NASTRAN analysis');   
                filepath = fullfile(pname,fname);
            end
            
            obj.filepath = filepath;
            if ~isfile(filepath)
               error('Specified F06 file does not exist');
            end
        end
    end
end

