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
            ForceTag  = strfind(tline,'FORCESINBARELEMENTS(CBAR)');
            
            % Reset the matrix if a new subcase is selected
            if subcase ~= c
                idisp = 0;
                jdisp = 0;
                ivel = 0;
                jvel = 0;
                iforce = 0;
                jforce = 0;
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
                    Dynamic.Displacements{1,a{1,1}}(idisp,:,jdisp) = [strdata{1,2}, strdata{1,3}, strdata{1,4},...
                        strdata{1,5}, strdata{1,6}, strdata{1,7}];
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
            if ~isempty(ForceTag)
                
                if gid ~= loadid{1,1}
                    jforce = jforce+1;
                    iforce = 0;
                    gid = loadid{1,1};
                    Dynamic.t(jforce) = loadid{1,1};
                end
                
                fgets(FID);fgets(FID);
                tline = fgets(FID);
                strdata = textscan(tline,'%f %f %f %f %f %f %f %f %f');
                while(~isempty(strdata{1,2}))
                    iforce = iforce + 1;
                    Dynamic.BarForces{a{1,1}}.Fx(iforce,jforce) = strdata{1,8};
                    Dynamic.BarForces{a{1,1}}.Fy(iforce,jforce) = strdata{1,6};
                    Dynamic.BarForces{a{1,1}}.Fz(iforce,jforce) = strdata{1,7};
                    Dynamic.BarForces{a{1,1}}.Mx(iforce,jforce) = strdata{1,9};
                    Dynamic.BarForces{a{1,1}}.My(iforce,jforce) = 0.5*(strdata{1,3}+strdata{1,5});
                    Dynamic.BarForces{a{1,1}}.Mz(iforce,jforce) = 0.5*(strdata{1,2}+strdata{1,4});
                    tline = fgets(FID);
                    strdata = textscan(tline,'%f f %f %f %f %f %f %f %f');
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
