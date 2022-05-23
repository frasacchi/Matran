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
            if numel(Ms)>8 || isempty(Ms)
                error('max Mach array length is 8, min length is 1')
            end
            if numel(Ks)>8 || isempty(Ks)
                error('max Reduced Freqeuncy array length is 8, min length is 1')
            end
            obj.Ms = Ms;
            obj.Ks = Ks;
            obj.Name = 'MKAERO1';
            
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [];
            format = '';
            for i = 1:length(obj.Ms)
                data = [data,{obj.Ms(i)}];
                format = [format,'r'];
            end
            if length(obj.Ms)<8
                format = [format,'n'];
            end
            for i = 1:length(obj.Ks)
                data = [data,{obj.Ks(i)}];
                format = [format,'r'];
            end
            obj.fprint_nas(fid,format,data);
        end
    end
end

