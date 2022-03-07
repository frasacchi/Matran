function modify_sandbox_path(folders, option)
%modify_sandbox_path Add/remove sandbox folders from the MATLAB path.
%
% Original code taken from the Mathworks Toolbox Tools File Exchange code:
% https://www.mathworks.com/matlabcentral/fileexchange/60070-toolbox-tools
%
% Copyright 2016 The Mathworks, Inc.
%
% Edits by Christopher Szczyglowski, University of Bristol, 2020

assert(iscellstr(folders), ['Expected the folders to be provided ', ...
    'as a cell-array of strings.']); %#ok<ISCLSTR>
option = validatestring(option, {'add', 'remove'});

%Construct full file paths
tbx_folders = ["tbx","Examples"];
package_directory       = fileparts(mfilename('fullpath'));
idx = logical(size(folders));
for i = 1:length(tbx_folders)
    idx = idx & ~contains(folders,tbx_folders(i),'IgnoreCase',true);
end
package_sub_directories = fullfile(package_directory, reshape(folders(idx),[],1));

%Include all subdirectories in the 'tbx' and 'Examples' folder.
sub_directories = [];
for i = 1:length(tbx_folders)
    this_folder = fullfile(package_directory,tbx_folders(i));
    if isfolder(this_folder)
        sub_directories = [sub_directories;...
            this_folder;...
            get_sub_folders(fullfile(package_directory,tbx_folders(i)))];
    end
end
folder_path = [package_sub_directories ; sub_directories];

% Capture path
oldPathList = path();

% Add toolbox directory to saved path
userPathList = userpath();
if isempty( userPathList )
    userPathCell = cell( [0 1] );
else
    userPathCell = textscan( userPathList, '%s', 'Delimiter', ';' );
    userPathCell = userPathCell{:};
end
savedPathList = pathdef();
savedPathCell = textscan( savedPathList, '%s', 'Delimiter', ';' );
savedPathCell = savedPathCell{:};
savedPathCell = setdiff( savedPathCell, userPathCell, 'stable' );

switch option
    case 'add'
        
        savedPathCell = [folder_path; savedPathCell];
        path_fcn = @addpath;
        
    case 'remove'
        
        savedPathCell = setdiff( savedPathCell, folder_path, 'stable' );
        path_fcn = @rmpath;
        
end

path( sprintf( '%s;', userPathCell{:}, savedPathCell{:} ) )
savepath()

% Restore path plus toolbox directory
path( oldPathList )
path_fcn( sprintf( '%s;', folder_path{:} ) )

end

function folders = get_sub_folders(folderpath)
    % find all files in the directory
    files = dir(fullfile(folderpath,'**'));
    % extract all unique folders not in a namespace convention
    if strcmp(filesep,'\')
        sep = ['\\'];
    else
        sep = filesep;
    end
    folders = arrayfun(@(x)string(strsplit(x.folder,[sep,'+'])),...
        files,'UniformOutput',false);
    folders = unique(cellfun(@(x)x(1),folders));
    % remove origanal fold from results
    folders = folders(~strcmp(folders,folderpath));
end

