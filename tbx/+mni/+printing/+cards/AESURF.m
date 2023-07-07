classdef AESURF < mni.printing.cards.BaseCard
    %AERO Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ID;
        LABEL;
        CID1;
        ALID1;
        CID2;
        ALID2;
        EFF;
        LDW;
        CREFC;
        CREFS;
        PLLIM;
        PULIM;
        HMLLIM;
        HMULIM;
        TQLLIM;
        TQULIM;
    end
    
    methods
        function obj = AESURF(ID,LABEL,CID1,ALID1,varargin)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            expectedLDW = {'LDW','NOLDW'};
            p = inputParser();
            
            p.addRequired('ID',@(x)x>0)
            p.addRequired('LABEL',@(x)ischar(x)||isstring(x))
            p.addRequired('CID1',@(x)x>0)
            p.addRequired('ALID1',@(x)x>0)
            p.addParameter('CID2','',@(x)x>0)
            p.addParameter('ALID2','',@(x)x>0)
            p.addParameter('EFF',[],@(x)x~=0)
            p.addParameter('LDW','',@(x)any(validatestring(x,expectedLDW)))
            p.addParameter('CREFC','',@(x)x>0)
            p.addParameter('CREFS','',@(x)x>0)
            p.addParameter('PLLIM','')
            p.addParameter('PULIM','')
            p.addParameter('HMLLIM','')
            p.addParameter('HMULIM','')
            p.addParameter('TQLLIM','')
            p.addParameter('TQULIM','')
            
            p.parse(ID,LABEL,CID1,ALID1,varargin{:})
            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end
            obj.Name = 'AESURF';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.ID},{obj.LABEL},{obj.CID1},{obj.ALID1}...
                {obj.CID2},{obj.ALID2},{obj.EFF},{obj.LDW},{obj.CREFC},...
                {obj.CREFS},{obj.PLLIM},{obj.PULIM},{obj.HMLLIM},...
                {obj.HMULIM},{obj.TQLLIM},{obj.TQULIM}];
            format = 'isiiiirsrrrrrrii';
            obj.fprint_nas(fid,format,data);
        end
    end
end

