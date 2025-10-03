classdef PCOMP < mni.printing.cards.BaseCard
    properties
        PID;
        Z0 double;
        NSM double;
        SB double;
        FT string {mustBeMember(FT,["HILL","HOFF","TSAI","STRN","HFAIL","HTAPE","HFABR",""])} = "";
        TREF double = 0;
        GE double = 0;
        LAM string {mustBeMember(LAM,["SYM","MEM","BEND","SMEAR","SMCORE",""])} = "";
        plyLayers (:,1) mni.printing.cards.PlyLayer = mni.printing.cards.PlyLayer.empty;
    end
    
    methods
        function obj = PCOMP(PID,Z0,NSM,SB,FT,TREF,GE,LAM,plyLayers)
            %PCOMP Construct an instance of this class
            %   required inputs are as follows:
            % PID - property identification
            arguments
                PID;
                Z0 double;
                NSM double;
                SB double;
                FT string {mustBeMember(FT,["HILL","HOFF","TSAI","STRN","HFAIL","HTAPE","HFABR",""])} = "";
                TREF double = 0;
                GE double = 0;
                LAM string {mustBeMember(LAM,["SYM","MEM","BEND","SMEAR","SMCORE",""])} = "";
                plyLayers (:,1) mni.printing.cards.PlyLayer = mni.printing.cards.PlyLayer.empty;
            end
            obj.PID = PID;
            obj.Z0 = Z0;
            obj.NSM = NSM;
            obj.SB = SB;
            obj.FT = FT;
            obj.TREF = TREF;
            obj.GE = GE;
            obj.LAM = LAM;
            obj.plyLayers = plyLayers;
            obj.Name = 'PCOMP';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.PID},{obj.Z0},{obj.NSM},{obj.SB},{obj.FT},{obj.TREF},{obj.GE},{obj.LAM}];
            format = 'irrrsrrs';

            % add format for ply layers
            if isempty(obj.plyLayers(1).Ti)
                error('First ply thickness, T1 = 0');
            end
            for i = 1:length(obj.plyLayers)
                [tmpData,tmpFormat] = obj.plyLayers(i).GetExportFormat();
                data = [data,tmpData];
                format = [format,tmpFormat];
            end
            obj.fprint_nas(fid,format,data,ConStr='+');
        end
    end
end

