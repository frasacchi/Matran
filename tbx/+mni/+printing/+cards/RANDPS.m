classdef RANDPS < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SID;
        J;
        K;
        X;
        Y;
        TID = nan;
    end
    
    methods
        function obj = RANDPS(SID,J,K,X,Y,opts)
            arguments
                SID;
                J double;
                K double;
                X double;
                Y double;
                opts.TID = nan;
            end
            obj.SID = SID;
            obj.J = J;
            obj.K = K;
            obj.X = X;
            obj.Y = Y;
            obj.TID = opts.TID;
            obj.Name = 'RANDPS';            
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.SID},{obj.J},{obj.K},{obj.X},{obj.Y},{obj.TID}];
            format = 'iiirri';
            obj.fprint_nas(fid,format,data);
        end
    end
end

