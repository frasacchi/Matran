% This example loads the windtunnel model and applies the modal
% displacements.
% the figure is fully explorable by 'left-click' and drag + 'middle_click 
% and draging'.
% elements can also be turned off in the plot by clicking on them in the
% legend.

close all
% load the model
model = mni.import_matran(fullfile('data','model.bdf'));
model.draw

% get modal data
res_modeshape = mni.result.f06(fullfile('data','sol103.f06')).read_modeshape;
res_freq = mni.result.f06(fullfile('data','sol103.f06')).read_modes;
%% apply deformation result
%pick which mode to plot (1->6)
modeshape_num = 4;

% apply the modal deformation
[~,i] = ismember(model.GRID.GID,res_modeshape.GID(modeshape_num,:));
model.GRID.Deformation = [res_modeshape.T1(modeshape_num,i);...
    res_modeshape.T2(modeshape_num,i);res_modeshape.T3(modeshape_num,i)];

% animate the plot to show the mode shape. 'scale' is the scale of the
% displacement. 'Frequency' is the frequency.
%
% PRESS SPACE TO END THE ANIMATION
%
model.update()
model.animate('Frequency',2,'Scale',0.2) 