function info = exportStage14Report(app)
% exportStage14Report
% Writes a portfolio-ready HTML report plus supporting CSV/PNG assets.

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
reportDir = fullfile(app.State.reportDir, ['Stage14Report_', timestamp]);
if ~exist(reportDir, 'dir')
    mkdir(reportDir);
end

info = struct();
info.reportDir = reportDir;
info.htmlFile = fullfile(reportDir, 'Stage14EngineeringReport.html');
info.files = strings(0, 1);

single = struct();
if isfield(app.State, 'Results') && isfield(app.State.Results, 'single')
    single = app.State.Results.single;
    rawCsv = fullfile(reportDir, 'SingleTrajectoryRawData.csv');
    exportRawTrajectory(single, rawCsv);
    info.files(end+1, 1) = string(rawCsv);
end

plotFiles = exportReportPlots(app, reportDir);
info.files = [info.files; plotFiles(:)];

compareTable = table();
if isfield(app.State, 'Results') && isfield(app.State.Results, 'scenarioCompare')
    compareTable = app.State.Results.scenarioCompare.summaryTable;
    file = fullfile(reportDir, 'ScenarioComparisonTable.csv');
    writetable(compareTable, file);
    info.files(end+1, 1) = string(file);
end

sensitivityTable = table();
if isfield(app.State, 'Results') && isfield(app.State.Results, 'sensitivity')
    sensitivityTable = app.State.Results.sensitivity.rankedTable;
    file = fullfile(reportDir, 'SensitivityRankingTable.csv');
    writetable(sensitivityTable, file);
    info.files(end+1, 1) = string(file);
end

verificationTable = exportOptionalResultTable(app, reportDir, {'verification'}, 'summaryTable', 'VerificationResults.csv');
constraintTable = exportOptionalResultTable(app, reportDir, {'constraintEnvelope'}, 'table', 'ConstraintViolations.csv');
optimizationTable = exportOptionalResultTable(app, reportDir, {'optimizationMode'}, 'rankedTable', 'OptimizationRankedCases.csv');
uncertaintyTable = exportOptionalResultTable(app, reportDir, {'uncertainty'}, 'summaryTable', 'UncertaintySummary.csv');
uncertaintyCases = exportOptionalResultTable(app, reportDir, {'uncertainty'}, 'caseTable', 'UncertaintyCases.csv');
if ~isempty(verificationTable)
    info.files(end+1, 1) = string(fullfile(reportDir, 'VerificationResults.csv'));
end
if ~isempty(constraintTable)
    info.files(end+1, 1) = string(fullfile(reportDir, 'ConstraintViolations.csv'));
end
if ~isempty(optimizationTable)
    info.files(end+1, 1) = string(fullfile(reportDir, 'OptimizationRankedCases.csv'));
end
if ~isempty(uncertaintyTable)
    info.files(end+1, 1) = string(fullfile(reportDir, 'UncertaintySummary.csv'));
end
if ~isempty(uncertaintyCases)
    info.files(end+1, 1) = string(fullfile(reportDir, 'UncertaintyCases.csv'));
end

assumptions = getAssumptions(app);
tutorial = getTutorial(app);

html = buildReportHtml(app, single, compareTable, sensitivityTable, plotFiles, ...
    verificationTable, constraintTable, optimizationTable, uncertaintyTable, assumptions, tutorial);
fid = fopen(info.htmlFile, 'w');
if fid < 0
    error('Stage14:ReportWriteFailed', 'Could not write Stage 14 HTML report.');
end
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, '%s', html);
info.files(end+1, 1) = string(info.htmlFile);
end

function T = exportOptionalResultTable(app, reportDir, resultPath, tableField, fileName)
T = table();
cursor = app.State.Results;
for k = 1:numel(resultPath)
    key = resultPath{k};
    if isstruct(cursor) && isfield(cursor, key)
        cursor = cursor.(key);
    else
        return;
    end
