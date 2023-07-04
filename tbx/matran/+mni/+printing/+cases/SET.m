classdef SET
properties
     Name = 'SET'
     ID = 0
     GIDs = []
end
methods
    function obj = SET(id, gids)
        arguments
            id (1,1) {mustBeInteger,mustBePositive}
            gids (:,1)
        end
        obj.ID = id;
        obj.GIDs = gids;
    end
    function writeToFile(obj,fid)
        if isempty(obj.GIDs)
            fprintf(fid,'SET %.0f = ALL',obj.ID);
        else
            GIDs = unique(obj.GIDs);
            % group GIDs
            groups = {[GIDs(1)]};
            for i = 2:length(GIDs)
                if GIDs(i)-GIDs(i-1) == 1
                    groups{end} = [groups{end}, GIDs(i)];
                else
                    groups{end+1} = GIDs(i);
                end
            end
            %create ID string
            str = sprintf('SET %.0f =',obj.ID);
            for i = 1:length(groups)
                gr = groups{i};
                if length(gr)<4
                    for j = 1:length(gr)
                        str = [str,sprintf(' %.0f,',gr(j))];
                    end
                else
                    str = [str,sprintf(' %.0f THRU %.0f,',gr(1),gr(end))];
                end
            end
            str = str(1:end-1);
            % if string is to long split it after commas
            if length(str)>70
                str = strsplit(str,',');
                strs = {str{1}};
                for i = 2:length(str)
                    if (length(strs{end}) + length(str{i})+1)>70
                        strs{end} = [strs{end},','];
                        strs{end+1} = str{i};
                    else
                        strs{end} = [strs{end},',',str{i}];
                    end
                end
            else
                strs = {str};
            end
            % write to file
            for i = 1:length(strs)
                fprintf(fid,'%s\n',strs{i});
            end
        end
        
    end
end
end