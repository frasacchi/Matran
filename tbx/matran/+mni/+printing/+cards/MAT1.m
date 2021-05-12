classdef MAT1 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        MID;
        E;
        G;
        NU;
        RHO;
        A;
        TREF;
        GE;
        ST;
        SC;
        SS;
        MCSID;
    end
    
    methods
        function obj = MAT1(MID,varargin)
            %MAT1 Construct an instance of this class
            %   required inputs are as follows:
            % MID - material identification
            % RHO - Density
            % A - Thermal Expansion
            %
            % optional parameters are:
            % RHO,A,GE,E,G,NU,TREF,ST,SC,SS,MCSID
            %
            % see NASTRAN users guide for more info
            p = inputParser();
            p.addRequired('MID',@(x)x>0)
            p.addParameter('RHO',[])          
            p.addParameter('A',[]);
            p.addParameter('GE',[]);
            p.addParameter('E',[]);
            p.addParameter('G',[]);
            p.addParameter('NU',[]);
            p.addParameter('TREF',[]);
            p.addParameter('ST',[]);
            p.addParameter('SC',[]);
            p.addParameter('SS',[]);
            p.addParameter('MCSID',[]);
            
            p.parse(MID,varargin{:})
            
            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end   
            obj.Name = 'MAT1';
        end
        
        function writeToFile(obj,fid)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            data = [{obj.MID},{obj.E},{obj.G},{obj.NU},{obj.RHO},{obj.A},...
                {obj.TREF},{obj.GE},{obj.ST},{obj.SC},{obj.SS},...
                {obj.MCSID}];
            format = 'irrrrrrrrrri';
            obj.fprint_nas(fid,format,data);
        end
    end
end

