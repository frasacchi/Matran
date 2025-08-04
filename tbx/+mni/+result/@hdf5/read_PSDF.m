function [Data] = read_PSDF(obj)
%read_PSDF : Desicriton here
%
% Inputs :
%
% Outputs :
%   - 'Data' : Structure containg all of the PSDF data. 
%                    Fields include:
%                       + Subcase      : Subcase Number
%                       + f            : frequencies at which PSDF is reported
%                       + Displacement : Displacement PSDF at requested nodes
%                       + BeamForce    : Beam Force PSDF at end points of requested elements
%                       + BeamStress   : Beam Stress PSDF at end points of requested elements with recovery points specified
% -------------------------------------------------------------------------
% Author: Ed Wheatcroft
% Contact: ed.wheatcroft@bristol.ac.uk
% Created: 01/08/2025
% Modified: 01/08/2025
%
% Change Log:
%   - Adapted from mni.result.read_random_turbulence()
% ======================================================================= %

% get domain data
domains = h5read(obj.filepath,'/NASTRAN/RESULT/DOMAINS');
try
    displacements = h5read(obj.filepath,'/NASTRAN/RESULT/NODAL/DISPLACEMENT');
catch
    displacements = [];
end
try
    beam_force = h5read(obj.filepath,'/NASTRAN/RESULT/ELEMENTAL/ELEMENT_FORCE/BEAM');
catch
    beam_force = [];
end
try
    beam_stress = h5read(obj.filepath,'/NASTRAN/RESULT/ELEMENTAL/STRESS/BEAM_RR');
catch
    beam_stress = [];
