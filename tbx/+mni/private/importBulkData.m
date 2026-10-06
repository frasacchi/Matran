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
%
% Revision: 2.0 (2026)
%   - Reading is done by mni.io.readDeck (sections, INCLUDE tree, small /
%     large / free field, continuations, replication), see
%     docs/bdf2baff/PROGRESS.md. Entries without a Matran class are kept
%     as mni.bulk.GenericCard objects (nothing is skipped).
%   - Optional output 'FileMeta.Deck' holds the read deck (Executive /
%     Case Control, PARAMs) for mni.analysis.buildInfo.
if nargin < 2 || isempty(logfcn)
    logfcn = @logger; %default is to print to command window
end

p = inputParser;
addParameter(p, 'ExpandInclude', false, @islogical);
addParameter(p, 'ImportMode', 'both');
addParameter(p, 'Verbose', true);
parse(p, varargin{:});

deck = mni.io.readDeck(filename, 'ExpandInclude', p.Results.ExpandInclude, ...
    'LogFcn', @(s) logfcn(s));

%PARAM / MDLPRM are solution settings (see mni.analysis.buildInfo)
cards = deck.Bulk(~ismember({deck.Bulk.Name}, {'PARAM', 'MDLPRM'}));
[FEModel, generic] = extractCards(cards, logfcn, p.Results.Verbose);

FileMeta.Deck        = deck;
FileMeta.SkippedBulk = {};
FileMeta.GenericBulk = generic;
FileMeta.UnknownBulk = generic;

end

%Parsing bulk data
function [FEM, generic] = extractCards(cards, logfcn, verbose)
%extractCards Creates one mni.bulk object per bulk data entry type and
%assigns every entry. Types without a class become mni.bulk.GenericCard.

logfcn('Extracting bulk data...');
FEM = mni.bulk.FEModel();
generic = {};
if isempty(cards)
    return
end
BulkDataMask = defineBulkMask();
names = {cards.Name};
[cardTypes, ~, iType] = unique(names, 'stable');
for iT = 1 : numel(cardTypes)
    cn  = cardTypes{iT};
    idx = find(iType == iT);
    nCard = numel(idx);
    [bClass, str] = isMatranClass(cn, BulkDataMask);
    if bClass
        BulkObj = feval(str, cn, nCard);
    else
        if ~isvarname(cn)
            logfcn(sprintf('%-10s %-8s (%8i) - invalid entry name', 'Skipped', cn, nCard));
            continue
        end
        BulkObj = mni.bulk.GenericCard(cn, nCard);
        generic{end + 1} = sprintf('%8s - %6i entry/entries', cn, nCard); %#ok<AGROW>
    end
    BulkMeta = getBulkMeta(BulkObj);
    if verbose
        pg = mni.util.textprogressbar(sprintf('%-10s %-8s (%8i)', 'Extracting', cn, nCard), logfcn);
    end
    step = max(1, floor(nCard / 20));
    for k = 1 : nCard
        c = cards(idx(k));
        try
            BulkObj.BulkAssignFunction(BulkObj, c.Fields, k, BulkMeta);
        catch ME
            error('mni:import:entry', '%s entry in %s (line %i):\n  %s\n  fields: %s', ...
                cn, c.File, c.Line, ME.message, strjoin(c.Fields, ' | '));
        end
        if verbose && (mod(k, step) == 0 || k == nCard)
            pg.update(k / nCard * 100);
        end
    end
    if verbose
        pg.close();
    end
    addItem(FEM, BulkObj);
end

end
