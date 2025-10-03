classdef Property < mni.bulk.BulkData
    %Property Describes the properties of a bulk data element.
    %
    % Valid Bulk Data Types:
    %   - PSHELL
    %
    
    methods % constructor
        function obj = Property(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'PSHELL'   , ...
                'BulkProps'  , {'PID', 'MID1', 'T', 'MID2', 'BK', 'MID3', 'TS', 'NSM', 'Z1', 'Z2', 'MID4'}, ...
                'PropTypes'  , {'i'  , 'i'   , 'r', 'i'   , 'r'     , 'i'   , 'r'   , 'r'  , 'r' , 'r' , 'i'   }, ...
                'PropDefault', {''   , ''    , 0  , 0     , 1       , 0     , .8333 , 0    , 0   , 0   , 0     }, ...
                'IDProp'     , 'PID');

            addBulkDataSet(obj, 'PCOMP'   , ...
                'BulkProps'  , {'PID', 'Z0', 'NSM', 'SB', 'FT', 'TREF', 'GE', 'LAM', 'MIDi', 'Ti', 'THETAi', 'SOUTi'}, ...
                'PropTypes'  , {'i'  , 'r' , 'r'  , 'r' , 'c' , 'r'   , 'r' , 'c'  , 'i'   , 'r' , 'r'     , 'c'    }, ...
                'PropDefault', {''   , -0.5, ''   , ''  , ''  , 0     , 0   , ''   , ''    , ''  , 0       , 'NO'   }, ...
                'IDProp'     , 'PID');

            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
end

