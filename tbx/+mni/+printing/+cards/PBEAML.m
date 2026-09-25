classdef PBEAML < mni.printing.cards.BaseCard
    %PBEAML Defines the properties of a beam element by cross-sectional dimensions.

    properties
        PID;   % Property identification number (Integer > 0)
        MID;   % Material identification number (Integer > 0)
        GROUP; % Cross-section group (Default="MSCBML0")
        TYPE;  % Cross-section shape

        % Sections should be an array of structs or objects containing:
        % .DIM : Array of dimensions (up to 14)
        % .NSM : Non-structural mass (Double)
        % .SO  : Stress output request ("YES" or "NO") (Required for stations > 1)
        % .X   : Distance ratio X/XB (Required for stations > 1; must equal 1.0 for End B)
        Sections;
    end

    methods
        function obj = PBEAML(PID, MID, TYPE, Sections, opts)
            %PBEAML Construct an instance of the PBEAML class
            arguments
                PID (1,1) double {mustBePositive}
                MID (1,1) double {mustBePositive}
                % Restrict TYPE to the allowed MSCBML0 cross-section shapes
                TYPE (1,1) string {mustBeMember(TYPE, ["ROD", "TUBE", "TUBE2", "L", "I", "CHAN", "T", "BOX", "BAR", "CROSS", "H", "T1", "I1", "CHAN1", "Z", "CHAN2", "T2", "BOX1", "HEXA", "HAT", "HAT1", "DBOX"])}
                Sections (:,1)
                opts.GROUP (1,1) string = "MSCBML0"
            end
            obj.PID = PID;
            obj.MID = MID;
            obj.GROUP = opts.GROUP;
            obj.TYPE = TYPE;
            obj.Sections = Sections;
            obj.Name = 'PBEAML';
        end

        function writeToFile(obj, fid, varargin)
            %writeToFile Print a PBEAML entry to file.

            writeToFile@mni.printing.cards.BaseCard(obj, fid, varargin{:});

            % Header: 4 real fields + 4 'b' chars in format. 'b' adds blank
            % columns WITHOUT consuming a data entry, so data has only 4 entries.
            data   = [{obj.PID}, {obj.MID}, {obj.GROUP}, {obj.TYPE}];
            format = 'iissbbbb';

            % Sanity check: End B must have X = 1.0
            if isprop(obj.Sections(end), 'X') || isfield(obj.Sections(end), 'X')
                if obj.Sections(end).X ~= 1
                    error('mni:PBEAML:BadEndBX', ...
                        'Last section must have X = 1.0 (got %.6g for PID %d).', ...
                        obj.Sections(end).X, obj.PID);
                end
            end

            for i = 1:length(obj.Sections)
                sec      = obj.Sections(i);
                dimCount = length(sec.DIM);
                dimCells = num2cell(sec.DIM(:)');

                if i == 1
                    % End A: DIM1(A)...DIMn(A), NSM(A)
                    data   = [data, dimCells, {sec.NSM}];
                    format = [format, repmat('r', 1, dimCount), 'r'];
                else
                    % Intermediate or End B: SO, X, DIM1...DIMn, NSM
                    data   = [data, {sec.SO}, {sec.X}, dimCells, {sec.NSM}];
                    format = [format, 'sr', repmat('r', 1, dimCount), 'r'];
                end
            end

            obj.fprint_nas(fid, format, data, ConStr='+');
        end
    end
end