classdef TLOAD1 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SID;
        EXCITEID;
        DELAYI = [];
        DELAYR = [];
        TYPE = [];
        TID= [];
        F = [];
        US0 = [];
        VS0 = [];
    end
    
    methods
        function obj = TLOAD1(SID,EXCITEID,varargin)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            p = inputParser();
            p.addRequired('SID',@(x)x>0);
            p.addRequired('EXCITEID',@(x)x>0);
            p.addParameter('TID',[],@(x)x>0);
            p.addParameter('F',[],@(x)x~=0);
            p.addParameter('DELAYI',[],@(x)x>0);
            p.addParameter('DELAYR',[]);
            p.addParameter('TYPE',[]);
            p.addParameter('US0',[]);
            p.addParameter('VS0',[]);
            p.parse(SID,EXCITEID,varargin{:});

            if ~isempty(p.Results.DELAYI) && ~isempty(p.Results.DELAYR)
                error('Only one of DELAYI or DELAYR can be defined')
            end
            if isempty(p.Results.TID) && isempty(p.Results.F)
                error('Either TID or F needs to be defined')
            end
            if ~isempty(p.Results.TID) && ~isempty(p.Results.F)
                error('Only either TID or F can be defined')
            end

            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end   
            obj.Name = 'TLOAD1';            
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
            data = [data,{obj.TYPE}];
            format = [format,'i'];
            if ~isempty(obj.TID)
                data = [data,{obj.TID}];
                format = [format,'i'];
            else
                data = [data,{obj.F}];
                format = [format,'r'];
            end
            data = [data,{obj.US0},{obj.VS0}];
            format = [format,'rr'];
            obj.fprint_nas(fid,format,data);
        end
    end
end

