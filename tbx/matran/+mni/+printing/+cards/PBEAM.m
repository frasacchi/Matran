classdef PBEAM < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        PID;
        MID;
        Sections (:,1) mni.printing.cards.BeamSection = mni.printing.cards.BeamSection.empty;
        K (2,1) double = [nan;nan];
        S (2,1) double;
        NSI (2,1) double;
        CW (2,1) double;
        MA (2,1) double;
        MB (2,1) double;
        NA (2,1) double;
        NB (2,1) double;
    end
    
    methods
        function obj = PBEAM(PID,MID,Sections,opts)
            %CONM2 Construct an instance of this class
            %   required inputs are as follows:
            % PID - property identification
            % MID - material identification
            % NSM - non-structural mass per unit length
            %
            % optional parameters are
            % A - Area of bar cross section
            % I1,I2,I12 - Area moments of inertia
            % J - Torsional constant
            % C1,C2,D1,D2,E1,E2,F1,F2 - Stress recovery coefficients
            % K1,K2 - Area factor for shear
            %
            % see NASTRAN users guide for more info
            arguments
                PID (1,1) double {mustBePositive}
                MID (1,1) double {mustBePositive}
                Sections (:,1) mni.printing.cards.BeamSection
                opts.K (2,1) double = [nan;nan]
                opts.S (2,1) double = [nan;nan]
                opts.NSI (2,1) double = [nan;nan]
                opts.CW (2,1) double = [nan;nan]
                opts.MA (2,1) double = [nan;nan]
                opts.MB (2,1) double = [nan;nan]
                opts.NA (2,1) double = [nan;nan]
                opts.NB (2,1) double = [nan;nan]
            end 
            obj.PID = PID;
            obj.MID = MID;
            obj.Sections = Sections;
            obj.K = opts.K;
            obj.S = opts.S;
            obj.NSI = opts.NSI;
            obj.CW = opts.CW;
            obj.MA = opts.MA;
            obj.MB = opts.MB;
            obj.NA = opts.NA;
            obj.NB = opts.NB;
            obj.Name = 'PBEAM';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.PID},{obj.MID}];
            format = 'ii';
            % add format for sections
            if obj.Sections(end).X ~= 1
                error('Last section must have X = 1');
            end
            for i = 1:length(obj.Sections)
                if i == 1
                    [tmpData,tmpFormat] = obj.Sections(i).GetExportFormat();
                else
                    data = [data,{obj.Sections(i).SO},{obj.Sections(i).X}];
                    format = [format,'sr'];
                    [tmpData,tmpFormat] = obj.Sections(i).GetExportFormat(WithStressPoints=obj.Sections(i).SO == "YES");
                end
                
                data = [data,tmpData];
                format = [format,tmpFormat];
            end
            % add additonal parameters
            data = [data,{obj.K(1)},{obj.K(2)},{obj.S(1)},{obj.S(2)},{obj.NSI(1)},{obj.NSI(2)},{obj.CW(1)},{obj.CW(2)},{obj.MA(1)},{obj.MA(2)},{obj.MB(1)},{obj.MB(2)},{obj.NA(1)},{obj.NA(2)},{obj.NB(1)},{obj.NB(2)}];
            format = [format,repmat('r',1,16)];
            obj.fprint_nas(fid,format,data,ConStr='+');
        end
    end
end

