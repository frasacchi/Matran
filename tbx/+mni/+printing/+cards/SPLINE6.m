classdef SPLINE6 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        EID;
        CAERO;
        AELIST;
        SETG;
        DZ;
        DZR;
        METH;
        USAGE;
        I2VNUM;
        D2VNUM;
        METHCON;
        NGRID;
        AUGWEI;
        METHVS;
        ELTOL;
        NCYCLE;
    end
    
    methods
        function obj = SPLINE6(EID,CAERO,AELIST,SETG,varargin)
            %GRID_CARD Construct an instance of this class
            %   Detailed explanation goes here
            p = inputParser();
            p.addRequired('EID',@(x)x>0)
            p.addRequired('CAERO',@(x)x>0)
            p.addRequired('AELIST',@(x)x>0)
            p.addRequired('SETG',@(x)x>0)
            p.addParameter('DZ',[],@(x)x>=0)
            p.addParameter('DZR',[],@(x)x>=0)
            p.addParameter('AUGWEI',[],@(x)x>=0)
            p.addParameter('I2VNUM',[],@(x)x>0)
            p.addParameter('D2VNUM',[],@(x)x>0)
            p.addParameter('METHCON',[],@(x)any(validatestring(x,...
                {'NODEPROX','CIRCBIAS'})))
            p.addParameter('METHVS',[],@(x)any(validatestring(x,...
                {'VS3','VS6'})))
            p.addParameter('NGRID',[],@(x)x>0)
            p.addParameter('METH','',@(x)any(validatestring(x,...
                {'FPS6','FPS3'})))
            p.addParameter('USAGE',[],@(x)any(validatestring(x,...
                {'FORCE','DISP','BOTH'})))
            p.addParameter('ELTOL',[],@(x)x>0)
            p.addParameter('NCYCLE',[],@(x)x>0)
            p.parse(EID,CAERO,AELIST,SETG,varargin{:})
            
            obj.Name = 'SPLINE6';
            obj.EID = p.Results.EID;
            obj.CAERO = p.Results.CAERO;
            obj.AELIST = p.Results.AELIST;
            obj.SETG = p.Results.SETG;
            obj.DZ = p.Results.DZ;
            obj.METH = p.Results.METH;
            obj.USAGE = p.Results.USAGE;
            obj.I2VNUM = p.Results.I2VNUM;
            obj.D2VNUM = p.Results.D2VNUM; 
            obj.DZR = p.Results.DZR;
            obj.METHCON = p.Results.METHCON;
            obj.NGRID = p.Results.NGRID;
            obj.AUGWEI = p.Results.AUGWEI;
            obj.METHVS = p.Results.METHVS;
            obj.ELTOL = p.Results.ELTOL;
            obj.NCYCLE = p.Results.NCYCLE;
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.EID},{obj.CAERO},{obj.AELIST},...
                {obj.SETG},{obj.DZ},{obj.METH},{obj.USAGE},{obj.I2VNUM},{obj.D2VNUM},...
                {obj.METHVS},{obj.DZR},{obj.METHCON},{obj.NGRID},{obj.ELTOL},{obj.NCYCLE},{obj.AUGWEI}];
            format = 'iiibifssbbiisrsirir';
            obj.fprint_nas(fid,format,data);
        end
    end
end

