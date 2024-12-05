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
        function obj = TLOAD1(SID,EXCITEID,opts)
            arguments
                SID (1,1) double {mustBePositive(SID)}
                EXCITEID (1,1) double {mustBePositive(EXCITEID)}
                opts.TID (1,1) double {mustBePositive(opts.TID)} = []
                opts.F double = []
                opts.DELAYI double {mustBePositive(opts.DELAYI)} = []
                opts.DELAYR = []
                opts.TYPE = []
                opts.US0 = []
                opts.VS0 = []
            end

            if ~isempty(opts.DELAYI) && ~isempty(opts.DELAYR)
                error('Only one of DELAYI or DELAYR can be defined')
            end
            if isempty(opts.TID) && isempty(opts.F)
                error('Either TID or F needs to be defined')
            end
            if ~isempty(opts.TID) && ~isempty(opts.F)
                error('Only either TID or F can be defined')
            end

            obj.SID = SID;
            obj.EXCITEID = EXCITEID;
            obj.TID = opts.TID;
            obj.F   = opts.F  ;
            obj.DELAYI = opts.DELAYI;
            obj.DELAYR = opts.DELAYR;
            obj.TYPE = opts.TYPE;
            obj.US0 = opts.US0;
            obj.VS0 = opts.VS0;
 
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

