function [res] = read_divergence(obj)
%READ_Divergence Reads the divergence from the .h5 file 
% Author: Fintan Healy
% Contact: fintan.healy@bristol.ac.uk
% Created: 06/03/2023
% Modified: 06/03/2023
%
% Change Log:
%   - 
% ======================================================================= %

% get eigenvalues
machs = h5read(obj.filepath,'/NASTRAN/INPUT/PARAMETER/DIVERG/MACHS');
try
    div_res = h5read(obj.filepath,'/NASTRAN/RESULT/AERODYNAMIC/DIVERGENCE');
catch err
    res = [];
    return
end
%convert to familar format
res = struct();
val = 0;
mach_idx = 1;
    for i = 1:length(div_res.ROOT)
        if div_res.ROOT(i) < val
            mach_idx = mach_idx + 1;
        end
        val = div_res.ROOT(i);
        res(i).MACH = machs.MI(mach_idx);
        res(i).ROOT = div_res.ROOT(i);
        res(i).Q = div_res.PRESSURE(i);
        res(i).CMPLX = complex(div_res.EIGR(i),div_res.EIGI(i));
    end
end

