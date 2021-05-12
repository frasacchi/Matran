classdef RBE2 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        EID;
        GN;
        CM;
        GMi;
        Alpha;
    end
    
    methods
        function obj = RBE2(EID,GN,CM,GMi,varargin)
            %GRID_CARD Construct an instance of this class
            %   Detailed explanation goes here
            p = inputParser();
            p.addRequired('EID',@(x)x>0)
            p.addRequired('GN',@(x)x>0)
            p.addRequired('CM')
            p.addRequired('GMi',@(x)~any(x<=0))
            p.addParameter('Alpha','')
            p.parse(EID,GN,CM,GMi,varargin{:})
            
            obj.Name = 'RBE2';
            obj.EID = p.Results.EID;
            obj.GN = p.Results.GN;
            obj.CM = p.Results.CM;
            obj.GMi = p.Results.GMi;
            obj.Alpha = p.Results.Alpha;           
        end
        
        function writeToFile(obj,fid)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            data = [{obj.EID},{obj.GN},{obj.CM}];
            format = 'iii';
            for i = 1:length(obj.GMi)
                data = [data,{obj.GMi(i)}];
                format = [format,'i'];
            end
            data = [data,{obj.Alpha}];
            format = [format,'r'];
            
            obj.fprint_nas(fid,format,data);
        end
    end
end

