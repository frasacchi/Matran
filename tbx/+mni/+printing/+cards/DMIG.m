classdef DMIG < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        NAME;
        IFO;
        TIN;
        TOUT;
        POLAR;
        NCOL;
        GJ;
        CJ;
        Gs;
        Cs;
        As;
        Bs;
    end

    properties
        SkipHeader logical = false;
    end
    
    methods
        function obj = DMIG(NAME,IFO,TIN,GJ,CJ,Gs,Cs,As,Bs,opts)
            arguments
                NAME;
                IFO double {mustBeMember(IFO,[1,2,6,9])};
                TIN double {mustBeMember(TIN,[1,2,3,4])};
                GJ;
                CJ;
                Gs;
                Cs;
                As;
                Bs;
                opts.POLAR = nan;
                opts.TOUT double = nan;
                opts.NCOL = nan;
                opts.SkipHeader = false;
            end
            obj.Name = 'DMIG';
            obj.NAME = NAME;
            obj.IFO = IFO;
            obj.TIN = TIN;
            obj.TOUT = opts.TOUT;
            obj.POLAR = opts.POLAR;
            obj.NCOL = opts.NCOL;
            obj.GJ = GJ;
            obj.CJ = CJ;
            obj.Gs = Gs;
            obj.Cs = Cs;
            obj.As = As;
            obj.Bs = Bs;
            obj.SkipHeader = opts.SkipHeader;  
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            % write the header card to the file
            if ~obj.SkipHeader
                data = [{obj.NAME},{0},{obj.IFO},{obj.TIN},{obj.TOUT},...
                    {obj.POLAR},{obj.NCOL}];
                format = 'siiiiibi';
                obj.fprint_nas(fid,format,data);
            end
            % write column entry format
            data = [{obj.NAME},{obj.GJ},{obj.CJ}];
            format = 'siib';
            for i = 1:length(obj.Gs)
                if isempty(obj.Bs)
                    data = [data,{obj.Gs(i)},{obj.Cs(i)},{obj.As(i)}];
                    format = [format,'iirb'];
                else
                    data = [data,{obj.Gs(i)},{obj.Cs(i)},{obj.As(i)},{obj.Bs(i)}];
                    format = [format,'iirr'];
                end
            end
            obj.fprint_nas(fid,format,data);
        end
    end
end