end
if isstruct(cursor) && isfield(cursor, tableField) && istable(cursor.(tableField))
    T = cursor.(tableField);
    if ~isempty(T)
        writetable(T, fullfile(reportDir, fileName));
    end
end
end

function files = exportReportPlots(app, reportDir)
files = strings(0, 1);
plotSpecs = {};
if isfield(app, 'SingleAxes') && ~isempty(app.SingleAxes) && isvalid(app.SingleAxes(1))
    plotSpecs(end+1, :) = {app.SingleAxes(1), 'SingleTrajectoryMainPlot.png'}; %#ok<AGROW>
end
if isfield(app, 'CompareAxes') && ~isempty(app.CompareAxes)
    for k = 1:numel(app.CompareAxes)
        if isvalid(app.CompareAxes(k))
            plotSpecs(end+1, :) = {app.CompareAxes(k), sprintf('ScenarioComparePlot_%d.png', k)}; %#ok<AGROW>
        end
    end
end
if isfield(app, 'SensitivityAxes') && ~isempty(app.SensitivityAxes) && isvalid(app.SensitivityAxes)
    plotSpecs(end+1, :) = {app.SensitivityAxes, 'SensitivityTornadoChart.png'}; %#ok<AGROW>
end
plotSpecs = addAxes(plotSpecs, app, 'VerificationAxes', 'VerificationPlot');
plotSpecs = addAxes(plotSpecs, app, 'ConstraintAxes', 'ConstraintEnvelopePlot');
plotSpecs = addAxes(plotSpecs, app, 'OptimizationAxes', 'OptimizationModePlot');
plotSpecs = addAxes(plotSpecs, app, 'UncertaintyAxes', 'UncertaintyBandPlot');

for k = 1:size(plotSpecs, 1)
    file = fullfile(reportDir, plotSpecs{k, 2});
    try
        exportgraphics(plotSpecs{k, 1}, file, 'Resolution', 160);
        files(end+1, 1) = string(file); %#ok<AGROW>
    catch
    end
end
end

function plotSpecs = addAxes(plotSpecs, app, fieldName, baseName)
if isfield(app, fieldName) && ~isempty(app.(fieldName))
    axesList = app.(fieldName);
    for k = 1:numel(axesList)
        if isvalid(axesList(k))
            plotSpecs(end+1, :) = {axesList(k), sprintf('%s_%d.png', baseName, k)}; %#ok<AGROW>
        end
    end
end
end

function html = buildReportHtml(app, single, compareTable, sensitivityTable, plotFiles, ...
    verificationTable, constraintTable, optimizationTable, uncertaintyTable, assumptions, tutorial)
titleText = 'Hypersonic Trajectory Calculator - Stage 14 Engineering Report';
insights = {};
if isfield(app, 'EngineeringInsightsArea') && isvalid(app.EngineeringInsightsArea)
    insights = app.EngineeringInsightsArea.Value;
end
if isfield(app.State, 'Results') && isfield(app.State.Results, 'scenarioCompare')
    insights = [insights(:); app.State.Results.scenarioCompare.insights(:)];
end

eventTable = table();
if isstruct(single) && isfield(single, 'keyEventTable')
    eventTable = single.keyEventTable;
elseif isstruct(single) && isfield(single, 't')
    [~, eventTable] = computeKeyEventsStage14(single);
end

html = "";
html = html + "<!doctype html><html><head><meta charset='utf-8'><title>" + titleText + "</title>";
html = html + "<style>body{font-family:Segoe UI,Arial,sans-serif;margin:34px;color:#1a232d;background:#f4f7fa;}h1,h2{color:#0d4777;}section{background:white;border:1px solid #c4ccd6;border-radius:8px;padding:18px;margin:16px 0;}table{border-collapse:collapse;width:100%;font-size:12px;}th,td{border:1px solid #d7dde5;padding:6px;text-align:left;}th{background:#e9f0f6;}img{max-width:100%;border:1px solid #c4ccd6;border-radius:6px;margin:10px 0;} .note{color:#5d6875;font-style:italic;}</style></head><body>";
html = html + "<h1>" + titleText + "</h1>";
html = html + "<p class='note'>Generated " + string(datetime('now')) + ". This is a simplified educational engineering analysis report, not a validated flight design, targeting tool, or certification artifact.</p>";

