function [files, BulkData] = extractIncludeFiles(BulkData, logfcn, parentPath)
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

% get file names
files = cellfun(@(x)x{2},BulkData(idx),'UniformOutput',false);

% remove quotation marks
files = regexp(files,'[^''"]*','match');
%Check if absolute or relative path
rel_path = cellfun(@(x)isempty(fileparts(x{1})),files);
% append relative paths with the current directory
files(rel_path) = cellfun(@(x)fullfile(parentPath,x),...
    files(rel_path),'UniformOutput',false);
files = cellfun(@(x)x{1},files,'UniformOutput',false);
% remove from bulkData
BulkData(idx) = [];

%Inform progress
logfcn(sprintf('Found the following included files:'));
logfcn(sprintf('\t- %s\n',files{:}));
end
