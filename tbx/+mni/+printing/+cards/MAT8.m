classdef MAT8 < mni.printing.cards.BaseCard
    %MAT8 Defines the material properties for a 2D orthotropic material.
    %-- TODO - fix edge cases (too many required properties)
    
    properties
        MID; E1; E2; NU12; G12; G1Z; G2Z; RHO; A1; A2; TREF;
        Xt; Xc; Yt; Yc; S; GE; F12; STRN;
        
        FailureCriterion;
        HFi;
        HTi;
        HFBi;
    end
    
    methods
        function obj = MAT8(MID,opts)
            arguments
            MID (1,1) {mustBePositive}
            
            % Required properties
            opts.E1 (1,1) {mustBePositive} = []
            opts.E2 (1,1) {mustBePositive} = []
            opts.NU12 (1,1) {mustBeNumeric} = []
            opts.G12 (1,1) {mustBePositive} = []
            opts.G1Z (1,1) {mustBeNumeric} = []
            opts.G2Z (1,1) {mustBeNumeric} = []
            opts.RHO (1,1) {mustBeNumeric} = []
            opts.A1 (1,1) {mustBeNumeric} = []
            opts.A2 (1,1) {mustBeNumeric} = []
            opts.TREF (1,1) {mustBeNumeric} = []
            opts.Xt (1,1) {mustBeNumeric} = []
            opts.Xc (1,1) {mustBeNumeric} = []
            opts.Yt (1,1) {mustBeNumeric} = []
            opts.Yc (1,1) {mustBeNumeric} = []
            opts.S (1,1) {mustBeNumeric} = []
            opts.GE (1,1) {mustBeNumeric} = []
            opts.F12 (1,1) {mustBeNumeric} = []
            opts.STRN (1,1) {mustBeNumeric} = []
            
            % Failure Criterion
            opts.FailureCriterion {mustBeMember(opts.FailureCriterion,{"","HFAIL","HTAPE","HFABR"})} = ""
            opts.HFi (1,:) {mustBeNumeric} = []
            opts.HTi (1,:) {mustBeNumeric} = []
            opts.HFBi (1,:) {mustBeNumeric} = []
            end
            
            % Required properties
            obj.MID = MID;
            
            % Optional properties
            optionNames = fieldnames(opts);
            for i = 1:length(optionNames)
            obj.(optionNames{i}) = opts.(optionNames{i});
            end
            
            obj.Name = 'MAT8';
        end
        
        function writeToFile(obj,fid,varargin)
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            
            if isempty(obj.MID)
                return
            end
            
            % Line 1
            data1 = [{obj.MID},{obj.E1},{obj.E2},{obj.NU12},{obj.G12},{obj.G1Z},{obj.G2Z},{obj.RHO}];
            format1 = 'irrrrrrr';
            obj.fprint_nas(fid,format1,data1);
            
            % Line 2
            data2 = [{obj.A1},{obj.A2},{obj.TREF},{obj.Xt},{obj.Xc},{obj.Yt},{obj.Yc},{obj.S}];
            format2 = 'rrrrrrrr';
            if ~all(cellfun(@isempty,data2))
                obj.fprint_nas(fid,['+',format2],data2);
            end
            
            % Line 3
            data3 = [{obj.GE},{obj.F12},{obj.STRN}];
            format3 = 'rrr';
            if ~all(cellfun(@isempty,data3))
                obj.fprint_nas(fid,['+',format3],data3);
            end
            
            % Failure criterion lines
            switch obj.FailureCriterion
                case 'HFAIL'
                    if ~isempty(obj.HFi)
                        data = {obj.FailureCriterion};
                        format = '+c';
                        for val = obj.HFi
                            data = [data, {val}];
                            format = [format, 'r'];
                        end
                        obj.fprint_nas(fid, format, data);
                    end
                case 'HTAPE'
                    if ~isempty(obj.HTi)
                        data = {obj.FailureCriterion};
                        format = '+c';
                        for val = obj.HTi
                            data = [data, {val}];
                            format = [format, 'r'];
                        end
                        obj.fprint_nas(fid, format, data);
                    end
                case 'HFABR'
                    if ~isempty(obj.HFBi)
                        data = {obj.FailureCriterion};
                        format = '+c';
                        for val = obj.HFBi
                            data = [data, {val}];
                            format = [format, 'r'];
                        end
                        obj.fprint_nas(fid, format, data);
                    end
            end
        end
    end
end
