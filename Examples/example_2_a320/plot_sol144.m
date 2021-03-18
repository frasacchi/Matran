% This example loads the windtunnel model and applies the displacements,
% aero pressures and forces for a static aeroelastic solution.
% the figure is fully explorable by 'left-click' and drag + 'middle_click 
% and draging'.
% elements can also be turned off in the plot by clicking on them in the
% legend.

close all
% load the model
model = mni.import_matran(fullfile('data','A320_half_model_SOL144.dat'));
model.draw

%extract the data
res_disp =  mni.result.f06(fullfile('data','A320_half_model_SOL144.f06')).read_disp;
res_aeroP = mni.result.f06(fullfile('data','A320_half_model_SOL144.f06')).read_aeroP;
res_aeroF = mni.result.f06(fullfile('data','A320_half_model_SOL144.f06')).read_aeroF;
% 
% % apply deformation result
[~,i] = ismember(model.GRID.GID,res_disp.GP);
model.GRID.Deformation = [res_disp.dX(:,i);res_disp.dY(:,i);res_disp.dZ(:,i)];
% 
% apply aero pressure
model.CAERO1.PanelPressure = res_aeroP.Cp;

%apply aero forces
f = [res_aeroF.aeroFx;res_aeroF.aeroFy;res_aeroF.aeroFz;...
    res_aeroF.aeroMx;res_aeroF.aeroMy;res_aeroF.aeroMz];
model.CAERO1.PanelForce = f';

% update the plot to apply deformations and aero pressures + forces
model.update('Scale',1)