function [Data] = read_dynamic(obj)
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

% get domain data
domains = h5read(obj.filepath,'/NASTRAN/RESULT/DOMAINS');
try
    displacements = h5read(obj.filepath,'/NASTRAN/RESULT/NODAL/DISPLACEMENT');
catch
    displacements = [];
end
try
    bar_force = h5read(obj.filepath,'/NASTRAN/RESULT/ELEMENTAL/ELEMENT_FORCE/BAR');
catch
    bar_force = [];
end
try
    beam_force = h5read(obj.filepath,'/NASTRAN/RESULT/ELEMENTAL/ELEMENT_FORCE/BEAM');
catch
    beam_force = [];
end
try
    quad_force = h5read(obj.filepath,'/NASTRAN/RESULT/ELEMENTAL/ELEMENT_FORCE/QUAD4');
catch
    quad_force = [];
end
subcases = unique(domains.SUBCASE);
subcases = subcases(subcases>0);
Data = struct();
for i = 1:length(subcases)
    % populate domain data
    Data(i).Subcase = subcases(i);
    idx = (domains.SUBCASE == subcases(i)) & (domains.ANALYSIS == 6);
    domain_IDs = domains.ID(idx);
    Data(i).t = domains.TIME_FREQ_EIGR(idx);
    % Data(i).Force = [];
    %% populate displacement data
    if ~isempty(displacements)
        idx_disp =  ismember(displacements.DOMAIN_ID,domain_IDs);
        Disp = [];
        
        if nnz(idx_disp)>0
            Disp=struct();
            Disp.IDs = unique(displacements.ID(idx_disp));
            Disp.X =  zeros(length(domain_IDs),length(Disp.IDs));
            Disp.Y =  zeros(length(domain_IDs),length(Disp.IDs));
            Disp.Z =  zeros(length(domain_IDs),length(Disp.IDs));
            Disp.RX = zeros(length(domain_IDs),length(Disp.IDs));
            Disp.RY = zeros(length(domain_IDs),length(Disp.IDs));
            Disp.RZ = zeros(length(domain_IDs),length(Disp.IDs));
            for j = 1:length(Disp.IDs)
                idx_ele = idx_disp & displacements.ID == Disp.IDs(j);
                Disp.X(:,j) = displacements.X(idx_ele);
                Disp.Y(:,j) = displacements.Y(idx_ele);
                Disp.Z(:,j) = displacements.Z(idx_ele);
                Disp.RX(:,j) = displacements.RX(idx_ele);
                Disp.RY(:,j) = displacements.RY(idx_ele);
                Disp.RZ(:,j) = displacements.RZ(idx_ele);
            end
        end
        Data(i).Displacement = Disp;
    end

    %% populate bar force data
    if ~isempty(bar_force)
        idx_disp =  ismember(bar_force.DOMAIN_ID,domain_IDs);
        Bar = [];
        if ~isempty(idx_disp)
            Bar=struct();
            Bar.EIDs = unique(bar_force.EID(idx_disp));
            Bar.Mx = zeros(length(domain_IDs),length(Bar.EIDs));
            Bar.My = zeros(length(domain_IDs),length(Bar.EIDs));
            Bar.Mz = zeros(length(domain_IDs),length(Bar.EIDs));
            Bar.Fx = zeros(length(domain_IDs),length(Bar.EIDs));
            Bar.Fy = zeros(length(domain_IDs),length(Bar.EIDs));
            Bar.Fz = zeros(length(domain_IDs),length(Bar.EIDs));
            for j = 1:length(Bar.EIDs)
                idx_ele = idx_disp & bar_force.EID == Bar.EIDs(j);
                Bar.Mx(:,j,1) = bar_force.TRQ(idx_ele);
                Bar.My(:,j,1) = bar_force.BM2A(idx_ele);
                Bar.Mz(:,j,1) = bar_force.BM1A(idx_ele);
                Bar.Fx(:,j,1) = bar_force.AF(idx_ele);
                Bar.Fy(:,j,1) = bar_force.TS2(idx_ele);
                Bar.Fz(:,j,1) = bar_force.TS1(idx_ele);
                Bar.Mx(:,j,2) = bar_force.TRQ(idx_ele);
                Bar.My(:,j,2) = bar_force.BM2B(idx_ele);
                Bar.Mz(:,j,2) = bar_force.BM1B(idx_ele);
                Bar.Fx(:,j,2) = bar_force.AF(idx_ele);
                Bar.Fy(:,j,2) = bar_force.TS2(idx_ele);
                Bar.Fz(:,j,2) = bar_force.TS1(idx_ele);
            end
        end
        Data(i).BarForce = Bar;
    end

    %% populate beam force data
    if ~isempty(beam_force)
        idx_disp =  ismember(beam_force.DOMAIN_ID,domain_IDs);
        Bar = [];
        if ~isempty(idx_disp)
            Bar=struct();
            Bar.EIDs = unique(beam_force.EID(idx_disp));
            Bar.Mx = zeros(length(domain_IDs),length(Bar.EIDs),2);
            Bar.My = zeros(length(domain_IDs),length(Bar.EIDs),2);
            Bar.Mz = zeros(length(domain_IDs),length(Bar.EIDs),2);
            Bar.Fx = zeros(length(domain_IDs),length(Bar.EIDs),2);
            Bar.Fy = zeros(length(domain_IDs),length(Bar.EIDs),2);
            Bar.Fz = zeros(length(domain_IDs),length(Bar.EIDs),2);
            for j = 1:length(Bar.EIDs)
                idx_ele = idx_disp & beam_force.EID == Bar.EIDs(j);
                Bar.Mx(:,j,1) = beam_force.TTRQ(1,idx_ele);
                Bar.Mz(:,j,1) = beam_force.BM1(1,idx_ele);
                Bar.My(:,j,1) = beam_force.BM2(1,idx_ele);
                Bar.Fx(:,j,1) = beam_force.AF(1,idx_ele);
                Bar.Fz(:,j,1) = beam_force.TS2(1,idx_ele);
                Bar.Fy(:,j,1) = beam_force.TS1(1,idx_ele);
                Bar.Mx(:,j,2) = beam_force.TTRQ(end,idx_ele);
                Bar.Mz(:,j,2) = beam_force.BM1(end,idx_ele);
                Bar.My(:,j,2) = beam_force.BM2(end,idx_ele);
                Bar.Fx(:,j,2) = beam_force.AF(end,idx_ele);
                Bar.Fz(:,j,2) = beam_force.TS2(end,idx_ele);
                Bar.Fy(:,j,2) = beam_force.TS1(end,idx_ele);
            end
        end
        Data(i).BeamForce = Bar;
    end

    %% populate quad4 force data
    if ~isempty(quad_force)
        idx_disp =  ismember(quad_force.DOMAIN_ID,domain_IDs);
        Quad = [];
        if nnz(idx_disp)>0
            Quad=struct();
            Quad.EIDs = unique(quad_force.EID(idx_disp));
            Quad.Mx = zeros(length(domain_IDs),length(Quad.EIDs),2);
            Quad.My = zeros(length(domain_IDs),length(Quad.EIDs),2);
            Quad.Mxy = zeros(length(domain_IDs),length(Quad.EIDs),2);
            Quad.Fx = zeros(length(domain_IDs),length(Quad.EIDs),2);
            Quad.Fy = zeros(length(domain_IDs),length(Quad.EIDs),2);
            Quad.Nx = zeros(length(domain_IDs),length(Quad.EIDs),2);
            Quad.Ny = zeros(length(domain_IDs),length(Quad.EIDs),2);
            Quad.Nxy = zeros(length(domain_IDs),length(Quad.EIDs),2);
            for j = 1:length(Quad.EIDs)
                idx_ele = idx_disp & quad_force.EID == Quad.EIDs(j);
                Quad.Mx(:,j,1) = quad_force.BMX(1,idx_ele);
                Quad.My(:,j,1) = quad_force.BMY(1,idx_ele);
                Quad.Mxy(:,j,1) = quad_force.BMXY(1,idx_ele);
                Quad.Fx(:,j,1) = quad_force.TX(1,idx_ele);
                Quad.Fy(:,j,1) = quad_force.TY(1,idx_ele);
                Quad.Nx(:,j,1) = quad_force.MX(1,idx_ele);
                Quad.Ny(:,j,1) = quad_force.MY(1,idx_ele);
                Quad.Nxy(:,j,1) = quad_force.MXY(1,idx_ele);
                Quad.Mx(:,j,2) = quad_force.BMX(end,idx_ele);
                Quad.My(:,j,2) = quad_force.BMY(end,idx_ele);
                Quad.Mxy(:,j,2) = quad_force.BMXY(end,idx_ele);
                Quad.Fx(:,j,2) = quad_force.TX(end,idx_ele);
                Quad.Fy(:,j,2) = quad_force.TY(end,idx_ele);
                Quad.Nx(:,j,2) = quad_force.MX(end,idx_ele);
                Quad.Ny(:,j,2) = quad_force.MY(end,idx_ele);
                Quad.Nxy(:,j,2) = quad_force.MXY(end,idx_ele);
            end
        end
        Data(i).Quad4Force = Quad;
    end
end
end

