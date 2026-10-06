classdef QrgNames
    %QrgNames Matches Matran property names against QRG field names.
    %
    % Matran stores vector fields as one masked property (CBEAM 'X' holds
    % X1..X3, 'GA_GB' holds GA and GB) and keeps a few historical names
    % (GRID 'GID' for 'ID'). The generic rules below cover the naming
    % patterns; 'Aliases' lists the remaining one-off differences.
    %
    % Syntax:
    %   >> tf = QrgNames.matches('CBEAM', 'X(2)', 'X2')       % true
    %   >> tf = QrgNames.matches('CONM2', 'I2(1)', 'I21')     % true

    properties (Constant)
        %{card, Matran name, QRG name}
        Aliases = { ...
            'GRID'   , 'GID'      , 'ID'       ; ...
            'CBUSH'  , 'X(1)'     , 'GO/X1'    ; ...
            'CBUSH'  , 'SI(1)'    , 'S1'       ; ...
            'CBUSH'  , 'SI(2)'    , 'S2'       ; ...
            'CBUSH'  , 'SI(3)'    , 'S3'       ; ...
            'AESURF' , 'AEID'     , 'ID'       ; ...
            'AESTAT' , 'AEID'     , 'ID'       ; ...
            'AEPARM' , 'AEID'     , 'ID'       ; ...
            'AELINK' , 'AEID'     , 'ID'       ; ...
            'CONM2'  , 'I1'       , 'I11'      ; ...
            'CONM1'  , 'M1'       , 'M11'      ; ...
            'PSHELL' , 'BK'       , '12I/T**3' ; ...
            'PSHELL' , 'TS'       , 'TS/T'     ; ...
            'CAERO1' , 'X1(1)'    , 'X1'       ; ...
            'CAERO1' , 'X1(2)'    , 'Y1'       ; ...
            'CAERO1' , 'X1(3)'    , 'Z1'       ; ...
            'CAERO1' , 'X4(1)'    , 'X4'       ; ...
            'CAERO1' , 'X4(2)'    , 'Y4'       ; ...
            'CAERO1' , 'X4(3)'    , 'Z4'       ; ...
            'CROD'   , 'GA_GB(1)' , 'G1'       ; ...
            'CROD'   , 'GA_GB(2)' , 'G2'       ; ...
            'PLOTEL' , 'GA_GB(1)' , 'G1'       ; ...
            'PLOTEL' , 'GA_GB(2)' , 'G2'       ; ...
            'CBEAM'  , 'SA_B(1)'  , 'SA'       ; ...
            'CBEAM'  , 'SA_B(2)'  , 'SB'       ; ...
            'SPLINE1', 'METHOD'   , 'METH'     ; ...
            'FLUTTER', 'NVALUE_OMAX', 'NVALUE/OMAX'; ...
            'SET1'   , 'Gi'       , 'ID1'      ; ...
            'SPLINE3', 'Gi'       , 'G2'       ; ... %list starts at the 2nd triplet
            'SPLINE3', 'Ci'       , 'C2'       ; ...
            'SPLINE3', 'Ai'       , 'A2'       };
    end

    properties (Constant)
        %Entries read by a dedicated parser (keyword lines, variable
        %streams, multi-entry matrices): positional coverage does not apply,
        %TestQrgCustomCards checks them against the QRG examples
        CustomParsed = {'PBUSH', 'PBEAML', 'PBARL', 'TRIM', 'TRIM2', 'AELINK', ...
            'DMI', 'DMIG'};
        %{card, {list properties that follow a keyword field}}
        KeywordListTable = {'RBE3', {'GMi', 'CMi'}};
        %{card, property, property whose value a blank field takes}
        %(QRG defaults such as PBEAM "NSI(B): same as end A")
        DerivedDefaults = { ...
            'PBEAM', 'NSIB' , 'NSIA'   ; ...
            'PBEAM', 'CW(2)', 'CW(1)'  ; ...
            'PBEAM', 'M_B(1)', 'M_A(1)'; ...
            'PBEAM', 'M_B(2)', 'M_A(2)'; ...
            'PBEAM', 'N_B(1)', 'N_A(1)'; ...
            'PBEAM', 'N_B(2)', 'N_A(2)'; ...
            'PBEAM', 'A_B'  , 'A_A'    ; ...
            'PBEAM', 'I1_B' , 'I1_A'   ; ...
            'PBEAM', 'I2_B' , 'I2_A'   ; ...
            'PBEAM', 'I12_B', 'I12_A'  ; ...
            'PBEAM', 'J_B'  , 'J_A'    ; ...
            'PBEAM', 'NSM_B', 'NSM_A'};
    end
    
    methods (Static)
        function l = keywordLists(card)
            t = QrgNames.KeywordListTable;
            idx = strcmp(t(:, 1), card);
            l = [t{idx, 2}];
            if isempty(l)
                l = {};
            end
        end
        function src = derivedDefault(card, prop)
            %derivedDefault Property whose value a blank 'prop' takes ('' if none).
            t = QrgNames.DerivedDefaults;
            idx = strcmp(t(:, 1), card) & strcmp(t(:, 2), prop);
            src = '';
            if any(idx)
                src = t{find(idx, 1), 3};
            end
        end
        function q = normalise(q)
            %normalise Upper case, no blanks / quotes ('C1 (A)' -> 'C1(A)').
            q = upper(regexprep(q, '[\s"'']', ''));
        end
        function tf = isBlank(q)
            tf = isempty(QrgNames.normalise(q));
        end
        function tf = isEtc(q)
            tf = ~isempty(regexp(QrgNames.normalise(q), '^-?ETC\.?-?$', 'once'));
        end
        function tf = matches(card, mName, qName)
            %matches True if the Matran field 'mName' reads the QRG field
            %'qName' (both may be '' for a blank field).
            q = QrgNames.normalise(qName);
            if isempty(mName) || strcmp(mName, 'b')
                tf = isempty(q);
                return
            end
            if isempty(q)
                tf = false;
                return
            end
            %'THETA or MCID': either name is fine
            alt = QrgNames.normalise(strsplit(qName, ' or '));
            tf = any(ismember(alt, QrgNames.candidates(card, mName)));
        end
        function c = candidates(card, mName)
            %candidates QRG names the Matran name 'mName' may stand for.
            c = {};
            al = QrgNames.Aliases;
            idx = strcmp(al(:, 1), card) & strcmp(al(:, 2), mName);
            c = [c, al(idx, 3)'];
            tok = regexp(mName, '^(\w+?)\((\d+)\)$', 'tokens', 'once');
            if isempty(tok)
                base = mName; k = '';
            else
                base = tok{1}; k = tok{2};
            end
            c{end + 1} = base;
            c{end + 1} = strrep(base, '_', '/');       %X_XB -> X/XB
            parts = strsplit(base, '_');
            if ~isempty(k)
                kk = str2double(k);
                c{end + 1} = [base, k];                 %X(2)  -> X2
                if numel(parts) >= kk
                    c{end + 1} = parts{kk};             %GA_GB(2) -> GB
                end
                if numel(base) == 2                     %WA(1) -> W1A
                    c{end + 1} = [base(1), k, base(2)];
                end
                if numel(parts) == 2 && numel(parts{2}) == 1
                    %PBEAM: C_A(1) -> C1(A) ; C_B(1) -> C1 (end B block)
                    c{end + 1} = sprintf('%s%s(%s)', parts{1}, k, parts{2});
                    c{end + 1} = [parts{1}, k];
                end
                if kk <= 2                              %CW(1) -> CW(A)
                    c{end + 1} = sprintf('%s(%s)', base, char('A' + kk - 1));
                end
            elseif numel(parts) == 2 && numel(parts{2}) == 1
                %PBEAM: I1_A -> I1(A) ; A_B -> A (end B block)
                c{end + 1} = sprintf('%s(%s)', parts{1}, parts{2});
                c{end + 1} = parts{1};
            elseif numel(base) > 2 && any(base(end) == 'AB')
                %PBEAM: NSIA -> NSI(A)
                c{end + 1} = sprintf('%s(%s)', base(1 : end - 1), base(end));
            end
            %list properties: 'Gi' / 'G' -> 'G1', 'WTi' -> 'WT1', 'Gij' -> 'G1,1'
            if endsWith(base, 'ij')
                c{end + 1} = [base(1 : end - 2), '1,1'];
            elseif endsWith(base, 'i')
                c{end + 1} = [base(1 : end - 1), '1'];
            end
            c{end + 1} = [base, '1'];
            c = QrgNames.normalise(c);
        end
    end
end
