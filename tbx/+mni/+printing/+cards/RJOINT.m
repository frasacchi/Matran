classdef RJOINT < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        EID;
        GA;
        GB;
        CB;
    end
    
    methods
        function obj = RJOINT(EID,GA,GB,varargin)
            %GRID_CARD Construct an instance of this class
            %   Detailed explanation goes here
            p = inputParser();
            p.addRequired('EID',@(x)x>0)
            p.addRequired('GA',@(x)x>0)
            p.addRequired('GB',@(x)x>0)
            p.addParameter('CB','')
            p.parse(EID,GA,GB,varargin{:})
            
            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end
            obj.Name = 'RJOINT';          
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.EID},{obj.GA},{obj.GB},{obj.CB}];
            format = 'iiis';
            obj.fprint_nas(fid,format,data);
        end
    end
end

