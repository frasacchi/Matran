classdef MKAERO1 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Ms;
        Ks;
    end

    methods
        function obj = MKAERO1(Ms,Ks)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            if isempty(Ms)
                error('min Mach array length is 1')
            end
            if isempty(Ks)
                error('min Reduced Freqeuncy array is 1')
            end
            obj.Ms = Ms;
            obj.Ks = Ks;
            obj.Name = 'MKAERO1';

        end

        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            tmpMs = reshape([obj.Ms,nan(1,8 - mod(length(obj.Ms),8))],8,[]);
            tmpKs = reshape([obj.Ks,nan(1,8 - mod(length(obj.Ks),8))],8,[]);
            for i = 1:size(tmpMs,2)
                for j = 1:size(tmpKs,2)
                    Midx = find(~isnan(tmpMs(:,i)),1,'last');
                    Kidx = find(~isnan(tmpKs(:,j)),1,'last');
                    writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
                    data = [];
                    format = '';
                    for k = 1:Midx
                        data = [data,{tmpMs(k,i)}];
                        format = [format,'r'];
                    end
                    if Midx<8
                        format = [format,'n'];
                    end
                    for k = 1:Kidx
                        data = [data,{tmpKs(k,j)}];
                        format = [format,'r'];
                    end
                    obj.fprint_nas(fid,format,data);
                end
            end
        end
    end
end

