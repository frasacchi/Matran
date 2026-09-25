classdef MAT8 < mni.printing.cards.BaseCard
    %MAT8 Defines the material properties for a 2D orthotropic material.
    %-- TODO - fix edge cases (too many required properties)

    properties
        MID; E1; E2; NU12; G12; G1Z; G2Z; RHO; A1; A2; TREF;
        Xt; Xc; Yt; Yc; S; GE; F12; STRN;

        FailureCriterion;
        HFi;
        HTi;
        HFBi;
    end

    methods
        function obj = MAT8(MID,opts)
            arguments
                MID (1,1) {mustBePositive}

                opts.E1   {mustBePositive} = []
                opts.E2   {mustBePositive} = []
                opts.NU12 {mustBeNumeric}  = []
                opts.G12  {mustBePositive} = []
                opts.G1Z  {mustBeNumeric}  = []
                opts.G2Z  {mustBeNumeric}  = []
                opts.RHO  {mustBeNumeric}  = []
                opts.A1   {mustBeNumeric}  = []
                opts.A2   {mustBeNumeric}  = []
                opts.TREF {mustBeNumeric}  = []
                opts.Xt   {mustBeNumeric}  = []
                opts.Xc   {mustBeNumeric}  = []
                opts.Yt   {mustBeNumeric}  = []
                opts.Yc   {mustBeNumeric}  = []
                opts.S    {mustBeNumeric}  = []
                opts.GE   {mustBeNumeric}  = []
                opts.F12  {mustBeNumeric}  = []
                opts.STRN {mustBeNumeric}  = []

                opts.FailureCriterion {mustBeMember(opts.FailureCriterion, ["","HFAIL","HTAPE","HFABR"])} = ""
                opts.HFi  (1,:) {mustBeNumeric} = []
                opts.HTi  (1,:) {mustBeNumeric} = []
                opts.HFBi (1,:) {mustBeNumeric} = []
            end

            % Required properties
            obj.MID = MID;

            % Optional properties
            optionNames = fieldnames(opts);
            for i = 1:length(optionNames)
                obj.(optionNames{i}) = opts.(optionNames{i});
            end

            obj.Name = 'MAT8';
        end

        function writeToFile(obj, fid, varargin)
            writeToFile@mni.printing.cards.BaseCard(obj, fid, varargin{:});
            if isempty(obj.MID); return; end

            if obj.LongFormat
                head = 'MAT8*'; cont = '*'; w = 16; perLine = 4; prec = 10;
            else
                head = 'MAT8';  cont = '+'; w = 8;  perLine = 8; prec = 5;
            end

            fields = {obj.MID, obj.E1, obj.E2, obj.NU12, ...
                obj.G12, obj.G1Z, obj.G2Z, obj.RHO, ...
                obj.A1,  obj.A2,  obj.TREF, obj.Xt, ...
                obj.Xc,  obj.Yt,  obj.Yc,  obj.S, ...
                obj.GE,  obj.F12, obj.STRN};

            last = find(~cellfun(@isempty, fields), 1, 'last');
            if isempty(last); return; end
            fields = fields(1:last);

            switch obj.FailureCriterion
                case 'HFAIL'; vals = obj.HFi;
                case 'HTAPE'; vals = obj.HTi;
                case 'HFABR'; vals = obj.HFBi;
                otherwise;    vals = [];
            end
            hasFail = ~isempty(vals);

            nLines = ceil(numel(fields) / perLine);
            fields(end+1:nLines*perLine) = {[]};

            blank = repmat(' ', 1, w);
            for li = 1:nLines
                if li == 1
                    line = sprintf('%-8s', head);
                else
                    line = sprintf('%-8s', cont);
                end
                for fi = 1:perLine
                    f = fields{(li-1)*perLine + fi};
                    if isempty(f)
                        s = blank;
                    elseif li == 1 && fi == 1
                        s = sprintf(['%-', num2str(w), 'd'], f);
                    else
                        s = obj.fmtField(f, w, prec);
                    end
                    line = [line, s];
                end
                if li < nLines || hasFail
                    line = [line, cont];
                end
                fprintf(fid, '%s\n', line);
            end

            if hasFail
                line = sprintf('%-8s', cont);
                line = [line, sprintf(['%-', num2str(w), 's'], obj.FailureCriterion)];
                for v = vals
                    line = [line, obj.fmtField(v, w, prec)];
                end
                fprintf(fid, '%s\n', line);
            end
        end

        function s = fmtField(~, val, w, prec)
            s = sprintf(['%.', num2str(prec), 'g'], val);
            if ~contains(s, '.') && ~contains(lower(s), 'e')
                s = [s, '.'];
            end
            if length(s) > w
                s = sprintf(['%.', num2str(max(prec-3, 1)), 'e'], val);
                if length(s) > w; s = s(1:w); end
            end
            s = sprintf(['%-', num2str(w), 's'], s);
        end

    end
end
