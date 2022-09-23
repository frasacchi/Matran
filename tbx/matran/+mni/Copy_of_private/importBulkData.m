function [FEModel, FileMeta] = importBulkData(filename, logfcn, varargin)
%importBulkData Imports the Nastran bulk data from a ASCII text file and
%returns a 'mni.bulk.FEModel' object containing the data.
%
% Syntax:
%	- Import a model from a text file (.bdf, .dat)
%       >> bulkFilename = 'myImportFile.bdf';
%       >> FEModel = importBulkData(bulkFilename);
%
% Detailed Description:
%	- Supports INCLUDE statements (in the entry point file and any nested
%	  INCLUDE files).
%
% References:
%	[1]. Nastran Getting Started Guide.
%   [2]. Nastran Quick Reference Guide.
%
% Author    : Christopher Szczyglowski
% Email     : chris.szczyglowski@gmail.com
% Timestamp : 13-Feb-2020 16:32:33
%
% Copyright (c) 2020 Christopher Szczyglowski
% All Rights Reserved
%
%
% Revision: 1.0 13-Feb-2020 16:32:33
%	- Initial function:
%
% <end_of_pre_formatted_H1>
%
% TODO - Look at whether we can take a sneak peak through all the files by
% only extracting the first 8 characters to understand file contents. Then
% we preallocate the objects and read the file in chunks instead of reading
% the whole file into the memory.

if nargin < 2
   logfcn = @logger; %default is to print to command window
end

%Import the data and return the 'mni.bulk.FEModel' object
[FEModel, skippedCards] = importBulkDataFromFile(filename, logfcn);

FileMeta.SkippedBulk = skippedCards;
FileMeta.UnknownBulk = strtrim(cellfun(@(x) x(1 : strfind(x, '-') - 1), skippedCards, 'Unif', false));

end

%Master function (recursive)
function [FEM, unknownBulk] = importBulkDataFromFile(bulkFilename, logfcn)
%importBulkDataFromFile Imports the bulk data from the file and returns an
%instance of the 'mni.bulk.FEModel' class.

[filepath,name,ext] = fileparts(bulkFilename);
% if ~isfile(bulkFilename)
%     filepath = fullfile(p.Results.filepath,filepath);
%     filename = fullfile(filepath,[name,ext]);
%     if ~isfile(filename)
%         error('the file "%s" does not exist in the current directory or at the filepath "%s"',bulkFilename,p.Results.filepath)
%     end
%     bulkFilename = filename;
% end
%Get raw text from the file
rawFileData = readCharDataFromFile(bulkFilename, logfcn);

%Split into Executive Control, Case Control and Bulk Data
[~, ~, bd, unresolvedBulk] = splitInputFile(rawFileData, logfcn);
bd = extractBulkData(bd);
%Extract "NASTRAN SYSTEM" commands from Executive Control

%Extract Case Control data

%Extract "PARAM" from Bulk Data
[Parameters, bd] = extractParameters(bd, logfcn);

%Extract "INCLUDE" statements and corresponding file names
[IncludeFiles, bd] = extractIncludeFiles(bd, logfcn,filepath);

%Extract bulk data
[FEM, unknownBulk] = extractCards(bd, logfcn);

%Loop through INCLUDE files (recursively)
[data, leftover] = cellfun(@(x) importBulkDataFromFile(x, logfcn),...
    IncludeFiles, 'Unif', false);

if ~isempty(data)
    logfcn(sprintf('Combining bulk data from file ''%s'' and any INCLUDE files...', bulkFilename));
    combine(horzcat(FEM, data{:}));
end

%Combine data & diagnostics from INCLUDE data
unknownBulk = [unknownBulk, cat(2, leftover{:})];

end

%Parsing bulk data
function [FEM, UnknownBulk] = extractCards(BulkData, logfcn)
%extractBulk Extracts the bulk data from the cell array
%'BulkData' and returns a collection of bulk data and
%aerodynamic bulk data as well as a cell array summarising the
%bulk data that has been skipped.

%Inform the user
logfcn('Extracting bulk data...');

%Preallocate
FEM = mni.bulk.FEModel();
UnknownBulk = {};

BulkDataMask = defineBulkMask();


%Extract all card names and continuation entries (for indexing)
names = cellfun(@(x)x{1},BulkData,'UniformOutput',false);
% get unique non-blank names
cardTypes = unique(names);

