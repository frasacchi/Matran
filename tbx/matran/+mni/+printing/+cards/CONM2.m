classdef CONM2 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        EID;
        G;
        CID;
        M;
        X;
        I;
    end
    
    methods
        function obj = CONM2(EID,G,M,opts)
            arguments
                EID double {mustBeGreaterThan(EID,0)}
                G double {mustBeGreaterThan(G,0)}
                M
                opts.X (3,1) double = [0;0;0];
                opts.CID double {validateEmptyInt(opts.CID,0)} = [];
                opts.I (6,1) double = zeros(6,1);
            end
            %CONM2 Construct an instance of this class
            %   required inputs are as follows:
            % EID - element identification
            % G - grid point identification
            % M - mass value
            %
            % optional parameters are
            % X - 3x1 vector, offset distance (default [0,0,0])
            % I - 6x1 vector, mass moments of inertia
            %           (I11,I21,I22,I31,I32,I33) default zeros
            % CID - coordinate system ID
            %
            % see NASTRAN users guide for more info
            obj.EID = EID;
            obj.M = M;
            obj.G = G;
            obj.I = opts.I;
            obj.X = opts.X;
            obj.CID = opts.CID;
            obj.Name = 'CONM2';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.EID},{obj.G},{obj.CID},{obj.M},...
                {obj.X(1)},{obj.X(2)},{obj.X(3)},...
                {obj.I(1)},{obj.I(2)},{obj.I(3)},{obj.I(4)},{obj.I(5)},{obj.I(6)}];
            format = 'iiirrrrbrrrrrr';
            obj.fprint_nas(fid,format,data);
        end
    end
end
function validateEmptyInt(x,GT)
assert(isempty(x) ||(mod(x,1)==0 && x>=GT))
end

