classdef TLOAD2 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SID;
        EXCITEID;
        DELAYI = [];
        DELAYR = [];
        TYPE = [];
        T1 = [];
        T2 = [];
        F = [];
        P = [];
        C = [];
        B = [];
        US0 = [];
        VS0 = [];
    end
    
    methods
        function obj = TLOAD2(SID,EXCITEID,varargin)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            p = inputParser();
            p.addRequired('SID',@(x)x>0);
            p.addRequired('EXCITEID',@(x)x>0);
            
            p.addParameter('DELAYI',[],@(x)x>0);
            p.addParameter('DELAYR',[]);
            p.addParameter('TYPE',[]);

            p.addParameter('T1',[],@(x)x>=0);
            p.addParameter('T2',[],@(x)x>0);
            p.addParameter('F',[],@(x)x>=0);
            p.addParameter('P',[]);
            p.addParameter('C',[]);
            p.addParameter('B',[]);
            p.addParameter('US0',[]);
            p.addParameter('VS0',[]);
            p.parse(SID,EXCITEID,varargin{:});

            if ~isempty(p.Results.DELAYI) && ~isempty(p.Results.DELAYR)
                error('Only one of DELAYI or DELAYR can be defined')
            end
            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end   
            obj.Name = 'TLOAD2';            
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.SID},{obj.EXCITEID}];
            format = 'ii';
            if isempty(obj.DELAYI) && isempty(obj.DELAYR)
                format = [format,'b'];
            elseif ~isempty(obj.DELAYI)
                data = [data,{obj.DELAYI}];
                format = [format,'i'];
            else
                data = [data,{obj.DELAYR}];
                format = [format,'r'];
            end
            data = [data,{obj.TYPE},{obj.T1},{obj.T2},{obj.F},{obj.P}];
            format = [format,'irrrr'];
            if ~isempty(obj.C) || ~isempty(obj.B) || ~isempty(obj.US0) || ~isempty(obj.VS0)
                data = [data,{obj.C},{obj.B},{obj.US0},{obj.VS0}];
                format = [format,'rrrr'];
            end
            obj.fprint_nas(fid,format,data);
        end
    end
end

