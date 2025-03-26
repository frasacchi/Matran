classdef CONM1 < mni.printing.cards.BaseCard
    %CONM1 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        EID;
        G;
        CID;
        M (6,6) double; % 6x6 mass matrix
    end
    
    methods
        function obj = CONM1(EID,G,M,opts)
            arguments
                EID double {mustBeGreaterThan(EID,0)}
                G double {mustBeGreaterThan(G,0)}
                M (6,6) double
                opts.CID double {validateEmptyInt(opts.CID,0)} = [];
            end
            %CONM2 Construct an instance of this class
            %   required inputs are as follows:
            % EID - element identification
            % G - grid point identification
            % M - 6x6 inertia tensor
            %
            % optional parameters are
            % CID - coordinate system ID
            %
            % see NASTRAN users guide for more info
            obj.EID = EID;
            obj.M = M;
            obj.G = G;
            obj.CID = opts.CID;
            obj.Name = 'CONM1';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            I = obj.M;
            data = [{obj.EID},{obj.G},{obj.CID},{I(1,1)},...
                {I(2,1)},{I(2,2)},{I(3,1)},{I(3,2)},{I(3,3)},{I(4,1)},...
                {I(4,2)},{I(4,3)},{I(4,4)},{I(5,1)},{I(5,2)},{I(5,3)},...
                {I(5,4)},{I(5,5)},{I(6,1)},{I(6,2)},{I(6,3)},{I(6,4)},...
                {I(6,5)},{I(6,6)}];
            format = 'iiirrrrrrrrrrrrrrrrrrrrr';
            obj.fprint_nas(fid,format,data);
        end
    end
end
function validateEmptyInt(x,GT)
assert(isempty(x) ||(mod(x,1)==0 && x>=GT))
end

