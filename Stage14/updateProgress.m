function app = updateProgress(app, percent, message)
% updateProgress
% Updates the Stage 14 progress indicator and status text.

theme = stage14Theme();
if nargin < 2 || isempty(percent)
    percent = 0;
end
if nargin < 3
    message = "";
end
if percent <= 1
    gaugeValue = 100 * max(0, min(1, percent));
else
    gaugeValue = max(0, min(100, percent));
end

if isfield(app, 'ProgressGauge') && isvalid(app.ProgressGauge)
    app.ProgressGauge.Value = gaugeValue;
end
if isfield(app, 'ProgressLabel') && isvalid(app.ProgressLabel)
    app.ProgressLabel.Text = char(string(message));
end
if isfield(app, 'StatusLabel') && isvalid(app.StatusLabel) && strlength(string(message)) > 0
    app.StatusLabel.Text = char("Status: " + string(message));
    app.StatusLabel.FontColor = [1 1 1];
end
if isfield(app, 'HomeStatusLabel') && isvalid(app.HomeStatusLabel) && strlength(string(message)) > 0
    app.HomeStatusLabel.Text = char("Status: " + string(message));
    app.HomeStatusLabel.FontColor = theme.text;
end
setObjectProperty(app, 'StatusBarPanel', 'BackgroundColor', theme.primary);
setObjectProperty(app, 'StatusBarGrid', 'BackgroundColor', theme.primary);
drawnow;
end

function setObjectProperty(app, fieldName, propName, propValue)
if isfield(app, fieldName) && isvalid(app.(fieldName)) && isprop(app.(fieldName), propName)
    try
        app.(fieldName).(propName) = propValue;
    catch
    end
end
end
