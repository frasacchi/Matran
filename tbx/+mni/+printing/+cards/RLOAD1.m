classdef RLOAD1 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SID;
        EXCITEID;
        DELAYI = [];
        DELAYR = [];
        DPHASEI = [];
        DPHASER = [];
        TC = [];
        RC = [];
        TD = []
        RD = [];
        TYPE = [];
    end
    
    methods
        function obj = RLOAD1(SID,EXCITEID,varargin)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            p = inputParser();
            p.addRequired('SID',@(x)x>0);
            p.addRequired('EXCITEID',@(x)x>0);
            p.addParameter('DELAYI',[],@(x)x>0);
            p.addParameter('DELAYR',[]);
            p.addParameter('DPHASEI',[],@(x)x>0);
            p.addParameter('DPHASER',[]);
            p.addParameter('TC',[],@(x)x>0);
            p.addParameter('RC',[]);
            p.addParameter('TD',[],@(x)x>0);
            p.addParameter('RD',[]);
            p.addParameter('TYPE',[]);
            p.parse(SID,EXCITEID,varargin{:});

            if ~isempty(p.Results.DELAYI) && ~isempty(p.Results.DELAYR)
                error('Only one of DELAYI or DELAYR can be defined')
            end
            if ~isempty(p.Results.DPHASEI) && ~isempty(p.Results.DPHASER)
                error('Only one of DPHASEI or DPHASER can be defined')
            end
            if ~isempty(p.Results.TC) && ~isempty(p.Results.RC)
                error('Only one of TC or RC can be defined')
            end
            if ~isempty(p.Results.TD) && ~isempty(p.Results.RD)
                error('Only one of TD or RD can be defined')
            end
            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end   
            obj.Name = 'RLOAD1';            
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.SID},{obj.EXCITEID}];
            format = 'ii';
            [format,data] = blank_ID_real(format,data,obj.DELAYI,obj.DELAYR);
            [format,data] = blank_ID_real(format,data,obj.DPHASEI,obj.DPHASER);
            [format,data] = blank_ID_real(format,data,obj.TC,obj.RC);
            [format,data] = blank_ID_real(format,data,obj.TD,obj.RD);
            data = [data,{obj.TYPE}];
            format = [format,'i'];
            obj.fprint_nas(fid,format,data);
        end
    end
end

function [format,data] = blank_ID_real(format,data,ID_value,real_value)
    if isempty(ID_value) && isempty(real_value)
        format = [format,'b'];
    elseif ~isempty(ID_value)
        data = [data,{ID_value}];
        format = [format,'i'];
    else
        data = [data,{real_value}];
        format = [format,'r'];
    end
end

