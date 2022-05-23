classdef FREQ1 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SID;
        F1;
        DF;
        NDF=1;
    end
    
    methods
        function obj = FREQ1(SID,F1,DF,NDF)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            obj.SID = SID;
            obj.F1 = F1;
            obj.DF = DF;
            if exist('NDF','var')
                obj.NDF = NDF;
            end
            obj.Name = 'FREQ1';
            
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.SID},{obj.F1},{obj.DF},{obj.NDF}];
            format = 'irri';
            obj.fprint_nas(fid,format,data);
        end
    end
end

