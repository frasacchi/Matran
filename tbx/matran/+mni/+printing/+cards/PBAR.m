classdef PBAR < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        PID;
        MID;
        A;
        I1;
        I2;
        I12;
        J;
        NSM;
        C1;
        C2;
        D1;
        D2;
        E1;
        E2;
        F1;
        F2;
        K1;
        K2;
    end
    
    methods
        function obj = PBAR(PID,MID,varargin)
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
            p = inputParser();
            p.addRequired('PID',@(x)x>0)
            p.addRequired('MID',@(x)x>0)
            p.addParameter('NSM',[]);
            p.addParameter('A',[]);
            p.addParameter('I1',[]);
            p.addParameter('I2',[]);
            p.addParameter('I12',[]);
            p.addParameter('J',[]);
            p.addParameter('C1',[]);
            p.addParameter('C2',[]);
            p.addParameter('D1',[]);
            p.addParameter('D2',[]);
            p.addParameter('E1',[]);
            p.addParameter('E2',[]);
            p.addParameter('F1',[]);
            p.addParameter('F2',[]);
            p.addParameter('K1',[]);
            p.addParameter('K2',[]);
            
            p.parse(PID,MID,varargin{:})
            
            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end   
            obj.Name = 'PBAR';
        end
        
        function writeToFile(obj,fid)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            data = [{obj.PID},{obj.MID},{obj.A},{obj.I1},{obj.I2},{obj.J},...
                {obj.NSM},{obj.C1},{obj.C2},{obj.D1},{obj.D2},...
                {obj.E1},{obj.E2},{obj.F1},{obj.F2},{obj.K1},{obj.K2},...
                {obj.I12}];
            format = 'iirrrrrbrrrrrrrrrrr';
            obj.fprint_nas(fid,format,data);
        end
    end
end

