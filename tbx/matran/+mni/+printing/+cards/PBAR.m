classdef PBAR < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        PID;
        MID;
        Section;
        K;
    end
    
    methods
        function obj = PBAR(PID,MID,Section,opts)
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
                Section (1,1) mni.printing.cards.BeamSection
                opts.K (2,1) double = [1;1]
            end
            obj.PID = PID;
            obj.MID = MID;
            obj.Section = Section;
            obj.K = opts.K;   
            obj.Name = 'PBAR';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.PID},{obj.MID}];
            format = 'ii';
            % add format for section
            [tmpData,tmpFormat] = obj.Section.GetExportBarFormat();
            data = [data,tmpData];
            format = [format,tmpFormat];
            % add additonal parameters
            data = [data,{obj.K(1)},{obj.K(2)}];
            format = [format,repmat('r',1,2)];
            obj.fprint_nas(fid,format,data,ConStr='+');
        end
    end
end

