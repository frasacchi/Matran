function varargout = import_matran(filename, varargin)
%import_matran Entry point function for importing data into the Matran
%framework.
%
% Syntax:
%   - Importing Matran data using 'uigetfile' to select file.
%       >> MatranData = import_matran();
%
%   - Importing Matran data using 'uigetfile' and using parameters
%       >> MatranData = import_matran([], 'Param1', val1, ...)
%
%	- Importing a FE model from text file (.bdf, .dat)
%       >> FEM = import_matran('models/uob_harw_R.bdf')
%
%   - Importing a FE model from a MSC.Nastran HDF5 file (.h5)
%       >> FEM = import_matran()
%
%   - Importing data and suppressing output to log
%       >> FEM = import_matran(..., 'Verbose', false);
%
%   - Importing data and providing a custom log function
%       >> fid = fopen('import_diary.txt', 'w');
%       >> log_fcn = @(str, bNewLine, bLiteral) fprintf(fid, '%s', str)
%       >> FEM = import_matran(..., 'LogFcn', log_fcn);
%
%   - What the deck runs (SOL, subcases and the bulk data each Case
%     Control selection points to, PARAMs, every entry type read)
%       >> [FEM, Info] = import_matran('sol101.bdf');
%       >> disp(Info.Summary); Info.Cards
%
%   - Also build a baff model from the bulk data (requires baff)
%       >> [FEM, Info, Model] = import_matran('model.bdf', 'ToBaff', true);
%       >> Info.Baff   %conversion report
%
% Outputs:
%   MatranData - mni.bulk.FEModel (and result sets for .h5 files)
%   Info       - deck description, see mni.analysis.buildInfo
%   Model      - baff.Model (only with 'ToBaff', true), see
%                mni.baff.fromFEModel. Solution settings, loads and case
%                control stay in Info; the baff model is the structure /
%                aero model only.
%
% Parameters:
%   'Verbose'       (true)  print the import log
%   'LogFcn'        custom log function
%   'ExpandInclude' (true)  read INCLUDE files
%   'ToBaff'        (false) build the baff model (third output)
%   'BaffOptions'   ({})    name-value options of mni.baff.fromFEModel
%
% Detailed Description:
%	- The import function is selected based on the extension of the file.
%
% See also: 
%
% References:
%	[1]. 
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 29-Apr-2020 20:46:17
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 29-Apr-2020 20:46:17
%	- Initial function:
%
% <end_of_pre_formatted_H1>
%
% TODO - Add .pch output reading
% TODO - Add .f06 output reading
% TODO - Add .op2 output reading

varargout = {[], [], []};

%descriptor, extensions, import function
prmpt = 'Select a file to import';
file_map = { ...
    {'Nastran bulk data files', 'Nastran h5 files'}, ...
    {{'.dat', '.bdf', '.pch', '.nas', '.blk'}, {'.h5'}}           , ...
    {@importBulkData          , @importH5} ; ...
    {''}, {{''}}, {}};

if nargin < 1 || isempty(filename)
   filename = [];
end
[filename, import_fcn, log_fcn, args, opts] = parse_inputs(prmpt, file_map, filename, varargin{:});
if isempty(filename)
    return
end

%Import the data
[MatranData, Meta] = import_fcn(filename, log_fcn, args{:});

%Do post-import actions
FEModel = [];
idxModel = arrayfun(@(o) isa(o, 'mni.bulk.FEModel'), MatranData);
if any(idxModel)
    FEModel = MatranData(idxModel);
    %Print summary
    printSummary(FEModel, 'LogFcn', log_fcn, 'RootFile', filename);
    if isfield(Meta, 'GenericBulk') && ~isempty(Meta.GenericBulk)
        log_fcn(sprintf(['The following entries have no Matran class and are ', ...
            'kept as text (mni.bulk.GenericCard):\n\n\t%-s\n'], ...
            sprintf('%s\n\t', Meta.GenericBulk{:})));
    elseif isempty(Meta.SkippedBulk)
        log_fcn('All bulk data entries were successfully extracted!');
    else
        log_fcn(sprintf(['The following cards have not been extracted ', ...
            'from the file ''%s'':\n\n\t%-s\n'], filename, ...
            sprintf('%s\n\t', Meta.SkippedBulk{:})));
    end
    %Make indices between bulk data objects
    makeIndices(FEModel);
    %CORD1x systems are defined by grids: resolve them once all are known
    i_resolveCord1(FEModel);
end
idxRes = arrayfun(@(o) isa(o, 'mni.result.ResultSet'), MatranData);
if any(idxRes) && any(idxModel)
    Results = MatranData(idxRes);
    Results.processResultsData(FEModel);
end
varargout{1} = MatranData;

%Deck description (SOL, subcases, PARAMs, entry types)
if nargout > 1 || opts.ToBaff
    if isfield(Meta, 'Deck')
        Info = mni.analysis.buildInfo(Meta.Deck, FEModel);
        log_fcn(sprintf('%s\n', Info.Summary));
    else
        Info = struct('File', filename, 'Summary', 'HDF5 import', 'Cards', table());
    end
    varargout{2} = Info;
