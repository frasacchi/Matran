classdef TestRoundTrip < matlab.unittest.TestCase
    %TestRoundTrip bdf -> Matran -> baff -> ADS -> bdf round trip
    %(mni.validation.roundTrip) on a small synthetic deck: a cantilever of
    %CBEAMs (PBEAML BAR) with a kinked child beam (other PBEAML), a CONM2 with offset, an
    %SPC1 root and a FORCE subcase.
    %
    % Skipped when baff / ADS are not on the path; the Nastran check is
    % skipped when MSC Nastran is not found (mni.validation.nastranExe).
    %
    % Run:
    %   >> addpath tbx
    %   >> runtests('unit_testing/TestRoundTrip.m')

    properties
        TmpDir
        Deck
    end

    methods (TestClassSetup)
        function setup(tc)
            tc.assumeTrue(exist('baff.Model', 'class') == 8, 'baff not on the path.');
            tc.assumeNotEmpty(which('ads.baff.baff2fe'), 'ADS not on the path.');
            tc.TmpDir = tempname;
            mkdir(tc.TmpDir);
            tc.addTeardown(@() rmdir(tc.TmpDir, 's'));
            tc.Deck = fullfile(tc.TmpDir, 'cantilever.bdf');
            TestRoundTrip.writeDeck(tc.Deck);
        end
    end

    methods (Test)
        function conversion(tc)
            ws = warning('off', 'all');
            c = onCleanup(@() warning(ws));
            [fem, info, bm] = mni.import_matran(tc.Deck, 'ToBaff', true, 'Verbose', false);
            tc.verifyEqual(info.Sol.Number, 101);
            tc.verifyEqual(height(info.Baff.Components), 2);
            tc.verifyEqual(info.Baff.Satellites.mass, 1);
            tc.verifyEqual(info.Baff.Satellites.constraint, 1);
            %mass: beams (rho A L) + CONM2
            s1 = mni.bulk.beamSection('BAR', [0.03, 0.005]);
            s2 = mni.bulk.beamSection('BAR', [0.02, 0.004]);
            m = 2700 * (s1.A * 1.0 + s2.A * 0.5) + 0.25;
            tc.verifyEqual(bm.GetMass(), m, 'RelTol', 1e-9);
            tc.verifyTrue(isprop(fem, 'PBEAML'));
        end
        function modelComparison(tc)
            ws = warning('off', 'all');
            c = onCleanup(@() warning(ws));
            R = mni.validation.roundTrip(tc.Deck, 'Name', 'cantilever', 'RunNastran', false, ...
                'OutDir', fullfile(tc.TmpDir, 'rt'), 'Verbose', false);
            G = R.Compare.Grids;
            tc.verifyEmpty(G.Unmatched, 'Original grids missing in the round trip.');
            %ADS writes coincident grids at the root (constraint grid + RBE2)
            %and at the junction (parent end / child root + RBE2): grids 1, 11
            tc.verifyEqual(G.Matched + G.Ambiguous, G.N1);
            tc.verifyEqual(setdiff([1 : 11, 101 : 105], G.Map(:, 1)), [1, 11]);
            tc.verifyEqual(R.Compare.Spc.DofsFound, R.Compare.Spc.Dofs);
            tc.verifyEqual(R.Compare.Conm.RoundTrip, R.Compare.Conm.Original, 'RelTol', 1e-9);
            tc.verifyEqual(R.Mass.Ads, R.Mass.Baff, 'RelTol', 1e-9);
            B = R.Compare.Beams;
            tc.verifyEqual(height(B), 12);   %CBEAM 1, 10, 101 touch grid 1 / 11
            tc.verifyLessThan(max(abs([B.ErrEA; B.ErrEI1; B.ErrEI2; B.ErrGJ])), 1e-6);
            tc.verifyGreaterThan(min(B.yDot), 1 - 1e-9);
            tc.verifyTrue(isfile(R.Report));
        end
        function nastran(tc)
            tc.assumeNotEmpty(mni.validation.nastranExe(), 'MSC Nastran not found.');
            ws = warning('off', 'all');
            c = onCleanup(@() warning(ws));
            R = mni.validation.roundTrip(tc.Deck, 'Name', 'cantilever', 'NumModes', 4, ...
                'OutDir', fullfile(tc.TmpDir, 'rtn'), 'Verbose', false);
            N = R.Nastran;
            tc.assertNotEmpty(N.Sol103.Modes, strjoin(R.Notes, newline));
            T = N.Sol103.Modes.Table;
            %PBEAML (Nastran section properties) vs PBEAM (mni.bulk.beamSection):
            %J differs by about 0.1 % for this BAR
            tc.verifyLessThan(max(abs(T.ErrPct)), 0.5);
            tc.verifyGreaterThan(min(T.MAC), 0.999);
            g = N.Sol103.Gpwg;
            tc.verifyEqual(g(2).Mass(1), g(1).Mass(1), 'RelTol', 1e-6);
            S = N.Sol101.Static;
            tc.verifyLessThan(max(S.RelErrNorm), 5e-3);
        end
    end

    methods (Static)
        function writeDeck(file)
            %cantilever along x (10 CBEAMs, 1 m), child beam (5 CBEAMs,
            %0.5 m) from the tip, kinked in y; CONM2 with offset at the tip
            fid = fopen(file, 'w');
            c = onCleanup(@() fclose(fid));
            fprintf(fid, ['SOL 101\nCEND\nTITLE = ROUND TRIP TEST\nSPC = 1\n', ...
                'SUBCASE 1\n  LOAD = 2\nBEGIN BULK\n']);
            fprintf(fid, 'MAT1,1,7.0+10,,.33,2700.\n');
            fprintf(fid, 'PBEAML,1,1,,BAR\n,.03,.005\n');
            fprintf(fid, 'PBEAML,2,1,,BAR\n,.02,.004\n');
            for i = 0 : 10
                fprintf(fid, 'GRID,%d,,%.4f,0.,0.\n', i + 1, 0.1 * i);
            end
            for i = 1 : 10
                fprintf(fid, 'CBEAM,%d,1,%d,%d,0.,0.,1.\n', i, i, i + 1);
            end
            for i = 1 : 5
                fprintf(fid, 'GRID,%d,,%.4f,%.4f,0.\n', 100 + i, 1 + 0.06 * i, 0.08 * i);
            end
            g = [11, 101 : 105];
            for i = 1 : 5
                fprintf(fid, 'CBEAM,%d,2,%d,%d,0.,0.,1.\n', 100 + i, g(i), g(i + 1));
            end
            fprintf(fid, 'CONM2,201,11,,.25,.01,.02,0.\n');
            fprintf(fid, 'SPC1,1,123456,1\n');
            fprintf(fid, 'FORCE,2,105,,10.,0.,0.,1.\n');
            fprintf(fid, 'ENDDATA\n');
        end
    end
end
