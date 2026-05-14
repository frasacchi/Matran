classdef SUPORT1 < mni.printing.cards.BaseCard
    %SUPORT1_CARD Defines a SUPORT1 card for Nastran.
    %
    % This card defines determinate reaction degrees-of-freedom for a
    % free-body analysis (e.g., SOL 144). It is activated by the
    % 'SUPORT1 = SID' command in the Case Control.
    %
    % The format is:
    % SUPORT1, SID, ID1, C1, ID2, C2, ...
    
    properties
        SID; % Set ID referenced in Case Control
        IDs; % Array of Grid or Scalar Point IDs (ID1, ID2, ...)
        Ci;  % Array of Component numbers (C1, C2, ...)
    end
    
    methods
        function obj = SUPORT1(SID, IDs, Ci)
            %SUPORT1 Construct an instance of this class

            if length(IDs) ~= length(Ci)
                error('IDs and component (Ci) vectors must be the same length.')
            end
            
            obj.SID = SID;
            obj.IDs = IDs;
            obj.Ci = Ci;
            obj.Name = 'SUPORT1';
            
        end
        
        function writeToFile(obj, fid, varargin)
            %writeToFile print SUPORT1 entry to file
            % Write the card name
            writeToFile@mni.printing.cards.BaseCard(obj, fid, varargin{:});
            % Set up the data for printing
            data = {obj.SID};
            format = 'i';
            for i = 1: length(obj.IDs)
                data = [data,{obj.IDs(i)},{obj.Ci(i)}];
                format = [format,'ii'];        
            end
            obj.fprint_nas(fid,format,data);
        end
    end
    
end