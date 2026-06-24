function app = displayStage14Warnings(app, warningText, successFlag)
% displayStage14Warnings
% Updates app warning/status labels without throwing errors.

if nargin < 3
    successFlag = true;
end
if isempty(warningText)
    warningText = "No warnings.";
end
theme = stage14Theme();
if iscell(warningText)
    warningText = string(strjoin(warningText, newline));
end

app.State.lastWarningText = string(warningText);
app.State.lastSuccess = logical(successFlag);

if isfield(app, 'StatusLabel') && isvalid(app.StatusLabel)
    if successFlag
        app.StatusLabel.Text = "Status: success";
        app.StatusLabel.FontColor = [1 1 1];
    else
        app.StatusLabel.Text = "Status: warning/failure";
        app.StatusLabel.FontColor = [1 1 1];
    end
end
if successFlag
    setObjectProperty(app, 'StatusBarPanel', 'BackgroundColor', theme.accent);
    setObjectProperty(app, 'StatusBarGrid', 'BackgroundColor', theme.accent);
else
    setObjectProperty(app, 'StatusBarPanel', 'BackgroundColor', theme.danger);
    setObjectProperty(app, 'StatusBarGrid', 'BackgroundColor', theme.danger);
end
if isfield(app, 'HomeStatusLabel') && isvalid(app.HomeStatusLabel)
    if successFlag
        app.HomeStatusLabel.Text = "Status: success";
        app.HomeStatusLabel.FontColor = [0.0 0.45 0.2];
    else
        app.HomeStatusLabel.Text = "Status: warning/failure";
        app.HomeStatusLabel.FontColor = [0.75 0.15 0.1];
    end
end
if isfield(app, 'WarningTextArea') && isvalid(app.WarningTextArea)
    app.WarningTextArea.Value = cellstr(splitlines(string(warningText)));
end
end

function setObjectProperty(app, fieldName, propName, propValue)
if isfield(app, fieldName) && isvalid(app.(fieldName)) && isprop(app.(fieldName), propName)
    try
        app.(fieldName).(propName) = propValue;
    catch
    end
end
end
