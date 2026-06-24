function app = addEventMarkers(app, results)
% addEventMarkers
% Adds max/impact markers to the current Stage 14 main plot.

if ~isfield(app, 'SingleAxes') || isempty(app.SingleAxes) || ~isvalid(app.SingleAxes(1))
    return;
end
if isfield(app, 'EventMarkers') && ~isempty(app.EventMarkers)
    try
        delete(app.EventMarkers(isvalid(app.EventMarkers)));
    catch
    end
end
app.EventMarkers = gobjects(0);

if isfield(app, 'EventMarkersCheckbox') && isvalid(app.EventMarkersCheckbox) && ~app.EventMarkersCheckbox.Value
    return;
end

ax = app.SingleAxes(1);
plotType = "Trajectory";
if isfield(app, 'MainPlotDropDown') && isvalid(app.MainPlotDropDown)
    plotType = string(app.MainPlotDropDown.Value);
end
events = findPeakEvents(results);
hold(ax, 'on');
app.EventMarkers(end+1) = plotEvent(ax, results, plotType, events.launch, '>', [0.00 0.48 0.42]);
app.EventMarkers(end+1) = plotEvent(ax, results, plotType, events.maxAltitude, '^', [0.1 0.45 0.85]);
app.EventMarkers(end+1) = plotEvent(ax, results, plotType, events.maxMach, 's', [0.7 0.2 0.15]);
app.EventMarkers(end+1) = plotEvent(ax, results, plotType, events.maxQ, 'd', [0.55 0.25 0.7]);
app.EventMarkers(end+1) = plotEvent(ax, results, plotType, events.maxDrag, 'v', [0.85 0.45 0.1]);
app.EventMarkers(end+1) = plotEvent(ax, results, plotType, events.maxLift, 'p', [0.00 0.50 0.30]);
app.EventMarkers(end+1) = plotEvent(ax, results, plotType, events.maxStagnationTemperature, 'h', [0.80 0.18 0.12]);
app.EventMarkers(end+1) = plotEvent(ax, results, plotType, events.maxLD, '*', [0.42 0.30 0.62]);
app.EventMarkers(end+1) = plotEvent(ax, results, plotType, events.impact, 'o', [0.05 0.05 0.05]);
app.EventMarkers = app.EventMarkers(isvalid(app.EventMarkers));
end

function marker = plotEvent(ax, results, plotType, event, markerStyle, color)
marker = gobjects(0);
if ~event.valid || ~isfinite(event.index)
    return;
end
[x, y] = eventCoordinates(results, plotType, event.index);
if ~isfinite(x) || ~isfinite(y)
    return;
end
marker = plot(ax, x, y, markerStyle, 'MarkerSize', 7, 'LineWidth', 1.6, ...
    'Color', color, 'MarkerFaceColor', color, 'MarkerEdgeColor', [1 1 1], ...
    'DisplayName', char(event.label), 'Tag', 'Stage14EventMarker');
try
    marker.ButtonDownFcn = @(src,~) showEventPoint(src, results, event);
    marker.PickableParts = 'visible';
    marker.HitTest = 'on';
catch
end
end

function showEventPoint(src, results, event)
try
    ax = ancestor(src, 'axes');
    fig = ancestor(src, 'figure');
    showSelectedTrajectoryPointStage14(fig, ax, src.XData(1), src.YData(1), results, event.index, event.label);
catch
end
try
    showEventExplanationStage14(src, event);
catch
end
end

function [x, y] = eventCoordinates(results, plotType, idx)
switch lower(char(plotType))
    case 'trajectory'
        x = valueAt(results, 'x', idx) / 1000;
        y = valueAt(results, 'h', idx) / 1000;
    case 'velocity'
        x = valueAt(results, 't', idx);
        y = valueAt(results, 'V', idx);
    case 'mach'
        x = valueAt(results, 't', idx);
        y = valueAt(results, 'Mach', idx);
    case 'dynamic pressure'
        x = valueAt(results, 't', idx);
        y = valueAt(results, 'q', idx) / 1000;
    case 'drag'
        x = valueAt(results, 't', idx);
        y = valueAt(results, 'drag', idx);
    case 'stagnation temperature'
        x = valueAt(results, 't', idx);
        y = valueAtAny(results, {'stagTemp','Tstag'}, idx);
    case 'angle of attack'
        x = valueAt(results, 't', idx);
        y = valueAt(results, 'alpha_deg', idx);
    case 'lift-to-drag'
        x = valueAt(results, 't', idx);
        y = valueAt(results, 'LD', idx);
    otherwise
        x = NaN;
        y = NaN;
end
end

function value = valueAt(results, fieldName, idx)
value = NaN;
if isstruct(results) && isfield(results, fieldName) && isnumeric(results.(fieldName)) && ...
        idx >= 1 && idx <= numel(results.(fieldName))
    data = results.(fieldName);
    value = data(idx);
end
end

function value = valueAtAny(results, names, idx)
value = NaN;
for k = 1:numel(names)
    value = valueAt(results, names{k}, idx);
    if isfinite(value)
        return;
    end
end
end
