classdef TestBdfReader < matlab.unittest.TestCase
    %TestBdfReader Input format rules of the QRG (ch.9 "Format of Bulk Data
    %Entries", "Continuations", "Replication"; ch.4/5 Executive and Case
    %Control) on mni.io.tokenizeBulk / readDeck / parseCaseControl, and the
    %import of the Examples decks.

    methods (Test)
        function freeSmallLargeField(tc)
            %QRG: the same GRID in free, small and large field format
            c = mni.io.tokenizeBulk({ ...
                'GRID,2,,1.0,-2.0,3.0,,136', ...
                'GRID    2               1.0     -2.0    3.0             136', ...
                'GRID*   2                               1.0             -2.0            *G1', ...
                '*G1     3.0                             136', ...
                'GRID*,2,,1.0,-2.0', ...
                '*,3.0,,136'});
            exp = {'2', '', '1.0', '-2.0', '3.0', '', '136', ''};
            for i = 1 : numel(c)
                tc.verifyEqual(c(i).Name, 'GRID');
                tc.verifyEqual(c(i).Fields, exp, sprintf('entry %d', i));
            end
        end
        function continuations(tc)
            %QRG: explicit (+P101), automatic (blank field 1, ','), long free
            %field lines and trailing commas
            c = mni.io.tokenizeBulk({ ...
                'MATT9,1101,2,3,4,,,,8,+P101', '+P101,9,,,,13', ...
                'SPC1,100,12456,1,2,3,4,5,6,7,8,9,10', ...
                'CHEXA,200, 200, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,', ...
                '17, 18, 19, 20', ...
                'EIGR,13,GIV,,30.', ',MASS'});
            tc.verifyEqual(c(1).Fields, {'1101', '2', '3', '4', '', '', '', '8', ...
                '9', '', '', '', '13', '', '', ''});
            tc.verifyEqual(c(2).Fields(1 : 12), [{'100', '12456'}, ...
                arrayfun(@num2str, 1 : 10, 'UniformOutput', false)]);
            tc.verifyEqual(c(3).Fields(1 : 22), arrayfun(@num2str, [200, 200, 1 : 20], ...
                'UniformOutput', false));
            tc.verifyEqual(c(4).Fields([1, 2, 4, 9]), {'13', 'GIV', '30.', 'MASS'});
        end
        function nastranReals(tc)
            %QRG: 7.0 .7E1 0.7+1 .70+1 7.E+0 70.-1 are all 7.0
            c = mni.io.tokenizeBulk({'FREQ,1,7.0,.7E1,0.7+1,.70+1,7.E+0,70.-1,7.0D0'});
            tc.verifyEqual(str2double(c.Fields(2 : 8)), repmat(7, 1, 7), 'AbsTol', 1e-12);
            %character data starting with a digit-like pattern is untouched
            c = mni.io.tokenizeBulk({'AESURF  1       AIL1-2  10      20'});
            tc.verifyEqual(c.Fields{2}, 'AIL1-2');
        end
        function replication(tc)
            %QRG "Replication" example (GRID 101 ... 105)
            c = mni.io.tokenizeBulk({'GRID, 101, 17, 1.0, 10.5,,17,3456', ...
                '=,*1,=,*0.2, *(0.1), ==', '=3'});
            tc.verifyEqual(numel(c), 5);
            tc.verifyEqual(str2double(arrayfun(@(x) x.Fields{1}, c, 'UniformOutput', false)), 101 : 105);
            tc.verifyEqual(str2double(arrayfun(@(x) x.Fields{3}, c, 'UniformOutput', false)), ...
                1.0 : 0.2 : 1.8, 'AbsTol', 1e-12);
            tc.verifyEqual(str2double(arrayfun(@(x) x.Fields{4}, c, 'UniformOutput', false)), ...
                10.5 : 0.1 : 10.9, 'AbsTol', 1e-12);
        end
        function caseControl(tc)
            cc = mni.io.parseCaseControl({'TITLE = My Wing', 'ECHO=NONE', ...
                'DISP(SORT1,REAL)=ALL', 'SPC = 73', 'METH = 5', ...
                'SET 1 = 1, 2, 5 THRU 8,', '  20 THRU 30 BY 5 EXCEPT 7', ...
                'SUBCASE 1', '  LOAD = 76', 'SUBCASE 2', '  LOAD = 77', '  SPC = 74'});
            tc.verifyEqual([cc.Subcases.ID], [1, 2]);
            e1 = cc.Subcases(1).Effective;
            e2 = cc.Subcases(2).Effective;
            tc.verifyEqual(e1(strcmp({e1.Command}, 'SPC')).Number, 73);
            tc.verifyEqual(e2(strcmp({e2.Command}, 'SPC')).Number, 74);
            tc.verifyEqual(e1(strcmp({e1.Command}, 'LOAD')).Number, 76);
            tc.verifyTrue(any(strcmp({e1.Command}, 'DISPLACEMENT')));   %DISP abbreviation
            tc.verifyTrue(any(strcmp({e1.Command}, 'METHOD')));         %METH abbreviation
            tc.verifyEqual(e1(strcmp({e1.Command}, 'TITLE')).Value, 'My Wing');
            tc.verifyEqual(cc.Sets.Values, [1, 2, 5, 6, 8, 20, 25, 30]);
        end
        function execControl(tc)
            ec = mni.io.parseExecControl({'ID MYJOB', 'SOL 144', 'TIME 600'});
            tc.verifyEqual(ec.Sol.Number, 144);
            tc.verifyEqual(ec.Sol.Name, 'AESTAT');
            ec = mni.io.parseExecControl({'SOL SEMODES'});
            tc.verifyEqual(ec.Sol.Number, 103);
        end
        function exampleDecks(tc)
            %Every entry of the Examples decks is imported by a typed class
            root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
            ex = fullfile(root, 'Examples');
            decks = { ...
                fullfile(ex, 'bwb', 'bwbID_tp3911f223_6fd0_4693_81b0_96ba940d62e5', 'Source', 'sol101.bdf'), 101; ...
                fullfile(ex, 'example_2_a320', 'data', 'A320_half_model_SOL144.dat'), 144; ...
                fullfile(ex, 'example_2_a320', 'data', 'NastranHeaderFile.dat'), 103; ...
                fullfile(ex, 'example_1_semispan_model', 'data', 'model.bdf'), []};
            for i = 1 : size(decks, 1)
                tc.assumeTrue(isfile(decks{i, 1}));
                ws = warning('off', 'all');
                [~, info] = mni.import_matran(decks{i, 1}, 'Verbose', false);
                warning(ws);
                tc.verifyEqual(info.Sol.Number, decks{i, 2}, decks{i, 1});
                tc.verifyTrue(all(info.Cards.Typed), sprintf('%s: generic entries %s', ...
                    decks{i, 1}, strjoin(info.Cards.Card(~info.Cards.Typed)', ', ')));
                for s = info.Subcases
                    tc.verifyTrue(isempty(s.Selections) || all([s.Selections.Found]), ...
                        sprintf('%s: unresolved Case Control selection', decks{i, 1}));
                end
            end
        end
    end
end
