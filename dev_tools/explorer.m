% +------------------------------------------------------+
% |           Interactive 3D Plot Exploration            |
% |              with MATLAB Implementation              | 
% |                                                      |
% | Author: Ph.D. Eng. Hristo Zhivomirov        08/27/17 | 
% +------------------------------------------------------+
% 
% function: explorer(hFig)
%
% Input:
% hFig - handle of the figure where an exploration must be applied
% 
% Output:
% N/A
%
% Instructions for use:
% - Click and hold the left mouse button and dragging over the axes to
%   rotate the figure;
% - Turn the mouse scroll wheel to increase or decrease the magnification
%   factor (i.e. to zoom in or out); 
% - Use the keyboard arrows to pan the figure;
% - Double-click the left mouse button to put a datatip (data cursor) on
%   the plot;
% - Press "Home" button to exit the 3D explorer and to restore the figure
%   to its original view.
function explorer(hFig)
% set the mouse callback functions
set(hFig, 'WindowButtonDownFcn',    @ButtonDownCallback, ...
          'WindowScrollWheelFcn',   @WindowScrollWheelCallback, ...
          'KeyPressFcn',            @KeyPressCallback, ...
          'WindowButtonUpFcn',      @ButtonUpCallback)
% save the original axes
ax0 = copyobj(gca, hFig);
set(hFig, 'UserData', ax0)
set(ax0, 'Visible', 'off')
set(ax0.Children, 'Visible', 'off')
% freeze the aspect ratio properties      
axis(gca, 'vis3d')
      
end
function ButtonDownCallback(src, eventdata)
if strcmp(get(src, 'SelectionType'), 'normal')
    % -> the left mouse button is clicked once
    % enable the interactive rotation
    ppos = get(0, 'PointerLocation');
    set(gca, 'UserData', ppos)
    set(gcf,'WindowButtonMotionFcn',@ButtonMotionCallback)
    ButtonMotionCallback(src)   
elseif strcmp(get(src, 'SelectionType'), 'extend')
    % -> the left mouse button is clicked once
    % enable the interactive rotation
    ppos = get(0, 'PointerLocation');
    set(gca, 'UserData', ppos)
    set(gcf,'WindowButtonMotionFcn',@ButtonDragCallback)
    ButtonDragCallback(src)
elseif strcmp(get(src, 'SelectionType'), 'open')
    % -> the left mouse button is double-clicked
    % create a datatip
    cursorMode = datacursormode(src);
    hDatatip = cursorMode.createDatatip(get(gca, 'Children'));
    
    % move the datatip to the position
    ax_ppos = get(gca, 'CurrentPoint');
    ax_ppos = ax_ppos([1, 3, 5]);  
    % uncomment the next line for Matlab R2014a and earlier
    % set(get(hDatatip, 'DataCursor'), 'DataIndex', index, 'TargetPoint', ax_ppos)
    set(hDatatip, 'Position', ax_ppos)
    cursorMode.updateDataCursors    
end
end
function ButtonMotionCallback(src, eventdata)
% check if the user data exist
if isempty(get(gca, 'UserData'))
    return
end
% camera rotation
old_ppos = get(gca, 'UserData');
new_ppos = get(0, 'PointerLocation');
set(gca, 'UserData', new_ppos)
dx = (new_ppos(1) - old_ppos(1))*0.25;
dy = (new_ppos(2) - old_ppos(2))*0.25;
camorbit(gca, -dx, -dy)
end

function ButtonDragCallback(src, eventdata)
% check if the user data exist
if isempty(get(gca, 'UserData'))
    return
end
% camera rotation
old_ppos = get(gca, 'UserData');
new_ppos = get(0, 'PointerLocation');
set(gca, 'UserData', new_ppos)
dx = (new_ppos(1) - old_ppos(1))*0.01;
dy = (new_ppos(2) - old_ppos(2))*0.01;
camdolly(gca, -dx, -dy, 0)
end

function WindowScrollWheelCallback(src, eventdata)
% set the zoom facor
if eventdata.VerticalScrollCount < 0
    % increase the magnification
    zoom_factor = 1.05;
else 
    % decrease the magnification
    zoom_factor = 0.95;
end
% camera zoom
camzoom(zoom_factor)
end
function KeyPressCallback(src, eventdata)
% check which key is pressed
if strcmp(eventdata.Key, 'uparrow')
    dx = 0; dy = 0.05; 
elseif strcmp(eventdata.Key, 'downarrow')
    dx = 0; dy = -0.05; 
elseif strcmp(eventdata.Key, 'leftarrow')
    dx = -0.05; dy = 0;
elseif strcmp(eventdata.Key, 'rightarrow')
    dx = 0.05; dy = 0;
else
    dx = 0; dy = 0;
end
% camera pan
camdolly(gca, dx, dy, 0)
% once again check which key is pressed
if strcmp(eventdata.Key, 'home')
    % restore the original axes and exit the explorer
    delete(gca)
    ax0 = get(src, 'UserData');
    set(ax0, 'Visible', 'on')
    set(ax0.Children, 'Visible', 'on')
    reset(src)
    explorer(gcf)
end
end
function ButtonUpCallback(src, eventdata)
% clear the pointer position
set(gca, 'UserData', [])
end