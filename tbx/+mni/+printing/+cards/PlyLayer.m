classdef PlyLayer
    properties
        MIDi(:,1) double = [];
        Ti(:,1) double = [];
        THETAi(:,1) double = [];
        SOUTi(:,1) string = [];
    end

    methods
        function obj = PlyLayer(MIDi,Ti,THETAi,SOUTi)
            arguments
                MIDi(:,1) double = [];
                Ti(:,1) double = [];
                THETAi(:,1) double = [];
                SOUTi(:,1) string = [];
            end
            obj.MIDi = MIDi;
            obj.Ti = Ti;
            obj.THETAi = THETAi;
            obj.SOUTi = SOUTi;
        end

        function [data,format] = GetExportFormat(obj)
            arguments
                obj;
            end
            data = [{obj.MIDi},{obj.Ti},{obj.THETAi},{obj.SOUTi}];
            format = 'irrs';

        end
    end

end


