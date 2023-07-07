%% f06read
% The following script reads a typical f06 file from NASTRAN and parses the
% data to Matlab separating the subcases into a cell array
% The assumption in this script is that the SORT1 option has been selected
% for the displacements
function [Dynamic] = read_dynamic(obj)

Dynamic.Displacements = [];
Dynamic.Velocities = [];

FID = fopen(obj.filepath,'r');
c = 0;
jdisp = 0;
gid = -1;

while feof(FID) ~=1
    tline = fgets(FID);
    tline = tline(tline~=' ');
    
    a = textscan(tline,'0SUBCASE %f');
    
    if ~isempty(a{1,1})
        
        subcase = a{1,1};
        tline = fgets(FID);        
        if contains(tline,{'LOAD STEP','TIME'})
            
            % Grab the time step
            if contains(tline,'LOAD STEP')
                loadid = textscan(tline,'LOAD STEP = %f');
            else
                loadid = textscan(tline,'TIME = %f');
            end
            
            tline  = fgets(FID);
            tline  = tline(tline~=' ');
            DispTag = strfind(tline,'DISPLACEMENTVECTOR');
            VelTag  = strfind(tline,'VELOCITYVECTOR');
            BarForceTag  = strfind(tline,'FORCESINBARELEMENTS(CBAR)');
            BeamForceTag  = strfind(tline,'FORCESINBEAMELEMENTS(CBEAM)');
            
            % Reset the matrix if a new subcase is selected
            if subcase ~= c
                idisp = 0;
                jdisp = 0;
                ivel = 0;
                jvel = 0;
                i_bar_force = 0;
                j_bar_force = 0;
                i_beam_force = 0;
                j_beam_force = 0;
            end
            
            % Store the displacements
            if ~isempty(DispTag)
                
                if gid ~= loadid{1,1}
                    jdisp = jdisp+1;
                    idisp = 0;
                    gid = loadid{1,1};
                    Dynamic.t(jdisp) = loadid{1,1};
                end
                
                fgets(FID);fgets(FID);
                tline = fgets(FID);
                strdata = textscan(tline,'%f G %f %f %f %f %f %f');
                while(~isempty(strdata{1,2}))
                    idisp = idisp + 1;
                    Dynamic.Displacements{1,a{1,1}}.dX(jdisp,idisp) = strdata{1,2};
                    Dynamic.Displacements{1,a{1,1}}.dY(jdisp,idisp) = strdata{1,3};
                    Dynamic.Displacements{1,a{1,1}}.dZ(jdisp,idisp) = strdata{1,4};
                    Dynamic.Displacements{1,a{1,1}}.thX(jdisp,idisp) = strdata{1,5};
                    Dynamic.Displacements{1,a{1,1}}.thY(jdisp,idisp) = strdata{1,6};
                    Dynamic.Displacements{1,a{1,1}}.thZ(jdisp,idisp) = strdata{1,7};
                    if jdisp == 1
                        Dynamic.Displacements{1,a{1,1}}.GP(idisp) = strdata{1,1};
                    end
                    tline = fgets(FID);
                    strdata = textscan(tline,'%f G %f %f %f %f %f %f');
                end
                c = subcase;
            end
            
            % Store the velocities
            if ~isempty(VelTag)
                
                if gid ~= loadid{1,1}
                    jvel = jvel+1;
                    ivel = 0;
                    gid = loadid{1,1};
                    Dynamic.t(jvel) = loadid{1,1};
                end
                
                fgets(FID);fgets(FID);
                tline = fgets(FID);
                strdata = textscan(tline,'%f G %f %f %f %f %f %f');
                while(~isempty(strdata{1,2}))
                    ivel = ivel + 1;
                    Dynamic.Velocities{1,a{1,1}}(ivel,:,jvel) = [strdata{1,2}, strdata{1,3}, strdata{1,4},...
                        strdata{1,5}, strdata{1,6}, strdata{1,7}];
                    tline = fgets(FID);
                    strdata = textscan(tline,'%f G %f %f %f %f %f %f');
                end
                c = subcase;
            end
            
            % Store the bar forces
            if ~isempty(BarForceTag)
                
                if gid ~= loadid{1,1}
                    j_bar_force = j_bar_force+1;
                    i_bar_force = 0;
                    gid = loadid{1,1};
                    Dynamic.t(j_bar_force) = loadid{1,1};
                end
                
                fgets(FID);fgets(FID);
                tline = fgets(FID);
                strdata = textscan(tline,'%f %f %f %f %f %f %f %f %f');
                while(~isempty(strdata{1,2}))
                    i_bar_force = i_bar_force + 1;
                    Dynamic.BarForces{a{1,1}}.Fx(j_bar_force,i_bar_force) = strdata{1,8};
                    Dynamic.BarForces{a{1,1}}.Fy(j_bar_force,i_bar_force) = strdata{1,6};
                    Dynamic.BarForces{a{1,1}}.Fz(j_bar_force,i_bar_force) = strdata{1,7};
                    Dynamic.BarForces{a{1,1}}.Mx(j_bar_force,i_bar_force) = strdata{1,9};
                    Dynamic.BarForces{a{1,1}}.My(j_bar_force,i_bar_force) = 0.5*(strdata{1,3}+strdata{1,5});
                    Dynamic.BarForces{a{1,1}}.Mz(j_bar_force,i_bar_force) = 0.5*(strdata{1,2}+strdata{1,4});
                    Dynamic.BarForces{a{1,1}}.MyA(j_bar_force,i_bar_force) = strdata{1,3};
                    Dynamic.BarForces{a{1,1}}.MzA(j_bar_force,i_bar_force) = strdata{1,2};
                    Dynamic.BarForces{a{1,1}}.MyB(j_bar_force,i_bar_force) = strdata{1,5};
                    Dynamic.BarForces{a{1,1}}.MzB(j_bar_force,i_bar_force) = strdata{1,4};
                    if j_bar_force == 1
                        Dynamic.BarForces{a{1,1}}.ID(i_bar_force) = strdata{1,1};
                    end
                    tline = fgets(FID);
                    strdata = textscan(tline,'%f %f %f %f %f %f %f %f %f');
                end
                c = subcase;
            end

            % Store the beam forces
            if ~isempty(BeamForceTag)    
                if gid ~= loadid{1,1}
                    j_beam_force = j_beam_force+1;
                    i_beam_force = 0;
                    gid = loadid{1,1};
                    Dynamic.t(j_beam_force) = loadid{1,1};
                end
                
                fgets(FID);fgets(FID);
                tline = fgets(FID);
                strdata = textscan(tline,'%f %f %f %f %f %f %f %f %f');
                while(~isempty(strdata{1,2}))
                    i_beam_force = i_beam_force + 1;
                    Dynamic.BeamForces{a{1,1}}.Fx(j_beam_force,i_beam_force) = strdata{1,6};
                    Dynamic.BeamForces{a{1,1}}.Fy(j_beam_force,i_beam_force) = strdata{1,4};
                    Dynamic.BeamForces{a{1,1}}.Fz(j_beam_force,i_beam_force) = strdata{1,5};
                    Dynamic.BeamForces{a{1,1}}.Mx(j_beam_force,i_beam_force) = strdata{1,7};
                    Dynamic.BeamForces{a{1,1}}.My(j_beam_force,i_beam_force) = strdata{1,3};
                    Dynamic.BeamForces{a{1,1}}.Mz(j_beam_force,i_beam_force) = strdata{1,2};
                    if j_beam_force == 1
                        Dynamic.BeamForces{a{1,1}}.ID(i_beam_force) = strdata{1,1};
                    end
                    tline = fgets(FID);
                    strdata = textscan(tline,'%f %f %f %f %f %f %f %f %f');
                end
                c = subcase;
            end
        end
              
    end
    
end
fclose(FID);

% Restructure the array for post-processing reasons
if ~isempty(Dynamic.Displacements)
    Dynamic.Displacements2{1,1} = permute(Dynamic.Displacements{1,1},[1 3 2]);
end
if ~isempty(Dynamic.Velocities)
    Dynamic.Velocities2{1,1}    = permute(Dynamic.Velocities{1,1},[1 3 2]);
end

end
