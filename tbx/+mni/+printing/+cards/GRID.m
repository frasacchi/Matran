classdef GRID < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ID;
        CP;
        X1;
        X2;
        X3;
        CD;
        PS;
        SEID;
    end
    
    methods
        function obj = GRID(ID,X,opts)
            arguments
                ID {mustBeGreaterThanOrEqual(ID,0)}
                X (3,1) double
                opts.CP {validateEmptyInt(opts.CP,0)} = [];
                opts.CD {validateEmptyInt(opts.CD,-1)} = [];
                opts.PS = '';
                opts.SEID {validateEmptyInt(opts.SEID,0)} = [];
            end
            
            obj.Name = 'GRID';
            obj.ID = ID;
            obj.CP = opts.CP;
            obj.X1 = X(1);
            obj.X2 = X(2);
            obj.X3 = X(3);
            obj.CD = opts.CD;
            obj.PS = opts.PS;
            obj.SEID = opts.SEID;            
        end
        
        function writeToFile(obj,fid)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            data = [{obj.ID},{obj.CP},{obj.X1},{obj.X2},...
                {obj.X3},{obj.CD},{obj.PS},{obj.SEID}];
            format = 'iifffisi';
            obj.fprint_nas(fid,format,data);
        end
    end
end
function validateEmptyInt(x,GT)
assert(isempty(x) || x>=GT)
end

