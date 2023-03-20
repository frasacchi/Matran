classdef INCLUDE < mni.printing.cards.BaseCard
    %INCLUDE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        File;
    end
    
    methods
        function obj = INCLUDE(File)
            %INCLUDE Construct an instance of this class
            %   Detailed explanation goes here        
            obj.File = File;
            obj.Name = 'INCLUDE';
        end
        
        function writeToFile(obj,fid,varargin)
            %writeToFile print DMI entry to file
            writeToFile@mni.printing.cards.BaseCard(obj,fid,varargin{:})
            %convert to literal string
            filepath = strrep(convertStringsToChars(obj.File),'\','\\');
            fileSections = strsplit(filepath,'\\');
            if length(fileSections) == 1;
                lines = fileSections;
            else
                lines = join(fileSections(1:2),'\\');
            end
            for i = 3:length(fileSections)
                if length(lines{end}) + length(fileSections{i}) + 1 + 2 > 60
                    lines{end+1} = ['\\',fileSections{i}];
                else
                    lines{end} = [lines{end},'\\',fileSections{i}];
                end
            end
            format = '';
            lines{1} = ['''',lines{1}];
            lines{end} = [lines{end},''''];
            for i = 1:length(lines)
                format = [format,'sn'];
            end
            obj.fprint_nas(fid,format,lines);
        end
    end
end