%Loop through cards - create objects & populate properties
for iCard = 1 : numel(cardTypes)   
    cn = cardTypes{iCard};  
    %Find all cards of this type in the collection BUT do not
    %include continuation lines. We are searching for the first
    %line of the card.
    idx = cellfun(@(x)~isempty(x),regexp(names,sprintf('^%s/*?',cn),'start'));
    nCard = nnz(idx);  
    if nCard == 0 %Catch
        continue
    end       
    [bClass, str] = isMatranClass(cn, BulkDataMask);
        
    %If the class exists then we can import the data, if not, skip it
    if bClass
        pg = mni.util.textprogressbar(sprintf('%-10s %-8s (%8i)', 'Extracting', ...
            cn, nCard));      
        %Initialise the object
        fcn     = str2func(str);
        BulkObj = fcn(cn, nCard);
        BulkMeta = getBulkMeta(BulkObj);
        cards = BulkData(idx);       
        %Extract data for each instance of the card
        for iCard = 1 : nCard %#ok<FXSET> 
            %Extract raw text data for this card and assign to the object
            propData =cards{iCard};
            BulkObj.BulkAssignFunction(BulkObj, propData(2:end), iCard, BulkMeta);
            %Strip the previous progress string and write the new one
            pg.update(iCard/nCard*100);
        end
        pg.close();
        
        %Add object to the model
        addItem(FEM, BulkObj);        
    else
        
        %Make a note of it
        logfcn(sprintf('%-10s %-8s (%8i)', 'Skipped', ...
            cn, nCard));
        UnknownBulk{end + 1} = sprintf( ...
            '%8s - %6i entry/entries', cn, nCard);
        
    end
    
end

end

function propData = extractBulkData(cardData)
% EXTRACTBULKDATA extracts each column entry of each row of the input 'cardData'
% 
% 'cardData' is a cell array where each cell is the string from the row in
% the bulk data entry section of a bdf file.
% this function returns propData which is a cell array in which each cell
% is another cell array of each column entry for a given card, where the
% first cell is the card name.
% - continuations are compressed onto one line and all +/* characters are
% removed
% 
% Author: Fintan Healy
% Date: 16/03/2021
% email: fintan.healy@bristol.ac.uk
%
    % remove blank rows
    blnk_idx = cellfun(@(x)~isempty(x),regexp(cardData,'^[\s]*$','match'));
    cardData(blnk_idx) = [];
    propData = cell(size(cardData));
    
    % extract comma seperated rows
    comma_idx = contains(cardData,',');
    if any(comma_idx)
        propData(comma_idx) = regexp(cardData(comma_idx),'[^,]*','match');
    end
    %extract include cards
    include_idx = ~comma_idx & contains(cardData,'INCLUDE');
    if any(include_idx)
        res = regexp(cardData(include_idx),'(.*) (.*)' ,'tokens');
        propData(include_idx) = cellfun(@(x)x{1},res,'UniformOutput',false);
    end
    
    % extract double precison cards
    long_idx = ~comma_idx & ~ include_idx & contains(cardData,'*');
    if any(long_idx)
        % split names
        expr = ['(.{0,8})',repmat('(.{0,16})',1,4)];
        propData(long_idx) = regexp(cardData(long_idx),expr,'tokens','once');
    end
    % extract cards in short form
    short_idx = ~(comma_idx|long_idx|include_idx);
    if any(short_idx)
        expr = repmat('(.{0,8})',1,9);
        propData(short_idx) = regexp(cardData(short_idx),expr,'tokens','once');
    end
    for i = 1:length(propData)
    % remove white space
       propData{i} = regexp(propData{i},'[^\s]*','match','once');
       % Check for scientific notation without 'E' e.g (-1.3-2) and replace with
       % standard form (-1.3E-2)
       propData{i} = regexprep(propData{i},'([0-9,\.])([+,-])(\d)','$1E$2$3');
    end
    
    %flatten continuations
    %cardRows = cellfun(@(x)isempty(x),regexp(cellfun(@(x)x{1},propData,'UniformOutput',false),'^[+\*]?'));
    cardRows = cellfun(@(x)x{1},propData,'UniformOutput',false);
    cardRows = ~(startsWith(cardRows,{'+','*'}) | cellfun(@isempty,cardRows));
    cardInds = [find(cardRows);length(cardRows)+1];
    propData(~cardRows) = cellfun(@(x)x(2:end),propData(~cardRows),...
        'UniformOutput',false);
    tmp_data = {};
    for i = 1:length(cardInds)-1
        tmp_data{i} = horzcat(propData{cardInds(i):cardInds(i+1)-1});
    end
    % remove stars
    for i = 1:length(tmp_data)
        tmp_data{i}{1} = regexprep(tmp_data{i}{1},'[/*]$','');
    end
    propData = tmp_data;
end