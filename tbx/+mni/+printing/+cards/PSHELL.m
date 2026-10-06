classdef PSHELL < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        PID;
        MID1;
        T;
        MID2;
        I12;
        MID3;
        TST;    % TS/T: transverse shear thickness ratio (blank -> Nastran default 0.833333)
        NSM;    % non-structural mass per unit area (blank -> 0)
    end
    
    methods
        function obj = PSHELL(PID,MID1,T,MID2,I12,MID3,opts)
            %PSHELL Construct an instance of this class
            %   required inputs are as follows:
            % PID - property identification
            % MID - material identification
            %   optional name-value inputs (written blank when empty):
            % TST - TS/T, transverse shear thickness / membrane thickness
            % NSM - non-structural mass per unit area
            arguments
                PID (1,1) double {mustBePositive}
                MID1 (1,1) double {mustBePositive}
                T (1,1) double {mustBePositive}
                MID2 (1,1) double {mustBePositive}
                I12 (:,1) double {mustBePositive}
                MID3 (1,1) double {mustBePositive}
                opts.TST (:,1) double = []
                opts.NSM (:,1) double = []
            end 
            obj.PID = PID;
            obj.MID1 = MID1;
            obj.T = T;
            obj.MID2 = MID2;
            obj.I12 = I12;
            obj.MID3 = MID3;
            obj.TST = opts.TST;
            obj.NSM = opts.NSM;
            obj.Name = 'PSHELL';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.PID},{obj.MID1},{obj.T},{obj.MID2},{obj.I12},{obj.MID3},{obj.TST},{obj.NSM}];
            format = 'iiririrr';
            obj.fprint_nas(fid,format,data);
            
        end
    end
end