end

%baff model from the bulk data
if opts.ToBaff
    assert(~isempty(FEModel), 'mni:import:ToBaff', 'No bulk data imported from ''%s''.', filename);
    assert(exist('baff.Model', 'class') == 8, 'mni:import:ToBaff', ...
        '''ToBaff'' requires the baff toolbox on the MATLAB path.');
    bopts = opts.BaffOptions;
    if isstruct(bopts)
        bopts = namedargs2cell(bopts);
    end
    [Model, report] = mni.baff.fromFEModel(FEModel, Info, bopts{:});
    Info.Baff = report;
    varargout{2} = Info;
    varargout{3} = Model;
end

end

function [filename, import_fcn, log_fcn, args, opts] = parse_inputs(prmpt, file_map, filename, varargin)
%parse_inputs Checks the user inputs and returns the file name, import
%function handle and logging function handle.
import_fcn = [];

%Parse parameters
p = inputParser;
addParameter(p, 'LogFcn' , @logger, @(x)isa(x, 'function_handle'));
addParameter(p, 'Verbose', true   , @(x)validateattributes(x, {'logical'}, {'scalar'}));
addParameter(p, 'ImportMode', 'both');
addParameter(p, 'ExpandInclude', true, @islogical);
addParameter(p, 'ToBaff', false, @islogical);
addParameter(p, 'BaffOptions', {}, @(x) iscell(x) || isstruct(x));
parse(p, varargin{:});

if p.Results.Verbose
    log_fcn = p.Results.LogFcn;
else
    log_fcn = @(s, a, b) fprintf(''); %dummy function
end
opts = struct('ToBaff', p.Results.ToBaff, 'BaffOptions', {p.Results.BaffOptions});

%Construct additional arguments to be passed straight to import method
args = {'ImportMode', p.Results.ImportMode};
args = [args, {'ExpandInclude', p.Results.ExpandInclude, 'Verbose', p.Results.Verbose}];

%Number of categories of files we are dealing with
%   - e.g. input data, results, etc.
nType    = size(file_map, 1); 
if isempty(filename) %Ask the user
    %Make the file-extension mapping for uigetfile
    strs = cell(1, nType);
    exts = cell(1, nType);
    for jj = 1 : nType
       ext_      = cellfun(@(x) strcat('*', x), file_map{jj, 2}, 'Unif', false);
       strs{jj}  = arrayfun(@(ii) sprintf('%s (%s)', file_map{jj, 1}{ii}, ...
            strjoin(strcat(ext_{ii}, ','))), 1 : numel(file_map{jj, 1}), 'Unif', false);
       exts{jj}  = cellfun(@(x) strjoin(x, '; '), ext_, 'Unif', false);
    end
    %Ask the user where the file is
    [filename, filepath] = uigetfile([horzcat(exts{:}) ; horzcat(strs{:})]', prmpt);
    if isnumeric(filename) && isnumeric(filepath)    
        filename = [];
        return
    else
        filename = fullfile(filepath, filename);
    end
end
validateattributes(filename, {'char'}, {'row', 'nonempty'}, mfilename, 'filename');

%Check file exists and is of the correct type
listValidExt = horzcat(file_map{:, 2});
allValidExt  = horzcat(listValidExt{:});
assert(exist(filename, 'file') == 2, ['File ''%s'' does not exist. Check ', ...
    'the filename and try again.'], filename);
[~, ~, ext] = fileparts(filename);
assert(any(strcmp(ext, allValidExt)), ['Expected the file to have one ', ...
    'of the following extensions:\n\n\t%s'], strjoin(allValidExt, '\n\t'));

%Associate extension with a particular row in the map
idx_type = false(nType, 1);
for ii = 1 : nType
    temp = file_map{ii, 2};
    idx_type(ii) = any(contains(horzcat(temp{:}), ext));
end

%Find the import function that corresponds to this extension
idx_fcn = cellfun(@(ext_list) any(contains(ext_list, ext)), listValidExt);
import_fcn = file_map{idx_type, 3}{idx_fcn};

end

function i_resolveCord1(FEModel)
%i_resolveCord1 Frames of the CORD1R / CORD1C / CORD1S entries in basic, so
%that CoordSystem.getPosition / getVector (GRID CP / CD) work for them.
if ~any(ismember(FEModel.UniqueClass, 'mni.bulk.CoordSystem'))
    return
end
obj = getItem(FEModel, 'mni.bulk.CoordSystem', true);
isCord1 = arrayfun(@(o) startsWith(o.CardName, 'CORD1'), obj);
if ~any(isCord1)
    return
end
try
    geo = mni.util.Geometry(FEModel);
    for o = reshape(obj(isCord1), 1, [])
        resolveFrames(o, geo);
    end
catch err
    warning('mni:import:cord1', 'CORD1x systems not resolved: %s', err.message);
end
end
