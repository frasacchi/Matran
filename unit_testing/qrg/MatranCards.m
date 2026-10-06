classdef MatranCards
    %MatranCards Introspection of the bulk data entries Matran can import.
    %
    % Syntax:
    %   >> t = MatranCards.list();            %struct array: Card, Class
    %   >> [pos, info] = MatranCards.layout('CBEAM');
    %
    % 'pos' is the field layout Matran assumes when it reads the entry,
    % flattened like QrgSpec.formatFields (fields 2..9 of every line). Each
    % element is the property that receives the field ('X(2)' for the 2nd
    % row of a masked property) or '' for a field that is skipped.

    methods (Static)
        function t = list()
            %list All (card, class) pairs of the mni.bulk package.
            persistent cache
            if ~isempty(cache)
                t = cache;
                return
            end
            pkg = meta.package.fromName('mni.bulk');
            t = struct('Card', {}, 'Class', {});
            for mc = pkg.ClassList'
                if mc.Abstract || ~any(strcmp(superclasses(mc.Name), 'mni.bulk.BulkData')) ...
                        || strcmp(mc.Name, 'mni.bulk.FEModel')
                    continue
                end
                try
                    obj = feval(mc.Name);
                catch
                    continue
                end
                names = obj.ValidBulkNames;
                for i = 1 : numel(names)
                    t(end + 1) = struct('Card', names{i}, 'Class', mc.Name); %#ok<AGROW>
                end
            end
            [~, idx] = sort({t.Card});
            t = t(idx);
            cache = t;
        end
        function cls = classOf(card)
            t = MatranCards.list();
            idx = strcmp({t.Card}, card);
            assert(any(idx), 'MatranCards:unknown', 'Matran has no class for ''%s''.', card);
            cls = t(find(idx, 1)).Class;
        end
        function [pos, info] = layout(card)
            %layout Positional field layout Matran uses for 'card'.
            obj  = feval(MatranCards.classOf(card), card, 1);
            meta = getBulkMeta(obj);
            fmt  = meta.Format;
            nb   = find(fmt ~= 'b');
            slot = cell(1, numel(nb));
            for i = 1 : numel(meta.Names)
                n = meta.Bounds(2, i) - meta.Bounds(1, i) + 1;
                for k = 1 : n
                    if n == 1
                        slot{meta.Bounds(1, i) + k - 1} = meta.Names{i};
                    else
                        slot{meta.Bounds(1, i) + k - 1} = sprintf('%s(%d)', meta.Names{i}, k);
                    end
                end
            end
            pos = repmat({''}, 1, numel(fmt));
            pos(nb) = slot;
            info.Format   = fmt;
            info.ListProp = meta.ListProp;
            info.Names    = meta.Names;
            info.Object   = obj;
            %Position of the first list field. 'ListStart' is what
            %BulkData.assignListCardData actually uses (one field per name
            %before the list); 'IntendedListStart' accounts for blanks and
            %masked properties. A difference is a Matran bug.
            info.ListStart = [];
            info.IntendedListStart = [];
            if ~isempty(meta.ListProp)
                first = find(ismember(meta.Names, meta.ListProp), 1);
                info.ListStart = first;
                nSlots = meta.Bounds(1, first) - 1;
                if nSlots == 0
                    info.IntendedListStart = 1;
                else
                    info.IntendedListStart = nb(nSlots) + 1;
                end
            end
        end
    end
end
