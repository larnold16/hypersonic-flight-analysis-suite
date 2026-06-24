function [app, bestIndex] = highlightBestScenarioCaseStage14(app, missionGoal)
% highlightBestScenarioCaseStage14
% Flags and visually highlights the best Scenario Compare row.

bestIndex = 0;
if ~isfield(app, 'CompareTable') || ~isvalid(app.CompareTable) || isempty(app.CompareTable.Data)
    return;
end
T = app.CompareTable.Data;
if ~istable(T) || height(T) == 0
    return;
end

goal = lower(string(missionGoal));
if contains(goal, "range") && any(strcmp(T.Properties.VariableNames, 'Range_km'))
    [~, bestIndex] = max(T.Range_km);
elseif contains(goal, "altitude") && any(strcmp(T.Properties.VariableNames, 'MaxAltitude_km'))
    [~, bestIndex] = max(T.MaxAltitude_km);
elseif contains(goal, "heating") && any(strcmp(T.Properties.VariableNames, 'MaxStagTemp_K'))
    [~, bestIndex] = min(T.MaxStagTemp_K);
elseif contains(goal, "structural") && any(strcmp(T.Properties.VariableNames, 'MaxDynamicPressure_kPa'))
    [~, bestIndex] = min(T.MaxDynamicPressure_kPa);
elseif any(strcmp(T.Properties.VariableNames, 'OverallDesignScore'))
    [~, bestIndex] = max(T.OverallDesignScore);
else
    bestIndex = 1;
end

if any(strcmp(T.Properties.VariableNames, 'BestCase'))
    T.BestCase(:) = false;
    if bestIndex >= 1 && bestIndex <= height(T)
        T.BestCase(bestIndex) = true;
    end
end
app.CompareTable.Data = T;
if isfield(app.State, 'Results') && isfield(app.State.Results, 'scenarioCompare')
    app.State.Results.scenarioCompare.summaryTable = T;
    app.State.Results.scenarioCompare.bestCaseIndex = bestIndex;
    if bestIndex >= 1 && bestIndex <= height(T)
        app.State.Results.scenarioCompare.bestCaseName = T.CaseName(bestIndex);
    end
end

try
    removeStyle(app.CompareTable);
catch
end
try
    theme = stage14Theme();
    style = uistyle('BackgroundColor', theme.accentSoft, 'FontWeight', 'bold');
    addStyle(app.CompareTable, style, 'row', bestIndex);
catch
end
if isfield(app, 'CompareBestLabel') && isvalid(app.CompareBestLabel) && bestIndex >= 1
    app.CompareBestLabel.Text = sprintf('Best case for %s: %s', char(string(missionGoal)), char(T.CaseName(bestIndex)));
end
end
