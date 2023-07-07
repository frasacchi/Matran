classdef DLOAD < mni.printing.cards.BaseCard
    %FLUTTER_CARD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SID;
        S;
        Ss;
        Ls;
    end
    
    methods
        function obj = DLOAD(SID,S,Ss,Ls)
            if numel(Ss)~=numel(Ls)
                error('Ss and Ls must be the same length')
            end            
            p = inputParser();
            p.addRequired('SID',@(x)x>0)
            p.addRequired('S')
            p.addRequired('Ss',@(x)numel(x)>=1)
            p.addRequired('Ls',@(x)numel(x)>=1)            
            p.parse(SID,S,Ss,Ls)  

            obj.SID = SID;
            obj.S = S;
            obj.Ss = Ss;
            obj.Ls = Ls;  
            obj.Name = 'DLOAD';
            
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            data = [{obj.SID},{obj.S}];
            format = 'ir';
            for i = 1:length(obj.Ss)
                data = [data,obj.Ss(i),obj.Ls(i)];
                format = [format,'ri'];
            end
            obj.fprint_nas(fid,format,data);
        end
    end
end

