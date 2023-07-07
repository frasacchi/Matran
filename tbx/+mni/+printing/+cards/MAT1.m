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
        function obj = MAT1(MID,opts)
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
            arguments
                MID (1,1) {mustBePositive}
                opts.RHO = nan;
                opts.A = nan;
                opts.GE = nan;
                opts.E = nan;
                opts.G = nan;
                opts.NU = nan;
                opts.TREF = nan;
                opts.ST = nan;
                opts.SC = nan;
                opts.SS = nan;
                opts.MCSID = nan;
            end
            obj.MID = MID;
            obj.RHO = opts.RHO;
            obj.A = opts.A;
            obj.GE = opts.GE;
            obj.E = opts.E;
            obj.G = opts.G;
            obj.NU = opts.NU;
            obj.TREF = opts.TREF;
            obj.ST = opts.ST;
            obj.SC = opts.SC;
            obj.SS = opts.SS;
            obj.MCSID = opts.MCSID;
            obj.Name = 'MAT1';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.MID},{obj.E},{obj.G},{obj.NU},{obj.RHO},{obj.A},{obj.TREF},{obj.GE}];
            format = 'irrrrrrr';
            if (~isempty(obj.ST) || ~isnan(obj.ST)) || (~isempty(obj.SC) || ~isnan(obj.SC)) || (~isempty(obj.SS) || ~isnan(obj.SS)) || (~isempty(obj.MCSID) || ~isnan(obj.MCSID))
                data = [data,{obj.ST},{obj.SC},{obj.SS},{obj.MCSID}];
                format = [format,'rrri'];
            end
            obj.fprint_nas(fid,format,data);
        end
    end
end

