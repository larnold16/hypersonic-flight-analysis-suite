function updateSelectedCasePanel(appFigure, caseRow, message)
% updateSelectedCasePanel
% Backward-compatible wrapper for the central Stage 14 selected-case updater.

if nargin < 3
    message = "Selected case updated.";
end
if isempty(appFigure) || ~isvalid(appFigure)
    return;
end

try
    app = appFigure.UserData;
    sourceInfo = struct();
    sourceInfo.sourceTableName = "SelectedCase";
    sourceInfo.statusMessage = string(message);
    app = updateSelectedCaseEverywhereStage14(app, caseRow, sourceInfo);
    appFigure.UserData = app;
catch ME
    try
        app = appFigure.UserData;
        if isfield(app, 'SelectedCaseLabel') && isvalid(app.SelectedCaseLabel)
            app.SelectedCaseLabel.Text = ['Case selected, but details failed to update: ', ME.message];
        end
        if isfield(app, 'StatusLabel') && isvalid(app.StatusLabel)
            app.StatusLabel.Text = ['Case selected, but details failed to update: ', ME.message];
            app.StatusLabel.FontColor = [0.65 0.1 0.1];
        end
        appFigure.UserData = app;
        drawnow;
    catch
    end
end
end
