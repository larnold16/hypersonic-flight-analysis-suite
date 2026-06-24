function app = updateMainPlot(app, selectedPlotType, results)
% updateMainPlot
% Draws the selected primary plot in SingleAxes(1).

if nargin < 2 || isempty(selectedPlotType)
    selectedPlotType = "Trajectory";
end
if nargin < 3 || isempty(results)
    if isfield(app.State, 'Results') && isfield(app.State.Results, 'single')
        results = app.State.Results.single;
    else
        return;
    end
end
if ~isfield(app, 'SingleAxes') || isempty(app.SingleAxes) || ~isvalid(app.SingleAxes(1))
    return;
end

ax = app.SingleAxes(1);
theme = stage14Theme();
app = clearMainPlotTransientGraphics(app, ax);
cla(ax, 'reset');
hold(ax, 'off');
styleStage14Axes(ax);
if isprop(ax, 'ColorOrderIndex')
    ax.ColorOrderIndex = 1;
end
[x, y, xLabelText, yLabelText, titleText] = plotData(results, selectedPlotType);
if isempty(x) || isempty(y)
    title(ax, char(selectedPlotType + " unavailable"));
    styleStage14Axes(ax);
    return;
end
lineHandle = plot(ax, x, y, '-', 'LineWidth', 2.2, ...
    'Color', theme.primary, 'DisplayName', 'Current run');
attachTrajectoryDataTipStage14(lineHandle, results);
attachTrajectoryPointSelectionStage14(lineHandle, app.Figure, results, "Current run");
hold(ax, 'on');
if isfield(app.State, 'savedRuns') && ~isempty(app.State.savedRuns)
    for k = 1:numel(app.State.savedRuns)
        saved = app.State.savedRuns(k).Results;
        [xs, ys] = plotData(saved, selectedPlotType);
        if ~isempty(xs) && ~isempty(ys)
            colorIndex = 1 + mod(k, size(theme.plotColors, 1));
            plot(ax, xs, ys, '--', 'LineWidth', 1.2, ...
                'Color', theme.plotColors(colorIndex, :), ...
                'DisplayName', char(app.State.savedRuns(k).Name));
        end
    end
    legend(ax, 'Location', 'best');
end
grid(ax, 'on');
xlabel(ax, xLabelText);
ylabel(ax, yLabelText);
title(ax, titleText);
app = addEventMarkers(app, results);
styleStage14Axes(ax);
end

function app = clearMainPlotTransientGraphics(app, ax)
if isfield(app, 'EventMarkers') && ~isempty(app.EventMarkers)
    try
        delete(app.EventMarkers(isvalid(app.EventMarkers)));
    catch
    end
end
app.EventMarkers = gobjects(0);

if isfield(app, 'SelectedPointMarker') && ~isempty(app.SelectedPointMarker)
    try
        delete(app.SelectedPointMarker(isvalid(app.SelectedPointMarker)));
    catch
    end
end
app.SelectedPointMarker = gobjects(0);

if nargin >= 2 && ~isempty(ax) && isvalid(ax)
    try
        delete(findall(ax, 'Tag', 'Stage14EventMarker'));
        delete(findall(ax, 'Tag', 'Stage14SelectedPointMarker'));
    catch
    end
end
end

function [x, y, xLabelText, yLabelText, titleText] = plotData(r, plotType)
x = [];
y = [];
xLabelText = '';
yLabelText = '';
titleText = char(plotType);
switch lower(char(plotType))
    case 'trajectory'
        x = getField(r, 'x') ./ 1000;
        y = getField(r, 'h') ./ 1000;
        xLabelText = 'Downrange (km)';
        yLabelText = 'Altitude (km)';
        titleText = 'Trajectory';
    case 'velocity'
        x = getField(r, 't');
        y = getField(r, 'V');
        xLabelText = 'Time (s)';
        yLabelText = 'Velocity (m/s)';
    case 'mach'
        x = getField(r, 't');
        y = getField(r, 'Mach');
        xLabelText = 'Time (s)';
        yLabelText = 'Mach';
    case 'dynamic pressure'
        x = getField(r, 't');
        y = getField(r, 'q') ./ 1000;
        xLabelText = 'Time (s)';
        yLabelText = 'Dynamic pressure (kPa)';
    case 'drag'
        x = getField(r, 't');
        y = getField(r, 'drag');
        xLabelText = 'Time (s)';
        yLabelText = 'Drag (N)';
    case 'stagnation temperature'
        x = getField(r, 't');
        y = firstField(r, {'stagTemp','Tstag'});
        xLabelText = 'Time (s)';
        yLabelText = 'Stagnation temperature (K)';
    case 'angle of attack'
        x = getField(r, 't');
        y = getField(r, 'alpha_deg');
        xLabelText = 'Time (s)';
        yLabelText = 'Angle of attack (deg)';
    case 'lift-to-drag'
        x = getField(r, 't');
        y = getField(r, 'LD');
        xLabelText = 'Time (s)';
        yLabelText = 'L/D';
end
end

function values = getField(s, fieldName)
values = [];
if isstruct(s) && isfield(s, fieldName) && isnumeric(s.(fieldName))
    values = s.(fieldName);
end
end

function values = firstField(s, names)
values = [];
for k = 1:numel(names)
    values = getField(s, names{k});
    if ~isempty(values)
        return;
    end
end
end
