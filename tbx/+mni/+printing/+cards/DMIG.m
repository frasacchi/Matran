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
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMIG entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})

            % print header
            data = [{obj.NAME},{0},{obj.IFO},{obj.TIN},{obj.TOUT},...
                {obj.POLAR},{obj.NCOL}];
            format = 'siiiiibi';
            obj.fprint_nas(fid,format,data);

            % print column entry
            for i = 1:length(obj.GJ)
                data = [{obj.NAME},{obj.GJ(i).ID},{obj.CJ(i)}];
                format = 'siib';
                for j=1:length(obj.Gs{i})
                    % if isempty(obj.Bs{i})
                        data = [data,{obj.Gs{i}(j).ID},{obj.Cs{i}(j)},{obj.As{i}(j)}];
                        format = [format,'iirb'];
                    % else
                    %     data = [data,{obj.Gs{i}(j).ID},{obj.Cs{i}(j)},{obj.As{i}(j)},{obj.Bs{i}(j)}];
                    %     format = [format,'iirr'];
                    % end      
                end
                obj.fprint_nas(fid,format,data);
            end    
        end
    end
end

