classdef MDLPRM < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        N;
        Val;
        Type;
    end
    
    methods
        function obj = MDLPRM(N,Type,Val)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                N string
                Type char {mustBeMember(Type,{'s','r','f','i'})}
                Val (1,1) double
            end
            
            obj.N = N;
            obj.Val = Val;
            obj.Type = Type;
            obj.Name = 'MDLPRM';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.N},{obj.Val}];
            format = ['s',obj.Type];
            obj.fprint_nas(fid,format,data);
        end
    end
end

