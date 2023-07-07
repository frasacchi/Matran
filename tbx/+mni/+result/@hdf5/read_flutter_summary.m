function [Data] = read_flutter_summary(obj)
    %READ_F06_FLUTTER : Reads the flutter data from the .f06 file with 
    %the name 'filename' which is located in 'dir_out'
    %
    % Inputs :
    %   - 'dir_out'  : Folder path of the folder containing the .f06 file
    %   - 'filename' : Name of the .f06 file (without file extension)
    %
    % Outputs :
    %   - 'Data' : Structure containg all of the Flutter Data data. 
    %                    Fields include:
    %                       + Mode      : Mode Number
    %                       + M         : Mach Number
    %                       + RHO_RATIO : Density Ratio
    %                       + KF        : Reduced Frequency
    %                       + V         : Velocity
    %                       + D         : Damping
    %                       + F         : Frequency
    %                       + CMPLX     : Complex Number of Mode
    % -------------------------------------------------------------------------
    % Author: Fintan Healy
    % Contact: fintan.healy@bristol.ac.uk
    % Created: 12/05/2021
    % Modified: 12/05/2021
    %
    % Change Log:
    %   - 
    % ======================================================================= %
    
    % get input flutter data
    
    flfact_fis = h5read(obj.filepath,'/NASTRAN/INPUT/PARAMETER/FLFACT/FIS');
    flfact_ID = h5read(obj.filepath,'/NASTRAN/INPUT/PARAMETER/FLFACT/IDENTITY');
    flutter = h5read(obj.filepath,'/NASTRAN/INPUT/PARAMETER/FLUTTER');
    dens_id = flutter.DENS(1);
    idx = find(flfact_ID.SID == dens_id,1);
    idx = (flfact_ID.FIS_POS(idx)+1):(flfact_ID.FIS_POS(idx)+flfact_ID.FIS_LEN(idx));
    dens = flfact_fis.FI(idx);
    
    idx = find(flfact_ID.SID == flutter.MACH(1),1);
    idx = (flfact_ID.FIS_POS(idx)+1):(flfact_ID.FIS_POS(idx)+flfact_ID.FIS_LEN(idx));
    machs = flfact_fis.FI(idx);
    
    % idx = find(flfact_ID.SID == flutter.RFREQ(1),1);
    % idx = flfact_ID.FIS_POS(idx)+1:flfact_ID.FIS_POS(idx)+1+flfact_ID.FIS_LEN(idx);
    % vs = abs(flfact_fis.FI(idx));
    
    summary = h5read(obj.filepath,'/NASTRAN/RESULT/AERODYNAMIC/FLUTTER/SUMMARY');
    % point = h5read(obj.filepath,'/NASTRAN/RESULT/AERODYNAMIC/FLUTTER/POINT');
    
    modes = unique(summary.POINT);
    Data = struct();
    dIdx = 1;
    for i = 1:length(modes)
        tmp_idx = find(summary.POINT == modes(i));
        for j = 1:length(tmp_idx)
        Data(dIdx).KF = summary.KFREQ(tmp_idx(j));
        Data(dIdx).V = summary.VELOCITY(tmp_idx(j));
        Data(dIdx).D = summary.DAMPING(tmp_idx(j));
        Data(dIdx).F = summary.FREQUENCY(tmp_idx(j));
        Data(dIdx).CMPLX = complex(summary.EIGR(tmp_idx(j)),summary.EIGI(tmp_idx(j)));
        Data(dIdx).M = machs(j);
        Data(dIdx).RHO_RATIO = dens(j);
        Data(dIdx).MODE = modes(i);
        Data(dIdx).POINT = j;
        dIdx = dIdx + 1; 
        end 
    end
    end 
    
    