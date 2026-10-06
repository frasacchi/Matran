function ids = entryIds(obj)
%entryIds Identification number (field 2) of every entry of a bulk data
%object, NaN where there is none.
%
% Syntax:
%   >> ids = mni.analysis.entryIds(fem.SPC1)

n = obj.NumBulk;
if isa(obj, 'mni.bulk.GenericCard')
    ids = str2double(obj.FIELD2);
    return
end
ids = nan(1, n);
id = obj.ID;
if numel(id) == n
    ids = double(id(:)');
    return
end
%no ID property: first data field when it is numeric
props = obj.CurrentBulkDataProps;
if ~isempty(props)
    v = obj.(props{1});
    if isnumeric(v) && size(v, 2) == n
        ids = double(v(1, :));
    end
end
end