end
subcases = unique(domains.SUBCASE(domains.RANDOM == 1));    % only extract data from subcases which are the result of a RANDOM analysis
subcases = subcases(subcases>0);
Data = struct();
% loop over all subcases...
for i = 1:length(subcases)
    % populate domain data
    Data(i).Subcase = subcases(i);
    RANDOMmask = (domains.SUBCASE == subcases(i)) & (domains.ANALYSIS == 5) & (domains.RANDOM == 1); % additional AND with RANDOM possibly redundant...
    domain_IDs = domains.ID(RANDOMmask);                % mask of all domain points in the current subcase which pertain to a RANDOM analysis
    Data(i).f = domains.TIME_FREQ_EIGR(RANDOMmask);

    %% populate displacement data
    if ~isempty(displacements)
        dispMask = ismember(displacements.DOMAIN_ID, domain_IDs);   % mask of all points in current output table which correspond to a RANDOM analysis.
        Disp = [];
        
        % if we have at least 1 datapoint in the output table which corresponds to a RANDOM analysis...
        if nnz(dispMask) > 0
            Disp = struct();
            Disp.IDs = unique(displacements.ID(dispMask));              % a list of all the GRIDids which are represented in the output table
            Disp.X =  zeros(length(domain_IDs), length(Disp.IDs));
            Disp.Y =  zeros(length(domain_IDs), length(Disp.IDs));
            Disp.Z =  zeros(length(domain_IDs), length(Disp.IDs));
            Disp.RX = zeros(length(domain_IDs), length(Disp.IDs));
            Disp.RY = zeros(length(domain_IDs), length(Disp.IDs));
            Disp.RZ = zeros(length(domain_IDs), length(Disp.IDs));
            
            % loop over all the GRIDids for which we have output...
            for j = 1:length(Disp.IDs)
                GRIDmask = dispMask & displacements.ID == Disp.IDs(j); % mask of all points which pertain to the current GRIDid
                % populate output
                Disp.X(:,j)  = displacements.X(GRIDmask);
                Disp.Y(:,j)  = displacements.Y(GRIDmask);
                Disp.Z(:,j)  = displacements.Z(GRIDmask);
                Disp.RX(:,j) = displacements.RX(GRIDmask);
                Disp.RY(:,j) = displacements.RY(GRIDmask);
                Disp.RZ(:,j) = displacements.RZ(GRIDmask);
            end
        end
        Data(i).Displacement = Disp;
    end
    
    %% populate beam force data - very similar structure to displacements
    if ~isempty(beam_force)
        forceMask =  ismember(beam_force.DOMAIN_ID, domain_IDs);
        Force = [];
        if ~isempty(forceMask)
            Force=struct();
            Force.EIDs = unique(beam_force.EID(forceMask));
            Force.GIDs = zeros(length(domain_IDs), length(Force.EIDs), 2);
            Force.x_L = zeros(length(domain_IDs), length(Force.EIDs), 2);
            Force.Mx = zeros(length(domain_IDs), length(Force.EIDs), 2);
            Force.My = zeros(length(domain_IDs), length(Force.EIDs), 2);
            Force.Mz = zeros(length(domain_IDs), length(Force.EIDs), 2);
            Force.Fx = zeros(length(domain_IDs), length(Force.EIDs), 2);
            Force.Fy = zeros(length(domain_IDs), length(Force.EIDs), 2);
            Force.Fz = zeros(length(domain_IDs), length(Force.EIDs), 2);
            for j = 1:length(Force.EIDs)
                EIDmask = forceMask & beam_force.EID == Force.EIDs(j);
                % current logic only pulls the forces from the first and last arc-length recovery points
                % first...
                Force.GIDs(:,j,1) = beam_force.GRID(1,EIDmask);
                Force.x_L(:,j,1)  = beam_force.SD(1,EIDmask);
                Force.Mx(:,j,1) = beam_force.TTRQ(1,EIDmask);
                Force.Mz(:,j,1) = beam_force.BM1(1,EIDmask);
                Force.My(:,j,1) = beam_force.BM2(1,EIDmask);
                Force.Fx(:,j,1) = beam_force.AF(1,EIDmask);
                Force.Fz(:,j,1) = beam_force.TS2(1,EIDmask);
                Force.Fy(:,j,1) = beam_force.TS1(1,EIDmask);
                % last
                Force.GIDs(:,j,2) = beam_force.GRID(end,EIDmask);
                Force.x_L(:,j,2)  = beam_force.SD(end,EIDmask);
                Force.Mx(:,j,2) = beam_force.TTRQ(end,EIDmask);
                Force.Mz(:,j,2) = beam_force.BM1(end,EIDmask);
                Force.My(:,j,2) = beam_force.BM2(end,EIDmask);
                Force.Fx(:,j,2) = beam_force.AF(end,EIDmask);
                Force.Fz(:,j,2) = beam_force.TS2(end,EIDmask);
                Force.Fy(:,j,2) = beam_force.TS1(end,EIDmask);
            end
        end
        Data(i).BeamForce = Force;
    end

    %% populate beam stress data
    if ~isempty(beam_stress)
        stressMask =  ismember(beam_stress.DOMAIN_ID, domain_IDs);
        Stress = [];
        if ~isempty(stressMask)
            Stress=struct();
            Stress.EIDs = unique(beam_stress.EID(stressMask));
            Stress.GIDs = zeros(length(domain_IDs), length(Stress.EIDs), 2);
            Stress.x_L = zeros(length(domain_IDs), length(Stress.EIDs), 2);
            Stress.C = zeros(length(domain_IDs), length(Stress.EIDs), 2);
            Stress.D = zeros(length(domain_IDs), length(Stress.EIDs), 2);
            Stress.E = zeros(length(domain_IDs), length(Stress.EIDs), 2);
            Stress.F = zeros(length(domain_IDs), length(Stress.EIDs), 2);
            for j = 1:length(Stress.EIDs)
                EIDmask = stressMask & beam_stress.EID == Stress.EIDs(j);
                % current logic only pulls the stresses from the first and last arc-length recovery points
                % first...
                Stress.GIDs(:,j,1) = beam_stress.GRID(1,  EIDmask);
                Stress.x_L(:,j,1)  = beam_stress.SD(1,  EIDmask);
                Stress.C(:,j,1) = beam_stress.XC(1,  EIDmask);
                Stress.D(:,j,1) = beam_stress.XD(1,  EIDmask);
                Stress.E(:,j,1) = beam_stress.XE(1,  EIDmask);
                Stress.F(:,j,1) = beam_stress.XF(1,  EIDmask);
                % last...
                Stress.GIDs(:,j,2) = beam_stress.GRID(end,  EIDmask);
                Stress.x_L(:,j,2)  = beam_stress.SD(end,  EIDmask);
                Stress.C(:,j,2) = beam_stress.XC(end,EIDmask);
                Stress.D(:,j,2) = beam_stress.XD(end,EIDmask);
                Stress.E(:,j,2) = beam_stress.XE(end,EIDmask);
                Stress.F(:,j,2) = beam_stress.XF(end,EIDmask);
            end
        end
        Data(i).BeamStress = Stress;
    end    

end
end

