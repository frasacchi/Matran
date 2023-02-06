classdef CBEAM < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        EID;
        PID;
        GA;
        GB;
        X;
        G0;
        OFFST;
        BIT;
        PA;
        PB;
        WA;
        WB;
        SA;
        SB;
    end
    
    methods
        function obj = CBEAM(EID,PID,GA,GB,opts)
            arguments
                EID double {mustBeInteger}
                PID double {mustBeInteger}
                GA double {mustBeInteger}
                GB double {mustBeInteger}
                opts.X (3,1) double {mustBeInteger} = [1;0;0];
                opts.G0 double {mustBeInteger} = [];
                opts.OFFST char {mustBeMember(opts.OFFST,{'','GGG','BGG','GGO','BGO','GoG','BOG','GOO','BOO'})} = '';
                opts.BIT double = [];
                opts.PA double {mustBeInteger} = [];
                opts.PB double {mustBeInteger} = [];
                opts.WA (3,1) double {mustBeInteger} = [0;0;0];
                opts.WB (3,1) double {mustBeInteger} = [0;0;0];
                opts.SA double {mustBeInteger} = [];
                opts.SB double {mustBeInteger} = [];
            end
            %CBEAM Construct an instance of this class
            %   required inputs are as follows:
            % EID - element identification
            % PID - Property Indetification of PAERO
            % GA - grid Point for start of beam
            % GB - Grid Point for end of beam
            %
            %   optional parameters are
            % G0 - see quick reference guide
            % X - orientation vector (x1-3 in qrg)
            % Wa - see quick reference guide
            % Wb - see quick reference guide
            % OFFST - see quick reference guide
            % PA - see quick reference guide
            % PB - see quick reference guide
            %
            % see NASTRAN users guide for more info
            obj.EID = EID;
            obj.PID = PID;
            obj.GA = GA;
            obj.GB = GB;
            obj.X = opts.X;
            obj.G0 = opts.G0;
            obj.OFFST = opts.OFFST;
            obj.BIT = opts.BIT;
            obj.PA = opts.PA;
            obj.PB = opts.PB;
            obj.WA = opts.WA;
            obj.WB = opts.WB;
            obj.SA = opts.SA;
            obj.SB = opts.SB;
            obj.Name = 'CBEAM';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            if ~isempty(obj.BIT)
                bitOff = obj.BIT;
                bitStr = 'r';
            else
                bitOff = obj.OFFST;
                bitStr = 's';
            end
            if isempty(obj.G0)
                data = [{obj.EID},{obj.PID},{obj.GA},{obj.GB},...
                {obj.X(1)},{obj.X(2)},{obj.X(3)},{bitOff},...
                {obj.PA},{obj.PB},{obj.WA(1)},{obj.WA(2)},{obj.WA(3)},...
                {obj.WB(1)},{obj.WB(2)},{obj.WB(3)},{obj.SA},{obj.SB}];
                format = ['iiiirrr',bitStr,'iirrrrrrii'];
            else
                data = [{obj.EID},{obj.PID},{obj.GA},{obj.GB},...
                {obj.G0},{bitOff},{obj.PA},{obj.PB},...
                {obj.WA(1)},{obj.WA(2)},{obj.WA(3)},...
                {obj.WB(1)},{obj.WB(2)},{obj.WB(3)},{obj.SA},{obj.SB}];
                format = ['iiiiibb',bitStr,'iirrrrrrii'];
            end
            obj.fprint_nas(fid,format,data);
        end
    end
end

