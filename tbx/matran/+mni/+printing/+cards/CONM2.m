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
        function obj = CONM2(EID,G,M,varargin)
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
            p = inputParser();
            p.addRequired('EID',@(x)x>0)
            p.addRequired('G',@(x)x>0)
            p.addRequired('M')            
            p.addParameter('I',[0,0,0,0,0,0],@(x)numel(x)==6)
            p.addParameter('X',[0,0,0],@(x)numel(x)==3)
            p.addParameter('CID',[],@(x)x>=0)
            
            p.parse(EID,G,M,varargin{:})
            
            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end   
            obj.Name = 'CONM2';
        end
        
        function writeToFile(obj,fid)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            data = [{obj.EID},{obj.G},{obj.CID},{obj.M},...
                {obj.X(1)},{obj.X(2)},{obj.X(3)},...
                {obj.I(1)},{obj.I(2)},{obj.I(3)},{obj.I(4)},{obj.I(5)},{obj.I(6)}];
            format = 'iiirrrrbrrrrrr';
            obj.fprint_nas(fid,format,data);
        end
    end
end

