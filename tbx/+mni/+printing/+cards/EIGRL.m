classdef EIGRL < mni.printing.cards.BaseCard
    %EIGRL Defines data needed to perform real eigenvalue (vibration or buckling)
    % analysis with the Lanczos method.
    
    properties
        SID;
        V1;
        V2;
        ND;
        MSGLVL;
        MAXSET;
        SHFSCL;
        NORM;
    end
    
    methods
        function obj = EIGRL(SID,varargin)
            %EIGRL Construct an instance of this class
            %   required inputs are as follows:
            %   SID
            %
            %   optional parameters are:
            %   V1, V2, ND, MSGLVL, MAXSET, SHFSCL, NORM
            %
            %   see NASTRAN users guide for more info
            
            norms = {'MASS','MAX'};
            
            p = inputParser();
            p.addRequired('SID',@(x) isnumeric(x) && x>0)
            p.addParameter('V1',[],@(x) isnumeric(x))
            p.addParameter('V2',[],@(x) isnumeric(x))
            p.addParameter('ND',[],@(x) isnumeric(x) && x>0)
            p.addParameter('MSGLVL',[],@(x) isnumeric(x) && x>=0 && x<=4)
            p.addParameter('MAXSET',[],@(x) isnumeric(x) && x>0 && x<=30)
            p.addParameter('SHFSCL',[],@(x) isnumeric(x))
            p.addParameter('NORM',[],@(x) any(validatestring(x,norms)))
            
            p.parse(SID,varargin{:})            
            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end   
            obj.Name = 'EIGRL';
            
            % Enforce V1 < V2 if both are provided
            if ~isempty(obj.V1) && ~isempty(obj.V2)
                if obj.V1 >= obj.V2
                   error('For EIGRL card, the following must be true: V1 < V2') 
                end
            end
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print EIGRL entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.SID},{obj.V1},{obj.V2},...
                {obj.ND},{obj.MSGLVL},{obj.MAXSET},{obj.SHFSCL},...
                {obj.NORM}];

            format = 'irriiirs';
            obj.fprint_nas(fid,format,data);
        end
    end
end