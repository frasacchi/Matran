classdef BeamSection
properties
    A double;
    I1 double;
    I2 double;
    I12 double;
    J double;
    X double;
    NSM double = 0;
    SO string {mustBeMember(SO,["YES","YESA","NO"])} = "YES";
    C (2,1) double = [nan;nan];
    D (2,1) double = [nan;nan];
    E (2,1) double = [nan;nan];
    F (2,1) double = [nan;nan];
end
methods
    function obj = BeamSection(A,I1,I2,I12,J,X,opts)
        arguments
            A double {mustBeGreaterThan(A,0)};
            I1 double {mustBeGreaterThan(I1,0)}; % Izz in beam coordinate system
            I2 double {mustBeGreaterThan(I2,0)}; % Iyy in beam coordinate system
            I12 double {mustBeGreaterThanOrEqual(I12,0)};  % Izy in beam coordinate system
            J double {mustBeGreaterThanOrEqual(J,0)}; % Ixx in beam coordinate system
            X double {mustBeInRange(X,0,1)};
            opts.NSM double = 0;
            opts.SO string {mustBeMember(opts.SO,["YES","YESA","NO"])} = "YES";
            opts.C (2,1) double = [nan;nan];
            opts.D (2,1) double = [nan;nan];
            opts.E (2,1) double = [nan;nan];
            opts.F (2,1) double = [nan;nan];
        end
        obj.A = A;
        obj.I1 = I1;
        obj.I2 = I2;
        obj.I12 = I12;
        obj.J = J;
        obj.X = X;
        obj.NSM = opts.NSM;
        obj.SO = opts.SO;
        obj.C = opts.C;
        obj.D = opts.D;
        obj.E = opts.E;
        obj.F = opts.F;
    end
    function [data,format] = GetExportFormat(obj,opts)
        arguments
            obj;
            opts.WithStressPoints logical = true;
        end
        data = [{obj.A},{obj.I1},{obj.I2},{obj.I12},{obj.J},{obj.NSM}];
        format = 'rrrrrr';
        if opts.WithStressPoints
            data = [data,{obj.C(1)},{obj.C(2)},{obj.D(1)},{obj.D(2)},{obj.E(1)},{obj.E(2)},{obj.F(1)},{obj.F(2)}];
            format = [format,'rrrrrrrr'];
        end
    end
    function [data,format] = GetExportBarFormat(obj)
        data = [{obj.A},{obj.I1},{obj.I2},{obj.J},{obj.NSM},{obj.C(1)},{obj.C(2)},{obj.D(1)},{obj.D(2)},{obj.E(1)},{obj.E(2)},{obj.F(1)},{obj.F(2)}];
        format = 'rrrrrbrrrrrrrr';
    end
end
end