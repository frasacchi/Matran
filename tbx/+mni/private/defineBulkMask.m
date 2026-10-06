function BulkDataMask = defineBulkMask()
%defineBulkMask Defines the cross-references between bulk data types and
%bulk data objects.
%
% The map is built from the class constructors of the mni.bulk package.

persistent mask
if isempty(mask)
    %Every bulk data type declared by a class of the mni.bulk package
    %(the class constructors define their valid bulk data names)
    mask = struct();
    pkg  = meta.package.fromName('mni.bulk');
    for mc = pkg.ClassList'
        if mc.Abstract || strcmp(mc.Name, 'mni.bulk.FEModel') || ...
                ~any(strcmp(superclasses(mc.Name), 'mni.bulk.BulkData'))
            continue
        end
        try
            obj = feval(mc.Name);
        catch
            continue
        end
        for n = obj.ValidBulkNames
            if isvarname(n{1}) && ~isfield(mask, n{1})
                mask.(n{1}) = mc.Name;
            end
        end
    end
end
BulkDataMask = mask;

end