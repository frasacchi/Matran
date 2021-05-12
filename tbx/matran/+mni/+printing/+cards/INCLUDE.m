classdef INCLUDE < mni.printing.cards.BaseCard
    %INCLUDE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        File;
    end
    
    methods
        function obj = INCLUDE(File)
            %INCLUDE Construct an instance of this class
            %   Detailed explanation goes here        
            obj.File = File;
            obj.Name = 'INCLUDE';
        end
        
        function writeToFile(obj,fid)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            data = [{obj.File}];
            format = 's';
            obj.fprint_nas(fid,format,data);
        end
    end
end

