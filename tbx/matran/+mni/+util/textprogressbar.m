classdef textprogressbar < handle
    %TEXTPROGRESSBAR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        str_current ='';
        info_str = '';
    end
    
    properties(Access = private)
       strPercentageLength = 10;   %   Length of percentage string (must be >5)
       strDotsMaximum      = 10;   %   The total number of dots in a progress bar
    end
    
    methods
        function obj = textprogressbar(info_str)
            %TEXTPROGRESSBAR Construct an instance of this class
            %   Detailed explanation goes here
            obj.info_str = info_str;
            fprintf([-1,'']);
            obj.update(0);
        end
        
        function update(obj,c)
            del_str = repmat('\b',1,length(obj.str_current)-1);
            c = floor(c);
            percentageOut = [num2str(c) '%%'];
            percentageOut = [percentageOut repmat(' ',1,obj.strPercentageLength-length(percentageOut)-1)];
            nDots = floor(c/100*obj.strDotsMaximum);
            dotOut = ['[' repmat('.',1,nDots) repmat(' ',1,obj.strDotsMaximum-nDots) ']'];
            obj.str_current = [obj.info_str,percentageOut,dotOut];
            fprintf([del_str,obj.str_current]);
        end
        function close(~)
           fprintf('\n');
        end
    end
end