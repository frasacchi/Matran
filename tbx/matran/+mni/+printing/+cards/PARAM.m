classdef PARAM < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        N;
        V1;
        V2;
        Type;
    end
    
    methods
        function obj = PARAM(N,Type,V1,varargin)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            p = inputParser();
            p.addOptional('V2',[]);
            p.parse(varargin{:});
            
            validatestring(Type,{'s','r','f','i'});
            obj.N = N;
            obj.V1 = V1;
            obj.V2 = p.Results.V2;
            obj.Type = Type;
            obj.Name = 'PARAM';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.N},{obj.V1},{obj.V2}];
            format = ['s',obj.Type,obj.Type];
            obj.fprint_nas(fid,format,data);
        end
    end
end

