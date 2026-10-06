classdef TestQrgCustomCards < matlab.unittest.TestCase
    %TestQrgCustomCards QRG examples of the entries Matran reads with a
    %dedicated parser (keyword lines, variable streams, multi-entry
    %matrices, alternate formats). Input text comes from the QRG spec, the
    %expected values are the meaning of the example given in the QRG text.

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
        function pbush(tc)
            %QRG PBUSH examples 1 and 2
            fem = tc.importExamples('PBUSH', 1);
            o = fem.PBUSH;
            tc.verifyEqual(o.K(:, 1)', [4.35, 2.4, 0, 0, 0, 3.1], 'AbsTol', 1e-12);
            tc.verifyEqual(o.GE(:, 1)', [0.06, 0, 0, 0, 0, 0], 'AbsTol', 1e-12);
            tc.verifyEqual(o.RCV(:, 1)', [7.3, 3.3, 1, 1], 'AbsTol', 1e-12);
            fem = tc.importExamples('PBUSH', 2);
            tc.verifyEqual(fem.PBUSH.B(:, 1)', [2.3, 0, 0, 0, 0, 0], 'AbsTol', 1e-12);
            tc.verifyEqual(fem.PBUSH.K(:, 1)', zeros(1, 6));
        end
        function pbeaml(tc)
            %QRG PBEAML example: TYPE T, stations at 0.4 and 0.6, end B
            %with blank dimensions (= end A)
            fem = tc.importExamples('PBEAML', 1);
            o = fem.PBEAML;
            tc.verifyEqual(o.PID, 99);
            tc.verifyEqual(o.MID, 21);
            tc.verifyEqual(o.TYPE{1}, 'T');
            tc.verifyEqual(o.DIM{1}, [12, 14.8, 2.5, 2.6], 'AbsTol', 1e-12);
            st = o.Stations{1};
            tc.verifyEqual([st.X_XB], [0.4, 0.6, 1], 'AbsTol', 1e-12);
            tc.verifyEqual({st.SO}, {'NO', 'YES', 'YES'});
            tc.verifyEqual(st(1).DIM, [6, 7, 1.2, 2.6], 'AbsTol', 1e-12);
            tc.verifyEqual(st(2).DIM, [6, 7.8, 5.6, 2.3], 'AbsTol', 1e-12);
            tc.verifyEqual(st(3).DIM, [12, 14.8, 2.5, 2.6], 'AbsTol', 1e-12);
        end
        function pbarl(tc)
            %QRG PBARL example: TYPE I, 6 dimensions then NSM
            fem = tc.importExamples('PBARL', 1);
            o = fem.PBARL;
            tc.verifyEqual(o.TYPE{1}, 'I');
            tc.verifyEqual(o.DIM{1}, [14, 6, 0.5, 0.5, 0.5, 0.5], 'AbsTol', 1e-12);
            tc.verifyEqual(o.NSMA(1), 0.2, 'AbsTol', 1e-12);
        end
        function trim(tc)
            fem = tc.importExamples('TRIM', 1);
            o = fem.TRIM;
            tc.verifyEqual([o.SID, o.MACH, o.Q, o.AEQR], [1, 0.9, 100, 0], 'AbsTol', 1e-12);
            tc.verifyEqual(o.Labels{1}, {'URDD3', 'ANGLEA', 'ELEV'});
            tc.verifyEqual(o.Values{1}, [1, 7, 0.2], 'AbsTol', 1e-12);
        end
        function trim2(tc)
            fem = tc.importExamples('TRIM2', 1);
            o = fem.TRIM2;
            tc.verifyEqual([o.SID, o.MACH, o.Q, o.AEQR], [1, 0.9, 100, 1], 'AbsTol', 1e-12);
            tc.verifyEqual(o.Labels{1}, {'URDD3', 'ANGLEA', 'ELEV'});
            tc.verifyEqual(o.Values{1}, [1, NaN, 0.2], 'AbsTol', 1e-12); %FREE -> NaN
        end
        function aelink(tc)
            fem = tc.importExamples('AELINK', 1);
            o = fem.AELINK;
            tc.verifyEqual(o.AEID, 10);
            tc.verifyEqual(o.LABLD{1}, 'INBDA');
            tc.verifyEqual(o.LinkLabels{1}, {'OTBDA'});
            tc.verifyEqual(o.LinkCoeffs{1}, -2);
        end
        function dmiReal(tc)
            %QRG DMI "Example of a Real Matrix" (BBB, 4 x 2)
            fem = tc.importExamples('DMI', 1 : 3);
            m = matrices(fem.DMI);
            tc.verifyEqual(m.Name, 'BBB');
            tc.verifyEqual(m.Data, [1 0; 3 6; 5 0; 0 8], 'AbsTol', 1e-12);
        end
        function dmiComplex(tc)
            %QRG DMI "Example of a Complex Matrix" (QQQ, 4 x 2)
            fem = tc.importExamples('DMI', 4 : 6);
            m = matrices(fem.DMI);
            exp = [1 + 2i, 0; 3, 6 + 7i; 5 + 6i, 0; 0, 8 + 9i];
            tc.verifyEqual(m.Data, exp, 'AbsTol', 1e-12);
        end
        function dmiThru(tc)
            %QRG DMI remark 8: value repeated with THRU
            fem = tc.importLines({ ...
                'DMI     RRR     0       2       1       1               12      1', ...
                'DMI     RRR     1       2       1.0     THRU    10      12      2.0'});
            m = matrices(fem.DMI);
            tc.verifyEqual(m.Data', [0, ones(1, 9), 0, 2], 'AbsTol', 1e-12);
        end
        function dmig(tc)
            %QRG DMIG example (complex, IFO 1)
            fem = tc.importExamples('DMIG', 1 : 2);
            m = matrices(fem.DMIG);
            E = m.Entries;
            tc.verifyEqual(height(E), 3);
            tc.verifyEqual([E.GJ, E.CJ, E.GI, E.CI], [27 1 2 3; 27 1 2 4; 27 1 50 0], 'AbsTol', 0);
            tc.verifyEqual([E.A, E.B], [3e5, 3e3; 2.5e10, 0; 1, 0], 'RelTol', 1e-12);
        end
        function beamG0(tc)
            %QRG CBAR / CBEAM alternate format: grid G0 in field 6
            for c = {'CBAR', 'CBEAM'}
                fem = tc.importExamples(c{1}, 2);
                o = fem.(c{1});
                tc.verifyEqual(o.G0, 105, c{1});
                tc.verifyEqual(o.OFFT{1}, 'GOG', c{1});
            end
        end
        function cbushForms(tc)
            %QRG CBUSH examples: G0 (1), grounded (2), CID (3), offset (4)
            fem = tc.importExamples('CBUSH', 1);
            tc.verifyEqual(fem.CBUSH.G0, 75);
            tc.verifyEqual(fem.CBUSH.GB, 100);
            fem = tc.importExamples('CBUSH', 2);
            tc.verifyTrue(isnan(fem.CBUSH.GB));
            tc.verifyEqual(fem.CBUSH.CID, 0);
            fem = tc.importExamples('CBUSH', 3);
            tc.verifyEqual(fem.CBUSH.CID, 6);
            fem = tc.importExamples('CBUSH', 4);
            tc.verifyEqual(fem.CBUSH.GB, 600);
            tc.verifyTrue(all(isnan(fem.CBUSH.X)) && isnan(fem.CBUSH.G0));
            tc.verifyEqual(fem.CBUSH.S, 0.25, 'AbsTol', 1e-12);
            tc.verifyEqual(fem.CBUSH.OCID, 10);
            tc.verifyEqual(fem.CBUSH.SI', [0, 10, 10], 'AbsTol', 1e-12);
        end
        function cord1GridPositions(tc)
            %GRID in a CORD1R system: CoordSystem.getPosition (used by the
            %Node drawing / global coordinates) must give the basic position
            fem = tc.importLines({'BEGIN BULK', 'GRID,1,,1.,2.,3.', 'GRID,2,,1.,2.,4.', ...
                'GRID,3,,2.,2.,3.', 'CORD1R,5,1,2,3', 'GRID,10,5,1.,0.5,0.25', 'ENDDATA'});
            X = fem.GRID.getDrawCoords();
            tc.verifyEqual(X(:, fem.GRID.GID == 10), [2; 2.5; 3.25], 'AbsTol', 1e-12);
            geo = mni.util.Geometry(fem);
            tc.verifyEqual(geo.position(10), [2; 2.5; 3.25], 'AbsTol', 1e-12);
        end
        function beamSectionProperties(tc)
            %mni.bulk.beamSection A, I1, I2, I12 of PBARL / PBEAML types.
            %Reference: MSC Nastran 2023.2, cantilever CBEAM with the PBEAML
            %vs a PBEAM with these values (equal mass and tip rotations).
            %QRG figures: horizontal axis z_elem, vertical axis y_elem.
            ref = {
                'BAR',   [0.03 0.005],                    [0.00015, 3.125e-10, 1.125e-08, 0]
                'L',     [0.03 0.02 0.003 0.004],         [0.000158, 5.578584388e-09, 1.338674262e-08, -5.035443038e-09]
                'T',     [0.03 0.02 0.003 0.004],         [0.000158, 5.578584388e-09, 6.840666667e-09, 0]
                'I',     [0.04 0.03 0.02 0.003 0.004 0.002], [0.000262, 5.699078372e-08, 1.040983333e-08, 0]
                'CHAN',  [0.03 0.04 0.003 0.004],         [0.000336, 8.6272e-08, 3.056914286e-08, 0]
                'BOX',   [0.03 0.02 0.002 0.003],         [0.000216, 1.1808e-08, 2.6568e-08, 0]
                'H',     [0.01 0.02 0.03 0.003],          [0.00063, 4.50225e-08, 6.525e-08, 0]
                'CROSS', [0.01 0.003 0.03 0.004],         [0.00013, 6.803333333e-09, 7.908333333e-10, 0]
                'TUBE2', [0.02 0.004],                    [0.0004523893421, 7.419185211e-08, 7.419185211e-08, 0]};
            for i = 1 : size(ref, 1)
                s = mni.bulk.beamSection(ref{i, 1}, ref{i, 2});
                tc.verifyEqual([s.A, s.I1, s.I2, s.I12], ref{i, 3}, 'RelTol', 1e-8, ...
                    'AbsTol', 1e-18, ref{i, 1});
            end
        end
    end

    methods
        function fem = importExamples(tc, card, idx)
            %Writes the example blocks 'idx' of 'card' into one file and
            %imports it. Illustration rows (cells with blanks) are dropped.
            lines = {};
            for i = idx
                L = QrgSpec.exampleLines(card, i);
                [~, ~, blk] = QrgSpec.exampleFields(card, i);
                rows = blk.rows;
                if ~iscell(rows{1})
                    rows = {rows};
                end
                keep = true(1, numel(L));
                for r = 2 : numel(L)
                    keep(r) = ~any(cellfun(@(x) contains(strtrim(x), ' '), rows{r}));
                end
                lines = [lines; L(keep)]; %#ok<AGROW>
            end
            fem = tc.importLines(lines);
        end
        function fem = importLines(tc, lines)
            file = [tempname(tc.TmpDir), '.bdf'];
            fid = fopen(file, 'w');
            fprintf(fid, '%s\n', lines{:});
            fclose(fid);
            ws = warning('off', 'all');
            c = onCleanup(@() warning(ws));
            fem = mni.import_matran(file, 'Verbose', false);
        end
    end
end
