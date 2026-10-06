function cat = cardCategory(name)
%cardCategory Role of a bulk data entry in the input deck.
%
%   'solution'   - solution settings selected by Case Control or used by
%                  the solution sequence (EIGRL, TRIM, FLUTTER, AERO, ...)
%   'load'       - static loads (FORCE, MOMENT, GRAV, LOAD, PLOADi, ...)
%   'dynamic'    - dynamic loads / excitation (DLOAD, TLOADi, RLOADi, ...)
%   'constraint' - SPC/MPC sets, SUPORT, degree-of-freedom sets
%   'parameter'  - PARAM, MDLPRM
%   'model'      - everything that defines the structure / aero model
%
% Syntax:
%   >> mni.analysis.cardCategory('EIGRL')   % 'solution'

persistent map
if isempty(map)
    map = containers.Map();
    i_add({'PARAM', 'MDLPRM'}, 'parameter');
    i_add({'EIGR', 'EIGRL', 'EIGC', 'EIGB', 'EIGP', 'TRIM', 'TRIM2', 'FLUTTER', ...
        'MKAERO1', 'MKAERO2', 'FLFACT', 'GUST', 'GUST2', 'TSTEP', 'TSTEPNL', 'FREQ', ...
        'FREQ1', 'FREQ2', 'FREQ3', 'FREQ4', 'FREQ5', 'TABDMP1', 'TABRND1', 'TABRNDG', ...
        'RANDPS', 'RANDT1', 'DIVERG', 'NLPARM', 'NLPCI', 'AERO', 'AEROS', 'AESTAT', ...
        'AEPARM', 'AELINK', 'AEDW', 'AEFORCE', 'AEPRESS', 'MONPNT1', 'MONPNT2', ...
        'MONPNT3', 'UXVEC', 'CSSCHD', 'DIVERG', 'EIGRL', 'ACMODL'}, 'solution');
    i_add({'FORCE', 'FORCE1', 'FORCE2', 'MOMENT', 'MOMENT1', 'MOMENT2', 'GRAV', ...
        'LOAD', 'PLOAD', 'PLOAD1', 'PLOAD2', 'PLOAD4', 'PLOADX1', 'RFORCE', 'ACCEL', ...
        'ACCEL1', 'SPCD', 'SLOAD', 'TEMP', 'TEMPD', 'DEFORM'}, 'load');
    i_add({'DLOAD', 'TLOAD1', 'TLOAD2', 'RLOAD1', 'RLOAD2', 'DAREA', 'DELAY', ...
        'DPHASE', 'TABLED1', 'TABLED2', 'TABLED3', 'TABLED4', 'ACSRCE', 'LSEQ'}, 'dynamic');
    i_add({'SPC', 'SPC1', 'SPCADD', 'MPC', 'MPCADD', 'SUPORT', 'SUPORT1', 'ASET', ...
        'ASET1', 'BSET', 'BSET1', 'CSET', 'CSET1', 'QSET', 'QSET1', 'OMIT', 'OMIT1', ...
        'SESET', 'GMSPC'}, 'constraint');
end
if isKey(map, upper(name))
    cat = map(upper(name));
else
    cat = 'model';
end

    function i_add(names, c)
        for k = 1 : numel(names)
            map(names{k}) = c;
        end
    end
end
