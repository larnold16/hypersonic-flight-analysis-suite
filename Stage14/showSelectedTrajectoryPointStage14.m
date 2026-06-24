function app = showSelectedTrajectoryPointStage14(fig, ax, xPlot, yPlot, results, idx, eventName)
% showSelectedTrajectoryPointStage14
% Updates the selected point side panel and highlights the clicked point.

app = fig.UserData;
if isempty(app)
    return;
end
if nargin < 7
    eventName = "trajectory point";
end

T = selectedPointTableStage14(results, idx, eventName);
app.State.selectedPoint = T;
if isfield(app, 'SelectedPointLabel') && isvalid(app.SelectedPointLabel)
    app.SelectedPointLabel.Text = char("Selected Point: " + string(eventName));
end
if isfield(app, 'SelectedPointTable') && isvalid(app.SelectedPointTable)
    app.SelectedPointTable.Data = T;
end

try
    if isfield(app, 'SelectedPointMarker') && ~isempty(app.SelectedPointMarker)
        delete(app.SelectedPointMarker(isvalid(app.SelectedPointMarker)));
    end
catch
end
theme = stage14Theme();
hold(ax, 'on');
app.SelectedPointMarker = plot(ax, xPlot, yPlot, 'o', 'MarkerSize', 11, ...
    'LineWidth', 2.2, 'Color', theme.danger, 'MarkerFaceColor', [1.0 0.93 0.25], ...
    'DisplayName', 'Selected point', 'Tag', 'Stage14SelectedPointMarker');

fig.UserData = app;
drawnow;
end
