classdef AELINK < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        ID;
        LABLD;
        LABLn = {};
        Cn = {};
    end
    
    methods
        function obj = AELINK(LABLD,LABLn_Cn,varargin)
            %AELINK Construct an instance of this class
            % see NASTRAN Quick Ref Guide for info on AELINK
            % Inputs:
            %   - ID: integer specifing which trim case it applies to ()
            %
            p = inputParser();
            p.addParameter('ID',0);
            p.parse(varargin{:});
            
            obj.ID = p.Results.ID;
            obj.LABLD = LABLD;
            
            for i = 1:length(LABLn_Cn)
                if length(LABLn_Cn{i})~= 2
                    error('LABLn_Cn must be a cell array of cells containing two elements')
                end
                obj.LABLn{i} = LABLn_Cn{i}{1};
                obj.Cn{i} = LABLn_Cn{i}{2};
            end
            obj.Name = 'AELINK';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.ID},{obj.LABLD}];
            format = 'is';
            for i = 1:length(obj.LABLn)
                data = [data,{obj.LABLn{i}},{obj.Cn{i}}];
                format = [format,'sr'];
            end
            obj.fprint_nas(fid,format,data);
        end
    end
end

