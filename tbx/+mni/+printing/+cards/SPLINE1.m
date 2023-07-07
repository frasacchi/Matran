classdef SPLINE1 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        EID;
        CAERO;
        BOX1;
        BOX2;
        SETG;
        DZ;
        METH;
        USAGE;
        NELEM;
        MELEM;
    end
    
    methods
        function obj = SPLINE1(EID,varargin)
            %GRID_CARD Construct an instance of this class
            %   Detailed explanation goes here
            p = inputParser();
            p.addRequired('EID',@(x)x>0)
            p.addParameter('CAERO',[],@(x)x>0)
            p.addParameter('BOX1',[],@(x)x>0)
            p.addParameter('BOX2',[],@(x)x>0)
            p.addParameter('SETG',[],@(x)x>0)
            p.addParameter('DZ',[],@(x)x>=0)
            p.addParameter('METH',[],@(x)any(validatestring(x,...
                {'IPS','TPS','FPS','RIS'})))
            p.addParameter('USAGE',[],@(x)any(validatestring(x,...
                {'FORCE','DISP','BOTH'})))
            p.addParameter('NELEM',[],@(x)x>0)
            p.addParameter('MELEM',[],@(x)x>0)
            p.parse(EID,varargin{:})
            
            obj.Name = 'SPLINE1';
            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end  
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.EID},{obj.CAERO},{obj.BOX1},{obj.BOX2}...
                {obj.SETG},{obj.DZ},{obj.METH},{obj.USAGE},...
                {obj.NELEM},{obj.MELEM}];
            format = 'iiiiirssii';
            obj.fprint_nas(fid,format,data);
        end
    end
end

