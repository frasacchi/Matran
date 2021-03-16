% This example loads the windtunnel model and applies the displacements
% from a ground loading simulation (sol101 with GRAV enabled)
% the figure is fully explorable by 'left-click' and drag + 'middle_click 
% and draging'.
% elements can also be turned off in the plot by clicking on them in the
% legend.

close all
% load the model
model = mni.import_matran(fullfile('data','model.bdf'));
model.draw
% extract the displacment data
res_disp = mni.result.f06(fullfile('data','sol101.f06')).read_disp;

% apply deformation results
[~,i] = ismember(model.GRID.GID,res_disp.GP);
model.GRID.Deformation = [res_disp.dX(:,i);res_disp.dY(:,i);res_disp.dZ(:,i)];

% update the figure (Scale is the normalised scale of displacements 
% to plot)
model.update('Scale',1)