classdef TABRND1 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TID;
        XAXIS;
        YAXIS;
        fi;
        gi;
    end
    
    methods

        function obj = TABRND1(TID, fi, gi, opts)
            arguments
                TID (1,1) double {mustBePositive}
                fi (1,:) double
                gi (1,:) double
                opts.XAXIS string {mustBeMember(opts.XAXIS,["LINEAR","LOG"])} = "";
                opts.YAXIS string {mustBeMember(opts.YAXIS,{'LINEAR','LOG'})} = "";
            end
            if numel(fi) ~= numel(gi)
                error('fi and gi must be the same length');
            end
            if numel(fi)==0
                error('fi and gi must be have non-zero length');
            end
            obj.TID   = TID;
            obj.fi    = fi;
            obj.gi    = gi;
            obj.XAXIS = opts.XAXIS;
            obj.YAXIS = opts.YAXIS;
            obj.Name  = 'TABRND1';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.TID},{obj.XAXIS},{obj.YAXIS}];
            format = 'issn';
            for i = 1:length(obj.fi)
                data = [data,obj.fi(i),obj.gi(i)];
                format = [format,'rr'];
            end
            data = [data,'ENDT'];
            format = [format,'s'];
            obj.fprint_nas(fid,format,data);
        end
    end
end

