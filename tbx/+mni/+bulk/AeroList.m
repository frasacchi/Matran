classdef AeroList < mni.bulk.BulkData
    %AeroList Describes a list of aerodynamic elements (AELIST)
    %or aerodynamic factors (AEFACT).
    %
    % Valid Bulk Data Types:
    %   - AELIST
    %   - AEFACT
    
    methods % construction
        function obj = AeroList(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'AEFACT', ...
                'BulkProps'  , {'SID', 'Di'}, ...
                'PropTypes'  , {'i'  , 'r'} , ...
                'PropDefault', {''   , '' } , ...
                'IDProp'     , 'SID', ...
                'ListProp'   , {'Di'}, ...
                'H5ListName' , {'D'});
            
            addBulkDataSet(obj, 'AELIST', ...
                'BulkProps'  , {'SID', 'E'}, ...
                'PropTypes'  , {'i'  , 'i'}, ... % SID is Integer [cite: 16], E is a list of Integers 
                'PropDefault', {''   , '' }, ...
                'IDProp'     , 'SID', ...      % SID is the Set ID 
                'ListProp'   , {'E'}, ...      % 'E' represents the list E1, E2, ... [cite: 8, 13, 17]
                'H5ListName' , {'E'});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
end