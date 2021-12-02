classdef COMMENT < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        comment;
    end
    
    methods
        function obj = COMMENT(comment)
            %GRID_CARD Construct an instance of this class
            %   Detailed explanation goes here
            obj.comment = comment;         
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            mni.printing.bdf.writeComment(obj.comment,fid)
        end
    end
end

