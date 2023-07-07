classdef SPLINE7 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        EID;
        CAERO;
        AELIST;
        SETG;
        DZ;
        DTOR;
        CID;
        USAGE;
        METHOD;
        DZR;
        IA2;
        EPSBM;
    end
    
    methods
        function obj = SPLINE7(EID,CAERO,AELIST,SETG,CID,varargin)
            %GRID_CARD Construct an instance of this class
            %   Detailed explanation goes here
            p = inputParser();
            p.addRequired('EID',@(x)x>0)
            p.addRequired('CAERO',@(x)x>0)
            p.addRequired('AELIST',@(x)x>0)
            p.addRequired('SETG',@(x)x>0)
            p.addRequired('CID',@(x)x>=0)
            p.addParameter('DZ',[],@(x)x>=0)
            p.addParameter('DTOR',[],@(x)x>=0)
            p.addParameter('METHOD','',@(x)any(validatestring(x,...
                {'FBS6','FBS3'})))
            p.addParameter('DZR',[],@(x)x>=0)
            p.addParameter('IA2',[],@(x)x>0)
            p.addParameter('USAGE',[],@(x)any(validatestring(x,...
                {'FORCE','DISP','BOTH'})))
            p.addParameter('EPSBM',[],@(x)x>0)
            p.parse(EID,CAERO,AELIST,SETG,CID,varargin{:})
            
            obj.Name = 'SPLINE7';
            obj.EID = p.Results.EID;
            obj.CAERO = p.Results.CAERO;
            obj.AELIST = p.Results.AELIST;
            obj.SETG = p.Results.SETG;
            obj.CID = p.Results.CID;
            obj.DZ = p.Results.DZ;
            obj.DTOR = p.Results.DTOR;
            obj.METHOD = p.Results.METHOD;
            obj.DZR = p.Results.DZR;
            obj.IA2 = p.Results.IA2;
            obj.USAGE = p.Results.USAGE;
            obj.EPSBM = p.Results.EPSBM;
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.EID},{obj.CAERO},{obj.AELIST},...
                {obj.SETG},{obj.DZ},{obj.DTOR},{obj.CID},{obj.USAGE},...
                {obj.METHOD},{obj.DZR},{obj.IA2},{obj.EPSBM}];
            format = 'iiibirribbbssrrr';
            obj.fprint_nas(fid,format,data);
        end
    end
end

