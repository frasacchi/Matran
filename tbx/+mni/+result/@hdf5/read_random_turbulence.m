function [Data] = read_random_turbulence(obj)
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
    displacements = h5read(obj.filepath,'/NASTRAN/RESULT/NODAL/DISPLACEMENT_CPLX');
catch
    displacements = [];
end
try
    beam_force = h5read(obj.filepath,'/NASTRAN/RESULT/ELEMENTAL/ELEMENT_FORCE/BEAM_CPLX');
catch
    beam_force = [];
end
subcases = unique(domains.SUBCASE);
subcases = subcases(subcases>0);
Data = struct();
for i = 1:length(subcases)
    % populate domain data
    Data(i).Subcase = subcases(i);
    idx = (domains.SUBCASE == subcases(i)) & (domains.ANALYSIS == 5);
    domain_IDs = domains.ID(idx);
    Data(i).f = domains.TIME_FREQ_EIGR(idx);
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
                Disp.X(:,j) = abs(complex(displacements.XR(idx_ele),displacements.XI(idx_ele)));
                Disp.Y(:,j) = abs(complex(displacements.YR(idx_ele),displacements.YI(idx_ele)));
                Disp.Z(:,j) = abs(complex(displacements.ZR(idx_ele),displacements.ZI(idx_ele)));
                Disp.RX(:,j) = abs(complex(displacements.RXR(idx_ele),displacements.RXI(idx_ele)));
                Disp.RY(:,j) = abs(complex(displacements.RYR(idx_ele),displacements.RYI(idx_ele)));
                Disp.RZ(:,j) = abs(complex(displacements.RZR(idx_ele),displacements.RZI(idx_ele)));
            end
        end
        Data(i).Displacement = Disp;
    end
     %% populate complex beam force data
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
                Bar.Mx(:,j,1) = abs(complex(beam_force.TTRQR(1,idx_ele),beam_force.TTRQI(1,idx_ele)));
                Bar.Mz(:,j,1) = abs(complex(beam_force.BM1R(1,idx_ele),beam_force.BM1I(1,idx_ele)));
                Bar.My(:,j,1) = abs(complex(beam_force.BM2R(1,idx_ele),beam_force.BM2I(1,idx_ele)));
                Bar.Fx(:,j,1) = abs(complex(beam_force.AFR(1,idx_ele),beam_force.AFI(1,idx_ele)));
                Bar.Fz(:,j,1) = abs(complex(beam_force.TS2R(1,idx_ele),beam_force.TS2I(1,idx_ele)));
                Bar.Fy(:,j,1) = abs(complex(beam_force.TS1R(1,idx_ele),beam_force.TS1I(1,idx_ele)));
                Bar.Mx(:,j,2) = abs(complex(beam_force.TTRQR(end,idx_ele),beam_force.TTRQI(end,idx_ele)));
                Bar.Mz(:,j,2) = abs(complex(beam_force.BM1R(end,idx_ele),beam_force.BM1I(end,idx_ele)));
                Bar.My(:,j,2) = abs(complex(beam_force.BM2R(end,idx_ele),beam_force.BM2I(end,idx_ele)));
                Bar.Fx(:,j,2) = abs(complex(beam_force.AFR(end,idx_ele),beam_force.AFI(end,idx_ele)));
                Bar.Fz(:,j,2) = abs(complex(beam_force.TS2R(end,idx_ele),beam_force.TS2I(end,idx_ele)));
                Bar.Fy(:,j,2) = abs(complex(beam_force.TS1R(end,idx_ele),beam_force.TS1I(end,idx_ele)));
            end
        end
        Data(i).BeamForce = Bar;
    end
end
end

