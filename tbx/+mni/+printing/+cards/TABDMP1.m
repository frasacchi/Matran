classdef TABDMP1 < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        TID;
        TYPE;
        Fs;
        Gs;
    end
    
    methods
        function obj = TABDMP1(TID,TYPE,Fs,Gs)
            %CAERO1 Construct an instance of this class
            %   required inputs are as follows:
            % SID,METHOD
            %
            % optional parameters are:
            % F1, F2, NE, ND, NORM, G, C
            %
            % see NASTRAN users guide for more info
            types = {'G','CRIT','Q'};
            if numel(Fs)~=numel(Gs)
                error('Fs and Gs must be the same length')
            end            
            p = inputParser();
            p.addRequired('TID',@(x)x>0)
            p.addRequired('TYPE',@(x)any(validatestring(x,types)))
            p.addRequired('Fs',@(x)numel(x)>1 && all(x>=0))
            p.addRequired('Gs',@(x)numel(x)>1)            
            p.parse(TID,TYPE,Fs,Gs)  

            obj.TID = TID;
            obj.TYPE = TYPE;
            obj.Fs = Fs;
            obj.Gs = Gs;  
            obj.Name = 'TABDMP1';
            
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.TID},{obj.TYPE}];
            format = 'isn';
            for i = 1:length(obj.Fs)
                data = [data,obj.Fs(i),obj.Gs(i)];
                format = [format,'rr'];
            end
            data = [data,'ENDT'];
            format = [format,'s'];
            obj.fprint_nas(fid,format,data);
        end
    end
end