fidelity = getField(app.State, 'fidelity', struct('stageName', 'Stage 14 app calling Stage 11/12/13 backends'));
html = html + "<section><h2>Model And Assumptions</h2><p>Stage/model used: " + escapeHtml(string(getField(fidelity, 'stageName', 'Stage 14 app calling Stage 11/12/13 backends'))) + ".</p>";
html = html + "<p>Aero, atmosphere, heating, stability, and scoring assumptions are simplified trend-analysis models. Interpret the results as relative engineering insight, not as validated vehicle performance.</p>";
if isstruct(assumptions) && isfield(assumptions, 'includedTable')
    html = html + "<h3>Included Physics</h3>" + tableToHtml(assumptions.includedTable);
    html = html + "<h3>Not Included / Simplifications</h3>" + tableToHtml(assumptions.notIncludedTable);
    html = html + "<p class='note'>" + escapeHtml(strjoin(string(assumptions.limitationsText), " ")) + "</p>";
end
html = html + "</section>";

html = html + "<section><h2>Vehicle Geometry And Inputs</h2>" + tableToHtml(vehicleReportTable(app.State.vehicle, app.State.launch)) + "</section>";

if isstruct(single) && isfield(single, 'range')
    html = html + "<section><h2>Summary Results</h2>" + tableToHtml(summaryReportTable(single)) + "</section>";
end
if ~isempty(eventTable)
    html = html + "<section><h2>Key Flight Events</h2>" + tableToHtml(eventTable) + "</section>";
end
if ~isempty(compareTable)
    html = html + "<section><h2>Scenario Comparison</h2>" + tableToHtml(compareTable) + "</section>";
end
if ~isempty(sensitivityTable)
    html = html + "<section><h2>Sensitivity Analysis</h2>" + tableToHtml(sensitivityTable) + "</section>";
end
if ~isempty(verificationTable)
    html = html + "<section><h2>Verification And Validation</h2>" + tableToHtml(verificationTable) + "</section>";
end
if ~isempty(constraintTable)
    html = html + "<section><h2>Constraint Envelope</h2>" + tableToHtml(constraintTable) + "</section>";
end
if ~isempty(optimizationTable)
    html = html + "<section><h2>Optimization Mode</h2>" + tableToHtml(optimizationTable) + "</section>";
end
if ~isempty(uncertaintyTable)
    html = html + "<section><h2>Uncertainty Summary</h2>" + tableToHtml(uncertaintyTable) + "</section>";
end
if isstruct(tutorial) && isfield(tutorial, 'table')
    html = html + "<section><h2>What Am I Looking At?</h2>" + tableToHtml(tutorial.table) + "</section>";
end
if ~isempty(insights)
    html = html + "<section><h2>Engineering Insights</h2><ul>";
    for k = 1:numel(insights)
        html = html + "<li>" + escapeHtml(string(insights{k})) + "</li>";
    end
    html = html + "</ul></section>";
end
if ~isempty(plotFiles)
    html = html + "<section><h2>Main Plots</h2>";
    for k = 1:numel(plotFiles)
        [~, name, ext] = fileparts(plotFiles(k));
        html = html + "<h3>" + string(name) + "</h3><img src='" + string(name) + string(ext) + "'>";
    end
    html = html + "</section>";
end
html = html + "<section><h2>Notes / Disclaimer</h2><p>This report is intended for educational portfolio documentation and engineering trend analysis. It should not be used for real-world targeting, flight safety, certification, or operational decisions.</p></section>";
html = html + "</body></html>";
end

function exportRawTrajectory(r, file)
T = table();
fields = {'t','x','h','V','Mach','q','drag','lift','stagTemp','flightPathAngle_deg','alpha_deg','LD'};
for k = 1:numel(fields)
    if isfield(r, fields{k}) && isnumeric(r.(fields{k}))
        T.(fields{k}) = r.(fields{k})(:);
    end
