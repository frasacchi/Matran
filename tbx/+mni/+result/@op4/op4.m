classdef op4
    %OP4 Summary of this class goes here
    %   Detailed explanation goes here   
    properties
        filepath;
    end
    
    methods
        function obj = op4(filepath)
            %OP4 Construct an instance of this class
            %   if filepathhas not been supplied it will open a filedialog
            
            if ~exist('filepath','var')
                [fname, pname, ~] = uigetfile('*.op4',...
                'Select the op4 output file from a NASTRAN analysis');   
                filepath = fullfile(pname,fname);
            end
            
            obj.filepath = filepath;
            if ~isfile(filepath)
               error('The specified op4 file does not exist: %s',filepath);
            end
        end
    end
end

