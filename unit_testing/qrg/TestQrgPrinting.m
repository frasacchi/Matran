classdef TestQrgPrinting < matlab.unittest.TestCase
    %TestQrgPrinting Checks that the mni.printing.cards entries (the cards
    %ADS writes) put every value in the field the MSC Nastran Quick
    %Reference Guide (QRG) assigns to it.
    %
    % Each fixture builds a card with distinct values, writes it with
    % writeToFile (small field, and large field where supported), splits
    % the text with mni.io.tokenizeBulk (Nastran field rules) and compares
    % each value with the field of the same name in the QRG format
    % (unit_testing/qrg/spec/qrg_bulk.json). A second check re-imports the
    % text with mni.import_matran (no error, entry typed).
    %
    % Run:
    %   >> addpath tbx unit_testing/qrg
    %   >> runtests('TestQrgPrinting')

    properties (TestParameter)
        Card = TestQrgPrinting.fixtureNames();
    end

    properties
        TmpDir
    end

    methods (TestClassSetup)
        function setup(tc)
            tc.assumeTrue(QrgSpec.isAvailable(), ...
                'QRG spec missing - run tools/qrg/extract_qrg.py');
            tc.TmpDir = tempname;
            mkdir(tc.TmpDir);
            tc.addTeardown(@() rmdir(tc.TmpDir, 's'));
        end
    end

    methods (Test)
        function fieldsAtQrgPositions(tc, Card)
            [obj, name, iFormat, expected] = TestQrgPrinting.fixture(Card);
            for longFormat = [false, true]
                if longFormat
                    if ~isprop(obj, 'LongFormat'), continue, end
                    obj.LongFormat = true;
                end
                c = tc.printAndSplit(obj);
                tc.assertNotEmpty(c, sprintf('%s: nothing printed.', Card));
                tc.verifyEqual(c(1).Name, name);
                tc.verifyEmpty(TestQrgPrinting.compare(name, iFormat, c(1).Fields, expected), ...
                    sprintf('%s (LongFormat %d)', Card, longFormat));
            end
        end
        function reimports(tc, Card)
            [obj, name] = TestQrgPrinting.fixture(Card);
            f = fullfile(tc.TmpDir, [Card, '_imp.bdf']);
            fid = fopen(f, 'w');
            fprintf(fid, 'BEGIN BULK\n');
            obj.writeToFile(fid);
            fprintf(fid, 'ENDDATA\n');
            fclose(fid);
            ws = warning('off', 'all');
            c = onCleanup(@() warning(ws));
            [~, info] = mni.import_matran(f, 'Verbose', false);
            k = strcmp(info.Cards.Card, name);
            tc.verifyTrue(any(k), sprintf('%s not imported.', name));
        end
    end

    methods
        function c = printAndSplit(tc, obj)
            f = fullfile(tc.TmpDir, 'card.bdf');
            fid = fopen(f, 'w');
            obj.writeToFile(fid);
            fclose(fid);
            lines = splitlines(fileread(f));
            lines = lines(~startsWith(strtrim(lines), '$') & strlength(strtrim(lines)) > 0);
            c = mni.io.tokenizeBulk(lines);
        end
    end

    methods (Static)
        function n = fixtureNames()
            n = {'GRID', 'CORD2R', 'CBEAM', 'CBEAM_G0', 'CBAR', 'PBAR', 'PBEAM', 'PBEAML', ...
                'CQUAD4', 'PSHELL', 'MAT1', 'MAT8', 'PCOMP', 'CONM2', 'CONM1', 'RBE2', 'RBE3', ...
                'SPC1', 'FORCE', 'MOMENT', 'RJOINT', 'CBUSH', 'CBUSH_X', 'CBUSH_CID', 'PBUSH', ...
                'CAERO1', 'PAERO1', 'AEFACT', 'AELIST', 'SET1', 'SPLINE1', 'SPLINE4', 'SPLINE7', ...
                'AESURF', 'AELINK', 'AERO', 'AEROS', 'EIGRL', 'SUPORT', 'SUPORT1', 'TRIM', ...
                'FLUTTER', 'MKAERO1', 'FLFACT', 'GUST'};
        end

        function [obj, name, iFormat, ex] = fixture(id)
            %obj: card; name: entry name; iFormat: QRG format block; ex:
            %{QRG field name or flattened index, expected value} ([] = blank)
            p = 'mni.printing.cards.';
            mk = @(c, varargin) feval([p, c], varargin{:});
            name = strtok(id, '_');
            iFormat = 1;
            switch id
                case 'GRID'
                    obj = mk('GRID', 11, [1.5; 2.5; 3.5], 'CP', 3, 'CD', 4, 'PS', '123', 'SEID', 2);
                    ex = {'ID', 11; 'CP', 3; 'X1', 1.5; 'X2', 2.5; 'X3', 3.5; 'CD', 4; 'PS', 123; 'SEID', 2};
                case 'CORD2R'
                    obj = mk('CORD2R', 5, [1; 2; 3], [4; 5; 6], [7; 8; 9], 'RID', 2);
                    ex = {'CID', 5; 'RID', 2; 'A1', 1; 'A2', 2; 'A3', 3; 'B1', 4; 'B2', 5; 'B3', 6; ...
                        'C1', 7; 'C2', 8; 'C3', 9};
                case 'CBEAM'
                    obj = mk('CBEAM', 10, 20, 1, 2, 'X', [0.1; 0.2; 0.3], 'OFFST', 'GOG', 'PA', 4, ...
                        'PB', 5, 'WA', [1; 2; 3], 'WB', [4; 5; 6], 'SA', 7, 'SB', 8);
                    ex = {'EID', 10; 'PID', 20; 'GA', 1; 'GB', 2; 'X1', 0.1; 'X2', 0.2; 'X3', 0.3; ...
                        'OFFT', 'GOG'; 'PA', 4; 'PB', 5; 'W1A', 1; 'W2A', 2; 'W3A', 3; 'W1B', 4; ...
                        'W2B', 5; 'W3B', 6; 'SA', 7; 'SB', 8};
                case 'CBEAM_G0'
                    obj = mk('CBEAM', 10, 20, 1, 2, 'G0', 9, 'OFFST', 'BGG');
                    iFormat = 2;
                    ex = {'EID', 10; 'PID', 20; 'GA', 1; 'GB', 2; 'G0', 9; 6, []; 7, []; 'OFFT', 'BGG'};
                case 'CBAR'
                    obj = mk('CBAR', 10, 20, 1, 2, 'X', [0.1; 0.2; 0.3], 'OFFST', 'GGO', 'PA', 4, ...
                        'PB', 5, 'Wa', [1; 2; 3], 'Wb', [4; 5; 6]);
                    ex = {'EID', 10; 'PID', 20; 'GA', 1; 'GB', 2; 'X1', 0.1; 'X2', 0.2; 'X3', 0.3; ...
                        'OFFT', 'GGO'; 'PA', 4; 'PB', 5; 'W1A', 1; 'W2A', 2; 'W3A', 3; 'W1B', 4; ...
                        'W2B', 5; 'W3B', 6};
                case 'PBAR'
                    s = mk('BeamSection', 1.5, 2.5, 3.5, 0.5, 4.5, 0, 'NSM', 0.25, 'C', [1; 2], ...
                        'D', [3; 4], 'E', [5; 6], 'F', [7; 8]);
                    obj = mk('PBAR', 3, 4, s, 'K', [0.8; 0.9]);
                    ex = {'PID', 3; 'MID', 4; 'A', 1.5; 'I1', 2.5; 'I2', 3.5; 'J', 4.5; 'NSM', 0.25; ...
                        8, []; 'C1', 1; 'C2', 2; 'D1', 3; 'D2', 4; 'E1', 5; 'E2', 6; 'F1', 7; 'F2', 8; ...
                        'K1', 0.8; 'K2', 0.9; 'I12', 0.5};
                case 'PBEAM'
                    sa = mk('BeamSection', 1.5, 2.5, 3.5, 0.5, 4.5, 0, 'NSM', 0.25);
                    sb = mk('BeamSection', 1.25, 2.25, 3.25, 0.75, 4.25, 1, 'NSM', 0.125, 'SO', "NO");
                    obj = mk('PBEAM', 3, 4, [sa; sb], 'K', [0.8; 0.9], 'S', [0.6; 0.7], ...
                        'NSI', [0.1; 0.2], 'CW', [0.3; 0.4]);
                    ex = {'PID', 3; 'MID', 4; 'A(A)', 1.5; 'I1(A)', 2.5; 'I2(A)', 3.5; 'I12(A)', 0.5; ...
                        'J(A)', 4.5; 'NSM(A)', 0.25; 'SO', 'NO'; 'X/XB', 1; 'A', 1.25; 'I1', 2.25; ...
                        'I2', 3.25; 'I12', 0.75; 'J', 4.25; 'NSM', 0.125};
                    %QRG remark 5: SO = NO -> no C..F line for end B, so K1 ... CW(B)
                    %follow at flattened fields 25-32
                    ex = [ex; {25, 0.8; 26, 0.9; 27, 0.6; 28, 0.7; 29, 0.1; 30, 0.2; 31, 0.3; 32, 0.4}];
                case 'PBEAML'
                    sec = struct('DIM', {[0.03, 0.005], [0.02, 0.004]}, 'NSM', {0.1, 0.2}, ...
                        'SO', {"YES", "NO"}, 'X', {0, 1});
                    obj = mk('PBEAML', 3, 4, "BAR", sec);
                    %variable DIM count: flattened positions (9 = first field of line 2)
                    ex = {'PID', 3; 'MID', 4; 'GROUP', 'MSCBML0'; 'TYPE', 'BAR'; 9, 0.03; 10, 0.005; ...
                        11, 0.1; 12, 'NO'; 13, 1; 14, 0.02; 15, 0.004; 16, 0.2};
                case 'CQUAD4'
                    obj = mk('CQUAD4', 7, 8, [1; 2; 3; 4]);
                    ex = {'EID', 7; 'PID', 8; 'G1', 1; 'G2', 2; 'G3', 3; 'G4', 4};
                case 'PSHELL'
                    obj = mk('PSHELL', 3, 4, 0.5, 5, 1.25, 6, 'TST', 0.75, 'NSM', 0.125);
                    ex = {'PID', 3; 'MID1', 4; 'T', 0.5; 'MID2', 5; '12I/T**3', 1.25; 'MID3', 6; ...
                        'TS/T', 0.75; 'NSM', 0.125};
                case 'MAT1'
                    obj = mk('MAT1', 3, 'E', 7e10, 'G', 2.6e10, 'NU', 0.33, 'RHO', 2700, 'A', 2.3e-5, ...
                        'TREF', 20, 'GE', 0.02, 'ST', 1e8, 'SC', 2e8, 'SS', 3e8, 'MCSID', 5);
                    ex = {'MID', 3; 'E', 7e10; 'G', 2.6e10; 'NU', 0.33; 'RHO', 2700; 'A', 2.3e-5; ...
                        'TREF', 20; 'GE', 0.02; 'ST', 1e8; 'SC', 2e8; 'SS', 3e8; 'MCSID', 5};
                case 'MAT8'
                    obj = mk('MAT8', 3, 'E1', 1.5e11, 'E2', 9e9, 'NU12', 0.3, 'G12', 5e9, 'G1Z', 4e9, ...
                        'G2Z', 3e9, 'RHO', 1600, 'A1', 1e-6, 'A2', 2e-5, 'TREF', 20, 'Xt', 2e9, ...
                        'Xc', 1.5e9, 'Yt', 5e7, 'Yc', 2e8, 'S', 9e7, 'GE', 0.01, 'F12', -0.5, 'STRN', 1);
                    ex = {'MID', 3; 'E1', 1.5e11; 'E2', 9e9; 'NU12', 0.3; 'G12', 5e9; 'G1Z', 4e9; ...
                        'G2Z', 3e9; 'RHO', 1600; 'A1', 1e-6; 'A2', 2e-5; 'TREF', 20; 'Xt', 2e9; ...
                        'Xc', 1.5e9; 'Yt', 5e7; 'Yc', 2e8; 'S', 9e7; 'GE', 0.01; 'F12', -0.5; 'STRN', 1};
                case 'PCOMP'
                    ply = [mk('PlyLayer', 7, 0.25, 45, "YES"); mk('PlyLayer', 8, 0.5, -45, "NO")];
                    obj = mk('PCOMP', 3, -0.5, 0.125, 1e8, "HOFF", 20, 0.01, "SYM", ply);
                    ex = {'PID', 3; 'Z0', -0.5; 'NSM', 0.125; 'SB', 1e8; 'FT', 'HOFF'; 'TREF', 20; ...
                        'GE', 0.01; 'LAM', 'SYM'; 'MID1', 7; 'T1', 0.25; 'THETA1', 45; 'SOUT1', 'YES'; ...
                        'MID2', 8; 'T2', 0.5; 'THETA2', -45; 'SOUT2', 'NO'};
                case 'CONM2'
                    obj = mk('CONM2', 5, 6, 2.5, 'X', [0.1; 0.2; 0.3], 'CID', 3, ...
                        'I', [1; 2; 3; 4; 5; 6]);
                    ex = {'EID', 5; 'G', 6; 'CID', 3; 'M', 2.5; 'X1', 0.1; 'X2', 0.2; 'X3', 0.3; ...
                        8, []; 'I11', 1; 'I21', 2; 'I22', 3; 'I31', 4; 'I32', 5; 'I33', 6};
                case 'CONM1'
                    M = tril(reshape(1 : 36, 6, 6)');
                    M = M + tril(M, -1)';
                    obj = mk('CONM1', 5, 6, M, 'CID', 3);
                    ex = {'EID', 5; 'G', 6; 'CID', 3};
                    for i = 1 : 6
                        for j = 1 : i
                            ex(end + 1, :) = {sprintf('M%d%d', i, j), M(i, j)}; %#ok<AGROW>
                        end
                    end
                case 'RBE2'
                    obj = mk('RBE2', 5, 6, 123456, [7, 8, 9], 'Alpha', 1e-5);
                    ex = {'EID', 5; 'GN', 6; 'CM', 123456; 'GM1', 7; 'GM2', 8; 'GM3', 9; 7, 1e-5};
                case 'RBE3'
                    obj = mk('RBE3', 5, 6, 123456, 1.5, 123, [7, 8, 9]);
                    ex = {'EID', 5; 2, []; 'REFGRID', 6; 'REFC', 123456; 'WT1', 1.5; 'C1', 123; ...
                        'G1,1', 7; 'G1,2', 8; 'G1,3', 9};
                case 'SPC1'
                    obj = mk('SPC1', 5, 123, [7, 8, 9]);
                    ex = {'SID', 5; 'C', 123; 'G1', 7; 'G2', 8; 'G3', 9};
                case {'FORCE', 'MOMENT'}
                    obj = mk(id, 5, 6, 2.5, [0.1; 0.2; 0.3], 'CID', 3);
                    ex = {'SID', 5; 'G', 6; 'CID', 3; id(1), 2.5; 'N1', 0.1; 'N2', 0.2; 'N3', 0.3};
                case 'RJOINT'
                    obj = mk('RJOINT', 5, 6, 7, 'CB', '12356');
                    ex = {'EID', 5; 'GA', 6; 'GB', 7; 'CB', 12356};
                case 'CBUSH'
                    obj = mk('CBUSH', 5, 6, 7, 8, 'G0', 9);
                    ex = {'EID', 5; 'PID', 6; 'GA', 7; 'GB', 8; 'GO/X1', 9; 'X2', []; 'X3', []; ...
                        'CID', []};
                case 'CBUSH_X'
                    obj = mk('CBUSH', 5, 6, 7, 8, 'X', [0.1, 0.2, 0.3]);
                    ex = {'EID', 5; 'PID', 6; 'GA', 7; 'GB', 8; 'GO/X1', 0.1; 'X2', 0.2; 'X3', 0.3; ...
                        'CID', []};
                case 'CBUSH_CID'
                    obj = mk('CBUSH', 5, 6, 7, 8, 'CID', 9);
                    ex = {'EID', 5; 'PID', 6; 'GA', 7; 'GB', 8; 'GO/X1', []; 'CID', 9};
                case 'PBUSH'
                    obj = mk('PBUSH', 5, 'K', [1, 2, 3, 4, 5, 6] * 1e3, 'B', [0, 0, 0, 7, 0, 0]);
                    %keyword lines: fields 2..9 of each line (flattened 8 per line)
                    ex = {1, 5; 2, 'K'; 3, 1e3; 4, 2e3; 5, 3e3; 6, 4e3; 7, 5e3; 8, 6e3; ...
                        10, 'B'; 11, []; 14, 7};
                case 'CAERO1'
                    obj = mk('CAERO1', 1001, 2, [0.5; 1.5; 0.25], [0.75; 3.5; 0.125], 1.25, 0.625, 1, ...
                        'CP', 3, 'NSPAN', 4, 'NCHORD', 5);
                    ex = {'EID', 1001; 'PID', 2; 'CP', 3; 'NSPAN', 4; 'NCHORD', 5; 'IGID', 1; ...
                        'X1', 0.5; 'Y1', 1.5; 'Z1', 0.25; 'X12', 1.25; 'X4', 0.75; 'Y4', 3.5; ...
                        'Z4', 0.125; 'X43', 0.625};
                case 'PAERO1'
                    obj = mk('PAERO1', 5, 'B1', 6, 'B2', 7);
                    ex = {'PID', 5; 'B1', 6; 'B2', 7};
                case 'AEFACT'
                    obj = mk('AEFACT', 5, [0, 0.25, 0.5, 0.75, 1, 0.1, 0.2, 0.3, 0.4, 0.6]);
                    ex = {'SID', 5; 'D1', 0; 'D2', 0.25; 'D5', 1; 'D9', 0.4; 11, 0.6};
                case 'AELIST'
                    obj = mk('AELIST', 5, 101 : 2 : 119);   %no runs (printed as THRU)
                    ex = {'SID', 5; 'E1', 101; 'E7', 113; 'E8', 115; 10, 117; 11, 119};
                case 'SET1'
                    obj = mk('SET1', 5, 101 : 2 : 119);     %no runs (printed as THRU)
                    ex = {'SID', 5; 'ID1', 101; 'ID7', 113; 'ID8', 115; 10, 117; 11, 119};
                case 'SPLINE1'
                    obj = mk('SPLINE1', 5, 1001, 1001, 1020, 7, 'DZ', 0.5, 'METH', 'FPS', ...
                        'USAGE', 'BOTH', 'NELEM', 10, 'MELEM', 12);
                    ex = {'EID', 5; 'CAERO', 1001; 'BOX1', 1001; 'BOX2', 1020; 'SETG', 7; 'DZ', 0.5; ...
                        'METH', 'FPS'; 'USAGE', 'BOTH'; 'NELEM', 10; 'MELEM', 12};
                case 'SPLINE4'
                    obj = mk('SPLINE4', 5, 1001, 6, 7, 'DZ', 0.5, 'METH', 'RIS', 'USAGE', 'FORCE', ...
                        'FTYPE', 'WF0', 'RCORE', 0.25);
                    ex = {'EID', 5; 'CAERO', 1001; 'AELIST', 6; 4, []; 'SETG', 7; 'DZ', 0.5; ...
                        'METH', 'RIS'; 'USAGE', 'FORCE'; 'FTYPE', 'WF0'; 'RCORE', 0.25};
                case 'SPLINE7'
                    obj = mk('SPLINE7', 5, 1001, 6, 7, 8, 'DZ', 0.5, 'DTOR', 1.5, 'USAGE', 'DISP', ...
                        'METHOD', 'FBS6', 'DZR', 0.25, 'IA2', 0.75, 'EPSBM', 0.125);
                    ex = {'EID', 5; 'CAERO', 1001; 'AELIST', 6; 'SETG', 7; 'DZ', 0.5; 'DTOR', 1.5; ...
                        'CID', 8; 'USAGE', 'DISP'; 'METHOD', 'FBS6'; 'DZR', 0.25; 'IA2', 0.75; ...
                        'EPSBM', 0.125};
                case 'AESURF'
                    obj = mk('AESURF', 5, 'AIL1', 6, 7, 'CID2', 8, 'ALID2', 9, 'EFF', 0.5, ...
                        'LDW', 'LDW', 'CREFC', 1.5, 'CREFS', 2.5, 'PLLIM', -0.25, 'PULIM', 0.25, ...
                        'HMLLIM', -10, 'HMULIM', 10, 'TQLLIM', 11, 'TQULIM', 12);
                    ex = {'ID', 5; 'LABEL', 'AIL1'; 'CID1', 6; 'ALID1', 7; 'CID2', 8; 'ALID2', 9; ...
                        'EFF', 0.5; 'LDW', 'LDW'; 'CREFC', 1.5; 'CREFS', 2.5; 'PLLIM', -0.25; ...
                        'PULIM', 0.25; 'HMLLIM', -10; 'HMULIM', 10; 'TQLLIM', 11; 'TQULIM', 12};
                case 'AELINK'
                    obj = mk('AELINK', 'AIL2', {{'AIL1', 0.5}, {'AIL3', -1.5}}, 'ID', 7);
                    ex = {'ID', 7; 'LABLD', 'AIL2'; 'LABL1', 'AIL1'; 'C1', 0.5; 'LABL2', 'AIL3'; ...
                        'C2', -1.5};
                case 'AERO'
                    obj = mk('AERO', 1.5, 1.225, 'ACSID', 3, 'VELOCITY', 50, 'SYMXZ', 1, 'SYMXY', -1);
                    ex = {'ACSID', 3; 'VELOCITY', 50; 'REFC', 1.5; 'RHOREF', 1.225; 'SYMXZ', 1; ...
                        'SYMXY', -1};
                case 'AEROS'
                    obj = mk('AEROS', 1.5, 12.5, 18.75, 'ACSID', 3, 'RCSID', 4, 'SYMXZ', 1, 'SYMXY', -1);
                    ex = {'ACSID', 3; 'RCSID', 4; 'REFC', 1.5; 'REFB', 12.5; 'REFS', 18.75; ...
                        'SYMXZ', 1; 'SYMXY', -1};
                case 'EIGRL'
                    obj = mk('EIGRL', 5, 'V1', 0.5, 'V2', 100, 'ND', 12, 'MSGLVL', 1, 'MAXSET', 7, ...
                        'SHFSCL', 2.5, 'NORM', 'MAX');
                    ex = {'SID', 5; 'V1', 0.5; 'V2', 100; 'ND', 12; 'MSGLVL', 1; 'MAXSET', 7; ...
                        'SHFSCL', 2.5; 'NORM', 'MAX'};
                case 'SUPORT'
                    obj = mk('SUPORT', [5, 6], [123, 456]);
                    ex = {'ID1', 5; 'C1', 123; 'ID2', 6; 'C2', 456};
                case 'SUPORT1'
                    obj = mk('SUPORT1', 3, [5, 6, 7, 8], [1, 2, 3, 4]);
                    ex = {'SID', 3; 'ID1', 5; 'C1', 1; 'ID2', 6; 'C2', 2; 'ID3', 7; 'C3', 3; 8, []; ...
                        'ID4', 8; 'C4', 4};
                case 'TRIM'
                    obj = mk('TRIM', 5, 0.5, 1500, {'ANGLEA', 0.1, 'PITCH', 0, 'URDD3', 1.5}, 'AEQR', 1);
                    ex = {'SID', 5; 'MACH', 0.5; 'Q', 1500; 'LABEL1', 'ANGLEA'; 'UX1', 0.1; ...
                        'LABEL2', 'PITCH'; 'UX2', 0; 'AEQR', 1; 'LABEL3', 'URDD3'; 'UX3', 1.5};
                case 'FLUTTER'
                    obj = mk('FLUTTER', 5, 'PK', 6, 7, 8, 12);
                    ex = {'SID', 5; 'METHOD', 'PK'; 'DENS', 6; 'MACH', 7; 'RFREQ', 8; ...
                        'NVALUE/ OMAX', 12};
                case 'MKAERO1'
                    obj = mk('MKAERO1', [0.1, 0.5], [0.01, 0.05, 0.1]);
                    ex = {'m1', 0.1; 'm2', 0.5; 'm3', []; 'k1', 0.01; 'k2', 0.05; 'k3', 0.1; 'k4', []};
                case 'FLFACT'
                    obj = mk('FLFACT', 5, [0.5, 1, 1.5]);
                    ex = {'SID', 5; 'F1', 0.5; 'F2', 1; 'F3', 1.5};
                case 'GUST'
                    obj = mk('GUST', 5, 6, 0.25, 10, 50);
                    ex = {'SID', 5; 'DLOAD', 6; 'WG', 0.25; 'X0', 10; 'V', 50};
                otherwise
                    error('TestQrgPrinting:fixture', 'No fixture ''%s''.', id);
            end
        end

        function bad = compare(name, iFormat, fields, ex)
            %mismatches between the printed fields and the expected values
            %at the QRG positions of the named fields
            q = QrgSpec.formatFields(name, iFormat);
            norm = @(s) upper(regexprep(char(s), '\s', ''));
            qn = cellfun(norm, q, 'UniformOutput', false);
            bad = {};
            for i = 1 : size(ex, 1)
                key = ex{i, 1};
                if ischar(key)
                    k = find(strcmp(qn, norm(key)), 1);
                    if isempty(k)
                        bad{end + 1} = sprintf('QRG %s has no field ''%s''', name, key); %#ok<AGROW>
                        continue
                    end
                    lbl = sprintf('%s (field %d)', key, k);
                else
                    k = key;
                    lbl = sprintf('field %d', k);
                end
                got = '';
                if k <= numel(fields), got = strtrim(fields{k}); end
                want = ex{i, 2};
                if isempty(want)
                    ok = isempty(got);
                elseif isnumeric(want)
                    v = nasNum(got);
                    ok = abs(v - want) <= 1e-5 * max(abs(want), 1e-12);
                else
                    ok = strcmpi(got, want);
                end
                if ~ok
                    if isnumeric(want), w = num2str(want, 8); else, w = char(want); end
                    bad{end + 1} = sprintf('%s: printed ''%s'', expected ''%s''', lbl, got, w); %#ok<AGROW>
                end
            end
        end
    end
end
