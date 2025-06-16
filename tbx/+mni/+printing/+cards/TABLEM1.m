classdef TABLEM1 < mni.printing.cards.BaseCard
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
        function obj = TABLEM1(TID, Xs, Ys, opts)
            arguments
                TID (1,1) double {mustBePositive}
                Xs (1,:) double
                Ys (1,:) double
                opts.XAXIS string {mustBeMember(opts.XAXIS,["LINEAR","LOG"])} = "";
                opts.YAXIS string {mustBeMember(opts.YAXIS,{'LINEAR','LOG'})} = "";
            end
            if numel(Xs) ~= numel(Ys)
                error('Xs and Ys must be the same length');
            end
            if numel(Xs)==0
                error('Xs and Ys must be have non-zero length');
            end
            obj.TID   = TID;
            obj.Xs    = Xs;
            obj.Ys    = Ys;
            obj.XAXIS = opts.XAXIS;
            obj.YAXIS = opts.YAXIS;
            obj.Name  = 'TABLEM1';
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

