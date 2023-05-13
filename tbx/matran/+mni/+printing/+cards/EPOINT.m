classdef EPOINT < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        IDs;
    end
    
    methods
        function obj = EPOINT(IDs)
            arguments
                IDs;
            end
            obj.IDs = IDs;
            obj.Name = 'EPOINT';            
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            cols = ceil(length(obj.IDs)/8);
            for i = 1:cols
                idx = ((i-1)*8+1):min(i*8,length(obj.IDs));
                data = [{obj.IDs(idx(1))}];
                format = 'i';
                for j = 2:length(idx)
                    data = [data,{obj.IDs(idx(j))}];
                    format = [format,'i'];
                end
                obj.fprint_nas(fid,format,data);
            end
        end
    end
end

