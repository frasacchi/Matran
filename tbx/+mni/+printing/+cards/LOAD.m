classdef LOAD < mni.printing.cards.BaseCard    
    properties
        SID;
        ScaleFactor;
        SIDs;
        Scales;
    end
    
    methods
        function obj = LOAD(SID,ScaleFactor,SIDs,Scales)
            arguments
                SID (1,1) double {mustBeInteger,mustBePositive}
                ScaleFactor (1,1) double {mustBeNumeric,mustBePositive}
                SIDs (:,1) double {mustBeInteger,mustBePositive}
                Scales (:,1) double {mustBeNumeric,mustBePositive}
            end
            if numel(SIDs)~=numel(Scales)
                error('SIDs and Scales must have the same number of elements')
            end            
            obj.SID = SID;
            obj.ScaleFactor = ScaleFactor;
            obj.SIDs = SIDs;
            obj.Scales = Scales;
            obj.Name = 'LOAD';            
        end
        
        function writeToFile(obj,fid,varargin)
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.SID},{obj.ScaleFactor}];
            format = 'ir';
            for i = 1:length(obj.SIDs)
                data = [data,obj.Scales(i),obj.SIDs(i)];
                format = [format,'ri'];
            end
            obj.fprint_nas(fid,format,data);
        end
    end
end

