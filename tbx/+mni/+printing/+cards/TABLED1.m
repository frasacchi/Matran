classdef TABLED1 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TID;
        XAXIS;
        YAXIS;
        Xs;
        Ys;
    end
    
    methods
        function obj = TABLED1(TID,Xs,Ys,varargin)
            types = {'LINEAR','LOG'};
            if numel(Xs)~=numel(Ys)
                error('xs and Ys must be the same length')
            end            
            p = inputParser();
            p.addRequired('TID',@(x)x>0);
            p.addRequired('Xs',@(x)numel(x)>1);
            p.addRequired('Ys',@(x)numel(x)>1);
            p.addParameter('XAXIS',[],@(x)any(validatestring(x,types)));
            p.addParameter('YAXIS',[],@(x)any(validatestring(x,types)));
            p.parse(TID,Xs,Ys,varargin{:}); 

            obj.TID = TID;
            obj.Xs = Xs;
            obj.Ys = Ys;
            obj.XAXIS = p.Results.XAXIS;  
            obj.YAXIS = p.Results.YAXIS; 
            obj.Name = 'TABLED1';
            
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.TID},{obj.XAXIS},{obj.YAXIS}];
            format = 'issn';
            for i = 1:length(obj.Xs)
                data = [data,obj.Xs(i),obj.Ys(i)];
                format = [format,'rr'];
            end
            data = [data,'ENDT'];
            format = [format,'s'];
            obj.fprint_nas(fid,format,data);
        end
    end
end

