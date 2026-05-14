function [files,BulkData] = extractIncludeFiles(BulkData,logfcn,filepath)
%extractIncludeFiles Finds all 'INCLUDE' statements in the raw file data
%and replaces them with the contents of that file. This function operates
%on a cell array of lines, which is the expected format.
%   - This is a recursive function.


idx  = cellfun(@(x)contains(x{1},'INCLUDE','IgnoreCase',true),BulkData);
if ~any(idx)
    files = {};
    return
end

logfcn(sprintf('Found %i INCLUDE statements. Expanding file contents...\n', numel(idx)));

% get file names
files = cellfun(@(x)join(x(2:end),''),BulkData(idx));
%stitch together all lines
files = regexprep(files,'[\r]','');
% remove quotation marks
files = regexprep(files,'[''"]','');

    function filename = checkfile(filename,filepath)
        if ~isfile(filename)

            % Determine if filename is an absolute path
            is_absolute_path = false;
            if ispc % On Windows systems
                % Check for drive letter (e.g., C:) followed by a path separator
                if numel(filename) >= 3 && filename(2) == ':' && (filename(3) == '\' || filename(3) == '/')
                    is_absolute_path = true;
                end
            end

            % Also check for paths starting with a path separator (e.g., / or \)
            % This covers Unix-like paths and also Windows paths starting with \ (root of current drive)
            if startsWith(filename, filesep) || startsWith(filename, '/')
                is_absolute_path = true;
            end

            if ~is_absolute_path
                filename = fullfile(filepath,filename); % Treat as relative path
            end

            if ~isfile(filename)
                error('the file "%s" does not exist in the current directory or at the filepath "%s"',filename,filepath)
            end

        end
    end

files = cellfun(@(x)checkfile(x,filepath),files,'UniformOutput',false);
% remove from bulkData
BulkData(idx) = [];

%Inform progress
logfcn(sprintf('Found the following included files:'));
logfcn(sprintf('\t- %s\n',files{:}));

% Find the LINE INDICES of all 'INCLUDE' statements.
% '(?i)' makes the search case-insensitive. '^' ensures it's at the start.

% include_line_indices = find(startsWith(rawData, 'INCLUDE', 'IgnoreCase', true));

% if isempty(include_line_indices)
%     return; % No INCLUDE statements found, we are done with this file.
% end

% % Loop through the found statements backwards to preserve array indices during replacement.
% for ii = numel(idx):-1:1

%     line_idx = idx(ii);
%     current_line = rawData{line_idx};

%     % --- MODIFICATION START ---
%     % Handle multi-line INCLUDE statements by concatenating continuation lines.
%     lines_to_remove = 0;
%     if ~endsWith(strtrim(current_line), '''') % If the line doesn't end with a quote, it's a multi-line statement
%         % Start with the first line, ensuring no trailing whitespace/newlines
%         line_parts = {strtrim(current_line)};
%         next_line_idx = line_idx + 1;
%         while next_line_idx <= numel(rawData) && startsWith(rawData{next_line_idx}, '        ')
%             % Append the trimmed content of the continuation line to our parts
%             line_parts{end+1} = strtrim(rawData{next_line_idx}); %#ok<AGROW>
%             lines_to_remove = lines_to_remove + 1;
%             next_line_idx = next_line_idx + 1;
%             if endsWith(line_parts{end},'''')
%                 break; % Stop if we've found the closing quote
%             end
%         end
%         % Join the parts together into a single line with no delimiters
%         current_line = strjoin(line_parts, '');
%     end

%     % Extract the filename from the (potentially concatenated) line using a regular expression.
%     inc_file_token = regexp(current_line, '(?i)^INCLUDE\s+''([^'']*)''', 'tokens', 'once');

%     if isempty(inc_file_token)
%         warning('Could not parse INCLUDE statement starting on line %d: "%s". Skipping.', line_idx, rawData{line_idx});
%         continue;
%     end

%     inc_filename = inc_file_token{1};
%     % Replace any double single-quotes with a single one, which can occur from concatenation
%     inc_filename = strrep(inc_filename, '''''', '''');
%     inc_filename = strtrim(inc_filename); % Trim any leading/trailing whitespace

%     % Determine if inc_filename is an absolute path
%     is_absolute_path = false;
%     if ispc % On Windows systems
%         % Check for drive letter (e.g., C:) followed by a path separator
%         if numel(inc_filename) >= 3 && inc_filename(2) == ':' && (inc_filename(3) == '\' || inc_filename(3) == '/')
%             is_absolute_path = true;
%         end
%     end
%     % Also check for paths starting with a path separator (e.g., / or \)
%     % This covers Unix-like paths and also Windows paths starting with \ (root of current drive)
%     if startsWith(inc_filename, filesep) || startsWith(inc_filename, '/')
%         is_absolute_path = true;
%     end

%     if is_absolute_path
%         inc_file_path = inc_filename; % Use the absolute path directly
%     else
%         inc_file_path = fullfile(root_path, inc_filename); % Treat as relative path
%     end

%     % Check if the included file exists
%     if ~exist(inc_file_path, 'file')
%         warning('The included file ''%s'' could not be found. Skipping.', inc_file_path);
%         continue;
%     end

%     % Read the data from the included file INTO A NEW CELL ARRAY OF LINES
%     logfcn(sprintf('Adding contents of included file: %s', inc_file_path));
%     % 'textread' is a simple way to read a file line-by-line into a cell array
%     inc_rawData_lines = textread(inc_file_path, '%[^\n]'); %#ok<DTXTRD>

%     % Recursively check for more INCLUDE statements in the new content
%     inc_root_path = fileparts(inc_file_path);
%     inc_rawData_lines = extractIncludeFiles(inc_rawData_lines, inc_root_path, logfcn);


%     % **The Core Logic:** Replace the single 'INCLUDE' line with the
%     % entire content of the included file.
%     rawData = [
%         rawData(1:line_idx-1);      % Lines before the INCLUDE statement
%         inc_rawData_lines;          % The new lines from the included file
%         rawData(line_idx + lines_to_remove + 1:end) % Lines after the INCLUDE and its continuation lines
%     ];

% end
end