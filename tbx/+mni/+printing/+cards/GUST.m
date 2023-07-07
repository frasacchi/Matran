classdef GUST < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SID;
        DLOAD;
        WG;
        X0;
        V;
    end
    
    methods
        function obj = GUST(SID,DLOAD,WG,X0,V)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            p = inputParser();
            p.addRequired('SID',@(x)x>0);
            p.addRequired('DLOAD',@(x)x>0);
            p.addRequired('WG',@(x)x~=0);
            p.addRequired('X0');
            p.addRequired('V',@(x)x>0);
            p.parse(SID,DLOAD,WG,X0,V);

            obj.SID = SID;
            obj.DLOAD = DLOAD;
            obj.WG = WG;
            obj.X0 = X0;
            obj.V = V;
            obj.Name = 'GUST';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.SID},{obj.DLOAD},{obj.WG},{obj.X0},{obj.V}];
            format = 'iirrr';
            obj.fprint_nas(fid,format,data);
        end
    end
end

