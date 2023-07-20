classdef hdf5
    %F06 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        filepath;
    end
    
    methods
        function obj = hdf5(filepath)
            %F06 Construct an instance of this class
            %   if filepathhas not been supplied it will open a filedialog
            
            if ~exist('filepath','var')
                [fname, pname, ~] = uigetfile('*.h5',...
                'Select the hdf5 output file from a NASTRAN analysis');   
                filepath = fullfile(pname,fname);
            end
            
            obj.filepath = filepath;
            if ~isfile(filepath)
               error('The specified hdf5 file does not exist: %s',filepath);
            end
        end
    end
end

