function sids = combinedSets(obj, idx)
%combinedSets Set identification numbers referenced by combination
%entries (SPCADD, MPCADD, LOAD, DLOAD) of object 'obj' at entries 'idx'.
%Empty for every other entry type.
%
% Syntax:
%   >> sids = mni.analysis.combinedSets(fem.SPCADD, 1)

sids = zeros(1, 0);
switch obj.CardName
    case {'SPCADD', 'MPCADD'}
        for k = idx(:)'
            if isa(obj, 'mni.bulk.GenericCard')
                v = str2double(obj.Fields{k}(2 : end));
            else
                v = obj.Si{k};
            end
            sids = [sids, v(~isnan(v))]; %#ok<AGROW>
        end
    case 'LOAD'
        for k = idx(:)'
            sids = [sids, obj.Li{k}]; %#ok<AGROW>
        end
    case 'DLOAD'
        for k = idx(:)'
            f = obj.Fields{k};
            v = str2double(f(4 : 2 : end)); %SID S S1 L1 S2 L2 ...
            sids = [sids, v(~isnan(v))]; %#ok<AGROW>
        end
end
end
