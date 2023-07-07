classdef AEFACT < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SID;
        VALUES;
    end
    
    methods
        function obj = AEFACT(SID,VALUES)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            obj.SID = SID;
            obj.VALUES = VALUES;
            obj.Name = 'AEFACT';
            
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.SID}];
            format = 'i';
            for i = 1: length(obj.VALUES)
                data(end+1) = {obj.VALUES(i)};
                format(end+1) = 'f';        
            end
            obj.fprint_nas(fid,format,data);
        end
    end
end

