classdef AEROS < mni.printing.cards.BaseCard
    %AERO Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ACSID;
        RCSID;
        REFC;
        REFB;
        REFS;
        SYMXZ;
        SYMXY;
    end
    
    methods
        function obj = AEROS(REFC,REFB,REFS,varargin)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            p = inputParser;
            p.addRequired('REFC',@(x)x>0)
            p.addRequired('REFB',@(x)x>0)
            p.addRequired('REFS',@(x)x>0)
            p.addParameter('ACSID','',@(x)isempty(x)||x>=0)
            p.addParameter('RCSID','',@(x)x>=0)
            p.addParameter('SYMXZ','',@(x)any(x==[-1,0,1]))
            p.addParameter('SYMXY','',@(x)any(x==[-1,0,1]))
            
            p.parse(REFC,REFB,REFS,varargin{:})
            
            for name = string(p.Parameters)
                obj.(name) = p.Results.(name);
            end
            obj.Name = 'AEROS';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.ACSID},{obj.RCSID},{obj.REFC},...
                {obj.REFB},{obj.REFS},{obj.SYMXZ},{obj.SYMXY}];
            format = 'iirrrii';
            obj.fprint_nas(fid,format,data);
        end
    end
end

