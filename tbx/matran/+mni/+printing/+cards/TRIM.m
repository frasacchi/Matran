classdef TRIM < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SID;
        MACH=0;
        Q=0;
        label_values = [];
        AEQR =1;

       
    end
    
    methods
        function obj = TRIM(SID,MACH,Q,label_values,varargin)
            %CAERO1 Construct an instance of this class
            %   required inputs are as follows:
            % SID - set identification number
            % MACH - Mach Number
            % Q - Dynamic pressure
            % label_values - a list of cells, in each cell the first elemnt
            %               is the label string, the second is the value
            %
            % optional parameters are
            % AEQR - Flag to request a rigid trim analysis (default 1.0)
            %
            % see NASTRAN users guide for more info
            p = inputParser();
            p.addRequired('SID',@(x)x>0)
            p.addRequired('MACH',@(x)x>=0 && x~=1)
            p.addRequired('Q',@(x)x>0)
            p.addRequired('label_values',@check_labels)
            p.addParameter('AEQR',[],@(x)x>=0 && x<=1)
            p.parse(SID,MACH,Q,label_values,varargin{:})
            
            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end 
            obj.Name = 'TRIM';
        end
        
        function writeToFile(obj,fid)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            data = [{obj.SID},{obj.MACH},{obj.Q}];
            format = 'irr';
            if length(obj.label_values)==2
                [data,format] = obj.write_labels(data,format,obj.label_values);
                data = [data,{obj.AEQR}];
                format = [format,'bbr'];
            elseif length(obj.label_values)==4
                [data,format] = obj.write_labels(data,format,obj.label_values);
                data = [data,{obj.AEQR}];
                format = [format,'r'];
            else
                [data,format] = obj.write_labels(data,format,obj.label_values(1:4));
                data = [data,{obj.AEQR}];
                format = [format,'r'];
                [data,format] = obj.write_labels(data,format,obj.label_values(5:end));
            end
            obj.fprint_nas(fid,format,data);
        end
    end
    methods(Access = private)
        function [data,format] = write_labels(obj,data,format,labels)
            for i = 1:length(labels)/2
                data = [data,{labels{(i-1)*2+1}},{labels{(i-1)*2+2}}];
                format = [format,'sr'];
            end
        end
    end
end

function out = check_labels(x)
    out = true;
    if isempty(x)
        error('labels cannot be empty')
    end
    if mod(length(x),2)==1
        error('labels must have an even number of elements')
    end
    for i =1:length(x)/2
        if ~ischar(x{(i-1)*2+1})
            error('First value is label-value pairs must be a charcter string not %s',class(x{1}));
        elseif ~isnumeric(x{(i-1)*2+2})
            error('First value is label-value pairs must be numeric, not %s',class(x{2}));
        end
    end        
end

