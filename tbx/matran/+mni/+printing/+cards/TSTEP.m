classdef TSTEP < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SID;
        Ns;
        DTs;
        NOs=[];
    end
    
    methods
        function obj = TSTEP(SID,Ns,DTs,NOs)
            %FLUTTER_CARD Construct an instance of this class
            %   Detailed explanation goes here
            if ~exist('NOs','var')
                NOs = ones(size(Ns));
            end
            if numel(Ns) ~= numel(DTs) || numel(Ns) ~= numel(NOs)
                error('Ns,DTs,and NOs must be arrays of the same length')
            end
            obj.SID = SID;
            obj.Ns = Ns;
            obj.DTs = DTs;
            obj.NOs = NOs;
            obj.Name = 'TSTEP';
            
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.SID},{obj.Ns(1)},{obj.DTs(1)},{obj.NOs(1)}];
            format = 'iiri';
            for i = 2:length(obj.Ns)
                data = [data,{obj.Ns(i)},{obj.DTs(i)},{obj.NOs(i)}];
                format = [format,'nbiri'];
            end
            obj.fprint_nas(fid,format,data);
        end
    end
end

