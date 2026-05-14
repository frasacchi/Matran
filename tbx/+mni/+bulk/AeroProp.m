classdef AeroProp < mni.bulk.BulkData
    %AeroProp Describes the aerodynamic properties of an element.
    %
    % Valid Bulk Data Types:
    %   - PAERO1
    
    methods % construction
        function obj = AeroProp(varargin)
            
            %Initialise the bulk data sets
            addBulkDataSet(obj, 'PAERO1'   , ...
                'BulkProps'  , {'PID', 'Bi'}, ...
                'PropTypes'  , {'i'  , 'i'} , ...
                'PropDefault', {''   , ''}  , ...
                'IDProp'     , 'PID', ...
                'ListProp'   , {'Bi'});
            
            varargin = parse(obj, varargin{:});
            preallocate(obj);
            
        end
    end
    
    methods % assigning data during import
        function assignH5BulkData(obj, bulkNames, bulkData)
            %assignH5BulkData Assigns the object data during the import
            %from a .h5 file.

            prpNames   = obj.CurrentBulkDataProps;
            if ~any(strcmp(obj.CardName, obj.ValidBulkNames))
                error('Update code');
            end
            
            %Build the prop data
            prpData       = cell(size(prpNames));
            prpData(ismember(prpNames, bulkNames)) = bulkData(ismember(bulkNames, prpNames));
            switch obj.CardName
                case 'PAERO1'
                    b_toks = {'B1', 'B2', 'B3', 'B4', 'B5', 'B6'};
                    prpData{ismember(prpNames, 'Bi')}      = ...
                        vertcat(bulkData{ismember(bulkNames, b_toks)});
            end
            assignH5BulkData@mni.bulk.BulkData(obj, prpNames, prpData)
        end
    end
    
end