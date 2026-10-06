classdef GenericCard < mni.bulk.BulkData
    %GenericCard Bulk data entry type that Matran has no class for.
    %
    % Nothing in a .bdf is dropped on import: every entry without a
    % dedicated class is stored as text in a GenericCard object named
    % after the entry (e.g. FEModel.PLOAD4). 'Fields' holds, per entry,
    % the data fields as Nastran reads them (fields 2..9 of the parent line
    % followed by fields 2..9 of each continuation, see
    % mni.io.tokenizeBulk), so the QRG field positions apply directly.
    %
    % Syntax:
    %   >> obj = mni.bulk.GenericCard('PLOAD4', 10);
    %   >> v = field(obj, 3);        %3rd data field of every entry (cellstr)
    %   >> v = fieldNum(obj, 3);     %... as numbers (NaN if blank / text)

    properties (Hidden = true)
        %Data fields of each entry (cellstr per entry)
        Fields = {};
    end

    methods
        function obj = GenericCard(name, nBulk)
            if nargin < 1
                name = 'GENERIC';
            end
            if nargin < 2
                nBulk = 1;
            end
            addBulkDataSet(obj, name, ...
                'BulkProps'  , {'FIELD2'}, ...
                'PropTypes'  , {'c'}     , ...
                'PropDefault', {''}      , ...
                'SetMethod'  , {'FIELD2', @validateText});
            parse(obj, name, nBulk);
            preallocate(obj);
            obj.EntryProps = {'Fields'};
            obj.Fields = repmat({{}}, 1, nBulk);
            obj.BulkAssignFunction = @assignGenericData;
        end
        function assignGenericData(obj, propData, index, ~)
            f = strtrim(reshape(propData, 1, []));
            last = find(~cellfun(@isempty, f), 1, 'last');
            if isempty(last)
                f = {};
            else
                f = f(1 : last);
            end
            obj.Fields{index} = f;
            if ~isempty(f)
                obj.FIELD2{index} = f{1};
            end
        end
        function v = field(obj, k)
            %field Data field 'k' (k = 1 is field 2 of the entry) of every
            %entry as text ('' if absent).
            v = repmat({''}, 1, numel(obj.Fields));
            for i = 1 : numel(obj.Fields)
                if numel(obj.Fields{i}) >= k
                    v{i} = obj.Fields{i}{k};
                end
            end
        end
        function v = fieldNum(obj, k)
            %fieldNum Data field 'k' of every entry as a number.
            v = str2double(field(obj, k));
        end
    end
end
