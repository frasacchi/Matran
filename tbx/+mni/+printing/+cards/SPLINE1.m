classdef SPLINE1 < mni.printing.cards.BaseCard
    %SPLINE1 Defines a surface spline for interpolating motion and/or forces.
    
    properties
        EID;    % Unique spline identification number [cite: 27]
        CAERO;  % Aero-element ID defining the plane of the spline [cite: 28]
        BOX1;   % First box ID in range [cite: 31]
        BOX2;   % Last box ID in range [cite: 31]
        SETG;   % Reference to SETi entry for structural grid points [cite: 33]
        DZ;     % Linear attachment flexibility [cite: 36]
        METH;   % Method: IPS, TPS, or FPS [cite: 37]
        USAGE;  % FORCE, DISP, or BOTH [cite: 39]
        NELEM;  % Num FE elements along local x-axis (FPS only) [cite: 41]
        MELEM;  % Num FE elements along local y-axis (FPS only) [cite: 43]
    end
    
    methods
        function obj = SPLINE1(EID, CAERO, BOX1, BOX2, SETG, varargin)
            %SPLINE1 Construct an instance of this class
            %   Required Inputs: EID, CAERO, BOX1, BOX2, SETG
            p = inputParser();
            
            % Required Positional Arguments (Integers > 0)
            p.addRequired('EID', @(x) x > 0);  
            p.addRequired('CAERO', @(x) x > 0);
            p.addRequired('BOX1', @(x) x > 0); 
            p.addRequired('BOX2', @(x) x > 0); 
            p.addRequired('SETG', @(x) x > 0); 
            
            % Optional Parameters
            % DZ: Real >= 0.0, Default = 0.0
            p.addParameter('DZ', [], @(x) x >= 0);
            
            % METH: IPS, TPS, or FPS
            p.addParameter('METH', [], @(x) any(validatestring(x, ...
                {'IPS', 'TPS', 'FPS'})));
                
            % USAGE: FORCE, DISP, or BOTH
            p.addParameter('USAGE', [], @(x) any(validatestring(x, ...
                {'FORCE', 'DISP', 'BOTH'})));
                
            % NELEM/MELEM: Integers > 0
            p.addParameter('NELEM', [], @(x) x > 0);
            p.addParameter('MELEM', [], @(x) x > 0);
            
            p.parse(EID, CAERO, BOX1, BOX2, SETG, varargin{:});
            
            obj.Name = 'SPLINE1';
            
            % Assign parsed results to properties
            % We iterate through p.Results to capture both required and optional
            names = fieldnames(p.Results);
            for i = 1:length(names)
                obj.(names{i}) = p.Results.(names{i});
            end 
        end
        
        function writeToFile(obj, fid, varargin)
            %writeToFile prints the SPLINE1 entry to the BDF file     
            writeToFile@mni.printing.cards.BaseCard(obj, fid, varargin{:});
            
            % Data cell array matching the Bulk Data Entry structure
            data = [{obj.EID}, {obj.CAERO}, {obj.BOX1}, {obj.BOX2}, ...
                    {obj.SETG}, {obj.DZ}, {obj.METH}, {obj.USAGE}, ...
                    {obj.NELEM}, {obj.MELEM}];
            
            format = 'iiiiirssii';
            
            obj.fprint_nas(fid, format, data);
        end
    end
end