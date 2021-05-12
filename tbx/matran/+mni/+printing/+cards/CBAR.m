classdef CBAR < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        EID;
        PID;
        GA;
        GB;
        X;
        Wa;
        Wb;
        OFFST;
        PA;
        PB;
    end
    
    methods
        function obj = CBAR(EID,PID,GA,GB,varargin)
            %CAERO1 Construct an instance of this class
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
            p = inputParser();
            p.addRequired('EID')
            p.addRequired('PID')
            p.addRequired('GA')
            p.addRequired('GB')
            p.addParameter('G0',[],@(x)x>0)
            p.addParameter('X',@(x)numel(x)==3)
            p.addParameter('Wa',@(x)numel(x)==3)
            p.addParameter('Wb',@(x)numel(x)==3)
            p.addParameter('OFFST','',@ischar)
            p.addParameter('PA',[],@(x)x>0)
            p.addParameter('PB',[],@(x)x>0)
            
            p.parse(EID,PID,GA,GB,varargin{:})
            
            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end   
            obj.Name = 'CBAR';
        end
        
        function writeToFile(obj,fid)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if isempty(obj.G0)
                data = [{obj.EID},{obj.PID},{obj.GA},{obj.GB},...
                {obj.X(1)},{obj.X(2)},{obj.X(3)},{obj.OFFST},...
                {obj.PA},{obj.PB},{obj.Wa(1)},{obj.Wa(2)},{obj.Wa(3)},...
                {obj.Wb(1)},{obj.Wb(2)},{obj.Wb(3)}];
                format = 'iiiirrrsiirrrrrr';
            else
                data = [{obj.EID},{obj.PID},{obj.GA},{obj.GB},...
                {obj.G0},{obj.OFFST},{obj.PA},{obj.PB},...
                {obj.Wa(1)},{obj.Wa(2)},{obj.Wa(3)},...
                {obj.Wb(1)},{obj.Wb(2)},{obj.Wb(3)}];
                format = 'iiiiibbsiirrrrrr';
            end
            obj.fprint_nas(fid,format,data);
        end
    end
end

