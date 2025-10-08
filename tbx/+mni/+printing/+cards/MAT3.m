classdef MAT3 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        MID;
        EX;
        ETH;
        EZ;
        NUXTH;
        NUXTHZ;
        NUZX;
        RHO;
        GZX;
        AX;
        ATH;
        AZ;
        TREF;
        GE;
    end
    
    methods
        function obj = MAT3(MID,opts)
            %MAT3 Construct an instance of this class
            %   required inputs are as follows:
            % see NASTRAN users guide for more info
            arguments
                MID (1,1) {mustBePositive}
                opts.EX = nan;
                opts.ETH = nan;
                opts.EZ = nan;
                opts.NUXTH = nan;
                opts.NUXTHZ = nan;
                opts.NUZX = nan;
                opts.RHO = nan;
                opts.GZX = nan;
                opts.AX = nan;
                opts.ATH = nan;
                opts.AZ = nan;
                opts.TREF = nan;
                opts.GE = nan;
            end
            obj.MID = MID;
            obj.EX = opts.EX;
            obj.ETH = opts.ETH;
            obj.EZ = opts.EZ;
            obj.NUXTH = opts.NUXTH;
            obj.NUXTHZ = opts.NUXTHZ;
            obj.NUZX = opts.NUZX;
            obj.RHO = opts.RHO;
            obj.GZX = opts.GZX;
            obj.AX = opts.AX;
            obj.ATH = opts.ATH;
            obj.AZ = opts.AZ;
            obj.TREF = opts.TREF;
            obj.GE = opts.GE;
            obj.Name = 'MAT3';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.MID},{obj.EX},{obj.ETH},{obj.EZ},{obj.NUXTH},{obj.NUXTHZ},{obj.NUZX},{obj.RHO},{obj.GZX},{obj.AX},{obj.ATH},{obj.AZ},{obj.TREF},{obj.GE}];
            format = 'irrrrrrrrrrrrr';
            obj.fprint_nas(fid,format,data);
        end
    end
end

