function onScatterPointClicked(scatterHandle, event, appFigure)
% onScatterPointClicked
% Handles click selection for Stage 14 scatter points.

if nargin < 3 || isempty(appFigure) || ~isvalid(appFigure)
    return;
end

try
    data = scatterHandle.UserData;
    if ~isstruct(data) || ~(isfield(data, 'caseTable') || isfield(data, 'CaseTable'))
        updateSelectedCasePanel(appFigure, table(), "Case table missing from scatter UserData");
        return;
    end

    if isstruct(event) && isfield(event, 'IntersectionPoint') && ~isempty(event.IntersectionPoint)
        point = event.IntersectionPoint(1, 1:2);
    elseif isobject(event) && isprop(event, 'IntersectionPoint') && ~isempty(event.IntersectionPoint)
        point = event.IntersectionPoint(1, 1:2);
    else
        ax = ancestor(scatterHandle, 'axes');
        cp = ax.CurrentPoint;
        point = cp(1, 1:2);
    end

    [caseRow, idx, distance] = findNearestScatterCase(scatterHandle, point);
    if isempty(idx) || distance > 0.08 || isempty(caseRow)
        updateSelectedCasePanel(appFigure, table(), "No case selected.");
        return;
    end

    app = appFigure.UserData;
    app = clearSelectedCaseCard(app);
    ax = ancestor(scatterHandle, 'axes');
    if isfield(app, 'SelectedPointMarker') && ~isempty(app.SelectedPointMarker) && ...
            isvalid(app.SelectedPointMarker)
        delete(app.SelectedPointMarker);
    end
    app.SelectedPointMarker = line(ax, scatterHandle.XData(idx), scatterHandle.YData(idx), ...
        'Marker', 'o', 'MarkerSize', 12, 'LineWidth', 2, ...
        'Color', [0 0 0], 'LineStyle', 'none', 'HitTest', 'off');

    sourceInfo = struct();
    if isstruct(data) && isfield(data, 'studyType')
        sourceInfo.sourceTableName = string(data.studyType);
    else
        sourceInfo.sourceTableName = "ScatterPoint";
    end
    caseId = getCaseId(caseRow);
    sourceInfo.statusMessage = "Selected CaseID: " + caseId;
    app = updateSelectedCaseEverywhereStage14(app, caseRow, sourceInfo);
    [app, dataTipOk] = showSelectedCaseDataTip(app, scatterHandle, idx, caseRow);
    if ~dataTipOk
        app = showSelectedCaseCardNearPoint(app, ax, scatterHandle.XData(idx), scatterHandle.YData(idx), caseRow);
    end
    appFigure.UserData = app;
    drawnow;
catch ME
    updateSelectedCasePanel(appFigure, table(), "Case selected, but details failed to update: " + string(ME.message));
    warning('Stage14:ScatterSelectionFailed', '%s', ME.message);
end
end

function caseId = getCaseId(caseRow)
caseId = "UNKNOWN";
try
    if istable(caseRow) && height(caseRow) > 0 && any(strcmpi(caseRow.Properties.VariableNames, 'CaseID'))
        idx = find(strcmpi(caseRow.Properties.VariableNames, 'CaseID'), 1);
        value = normalizeCaseIDStage14(caseRow.(caseRow.Properties.VariableNames{idx}));
        if ~isempty(value)
            caseId = value(1);
        end
    end
catch
    caseId = "UNKNOWN";
end
end
