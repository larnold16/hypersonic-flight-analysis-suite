function app = plotScenarioCompareStage14(app, compare)
% plotScenarioCompareStage14
% Draws Scenario Compare overlays without changing the backend results.

if ~isfield(app, 'CompareAxes') || isempty(app.CompareAxes)
    return;
end
axesList = app.CompareAxes;
clearAxes(axesList);
if ~isstruct(compare) || ~isfield(compare, 'caseResults')
    return;
end

theme = stage14Theme();
labels = strings(numel(compare.caseResults), 1);
for k = 1:numel(compare.caseResults)
    r = compare.caseResults{k};
    if isempty(r) || ~isstruct(r)
        continue;
    end
    labels(k) = string(getField(r, 'caseName', "Case " + k));
    color = theme.plotColors(1 + mod(k - 1, size(theme.plotColors, 1)), :);
    plotOne(axesList(1), r, 'x', 1000, 'h', 1000, labels(k), color);
    plotOne(axesList(2), r, 't', 1, 'Mach', 1, labels(k), color);
    plotOne(axesList(3), r, 't', 1, 'q', 1000, labels(k), color);
    plotOne(axesList(4), r, 't', 1, {'stagTemp','Tstag'}, 1, labels(k), color);
    plotOne(axesList(5), r, 't', 1, 'V', 1, labels(k), color);
end

setLabels(axesList(1), 'Trajectory overlay', 'Range (km)', 'Altitude (km)');
setLabels(axesList(2), 'Mach vs time', 'Time (s)', 'Mach');
setLabels(axesList(3), 'Dynamic pressure vs time', 'Time (s)', 'q (kPa)');
setLabels(axesList(4), 'Stagnation temperature vs time', 'Time (s)', 'Tstag (K)');
setLabels(axesList(5), 'Velocity vs time', 'Time (s)', 'Velocity (m/s)');

for k = 1:numel(axesList)
    if isvalid(axesList(k))
        legend(axesList(k), 'Location', 'best');
    end
end
styleStage14Axes(axesList);
end

function plotOne(ax, r, xField, xScale, yField, yScale, label, color)
if ~isvalid(ax)
    return;
end
x = fieldValues(r, xField) ./ xScale;
y = fieldValues(r, yField) ./ yScale;
if isempty(x) || isempty(y)
    return;
end
n = min(numel(x), numel(y));
hold(ax, 'on');
h = plot(ax, x(1:n), y(1:n), 'LineWidth', 1.6, 'Color', color, 'DisplayName', char(label));
attachTrajectoryDataTipStage14(h, r);
try
    attachTrajectoryPointSelectionStage14(h, ancestor(ax, 'figure'), r, label);
catch
end
end

function setLabels(ax, titleText, xText, yText)
if ~isvalid(ax)
    return;
end
title(ax, titleText);
xlabel(ax, xText);
ylabel(ax, yText);
grid(ax, 'on');
end

function values = fieldValues(s, fieldName)
values = [];
if iscell(fieldName)
    for k = 1:numel(fieldName)
        values = fieldValues(s, fieldName{k});
        if ~isempty(values)
            return;
        end
    end
elseif isstruct(s) && isfield(s, fieldName) && isnumeric(s.(fieldName))
    values = s.(fieldName)(:);
end
end

function clearAxes(axesList)
for k = 1:numel(axesList)
    if isvalid(axesList(k))
        cla(axesList(k));
    end
end
end

function value = getField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end
