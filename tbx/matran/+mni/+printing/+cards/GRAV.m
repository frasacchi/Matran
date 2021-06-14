classdef GRAV < mni.printing.cards.BaseCard
    %GRAV Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SID;
        CID;
        A;
        Ni;
        MB;
    end
    
    methods
        function obj = GRAV(SID,A,Ni,varargin)
            %CAERO1 Construct an instance of this class
            %   required inputs are as follows:
            % SID - Set Identification Number
            % PID - Acceleration vector scale factor
            % Ni - Acceleration vector components measured in coordinate
            %           system CID (3x1 vector)
            %
            % optional parameters are
            % CID - coordinate system ID (default = 0)
            % MB - see quick reference guide
            %
            % see NASTRAN users guide for more info
            p = inputParser();
            p.addRequired('SID',@(x)x>0)
            p.addRequired('A',@(x)isnumeric(x)&& numel(x)==1)
            p.addRequired('Ni',@(x)numel(x)==3)
            p.addParameter('MB',[])
            p.addParameter('CID',[],@(x)x>=0)
            
            p.parse(SID,A,Ni,varargin{:})
            
            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end   
            obj.Name = 'GRAV';
        end
        
        function writeToFile(obj,fid)
            data = [{obj.SID},{obj.CID},{obj.A},...
                {obj.Ni(1)},{obj.Ni(2)},{obj.Ni(3)},{obj.MB}];
            format = 'iirrrri';
            obj.fprint_nas(fid,format,data);
        end
    end
end

