classdef SPC1 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SID;
        C;
        Gi;
    end
    
    methods
        function obj = SPC1(SID,C,Gi)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            obj.SID = SID;
            obj.C = C;
            obj.Gi = Gi;
            obj.Name = 'SPC1';
            
        end
        
        function writeToFile(obj,fid)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            data = [{obj.SID},{obj.C}];
            format = 'ii';
            for i = 1: length(obj.Gi)
                data(end+1) = {obj.Gi(i)};
                format(end+1) = 'i';        
            end
            obj.fprint_nas(fid,format,data);
        end
    end
end

