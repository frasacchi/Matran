classdef FREQ < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SID;
        Fi;
    end
    
    methods
        function obj = FREQ(SID,Fi)
            obj.SID = SID;
            obj.Fi = Fi;
            obj.Name = 'FREQ';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.SID}];
            format = 'i';
            for i = 1:length(obj.Fi)
                data = [data {obj.Fi(i)}];
                format = [format,'r'];
            end
            obj.fprint_nas(fid,format,data);
        end
    end
end

