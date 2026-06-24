function app = updateStage14Tables(app, tableName, inputData)
% updateStage14Tables
% Stores a table in app state and displays it in Results Tables.

if ~istable(inputData)
    inputData = struct2table(inputData);
end

safeName = matlab.lang.makeValidName(tableName);
studyType = inferCaseStudyType(safeName);
if strlength(studyType) > 0
    inputData = standardizeCaseTableStage14(inputData, studyType);
end
app.State.Tables.(safeName) = inputData;
app.State.currentTableName = safeName;

if isfield(app, 'ResultsTable') && isvalid(app.ResultsTable)
    app.ResultsTable.Data = inputData;
end
if isfield(app, 'CurrentTableDropDown') && isvalid(app.CurrentTableDropDown)
    names = fieldnames(app.State.Tables);
    app.CurrentTableDropDown.Items = names;
    app.CurrentTableDropDown.Value = safeName;
end
if isfield(app, 'StatusTable') && isvalid(app.StatusTable)
    app.StatusTable.Data = appStatusTable(app.State);
end
end

function T = appStatusTable(state)
T = table(string(state.lastRunType), logical(state.lastSuccess), string(state.lastWarningText), ...
    'VariableNames', {'LastRunType','Success','Warnings'});
end

function studyType = inferCaseStudyType(tableName)
name = lower(char(string(tableName)));
studyType = "";
if contains(name, 'montecarlocases')
    studyType = "MonteCarlo";
elseif strcmp(name, 'montecarlo')
    studyType = "MonteCarlo";
elseif contains(name, 'paretodesigns') || strcmp(name, 'pareto')
    studyType = "Pareto";
elseif contains(name, 'optimizationresults')
    studyType = "Optimization";
elseif strcmp(name, 'doe')
    studyType = "DOE";
elseif contains(name, 'anglesweep')
    studyType = "AngleSweep";
elseif contains(name, 'selectedcase') && ~contains(name, 'details')
    studyType = "SelectedCase";
end
end
