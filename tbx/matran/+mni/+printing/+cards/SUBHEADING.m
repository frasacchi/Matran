classdef SUBHEADING < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        text;
    end
    
    methods
        function obj = SUBHEADING(text)
            %GRID_CARD Construct an instance of this class
            %   Detailed explanation goes here
            obj.text = text;         
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            mni.printing.bdf.writeSubHeading(fid,obj.text)
        end
    end
end