end
if ~isempty(T)
    writetable(T, file);
end
end

function T = vehicleReportTable(vehicle, launch)
names = ["Body type"; "Length m"; "Diameter m"; "Fineness ratio"; "Reference area m^2"; ...
    "Mass kg"; "Static margin %"; "CG location m"; "CP location m"; "Launch angle deg"; "Initial speed m/s"];
staticMargin = (getField(vehicle, 'cpLocation_m', NaN) - getField(vehicle, 'cgLocation_m', NaN)) / max(getField(vehicle, 'length', NaN), eps);
values = [
    string(getField(vehicle, 'bodyType', 'Custom baseline'))
    string(getField(vehicle, 'length', NaN))
    string(getField(vehicle, 'diameter', NaN))
    string(getField(vehicle, 'finenessRatio', NaN))
    string(getField(vehicle, 'referenceArea', NaN))
    string(getField(vehicle, 'mass', NaN))
    string(100 * staticMargin)
    string(getField(vehicle, 'cgLocation_m', NaN))
    string(getField(vehicle, 'cpLocation_m', NaN))
    string(getField(launch, 'launchAngle_deg', NaN))
    string(getField(launch, 'initialSpeed_mps', NaN))];
T = table(names, values, 'VariableNames', {'Parameter','Value'});
end

function T = summaryReportTable(r)
score = computeDesignScoreStage14(r, "Balanced");
names = ["Range km"; "Max altitude km"; "Impact speed m/s"; "Time of flight s"; ...
    "Max Mach"; "Max dynamic pressure kPa"; "Max stagnation temperature K"; ...
    "Heating risk"; "Structural load risk"; "Overall design score"];
values = [
    string(getField(r, 'range', NaN) / 1000)
    string(getField(r, 'maxAltitude', NaN) / 1000)
    string(getField(r, 'impactSpeed', NaN))
    string(getField(r, 'timeOfFlight', NaN))
    string(getField(r, 'maxMach', NaN))
    string(getField(r, 'maxQ', NaN) / 1000)
    string(getField(r, 'maxStagTemp', NaN))
    string(score.HeatingRisk)
    string(score.StructuralLoadRisk)
    string(score.OverallDesignScore)];
T = table(names, values, 'VariableNames', {'Metric','Value'});
end

function assumptions = getAssumptions(app)
if isfield(app.State, 'assumptions')
    assumptions = app.State.assumptions;
else
    fidelity = getField(app.State, 'fidelity', struct('stageName', 'Stage 14: MATLAB App / interactive interface'));
    assumptions = buildAssumptionsListStage14(getField(fidelity, 'stageName', 'Stage 14: MATLAB App / interactive interface'), app.State);
end
end

function tutorial = getTutorial(app)
if isfield(app.State, 'Results') && isfield(app.State.Results, 'tutorial')
    tutorial = app.State.Results.tutorial;
else
    tutorial = generateTutorialContentStage14();
end
end

function html = tableToHtml(T)
if isempty(T)
    html = "<p>No data available.</p>";
    return;
end
html = "<table><thead><tr>";
for c = 1:width(T)
    html = html + "<th>" + escapeHtml(string(T.Properties.VariableNames{c})) + "</th>";
end
html = html + "</tr></thead><tbody>";
for r = 1:height(T)
    html = html + "<tr>";
    for c = 1:width(T)
        value = T{r,c};
        if iscell(value)
            value = value{1};
        end
        if isnumeric(value) || islogical(value)
            text = string(value);
        else
            text = string(value);
        end
        html = html + "<td>" + escapeHtml(text) + "</td>";
    end
    html = html + "</tr>";
end
html = html + "</tbody></table>";
end

function text = escapeHtml(text)
text = replace(string(text), "&", "&amp;");
text = replace(text, "<", "&lt;");
text = replace(text, ">", "&gt;");
text = replace(text, """", "&quot;");
end

function value = getField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end
