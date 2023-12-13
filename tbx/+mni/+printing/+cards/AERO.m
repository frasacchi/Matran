classdef AERO < mni.printing.cards.BaseCard
    %AERO Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ACSID;
        VELOCITY;
        REFC;
        RHOREF;
        SYMXZ;
        SYMXY;
    end
    
    methods
        function obj = AERO(REFC,RHOREF,varargin)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            p = inputParser();
            
            p.addRequired('REFC',@(x)x>0)
            p.addRequired('RHOREF',@(x)x>0)
            p.addParameter('ACSID',[],@(x)x>0)
            p.addParameter('VELOCITY',[],@(x)x>=0)
            p.addParameter('SYMXZ',[])
            p.addParameter('SYMXY',[])
            
            p.parse(REFC,RHOREF,varargin{:})
            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end
            obj.Name = 'AERO';
            
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.ACSID},{obj.VELOCITY},{obj.REFC},...
                {obj.RHOREF},{obj.SYMXZ},{obj.SYMXY}];
            format = 'irrrii';
            obj.fprint_nas(fid,format,data);
        end
    end
end

