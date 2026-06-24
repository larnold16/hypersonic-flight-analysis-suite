function app = updateSelectedCaseEverywhereStage14(app, selectedCase, sourceInfo)
% updateSelectedCaseEverywhereStage14
% Central selected-case updater for Stage 14 app state and UI.

if nargin < 3 || ~isstruct(sourceInfo)
    sourceInfo = struct();
end
sourceName = getInfo(sourceInfo, 'sourceTableName', "SelectedCase");
statusMessage = getInfo(sourceInfo, 'statusMessage', "");

if isempty(selectedCase) || ~istable(selectedCase) || height(selectedCase) == 0
    app = clearSelectedCaseState(app, statusMessage);
    drawnow;
    return;
end

try
    selectedCase = standardizeCaseTableStage14(selectedCase(1,:), sourceName);
catch
    selectedCase = selectedCase(1,:);
end

caseID = getCaseID(selectedCase);
detailTable = selectedCaseDetailTableStage14(selectedCase);

app.SelectedCase = selectedCase;
app.SelectedCaseID = caseID;
app.State.selectedCase = selectedCase;
app.State.selectedCaseID = caseID;
app.State.selectedCaseSource = sourceName;
app.State.Tables.SelectedCase = selectedCase;
app.State.Tables.SelectedCaseDetails = detailTable;

if isfield(app, 'SelectedCaseLabel') && isvalid(app.SelectedCaseLabel)
    app.SelectedCaseLabel.Text = char("Selected CaseID: " + caseID);
end
if isfield(app, 'SelectedCaseTable') && isvalid(app.SelectedCaseTable)
    app.SelectedCaseTable.Data = detailTable;
end
if isfield(app, 'ResultsTable') && isvalid(app.ResultsTable)
    app.ResultsTable.Data = detailTable;
end
if isfield(app, 'CurrentTableDropDown') && isvalid(app.CurrentTableDropDown)
    names = fieldnames(app.State.Tables);
    app.CurrentTableDropDown.Items = names;
    if any(strcmp(names, 'SelectedCaseDetails'))
        app.CurrentTableDropDown.Value = 'SelectedCaseDetails';
    end
end
if isfield(app, 'StatusLabel') && isvalid(app.StatusLabel)
    if strlength(statusMessage) == 0
        statusMessage = "Selected CaseID: " + caseID;
    end
    app.StatusLabel.Text = char(statusMessage);
    app.StatusLabel.FontColor = [0.0 0.45 0.2];
end
if isfield(app, 'ExportSelectedCaseButton') && isvalid(app.ExportSelectedCaseButton)
    app.ExportSelectedCaseButton.Enable = 'on';
end
if isfield(app, 'OpenSelectedCaseButton') && isvalid(app.OpenSelectedCaseButton)
    app.OpenSelectedCaseButton.Enable = 'on';
end
if isfield(app, 'CaseIdField') && isvalid(app.CaseIdField)
    try
        app.CaseIdField.Value = char(caseID);
    catch
    end
end

app = updateHomeSelectedMetrics(app, selectedCase);
drawnow;
end

function app = clearSelectedCaseState(app, message)
if nargin < 2 || strlength(string(message)) == 0
    message = "No case selected.";
end
app.SelectedCase = table();
app.SelectedCaseID = "";
app.State.selectedCase = table();
app.State.selectedCaseID = "";
app.State.selectedCaseSource = "";
detailTable = selectedCaseDetailTableStage14(table());
app.State.Tables.SelectedCaseDetails = detailTable;
if isfield(app, 'SelectedCaseLabel') && isvalid(app.SelectedCaseLabel)
    app.SelectedCaseLabel.Text = char(message);
end
if isfield(app, 'SelectedCaseTable') && isvalid(app.SelectedCaseTable)
    app.SelectedCaseTable.Data = detailTable;
end
if isfield(app, 'StatusLabel') && isvalid(app.StatusLabel)
    app.StatusLabel.Text = char(message);
    app.StatusLabel.FontColor = [0.65 0.1 0.1];
end
if isfield(app, 'ExportSelectedCaseButton') && isvalid(app.ExportSelectedCaseButton)
    app.ExportSelectedCaseButton.Enable = 'off';
end
if isfield(app, 'OpenSelectedCaseButton') && isvalid(app.OpenSelectedCaseButton)
    app.OpenSelectedCaseButton.Enable = 'off';
end
end

function app = updateHomeSelectedMetrics(app, selectedCase)
setMetric(app, 'Range', getFormatted(selectedCase, 'Range_km', '%.2f km'));
setMetric(app, 'Max altitude', getFormatted(selectedCase, 'MaxAltitude_km', '%.2f km'));
setMetric(app, 'Impact speed', getFormatted(selectedCase, 'ImpactSpeed_mps', '%.1f m/s'));
setMetric(app, 'Max Mach', getFormatted(selectedCase, 'MaxMach', '%.2f'));
setMetric(app, 'Max q', getFormatted(selectedCase, 'MaxQ_kPa', '%.1f kPa'));
setMetric(app, 'Max stagnation temp', getFormatted(selectedCase, 'MaxStagTemp_K', '%.0f K'));
setMetric(app, 'Time to max altitude', "N/A");
setMetric(app, 'Time to impact', getFormatted(selectedCase, 'TimeOfFlight_s', '%.2f s'));
setMetric(app, 'Feasibility', getText(selectedCase, 'Feasible'));
end

function setMetric(app, metricField, valueText)
metricField = matlab.lang.makeValidName(metricField);
if isfield(app, 'MetricLabels') && isfield(app.MetricLabels, metricField) && ...
        isvalid(app.MetricLabels.(metricField))
    app.MetricLabels.(metricField).Text = char(valueText);
end
end

function text = getFormatted(T, fieldName, formatSpec)
value = getNumeric(T, fieldName);
if isfinite(value)
    text = string(sprintf(formatSpec, value));
else
    text = "N/A";
end
end

function text = getText(T, fieldName)
if any(strcmpi(T.Properties.VariableNames, fieldName))
    idx = find(strcmpi(T.Properties.VariableNames, fieldName), 1);
    value = T.(T.Properties.VariableNames{idx});
    if islogical(value)
        text = string(value(1));
    else
        text = string(value(1));
    end
else
    text = "N/A";
end
end

function value = getNumeric(T, fieldName)
value = NaN;
if any(strcmpi(T.Properties.VariableNames, fieldName))
    idx = find(strcmpi(T.Properties.VariableNames, fieldName), 1);
    raw = T.(T.Properties.VariableNames{idx});
    if isnumeric(raw) || islogical(raw)
        value = double(raw(1));
    else
        value = str2double(string(raw(1)));
    end
end
end

function caseID = getCaseID(T)
if any(strcmpi(T.Properties.VariableNames, 'CaseID'))
    idx = find(strcmpi(T.Properties.VariableNames, 'CaseID'), 1);
    caseID = normalizeCaseIDStage14(T.(T.Properties.VariableNames{idx}));
    if isempty(caseID)
        caseID = "UNKNOWN";
    else
        caseID = caseID(1);
    end
else
    caseID = "UNKNOWN";
end
end

function value = getInfo(info, fieldName, defaultValue)
if isstruct(info) && isfield(info, fieldName) && ~isempty(info.(fieldName))
    value = string(info.(fieldName));
else
    value = string(defaultValue);
end
end
