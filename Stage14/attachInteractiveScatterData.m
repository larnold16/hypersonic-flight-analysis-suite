function scatterHandle = attachInteractiveScatterData(scatterHandle, caseTable, appFigure, xField, yField, studyType)
% attachInteractiveScatterData
% Stores case rows on a scatter object and connects point-click behavior.

if isempty(scatterHandle) || ~isvalid(scatterHandle)
    return;
end
if nargin < 6 || isempty(studyType)
    studyType = "Stage14";
end
try
    caseTable = standardizeCaseTableStage14(caseTable, studyType);
catch
    if ~istable(caseTable)
        caseTable = table();
    end
end

data = struct();
data.caseTable = caseTable;
data.CaseTable = caseTable;
data.xField = char(xField);
data.yField = char(yField);
data.XField = char(xField);
data.YField = char(yField);
data.caseIDField = 'CaseID';
data.studyType = string(studyType);
data.xData = scatterHandle.XData(:);
data.yData = scatterHandle.YData(:);
data.CaseID = string(safeGetTableValueStage14(caseTable, {'CaseID','caseId'}, strings(height(caseTable), 1)));

scatterHandle.UserData = data;
scatterHandle.PickableParts = 'visible';
scatterHandle.HitTest = 'on';
scatterHandle.ButtonDownFcn = @(src, event) onScatterPointClicked(src, event, appFigure);

try
    dt = scatterHandle.DataTipTemplate;
    dt.DataTipRows = dataTipRowsForTable(caseTable, data.CaseID);
catch
    % Older MATLAB graphics or some plot types may not support templates.
end
end

function rows = dataTipRowsForTable(T, caseIds)
rows = dataTipTextRow('CaseID', string(caseIds));
rows = addTipRow(rows, T, 'StudyType', 'StudyType');
rows = addTipRow(rows, T, 'Feasible', 'Feasible');
rows = addTipRow(rows, T, 'Range_km', 'Range km');
rows = addTipRow(rows, T, 'MaxAltitude_km', 'Max altitude km');
rows = addTipRow(rows, T, 'MaxQ_kPa', 'Max q kPa');
rows = addTipRow(rows, T, 'MaxHeating_kW_m2', 'Heating kW/m^2');
rows = addTipRow(rows, T, 'MaxGLoad', 'Max g-load');
rows = addTipRow(rows, T, 'Score', 'Score');
rows = addTipRow(rows, T, 'LaunchAngle_deg', 'Launch angle deg');
rows = addTipRow(rows, T, 'BodyType', 'Body type');
end

function rows = addTipRow(rows, T, fieldName, label)
idx = find(strcmpi(T.Properties.VariableNames, fieldName), 1);
if isempty(idx)
    return;
end
values = T.(T.Properties.VariableNames{idx});
if islogical(values)
    values = string(values);
elseif iscell(values)
    values = string(values);
elseif iscategorical(values)
    values = string(values);
end
rows(end+1) = dataTipTextRow(label, values);
end
