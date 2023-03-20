function [files, BulkData] = extractIncludeFiles(BulkData, logfcn,filepath)
%extractIncludeFiles Extracts the path to any files containing
%data that is included in the bulk data.
%
% Syntax:
%	- Brief explanation of the syntax...
%
% Detailed Description:
%	- Detailed explanation of the function and how it works...
%
% See also: 
%
% References:
%	[1]. 
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 19-Apr-2020 16:03:13
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 19-Apr-2020 16:03:13
%	- Initial function:
%
% <end_of_pre_formatted_H1>
if nargin < 2 || isempty(logfcn)
    logfcn = @(s) fprintf('');
end
if nargin < 3
    parentPath = '';
end

%Find all lines containing "INCLUDE"
idx  = cellfun(@(x)contains(x{1},'INCLUDE'),BulkData);
if ~any(idx)
   files = {};
   return 
end
% get file names
files = cellfun(@(x)join(x(2:end),''),BulkData(idx));
%stitch together all lines
% remove quotation marks
files = regexprep(files,'[''"]','');
function filename = checkfile(filename,filepath)
    if ~isfile(filename)
        if ~isfile(fullfile(filepath,filename))
            error('the file "%s" does not exist in the current directory or at the filepath "%s"',filename,filepath)
        end
        filename = fullfile(filepath,filename);
    end
end
files = cellfun(@(x)checkfile(x,filepath),files,'UniformOutput',false);
% remove from bulkData
BulkData(idx) = [];

%Inform progress
logfcn(sprintf('Found the following included files:'));
logfcn(sprintf('\t- %s\n',files{:}));
end
