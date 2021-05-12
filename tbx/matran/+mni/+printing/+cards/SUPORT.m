classdef SUPORT < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        IDs;
        Ci;
    end
    
    methods
        function obj = SUPORT(IDs,Ci)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            if length(IDs)~=length(Ci)
                error('IDs and componet vectors must be the same length (see quick reference guide)')
            end
            obj.IDs = IDs;
            obj.Ci = Ci;
            obj.Name = 'SUPORT';
            
        end
        
        function writeToFile(obj,fid)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            data = [];
            format = '';
            for i = 1: length(obj.IDs)
                data = [data,{obj.IDs(i)},{obj.Ci(i)}];
                format = [format,'ii'];        
            end
            obj.fprint_nas(fid,format,data);
        end
    end
end

