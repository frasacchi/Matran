function [Parameters, BulkData] = extractParameters(BulkData, logfcn)
%extractParameters Extracts the parameters from the bulk data
%and returns the cell array 'BulkData' with all parameter lines
%removed.
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
%	[1]. "Can quantum-mechanical description of physical reality be
%         considered complete?", A Einstein, Physical Review 47(10):777,
%         American Physical Society 1935, 0031-899X
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 01-May-2020 08:21:02
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 01-May-2020 08:21:02
%	- Initial function:
%
% <end_of_pre_formatted_H1>

if nargin < 2 || isempty(logfcn)
    logfcn = @(s) fprintf('');
end

%Extract the name-value data for each parameter
[Parameters.PARAM,idx_PARAM]  = i_extractParamValue(BulkData,'PARAM', logfcn);
[Parameters.MDLPRM,idx_MDLPRM]  = i_extractParamValue(BulkData,'MDLPRM', logfcn);

%Remove all parameters from 'BulkData'
BulkData = BulkData(~or(idx_PARAM, idx_MDLPRM));

    function [paramOut,idx] = i_extractParamValue(paramData,param_str,logfcn)
        idx  = cellfun(@(x)contains(x{1},param_str),paramData);
             
        %extractParamValue Extracts the parameter name and value
        %from each line in 'paramData'.
        
        if ~any(idx) %Escape route
            paramOut = [];
            return
        end      
        %Preallocate
        [name,value]  = deal(cell(nnz(idx),1));
        ind = find(idx);
        for i = 1 : nnz(idx)
            row = paramData{ind(i)};
            name{i}  = row{2};
            value{i} = row{3};
        end
        %Convert to structure
        paramOut = cell2struct(value, name);        
        %Inform progress
        logfcn(sprintf('Extracted the following parameters:'));
        logfcn(sprintf('\t- %s\n', name{:}));       
    end
end
