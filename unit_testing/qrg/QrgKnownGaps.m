classdef QrgKnownGaps
    %QrgKnownGaps QRG fields Matran deliberately does not import.
    %
    % Each entry: {card, {QRG field names}, reason}. Only fields that are
    % irrelevant for Matran's use (plotting, FE model exchange) belong here;
    % everything else must be imported.

    properties (Constant)
        List = { ...
            'MAT8', {'"HFAIL"', 'HF1', 'HF2', 'HF3', 'HF4', 'HF10', 'HF11', ...
            '"HTAPE"', 'HT1', 'HT2', 'HT3', 'HT4', 'HT5', 'HT6', 'HT10', 'HT11', 'HT12', ...
            '"HFABR"', 'HFB1', 'HFB2', 'HFB3', 'HFB4', 'HFB5', 'HFB6', 'HFB10', 'HFB11', 'HFB12'}, ...
            ['Optional keyword lines (HFAIL/HTAPE/HFABR failure theory data, SOL 400 ', ...
            'progressive failure). Not used by the FE model exchange.']};
    end

    methods (Static)
        function f = fields(card)
            l = QrgKnownGaps.List;
            idx = strcmp(l(:, 1), card);
            f = [l{idx, 2}];
            if isempty(f)
                f = {};
            end
        end
    end
end
