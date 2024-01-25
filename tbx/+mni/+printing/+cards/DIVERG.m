classdef DIVERG < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SID;    % set identifier
        NROOT;  % number of divergence pressures
        Ms;     % list of mach numbers to run analysis at
    end
    
    methods
        function obj = DIVERG(SID,NROOT,Ms)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            obj.SID = SID;
            obj.NROOT = NROOT;
            obj.Ms = unique(Ms);
            obj.Name = 'DIVERG';
            
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.SID},{obj.NROOT}];
            format = 'ii';
            for i = 1: length(obj.Ms)
                data(end+1) = {obj.Ms(i)};
                format(end+1) = 'f';        
            end
            format(end+1) = 'b';  
            obj.fprint_nas(fid,format,data);
        end
    end
    
    methods(Static)
        function out = split_contiguous(A)
        %SPLIT_CONTIGUOUS Summary of this function goes here
        %   Detailed explanation goes here
            out = {A(1),};
            for i =2:length(A)
                if A(i)-out{end}(end) == 1
                    out{end}(end+1) = A(i);
                else
                    out{end+1} = A(i);
                end
            end
        end
    end
end

