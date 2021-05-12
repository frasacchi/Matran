classdef EIGR < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SID;
        METHOD;
        F1;
        F2;
        NE;
        ND;
        NORM;
        G;
        C;
    end
    
    methods
        function obj = EIGR(SID,METHOD,varargin)
            %CAERO1 Construct an instance of this class
            %   required inputs are as follows:
            % SID,METHOD
            %
            % optional parameters are:
            % F1, F2, NE, ND, NORM, G, C
            %
            % see NASTRAN users guide for more info
            methods = {'LAN','AHOU','INV','SINV','GIV','MGIV','HOU',...
                'MHOU','AGIV'};
            norms = {'MASS','MAX','POINT'};
            
            p = inputParser();
            p.addRequired('SID',@(x)x>0)
            p.addRequired('METHOD',@(x)any(validatestring(x,methods)))
            p.addParameter('F1',[],@(x)x>=0)
            p.addParameter('F2',[],@(x)x>0)
            p.addParameter('NE',[],@(x)x>0)
            p.addParameter('ND',[],@(x)x>=0)
            p.addParameter('NORM',[],@(x)any(validatestring(x,norms)))
            p.addParameter('G',[],@(x)x>0)
            p.addParameter('C',[],@(x)x>=1 && x<=6)
            
            p.parse(SID,METHOD,varargin{:})            
            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end   
            obj.Name = 'EIGR';
            
            if ~isempty(obj.F1)
                if isempty(obj.F2)
                    error('For EIGR card either both or neither frequency bounds must be supplied')
                end
                if obj.F1>=obj.F2
                   error('For EIGR card the following must be true F1 < F2') 
                end
            end
        end
        
        function writeToFile(obj,fid)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            data = [{obj.SID},{obj.METHOD},{obj.F1},...
                {obj.F2},{obj.NE},{obj.ND},{obj.NORM},...
                {obj.G},{obj.C}];
            format = 'isrriibbsii';
            obj.fprint_nas(fid,format,data);
        end
    end
end

