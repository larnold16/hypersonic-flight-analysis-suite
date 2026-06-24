function app = HypersonicTrajectoryApp(vehicle, constants, varargin)
% HypersonicTrajectoryApp
% Programmatic MATLAB GUI for Stage 14.
%
% This app is deliberately a front end. It calls Stage 11, Stage 12, and
% Stage 13 backend functions instead of duplicating trajectory physics.

if nargin < 1 || ~isstruct(vehicle)
    vehicle = struct();
end
if nargin < 2 || ~isstruct(constants)
    constants = struct();
end

visible = parseVisible(varargin);
state = buildStage14DefaultState(vehicle, constants);

app = struct();
app.State = state;
app.Figure = uifigure('Name', 'Hypersonic Trajectory Calculator - Stage 14', ...
    'Position', [80 80 1450 850], 'Visible', visible);
app.SelectedPointMarker = gobjects(0);
app.EventMarkers = gobjects(0);
app.SelectedCaseCard = gobjects(0);
app.SelectedCaseDataTip = gobjects(0);

mainGrid = uigridlayout(app.Figure, [2 1]);
mainGrid.RowHeight = {'1x', 40};
mainGrid.Padding = [8 8 8 8];
app.TabGroup = uitabgroup(mainGrid);
app.TabGroup.Layout.Row = 1;
app = createGlobalStatusBar(app, mainGrid);

app = createHomeTab(app);
app = createGuidedBuilderTab(app);
app = createVehicleTab(app);
app = createLaunchTab(app);
app = createPhysicsTab(app);
app = createSingleTab(app);
app = createScenarioCompareTab(app);
app = createSensitivityTab(app);
app = createRiskDashboardTab(app);
app = createVerificationValidationTab(app);
app = createAssumptionsTab(app);
app = createConstraintEnvelopeTab(app);
app = createOptimizationModeTab(app);
app = createUncertaintyTab(app);
app = createTutorialTab(app);
app = createAngleSweepTab(app);
app = createValidationTab(app);
app = createMonteCarloTab(app);
app = createParetoTab(app);
app = createResultsTab(app);
app = createReportsTab(app);
app = applyStage14Theme(app);
app = applyStage14Tooltips(app);

app.Figure.UserData = app;
refreshControlsFromState(app.Figure);
updateSelectedCasePanel(app.Figure, table(), "No case selected.");
end

function visible = parseVisible(args)
visible = 'on';
for k = 1:2:numel(args)
    if strcmpi(args{k}, 'Visible')
        visible = args{k+1};
    end
end
end

function app = createGlobalStatusBar(app, parentGrid)
app.StatusBarPanel = uipanel(parentGrid, 'BorderType', 'none');
app.StatusBarPanel.Layout.Row = 2;
barGrid = uigridlayout(app.StatusBarPanel, [1 3]);
app.StatusBarGrid = barGrid;
barGrid.ColumnWidth = {260, '1x', 340};
barGrid.Padding = [0 2 0 0];
barGrid.ColumnSpacing = 10;

app.StatusLabel = uilabel(barGrid, 'Text', 'Status: ready', 'FontWeight', 'bold');
app.ProgressGauge = uigauge(barGrid, 'linear', 'Limits', [0 100], 'Value', 0);
app.ProgressLabel = uilabel(barGrid, 'Text', 'Ready', 'HorizontalAlignment', 'right');
end

function app = createHomeTab(app)
tab = uitab(app.TabGroup, 'Title', 'Home / Dashboard');
grid = uigridlayout(tab, [3 3]);
grid.RowHeight = {90, '1x', 190};
grid.ColumnWidth = {'1.2x', '1x', '1x'};
grid.Padding = [12 12 12 12];
grid.RowSpacing = 10;
grid.ColumnSpacing = 10;

titlePanel = uipanel(grid, 'Title', 'Hypersonic Trajectory Calculator');
titlePanel.Layout.Row = 1; titlePanel.Layout.Column = [1 3];
titleGrid = uigridlayout(titlePanel, [1 3]);
uilabel(titleGrid, 'Text', 'Stage 14 Interactive MATLAB Engineering App', ...
    'FontSize', 20, 'FontWeight', 'bold');
app.HomeStatusLabel = uilabel(titleGrid, 'Text', 'Status: ready', 'FontWeight', 'bold');
uilabel(titleGrid, 'Text', ['Output: ', app.State.outputRoot], 'HorizontalAlignment', 'right');

buttonPanel = uipanel(grid, 'Title', 'Quick Actions');
buttonPanel.Layout.Row = 2; buttonPanel.Layout.Column = 1;
buttonGrid = uigridlayout(buttonPanel, [8 1]);
app.HomeRunSingleButton = uibutton(buttonGrid, 'Text', 'Run Single Trajectory', 'ButtonPushedFcn', @(~,~) runSingleCallback(app.Figure));
app.HomeRunAngleButton = uibutton(buttonGrid, 'Text', 'Run Angle Sweep', 'ButtonPushedFcn', @(~,~) runAngleSweepCallback(app.Figure));
app.HomeRunValidationButton = uibutton(buttonGrid, 'Text', 'Run Stage 12 Validation', 'ButtonPushedFcn', @(~,~) runValidationCallback(app.Figure));
app.HomeRunMonteCarloButton = uibutton(buttonGrid, 'Text', 'Run Monte Carlo', 'ButtonPushedFcn', @(~,~) runMonteCarloCallback(app.Figure));
app.HomeRunParetoButton = uibutton(buttonGrid, 'Text', 'Run Pareto Study', 'ButtonPushedFcn', @(~,~) runParetoCallback(app.Figure));
app.HomeTutorialButton = uibutton(buttonGrid, 'Text', 'What am I looking at?', 'ButtonPushedFcn', @(~,~) refreshTutorialCallback(app.Figure));
app.HomeGenerateReportButton = uibutton(buttonGrid, 'Text', 'Generate Report', 'ButtonPushedFcn', @(~,~) generateReportCallback(app.Figure));
app.HomeExportSessionButton = uibutton(buttonGrid, 'Text', 'Export Session', 'ButtonPushedFcn', @(~,~) exportSessionCallback(app.Figure));

metricsPanel = uipanel(grid, 'Title', 'Key Metrics');
metricsPanel.Layout.Row = 2; metricsPanel.Layout.Column = 2;
metricsGrid = uigridlayout(metricsPanel, [9 2]);
labels = {'Range','Max altitude','Impact speed','Max Mach','Max q', ...
    'Max stagnation temp','Time to max altitude','Time to impact','Feasibility'};
app.MetricLabels = struct();
for k = 1:numel(labels)
    uilabel(metricsGrid, 'Text', labels{k});
    app.MetricLabels.(matlab.lang.makeValidName(labels{k})) = uilabel(metricsGrid, 'Text', '--', 'FontWeight', 'bold');
end

statusPanel = uipanel(grid, 'Title', 'Run Status / Warnings');
statusPanel.Layout.Row = 2; statusPanel.Layout.Column = 3;
statusGrid = uigridlayout(statusPanel, [2 1]);
statusGrid.RowHeight = {'1x', '1x'};
app.StatusTable = uitable(statusGrid, 'Data', table("None", false, "No runs yet.", ...
    'VariableNames', {'LastRunType','Success','Warnings'}));
app.WarningTextArea = uitextarea(statusGrid, 'Editable', 'off', 'Value', {'No runs yet.'});

selectedPanel = uipanel(grid, 'Title', 'Selected Case Details');
selectedPanel.Layout.Row = 3; selectedPanel.Layout.Column = [1 3];
selectedGrid = uigridlayout(selectedPanel, [1 3]);
selectedGrid.ColumnWidth = {240, '1x', 160};
app.SelectedCaseLabel = uilabel(selectedGrid, 'Text', 'No case selected.', 'FontWeight', 'bold');
app.SelectedCaseTable = uitable(selectedGrid, 'Data', table());
buttonGrid2 = uigridlayout(selectedGrid, [4 1]);
app.CaseIdField = uieditfield(buttonGrid2, 'text', 'Value', '');
uibutton(buttonGrid2, 'Text', 'Jump to CaseID', 'ButtonPushedFcn', @(~,~) jumpToCaseCallback(app.Figure));
app.OpenSelectedCaseButton = uibutton(buttonGrid2, 'Text', 'Open Selected Case', ...
    'Enable', 'off', 'ButtonPushedFcn', @(~,~) openSelectedCaseCallback(app.Figure));
app.ExportSelectedCaseButton = uibutton(buttonGrid2, 'Text', 'Export Selected Case', ...
    'Enable', 'off', 'ButtonPushedFcn', @(~,~) exportSelectedCaseCallback(app.Figure));
end

function app = createGuidedBuilderTab(app)
tab = uitab(app.TabGroup, 'Title', 'Guided Builder');
grid = uigridlayout(tab, [1 2]);
grid.ColumnWidth = {430, '1x'};

left = uipanel(grid, 'Title', 'Guided Vehicle Builder');
form = uigridlayout(left, [10 2]);
form.ColumnWidth = {170, '1x'};
app.BuilderBodyDropDown = addDropDown(form, 'Body type', ...
    {'Slender cone-cylinder','Blunt body','Long slender projectile','Custom'}, ...
    'Slender cone-cylinder');
app.BuilderMissionDropDown = addDropDown(form, 'Mission goal', ...
    {'Max range','Max altitude','Min heating','Balanced'}, 'Balanced');
app.BuilderLaunchDropDown = addDropDown(form, 'Launch method', ...
    {'Gun launch / initial velocity only','Rocket boost placeholder','Custom'}, ...
    'Gun launch / initial velocity only');
app.ApplyBuilderPresetButton = uibutton(form, 'Text', 'Apply Preset', ...
    'ButtonPushedFcn', @(~,~) applyGuidedBuilderCallback(app.Figure));
app.ResetDefaultsButton = uibutton(form, 'Text', 'Reset Defaults', ...
    'ButtonPushedFcn', @(~,~) resetDefaultsCallback(app.Figure));
uilabel(form, 'Text', 'Manual overrides');
uilabel(form, 'Text', 'Use Vehicle Setup after applying a preset.');
uilabel(form, 'Text', 'Assumption');
uilabel(form, 'Text', 'Educational geometry/aero starting point.');
uilabel(form, 'Text', 'Score note');
uilabel(form, 'Text', 'Dashboard scores are heuristic.');
uilabel(form, 'Text', 'Export note');
uilabel(form, 'Text', 'Reports include the selected preset inputs.');

right = uipanel(grid, 'Title', 'Geometry Summary / Preview');
rightGrid = uigridlayout(right, [2 1]);
rightGrid.RowHeight = {190, '1x'};
app.BuilderSummaryTable = uitable(rightGrid, 'Data', vehicleInfoTable(app.State.vehicle));
app.VehiclePreviewAxes = uiaxes(rightGrid);
end

function app = createVehicleTab(app)
tab = uitab(app.TabGroup, 'Title', 'Vehicle Setup');
grid = uigridlayout(tab, [1 2]);
grid.ColumnWidth = {430, '1x'};
left = uipanel(grid, 'Title', 'Vehicle Inputs');
form = uigridlayout(left, [13 2]);
form.ColumnWidth = {160, '1x'};

app.BodyTypeDropDown = addDropDown(form, 'Body type', ...
    {'Slender cone','Ogive nose','Blunt nose','Finned dart','Custom baseline'}, 'Custom baseline');
app.MassField = addNumeric(form, 'Mass kg', 5);
app.LengthField = addNumeric(form, 'Length m', 0.45);
app.DiameterField = addNumeric(form, 'Diameter m', 0.0564);
app.NoseRadiusField = addNumeric(form, 'Nose radius m', 0.0282);
app.CGField = addNumeric(form, 'CG location m', 0.225);
app.CPField = addNumeric(form, 'CP location m', 0.270);
app.StaticMarginField = addNumeric(form, 'Static margin %', 10);
app.ReferenceAreaField = addNumeric(form, 'Reference area m^2', pi * 0.0564^2 / 4);
app.CdMultiplierField = addNumeric(form, 'Cd multiplier', 1.0);
app.CLMultiplierField = addNumeric(form, 'CLalpha multiplier', 1.0);
app.FinCheckbox = addCheckBox(form, 'Fins enabled', false);
uibutton(form, 'Text', 'Load Vehicle Preset', 'ButtonPushedFcn', @(~,~) loadPresetCallback(app.Figure));
uibutton(form, 'Text', 'Validate Vehicle Inputs', 'ButtonPushedFcn', @(~,~) validateVehicleCallback(app.Figure));

right = uipanel(grid, 'Title', 'Calculated Vehicle Data');
rightGrid = uigridlayout(right, [1 1]);
app.VehicleInfoTable = uitable(rightGrid, 'Data', table());
end

function app = createLaunchTab(app)
tab = uitab(app.TabGroup, 'Title', 'Launch Conditions');
grid = uigridlayout(tab, [1 2]);
grid.ColumnWidth = {430, '1x'};
left = uipanel(grid, 'Title', 'Launch Inputs');
form = uigridlayout(left, [12 2]);
form.ColumnWidth = {180, '1x'};
app.SpeedField = addNumeric(form, 'Initial speed m/s', 1800);
app.InitialMachField = addNumeric(form, 'Initial Mach', 0);
app.AngleField = addNumeric(form, 'Launch angle deg', 25);
app.YawField = addNumeric(form, 'Yaw angle deg', 0);
app.InitialAltitudeField = addNumeric(form, 'Initial altitude m', 0);
app.InitialDownrangeField = addNumeric(form, 'Initial downrange m', 0);
app.InitialCrossrangeField = addNumeric(form, 'Initial crossrange m', 0);
app.PRateField = addNumeric(form, 'p deg/s', 0);
app.QRateField = addNumeric(form, 'q deg/s', 0);
app.RRateField = addNumeric(form, 'r deg/s', 0);
uibutton(form, 'Text', 'Low Angle 10 deg', 'ButtonPushedFcn', @(~,~) setAnglePreset(app.Figure, 10));
uibutton(form, 'Text', 'Practical 25 deg', 'ButtonPushedFcn', @(~,~) setAnglePreset(app.Figure, 25));
uibutton(form, 'Text', 'High Practical 45 deg', 'ButtonPushedFcn', @(~,~) setAnglePreset(app.Figure, 45));
uibutton(form, 'Text', 'Lofted Research 55 deg', 'ButtonPushedFcn', @(~,~) setAnglePreset(app.Figure, 55));

right = uipanel(grid, 'Title', 'Launch Notes');
rightGrid = uigridlayout(right, [1 1]);
uitextarea(rightGrid, 'Editable', 'off', 'Value', { ...
    'Default mode uses the practical 5-45 deg envelope.', ...
    'Lofted research angles are available but are not the default.', ...
    'The app stores p/q/r angular rates for 6-DOF setup.'});
end

function app = createPhysicsTab(app)
tab = uitab(app.TabGroup, 'Title', 'Physics Options');
grid = uigridlayout(tab, [1 2]);
grid.ColumnWidth = {430, '1x'};
left = uipanel(grid, 'Title', 'Model Toggles');
form = uigridlayout(left, [13 2]);
form.ColumnWidth = {190, '1x'};
app.DofDropDown = addDropDown(form, 'Dynamics mode', {'3DOF','6DOF'}, '3DOF');
app.LiftCheckbox = addCheckBox(form, 'Lift enabled', true);
app.DragCheckbox = addCheckBox(form, 'Drag enabled', true);
app.WindCheckbox = addCheckBox(form, 'Wind enabled', false);
app.HeatingCheckbox = addCheckBox(form, 'Heating enabled', true);
app.StabilityCheckbox = addCheckBox(form, 'Stability enabled', true);
app.CurvatureCheckbox = addCheckBox(form, 'Earth curvature approx', false);
app.RotationCheckbox = addCheckBox(form, 'Earth rotation / Coriolis', false);
app.LowAltCheckbox = addCheckBox(form, 'Low-altitude constraint mode', false);
app.EnvelopeDropDown = addDropDown(form, 'Angle envelope', ...
    {'Practical envelope: 5 to 45 deg','Lofted research envelope: 45 to 75 deg', ...
    'Full diagnostic envelope: 5 to 75 deg','Custom envelope'}, ...
    'Practical envelope: 5 to 45 deg');
app.AngleMinField = addNumeric(form, 'Angle min deg', 5);
app.AngleMaxField = addNumeric(form, 'Angle max deg', 45);
app.AngleStepField = addNumeric(form, 'Angle step deg', 5);

right = uipanel(grid, 'Title', 'Physics Backend Note');
rightGrid = uigridlayout(right, [1 1]);
uitextarea(rightGrid, 'Editable', 'off', 'Value', { ...
    'Stage 14 calls Stage 11, Stage 12, and Stage 13 backends.', ...
    'Lift can be disabled by setting alpha/CL scaling to zero before calling Stage 11.', ...
    'Drag-off comparisons are handled quantitatively in the Stage 12 physics diagnostics.', ...
    'Backend assumptions remain those documented in Stages 11-13.'});
end

function app = createSingleTab(app)
tab = uitab(app.TabGroup, 'Title', 'Single Trajectory');
grid = uigridlayout(tab, [3 1]);
grid.RowHeight = {82, '1x', 180};
top = uigridlayout(grid, [2 8]);
top.RowHeight = {34, 34};
app.RunSingleButton = uibutton(top, 'Text', 'Run Single Trajectory', 'ButtonPushedFcn', @(~,~) runSingleCallback(app.Figure));
uibutton(top, 'Text', 'Open Summary Table', 'ButtonPushedFcn', @(~,~) openCurrentTableCallback(app.Figure));
uibutton(top, 'Text', 'Export Single Trajectory', 'ButtonPushedFcn', @(~,~) exportCurrentTableCallback(app.Figure));
uibutton(top, 'Text', 'Generate Stage 11 Report', 'ButtonPushedFcn', @(~,~) generateStage11ReportCallback(app.Figure));
uibutton(top, 'Text', 'Run 6-DOF Debug Check', 'ButtonPushedFcn', @(~,~) run6DOFDebugCallback(app.Figure));
app.DofModeLabel = uilabel(top, 'Text', '3-DOF mode active', 'FontWeight', 'bold');
uilabel(top, 'Text', 'Main plot');
app.MainPlotDropDown = uidropdown(top, 'Items', {'Trajectory','Velocity','Mach','Dynamic Pressure', ...
    'Drag','Stagnation Temperature','Angle of Attack','Lift-to-Drag'}, ...
    'Value', 'Trajectory', 'ValueChangedFcn', @(~,~) refreshMainPlotCallback(app.Figure));
app.EventMarkersCheckbox = uicheckbox(top, 'Text', 'Event markers', 'Value', true, ...
    'ValueChangedFcn', @(~,~) refreshMainPlotCallback(app.Figure));
uibutton(top, 'Text', 'Save Run for Compare', 'ButtonPushedFcn', @(~,~) saveCurrentRunCallback(app.Figure));
uibutton(top, 'Text', 'Export Results CSV', 'ButtonPushedFcn', @(~,~) exportResultsCSVCallback(app.Figure));
uibutton(top, 'Text', 'Export Plot PNG', 'ButtonPushedFcn', @(~,~) exportPlotPNGCallback(app.Figure));
uibutton(top, 'Text', 'Reset Plot View', 'ButtonPushedFcn', @(~,~) resetMainPlotViewCallback(app.Figure));
content = uigridlayout(grid, [1 2]);
content.ColumnWidth = {'1.4x', '1x'};
axesGrid = uigridlayout(content, [2 3]);
app.SingleAxes = gobjects(1, 6);
for k = 1:6
    app.SingleAxes(k) = uiaxes(axesGrid);
end
rightGrid = uigridlayout(content, [3 1]);
rightGrid.RowHeight = {150, '1x', '1x'};
pointPanel = uipanel(rightGrid, 'Title', 'Selected Point Data');
pointGrid = uigridlayout(pointPanel, [2 1]);
pointGrid.RowHeight = {24, '1x'};
app.SelectedPointLabel = uilabel(pointGrid, 'Text', 'Selected Point: click a plotted point or event marker', 'FontWeight', 'bold');
app.SelectedPointTable = uitable(pointGrid, 'Data', selectedPointTableStage14(struct('t',0,'x',0,'h',0,'V',0), 1, "No point selected"));
app.SingleTable = uitable(rightGrid, 'Data', table());
app.EngineeringInsightsArea = uitextarea(rightGrid, 'Editable', 'off', ...
    'Value', {'Engineering insights will appear after a run.'});
comparisonPanel = uipanel(grid, 'Title', 'Saved Run Comparison');
comparisonGrid = uigridlayout(comparisonPanel, [1 1]);
app.ComparisonTable = uitable(comparisonGrid, 'Data', table());
end

function app = createScenarioCompareTab(app)
tab = uitab(app.TabGroup, 'Title', 'Scenario Compare');
grid = uigridlayout(tab, [3 1]);
grid.RowHeight = {110, '1x', 230};

controls = uigridlayout(grid, [2 8]);
controls.RowHeight = {34, 60};
app.CompareSweepDropDown = uidropdown(controls, 'Items', ...
    {'Launch angle sweep','Initial velocity sweep','Mass sweep','Diameter sweep', ...
    'Body type comparison','Custom manual case list'}, 'Value', 'Launch angle sweep');
app.CompareMissionDropDown = uidropdown(controls, 'Items', ...
    {'Maximum range','Maximum altitude','Minimum heating','Minimum structural load','Balanced'}, ...
    'Value', 'Balanced', 'ValueChangedFcn', @(~,~) scenarioMissionChangedCallback(app.Figure));
app.RunCompareButton = uibutton(controls, 'Text', 'Run Scenario Compare', ...
    'ButtonPushedFcn', @(~,~) runScenarioCompareCallback(app.Figure));
app.CompareSortDropDown = uidropdown(controls, 'Items', {'OverallDesignScore','Range_km', ...
    'MaxAltitude_km','MaxDynamicPressure_kPa','MaxStagTemp_K','TimeToImpact_s'}, ...
    'Value', 'OverallDesignScore');
uibutton(controls, 'Text', 'Sort Table', 'ButtonPushedFcn', @(~,~) sortScenarioCompareCallback(app.Figure));
uibutton(controls, 'Text', 'Export Compare CSV', 'ButtonPushedFcn', @(~,~) exportScenarioCompareCSVCallback(app.Figure));
uibutton(controls, 'Text', 'Export Report', 'ButtonPushedFcn', @(~,~) exportEngineeringReportCallback(app.Figure));
app.CompareBestLabel = uilabel(controls, 'Text', 'Best case: --', 'FontWeight', 'bold');
app.CompareManualTextArea = uitextarea(controls, 'Value', {'Custom lines: Name, angle_deg, speed_mps, mass_kg, diameter_m, length_m, CdScale, BodyType, staticMargin_pct, alpha_deg'});
app.CompareManualTextArea.Layout.Column = [1 8];

axesGrid = uigridlayout(grid, [1 5]);
app.CompareAxes = gobjects(1, 5);
for k = 1:5
    app.CompareAxes(k) = uiaxes(axesGrid);
end

bottom = uigridlayout(grid, [1 2]);
bottom.ColumnWidth = {'1.3x', '1x'};
app.CompareTable = uitable(bottom, 'Data', table(), 'CellSelectionCallback', @(src,event) compareTableSelectionCallback(app.Figure, src, event));
app.CompareInsightsArea = uitextarea(bottom, 'Editable', 'off', ...
    'Value', {'Scenario Compare insights will appear after a run.'});
end

function app = createSensitivityTab(app)
tab = uitab(app.TabGroup, 'Title', 'Sensitivity Analysis');
grid = uigridlayout(tab, [3 1]);
grid.RowHeight = {50, '1x', 230};

controls = uigridlayout(grid, [1 6]);
app.SensitivityPerturbField = uieditfield(controls, 'numeric', 'Value', 5, ...
    'Limits', [0.1 25], 'Tooltip', 'Percent perturbation for most variables. Launch angle and static margin use small absolute changes.');
uilabel(controls, 'Text', 'Perturbation %');
app.RunSensitivityButton = uibutton(controls, 'Text', 'Run Sensitivity Analysis', ...
    'ButtonPushedFcn', @(~,~) runSensitivityCallback(app.Figure));
uibutton(controls, 'Text', 'Export Sensitivity CSV', 'ButtonPushedFcn', @(~,~) exportSensitivityCSVCallback(app.Figure));
uibutton(controls, 'Text', 'Export Report', 'ButtonPushedFcn', @(~,~) exportEngineeringReportCallback(app.Figure));
uilabel(controls, 'Text', 'One-at-a-time baseline-safe study');

app.SensitivityAxes = uiaxes(grid);
bottom = uigridlayout(grid, [1 2]);
bottom.ColumnWidth = {'1.4x', '1x'};
app.SensitivityTable = uitable(bottom, 'Data', table());
app.SensitivityInsightsArea = uitextarea(bottom, 'Editable', 'off', ...
    'Value', {'Sensitivity insights will appear after a run.'});
end

function app = createRiskDashboardTab(app)
tab = uitab(app.TabGroup, 'Title', 'Risk Dashboard');
grid = uigridlayout(tab, [2 2]);
grid.RowHeight = {190, '1x'};
grid.ColumnWidth = {'1x', '1x'};

gaugePanel = uipanel(grid, 'Title', 'Simplified Design Score');
gaugePanel.Layout.Row = 1; gaugePanel.Layout.Column = [1 2];
gaugeGrid = uigridlayout(gaugePanel, [2 3]);
gaugeGrid.RowHeight = {22, '1x'};
uilabel(gaugeGrid, 'Text', 'Overall', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
uilabel(gaugeGrid, 'Text', 'Range', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
uilabel(gaugeGrid, 'Text', 'Altitude', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
app.RiskOverallGauge = uigauge(gaugeGrid, 'semicircular', 'Limits', [0 100], 'Value', 0);
app.RiskRangeGauge = uigauge(gaugeGrid, 'semicircular', 'Limits', [0 100], 'Value', 0);
app.RiskAltitudeGauge = uigauge(gaugeGrid, 'semicircular', 'Limits', [0 100], 'Value', 0);

app.RiskTable = uitable(grid, 'Data', table(["No run yet"], ["Run a scenario first"], ...
    'VariableNames', {'Metric','Value'}));
app.RiskInsightsArea = uitextarea(grid, 'Editable', 'off', 'Value', { ...
    'Risk dashboard values are simplified educational heuristics.', ...
    'Run a single trajectory or scenario comparison to populate this view.'});
end

function app = createVerificationValidationTab(app)
tab = uitab(app.TabGroup, 'Title', 'Verification & Validation');
grid = uigridlayout(tab, [3 1]);
grid.RowHeight = {54, '1x', 230};

controls = uigridlayout(grid, [1 6]);
app.RunVerificationButton = uibutton(controls, 'Text', 'Run V&V Diagnostics', ...
    'ButtonPushedFcn', @(~,~) runVerificationValidationCallback(app.Figure));
uibutton(controls, 'Text', 'Export V&V CSV', ...
    'ButtonPushedFcn', @(~,~) exportVerificationCSVCallback(app.Figure));
uilabel(controls, 'Text', 'Checks: vacuum analytic, energy, drag, max-Q, impact, input sanity');
uilabel(controls, 'Text', 'Uses Stage 12/11 diagnostic backend');
uilabel(controls, 'Text', 'Report section ready');
uilabel(controls, 'Text', 'Educational verification, not flight-data validation');

axesGrid = uigridlayout(grid, [1 2]);
app.VerificationAxes = gobjects(1, 2);
app.VerificationAxes(1) = uiaxes(axesGrid);
app.VerificationAxes(2) = uiaxes(axesGrid);

bottom = uigridlayout(grid, [1 2]);
bottom.ColumnWidth = {'1.35x', '1x'};
app.VerificationTable = uitable(bottom, 'Data', table());
app.VerificationInsightsArea = uitextarea(bottom, 'Editable', 'off', ...
    'Value', {'Run V&V Diagnostics to quantify vacuum agreement, energy behavior, max-Q timing, impact detection, and input sanity.'});
end

function app = createAssumptionsTab(app)
tab = uitab(app.TabGroup, 'Title', 'Assumptions Manager');
grid = uigridlayout(tab, [3 2]);
grid.RowHeight = {60, '1x', 170};
grid.ColumnWidth = {'1x', '1x'};

top = uipanel(grid, 'Title', 'Model Fidelity');
top.Layout.Row = 1; top.Layout.Column = [1 2];
topGrid = uigridlayout(top, [1 4]);
options = updateModelFidelityOptionsStage14();
app.ModelFidelityDropDown = uidropdown(topGrid, 'Items', options, 'Value', options{end}, ...
    'ValueChangedFcn', @(~,~) modelFidelityChangedCallback(app.Figure));
uibutton(topGrid, 'Text', 'Refresh Assumptions', 'ButtonPushedFcn', @(~,~) modelFidelityChangedCallback(app.Figure));
uilabel(topGrid, 'Text', 'Feature availability updates from selected fidelity.', 'FontWeight', 'bold');
uilabel(topGrid, 'Text', 'Higher stages add diagnostics, uncertainty, and trade studies.');

included = uipanel(grid, 'Title', 'Included');
included.Layout.Row = 2; included.Layout.Column = 1;
includedGrid = uigridlayout(included, [1 1]);
app.AssumptionsIncludedTable = uitable(includedGrid, 'Data', table());

notIncluded = uipanel(grid, 'Title', 'Not Included / Simplifications');
notIncluded.Layout.Row = 2; notIncluded.Layout.Column = 2;
notGrid = uigridlayout(notIncluded, [1 1]);
app.AssumptionsNotIncludedTable = uitable(notGrid, 'Data', table());

limitPanel = uipanel(grid, 'Title', 'Model Limitations');
limitPanel.Layout.Row = 3; limitPanel.Layout.Column = [1 2];
limitGrid = uigridlayout(limitPanel, [1 1]);
app.ModelLimitationsArea = uitextarea(limitGrid, 'Editable', 'off', ...
    'Value', {'Select a model fidelity to review included physics and limitations.'});
end

function app = createConstraintEnvelopeTab(app)
tab = uitab(app.TabGroup, 'Title', 'Constraint Envelope');
grid = uigridlayout(tab, [3 1]);
grid.RowHeight = {98, '1x', 220};

controls = uigridlayout(grid, [2 9]);
controls.RowHeight = {34, 34};
app.MaxQConstraintField = addNumericNoLabel(controls, 2000); uilabel(controls, 'Text', 'Max q kPa');
app.MaxStagTempConstraintField = addNumericNoLabel(controls, 2500); uilabel(controls, 'Text', 'Max T0 K');
app.MaxMachConstraintField = addNumericNoLabel(controls, 8); uilabel(controls, 'Text', 'Max Mach');
app.MaxGConstraintField = addNumericNoLabel(controls, 75); uilabel(controls, 'Text', 'Max g');
app.MinStaticMarginConstraintField = addNumericNoLabel(controls, 5); uilabel(controls, 'Text', 'Min SM %');
app.MaxAlphaConstraintField = addNumericNoLabel(controls, 10); uilabel(controls, 'Text', 'Max AoA deg');
app.MaxDragConstraintField = addNumericNoLabel(controls, 6000); uilabel(controls, 'Text', 'Max drag N');
app.MaxLiftConstraintField = addNumericNoLabel(controls, 2500); uilabel(controls, 'Text', 'Max lift N');
app.RunConstraintEnvelopeButton = uibutton(controls, 'Text', 'Run Constraint Check', ...
    'ButtonPushedFcn', @(~,~) runConstraintEnvelopeCallback(app.Figure));
uibutton(controls, 'Text', 'Export Constraint CSV', ...
    'ButtonPushedFcn', @(~,~) exportConstraintCSVCallback(app.Figure));

axesGrid = uigridlayout(grid, [1 5]);
app.ConstraintAxes = gobjects(1, 5);
for k = 1:5
    app.ConstraintAxes(k) = uiaxes(axesGrid);
end

bottom = uigridlayout(grid, [1 2]);
bottom.ColumnWidth = {'1.35x', '1x'};
app.ConstraintTable = uitable(bottom, 'Data', table());
app.ConstraintInsightsArea = uitextarea(bottom, 'Editable', 'off', ...
    'Value', {'Run Constraint Check to plot limits, margins, and violation intervals for the current baseline trajectory.'});
end

function app = createOptimizationModeTab(app)
tab = uitab(app.TabGroup, 'Title', 'Optimization Mode');
grid = uigridlayout(tab, [3 1]);
grid.RowHeight = {205, '1x', 230};

top = uigridlayout(grid, [1 2]);
top.ColumnWidth = {310, '1x'};

left = uipanel(top, 'Title', 'Objective / Actions');
leftGrid = uigridlayout(left, [7 1]);
app.OptObjectiveDropDown = uidropdown(leftGrid, 'Items', {'Maximize range','Maximize altitude', ...
    'Minimize heating','Minimize dynamic pressure','Minimize drag loss','Maximize impact speed', ...
    'Best balanced design'}, 'Value', 'Best balanced design');
app.RunOptimizationGridButton = uibutton(leftGrid, 'Text', 'Run Grid Optimization', ...
    'ButtonPushedFcn', @(~,~) runOptimizationGridCallback(app.Figure));
app.ApplyBestDesignButton = uibutton(leftGrid, 'Text', 'Apply Best Design', 'Enable', 'off', ...
    'ButtonPushedFcn', @(~,~) applyBestDesignCallback(app.Figure));
uibutton(leftGrid, 'Text', 'Export Optimization CSV', ...
    'ButtonPushedFcn', @(~,~) exportOptimizationGridCSVCallback(app.Figure));
app.OptMaxCasesField = uieditfield(leftGrid, 'numeric', 'Value', 120, 'Limits', [1 2000]);
uilabel(leftGrid, 'Text', 'Max cases evaluated');
uilabel(leftGrid, 'Text', 'Best design is not applied until clicked.');

ranges = uipanel(top, 'Title', 'Design Variables / Ranges');
rangeGrid = uigridlayout(ranges, [9 5]);
rangeGrid.ColumnWidth = {150, '1x', '1x', '1x', 70};
uilabel(rangeGrid, 'Text', 'Variable', 'FontWeight', 'bold');
uilabel(rangeGrid, 'Text', 'Min', 'FontWeight', 'bold');
uilabel(rangeGrid, 'Text', 'Max', 'FontWeight', 'bold');
uilabel(rangeGrid, 'Text', 'Step', 'FontWeight', 'bold');
uilabel(rangeGrid, 'Text', 'Units', 'FontWeight', 'bold');
[app.OptUseAngleCheckbox, app.OptAngleMinField, app.OptAngleMaxField, app.OptAngleStepField] = addOptRow(rangeGrid, 'Launch angle', true, 5, 45, 5, 'deg');
[app.OptUseSpeedCheckbox, app.OptSpeedMinField, app.OptSpeedMaxField, app.OptSpeedStepField] = addOptRow(rangeGrid, 'Initial velocity', false, 1600, 2200, 200, 'm/s');
[app.OptUseMassCheckbox, app.OptMassMinField, app.OptMassMaxField, app.OptMassStepField] = addOptRow(rangeGrid, 'Mass', false, 3, 10, 1, 'kg');
[app.OptUseDiameterCheckbox, app.OptDiameterMinField, app.OptDiameterMaxField, app.OptDiameterStepField] = addOptRow(rangeGrid, 'Diameter', false, 0.04, 0.09, 0.01, 'm');
[app.OptUseLengthCheckbox, app.OptLengthMinField, app.OptLengthMaxField, app.OptLengthStepField] = addOptRow(rangeGrid, 'Length', false, 0.35, 0.75, 0.1, 'm');
[app.OptUseCdCheckbox, app.OptCdMinField, app.OptCdMaxField, app.OptCdStepField] = addOptRow(rangeGrid, 'Cd multiplier', false, 0.8, 1.2, 0.1, 'scale');
[app.OptUseAlphaCheckbox, app.OptAlphaMinField, app.OptAlphaMaxField, app.OptAlphaStepField] = addOptRow(rangeGrid, 'Angle of attack', false, 0, 6, 1, 'deg');
[app.OptUseStaticMarginCheckbox, app.OptStaticMarginMinField, app.OptStaticMarginMaxField, app.OptStaticMarginStepField] = addOptRow(rangeGrid, 'Static margin', false, 5, 20, 5, '%');

axesGrid = uigridlayout(grid, [1 2]);
app.OptimizationAxes = gobjects(1, 2);
app.OptimizationAxes(1) = uiaxes(axesGrid);
app.OptimizationAxes(2) = uiaxes(axesGrid);

bottom = uigridlayout(grid, [1 2]);
bottom.ColumnWidth = {'1.35x', '1x'};
app.OptimizationGridTable = uitable(bottom, 'Data', table());
app.OptimizationStatusArea = uitextarea(bottom, 'Editable', 'off', ...
    'Value', {'Select variables, set ranges, and run a simple grid search. Constraint Envelope limits are respected.'});
end

function app = createUncertaintyTab(app)
tab = uitab(app.TabGroup, 'Title', 'Uncertainty Bands');
grid = uigridlayout(tab, [3 1]);
grid.RowHeight = {78, '1x', 220};

controls = uigridlayout(grid, [2 8]);
app.UncCdPctField = addNumericNoLabel(controls, 10); uilabel(controls, 'Text', 'Cd +/- %');
app.UncSpeedPctField = addNumericNoLabel(controls, 2); uilabel(controls, 'Text', 'Speed +/- %');
app.UncAngleDegField = addNumericNoLabel(controls, 1); uilabel(controls, 'Text', 'Angle +/- deg');
app.UncMassPctField = addNumericNoLabel(controls, 5); uilabel(controls, 'Text', 'Mass +/- %');
app.UncDiameterPctField = addNumericNoLabel(controls, 2); uilabel(controls, 'Text', 'Diameter +/- %');
app.UncDensityPctField = addNumericNoLabel(controls, 10); uilabel(controls, 'Text', 'Density +/- %');
app.RunUncertaintyButton = uibutton(controls, 'Text', 'Run Uncertainty Bands', ...
    'ButtonPushedFcn', @(~,~) runUncertaintyBandsCallback(app.Figure));
uibutton(controls, 'Text', 'Export Uncertainty CSV', ...
    'ButtonPushedFcn', @(~,~) exportUncertaintyCSVCallback(app.Figure));

axesGrid = uigridlayout(grid, [1 5]);
app.UncertaintyAxes = gobjects(1, 5);
for k = 1:5
    app.UncertaintyAxes(k) = uiaxes(axesGrid);
end

bottom = uigridlayout(grid, [1 2]);
bottom.ColumnWidth = {'1.25x', '1x'};
app.UncertaintyTable = uitable(bottom, 'Data', table());
app.UncertaintyInsightsArea = uitextarea(bottom, 'Editable', 'off', ...
    'Value', {'Run Uncertainty Bands to see low/high deterministic envelopes around the baseline trajectory.'});
end

function app = createTutorialTab(app)
tab = uitab(app.TabGroup, 'Title', 'Tutorial');
app.TutorialTab = tab;
grid = uigridlayout(tab, [2 1]);
grid.RowHeight = {44, '1x'};
top = uigridlayout(grid, [1 3]);
uibutton(top, 'Text', 'What am I looking at?', 'ButtonPushedFcn', @(~,~) refreshTutorialCallback(app.Figure));
uilabel(top, 'Text', 'Student-friendly explanations of key trajectory terms.', 'FontWeight', 'bold');
uilabel(top, 'Text', 'These notes are included in the engineering report.');
content = uigridlayout(grid, [1 2]);
content.ColumnWidth = {'1.2x', '1x'};
tutorial = generateTutorialContentStage14();
app.TutorialTable = uitable(content, 'Data', tutorial.table);
app.TutorialTextArea = uitextarea(content, 'Editable', 'off', 'Value', tutorial.text);
app.State.Results.tutorial = tutorial;
end

function app = createAngleSweepTab(app)
tab = uitab(app.TabGroup, 'Title', 'Angle Sweep');
grid = uigridlayout(tab, [3 1]);
grid.RowHeight = {54, '1x', 190};
controls = uigridlayout(grid, [1 8]);
app.SweepMinField = uieditfield(controls, 'numeric', 'Value', 5);
app.SweepMaxField = uieditfield(controls, 'numeric', 'Value', 45);
app.SweepStepField = uieditfield(controls, 'numeric', 'Value', 5);
uibutton(controls, 'Text', 'Use Practical', 'ButtonPushedFcn', @(~,~) setSweepEnvelope(app.Figure, 5, 45));
uibutton(controls, 'Text', 'Use Lofted', 'ButtonPushedFcn', @(~,~) setSweepEnvelope(app.Figure, 45, 75));
uibutton(controls, 'Text', 'Use Full Diagnostic', 'ButtonPushedFcn', @(~,~) setSweepEnvelope(app.Figure, 5, 75));
uibutton(controls, 'Text', 'Run Angle Sweep', 'ButtonPushedFcn', @(~,~) runAngleSweepCallback(app.Figure));
app.AngleBestLabel = uilabel(controls, 'Text', 'Best angle: --');
axesGrid = uigridlayout(grid, [2 3]);
app.AngleAxes = gobjects(1, 6);
for k = 1:6
    app.AngleAxes(k) = uiaxes(axesGrid);
end
app.AngleTable = uitable(grid, 'Data', table());
end

function app = createValidationTab(app)
tab = uitab(app.TabGroup, 'Title', 'Stage Comparison / Validation');
grid = uigridlayout(tab, [3 1]);
grid.RowHeight = {44, '1x', 220};
buttons = uigridlayout(grid, [1 4]);
uibutton(buttons, 'Text', 'Run All Validation Cases', 'ButtonPushedFcn', @(~,~) runValidationCallback(app.Figure));
uibutton(buttons, 'Text', 'Run Stage Comparison', 'ButtonPushedFcn', @(~,~) runStageComparisonCallback(app.Figure));
uibutton(buttons, 'Text', 'Run Regression Tests', 'ButtonPushedFcn', @(~,~) runRegressionCallback(app.Figure));
uibutton(buttons, 'Text', 'Run Physics Diagnostics', 'ButtonPushedFcn', @(~,~) runPhysicsDiagnosticsCallback(app.Figure));
axesGrid = uigridlayout(grid, [1 2]);
app.ValidationAxes = gobjects(1, 2);
app.ValidationAxes(1) = uiaxes(axesGrid);
app.ValidationAxes(2) = uiaxes(axesGrid);
app.ValidationTable = uitable(grid, 'Data', table());
end

function app = createMonteCarloTab(app)
tab = uitab(app.TabGroup, 'Title', 'Monte Carlo');
grid = uigridlayout(tab, [3 1]);
grid.RowHeight = {80, '1x', 210};
controls = uigridlayout(grid, [2 10]);
app.MCNField = addNumericNoLabel(controls, 200); uilabel(controls, 'Text', 'N');
app.MCSpeedUncField = addNumericNoLabel(controls, 2); uilabel(controls, 'Text', 'Speed %');
app.MCAngleUncField = addNumericNoLabel(controls, 1); uilabel(controls, 'Text', 'Angle deg');
app.MCMassUncField = addNumericNoLabel(controls, 5); uilabel(controls, 'Text', 'Mass %');
app.MCCdUncField = addNumericNoLabel(controls, 10); uilabel(controls, 'Text', 'Cd %');
app.MCClUncField = addNumericNoLabel(controls, 10); uilabel(controls, 'Text', 'CL %');
app.MCDensityUncField = addNumericNoLabel(controls, 5); uilabel(controls, 'Text', 'Density %');
app.MCCGUncField = addNumericNoLabel(controls, 2); uilabel(controls, 'Text', 'CG %');
app.MCCPUncField = addNumericNoLabel(controls, 2); uilabel(controls, 'Text', 'CP %');
app.RunMonteCarloButton = uibutton(controls, 'Text', 'Run Monte Carlo', 'ButtonPushedFcn', @(~,~) runMonteCarloCallback(app.Figure));
axesGrid = uigridlayout(grid, [2 3]);
app.MonteCarloAxes = gobjects(1, 6);
for k = 1:6
    app.MonteCarloAxes(k) = uiaxes(axesGrid);
end
app.MonteCarloTable = uitable(grid, 'Data', table());
end

function app = createParetoTab(app)
tab = uitab(app.TabGroup, 'Title', 'Pareto / Optimization');
grid = uigridlayout(tab, [3 1]);
grid.RowHeight = {54, '1x', 240};
controls = uigridlayout(grid, [1 8]);
app.StudyTypeDropDown = addDropDownNoLabel(controls, ...
    {'constrained design optimization','launch angle optimization','vehicle geometry optimization','Pareto trade study','DOE'}, ...
    'Pareto trade study');
app.ObjectiveDropDown = addDropDownNoLabel(controls, ...
    {'maximize range','maximize altitude','minimize max q','minimize max heating','minimize g-load','best balanced score'}, ...
    'best balanced score');
app.ConstraintProfileDropDown = addDropDownNoLabel(controls, {'generic','practical low-altitude','custom'}, 'generic');
app.RunOptimizationButton = uibutton(controls, 'Text', 'Run Optimization', 'ButtonPushedFcn', @(~,~) runOptimizationCallback(app.Figure));
app.RunParetoButton = uibutton(controls, 'Text', 'Run Pareto Study', 'ButtonPushedFcn', @(~,~) runParetoCallback(app.Figure));
app.RunDOEButton = uibutton(controls, 'Text', 'Run DOE', 'ButtonPushedFcn', @(~,~) runDOECallback(app.Figure));
uibutton(controls, 'Text', 'Export Pareto Designs', 'ButtonPushedFcn', @(~,~) exportParetoCallback(app.Figure));
uibutton(controls, 'Text', 'Open Full Case Table', 'ButtonPushedFcn', @(~,~) openCurrentTableCallback(app.Figure));
axesGrid = uigridlayout(grid, [2 2]);
app.ParetoAxes = gobjects(1, 4);
for k = 1:4
    app.ParetoAxes(k) = uiaxes(axesGrid);
end
app.ParetoTable = uitable(grid, 'Data', table());
end

function app = createResultsTab(app)
tab = uitab(app.TabGroup, 'Title', 'Results Tables');
grid = uigridlayout(tab, [3 1]);
grid.RowHeight = {44, '1x', 190};
controls = uigridlayout(grid, [1 8]);
app.CurrentTableDropDown = uidropdown(controls, 'Items', {'None'}, 'Value', 'None');
uibutton(controls, 'Text', 'Show Table', 'ButtonPushedFcn', @(~,~) showSelectedTableCallback(app.Figure));
uibutton(controls, 'Text', 'Open Table in Popup', 'ButtonPushedFcn', @(~,~) openCurrentTableCallback(app.Figure));
uibutton(controls, 'Text', 'Export Current Table to CSV', 'ButtonPushedFcn', @(~,~) exportCurrentTableCallback(app.Figure));
uibutton(controls, 'Text', 'Export All Tables', 'ButtonPushedFcn', @(~,~) exportAllTablesCallback(app.Figure));
uibutton(controls, 'Text', 'Save Current Run', 'ButtonPushedFcn', @(~,~) saveCurrentRunCallback(app.Figure));
uibutton(controls, 'Text', 'Clear Saved Runs', 'ButtonPushedFcn', @(~,~) clearSavedRunsCallback(app.Figure));
uibutton(controls, 'Text', 'Export Summary CSV', 'ButtonPushedFcn', @(~,~) exportSummaryCSVCallback(app.Figure));
app.ResultsTable = uitable(grid, 'Data', table());
app.ResultsComparisonTable = uitable(grid, 'Data', table());
end

function app = createReportsTab(app)
tab = uitab(app.TabGroup, 'Title', 'Reports / Export');
grid = uigridlayout(tab, [1 2]);
grid.ColumnWidth = {360, '1x'};
buttons = uipanel(grid, 'Title', 'Reports and Export');
buttonGrid = uigridlayout(buttons, [10 1]);
uibutton(buttonGrid, 'Text', 'Generate Stage 11 Report', 'ButtonPushedFcn', @(~,~) generateStage11ReportCallback(app.Figure));
uibutton(buttonGrid, 'Text', 'Generate Stage 12 Validation Report', 'ButtonPushedFcn', @(~,~) generateStage12ReportCallback(app.Figure));
uibutton(buttonGrid, 'Text', 'Generate Stage 13 Optimization Report', 'ButtonPushedFcn', @(~,~) generateStage13ReportCallback(app.Figure));
uibutton(buttonGrid, 'Text', 'Generate Stage 14 App Session Report', 'ButtonPushedFcn', @(~,~) exportSessionCallback(app.Figure));
uibutton(buttonGrid, 'Text', 'Export Engineering HTML Report', 'ButtonPushedFcn', @(~,~) exportEngineeringReportCallback(app.Figure));
uibutton(buttonGrid, 'Text', 'Export Current Session', 'ButtonPushedFcn', @(~,~) exportSessionCallback(app.Figure));
uibutton(buttonGrid, 'Text', 'Export Portfolio Package', 'ButtonPushedFcn', @(~,~) createPortfolioSummaryCallback(app.Figure));
uibutton(buttonGrid, 'Text', 'Save Scenario', 'ButtonPushedFcn', @(~,~) saveScenarioCallback(app.Figure));
uibutton(buttonGrid, 'Text', 'Load Scenario', 'ButtonPushedFcn', @(~,~) loadScenarioCallback(app.Figure));
uibutton(buttonGrid, 'Text', 'Load Default Demo', 'ButtonPushedFcn', @(~,~) loadDefaultDemoCallback(app.Figure));
right = uipanel(grid, 'Title', 'Export Notes');
rightGrid = uigridlayout(right, [1 1]);
uitextarea(rightGrid, 'Editable', 'off', 'Value', { ...
    'Stage 14 exports to Outputs/Stage14.', ...
    'Tables are written as CSV files.', ...
    'Sessions and selected cases are written as MAT files.', ...
    'The portfolio summary is written to Reports/Stage14PortfolioSummary.txt.'});
end

function control = addNumeric(parent, labelText, value)
uilabel(parent, 'Text', labelText);
control = uieditfield(parent, 'numeric', 'Value', value);
end

function control = addNumericNoLabel(parent, value)
control = uieditfield(parent, 'numeric', 'Value', value);
end

function control = addDropDown(parent, labelText, items, value)
uilabel(parent, 'Text', labelText);
control = uidropdown(parent, 'Items', items, 'Value', value);
end

function control = addDropDownNoLabel(parent, items, value)
control = uidropdown(parent, 'Items', items, 'Value', value);
end

function control = addCheckBox(parent, labelText, value)
uilabel(parent, 'Text', labelText);
control = uicheckbox(parent, 'Text', '', 'Value', value);
end

function [checkbox, minField, maxField, stepField] = addOptRow(parent, labelText, enabled, minValue, maxValue, stepValue, unitsText)
checkbox = uicheckbox(parent, 'Text', labelText, 'Value', enabled);
minField = uieditfield(parent, 'numeric', 'Value', minValue);
maxField = uieditfield(parent, 'numeric', 'Value', maxValue);
stepField = uieditfield(parent, 'numeric', 'Value', stepValue);
uilabel(parent, 'Text', unitsText);
end

function runSingleCallback(fig)
app = beginCallback(fig);
try
    app = setRunControlsEnabled(app, false);
    app = updateProgress(app, 0.05, "Initializing vehicle parameters...");
    [validInputs, validationMessages] = validateStage14Inputs(app);
    if ~validInputs
        error('Stage14:InvalidInputs', '%s', strjoin(cellstr(validationMessages), newline));
    end
    app = readControls(app);
    app = updateProgress(app, 0.20, "Running trajectory solver...");
    [vehicle, constants, cfg] = makeStage11Config(app, 1);
    r = runSingleTrajectory(vehicle, constants, cfg);
    r.stage = 11;
    r.config = cfg;
    app = updateProgress(app, 0.70, "Processing aerodynamic data...");
    [r.keyEvents, r.keyEventTable] = computeKeyEventsStage14(r);
    r.designScore = computeDesignScoreStage14(r, "Balanced");
    app.State.Results.single = r;
    app.State.lastRunType = 'Single Trajectory';
    T = singleSummaryTable(r);
    app.SingleTable.Data = T;
    app = updateStage14Tables(app, 'SingleTrajectorySummary', T);
    app = updateProgress(app, 0.84, "Generating plots...");
    app = updateStage14Plots(app, 'single', r);
    app = updateMainPlot(app, app.MainPlotDropDown.Value, r);
    app = updateHomeMetrics(app, r, true);
    app.EngineeringInsightsArea.Value = generateEngineeringInsights(r, vehicle, constants);
    app = updateRiskDashboardStage14(app, r, "Balanced");
    warnings = getWarnings(r);
    if strcmpi(cfg.dofMode, '6DOF')
        app.DofModeLabel.Text = '6-DOF mode active';
        if ~is6DofValidated(app)
            warnings = [warnings, {'Warning: 6-DOF mode is experimental. Validate before using results.'}]; %#ok<AGROW>
        end
    else
        app.DofModeLabel.Text = '3-DOF mode active';
    end
    app = displayStage14Warnings(app, warnings, true);
    app = updateProgress(app, 1.0, "Simulation complete.");
catch ME
    app = updateProgress(app, 0, "Simulation failed.");
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Single trajectory failed');
end
app = setRunControlsEnabled(app, true);
finishCallback(fig, app);
end

function refreshMainPlotCallback(fig)
app = beginCallback(fig);
try
    if isfield(app.State, 'Results') && isfield(app.State.Results, 'single')
        app = updateMainPlot(app, app.MainPlotDropDown.Value, app.State.Results.single);
    end
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function saveCurrentRunCallback(fig)
app = beginCallback(fig);
try
    app = saveCurrentRun(app);
    if isfield(app, 'ResultsComparisonTable') && isvalid(app.ResultsComparisonTable)
        app.ResultsComparisonTable.Data = app.State.Tables.SavedRunComparison;
    end
    if isfield(app.State, 'Results') && isfield(app.State.Results, 'single')
        app = updateMainPlot(app, app.MainPlotDropDown.Value, app.State.Results.single);
    end
    app = displayStage14Warnings(app, "Current run saved for comparison.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function clearSavedRunsCallback(fig)
app = beginCallback(fig);
app.State.savedRuns = struct([]);
app.State.savedRunCounter = 0;
app = updateComparisonTable(app);
if isfield(app, 'ResultsComparisonTable') && isvalid(app.ResultsComparisonTable)
    app.ResultsComparisonTable.Data = app.State.Tables.SavedRunComparison;
end
if isfield(app.State, 'Results') && isfield(app.State.Results, 'single')
    app = updateMainPlot(app, app.MainPlotDropDown.Value, app.State.Results.single);
end
app = displayStage14Warnings(app, "Saved comparison runs cleared.", true);
finishCallback(fig, app);
end

function exportResultsCSVCallback(fig)
app = beginCallback(fig);
try
    file = exportResultsCSV(app, app.State.Results.single);
    app = displayStage14Warnings(app, "Results CSV exported: " + string(file), true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function exportSummaryCSVCallback(fig)
app = beginCallback(fig);
try
    file = exportSummaryMetricsStage14(app, app.State.Results.single);
    app = displayStage14Warnings(app, "Summary CSV exported: " + string(file), true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function exportPlotPNGCallback(fig)
app = beginCallback(fig);
try
    file = exportPlotPNG(app);
    app = displayStage14Warnings(app, "Plot PNG exported: " + string(file), true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function resetMainPlotViewCallback(fig)
app = beginCallback(fig);
try
    if isfield(app, 'SingleAxes') && ~isempty(app.SingleAxes) && isvalid(app.SingleAxes(1))
        axis(app.SingleAxes(1), 'auto');
    end
    app = displayStage14Warnings(app, "Main plot view reset.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function run6DOFDebugCallback(fig)
app = beginCallback(fig);
try
    app = readControls(app);
    [vehicle, constants, cfg] = makeStage11Config(app, 1);
    cfg.outputRoot = fullfile(app.State.outputRoot, 'Stage11Backend', 'Debug6DOF');
    cfg.figureVisible = 'off';
    cfg.verbose = true;
    cfg.launchSpeed_mps = app.State.launch.initialSpeed_mps;
    cfg.launchAngle_deg = app.State.launch.launchAngle_deg;
    cfg.launchYaw_deg = app.State.launch.yawAngle_deg;
    cfg.initialAltitude_m = app.State.launch.initialAltitude_m;
    debug = debug6DOF_stage11(vehicle, constants, cfg);
    app.State.Results.debug6DOF = debug;
    app.State.lastRunType = '6-DOF Debug Check';
    app.ValidationTable.Data = debug.summaryTable;
    app.SingleTable.Data = debug.summaryTable;
    app = updateStage14Tables(app, 'Debug6DOFSummary', debug.summaryTable);
    app = updateStage14Tables(app, 'Debug6DOFVacuumErrors', debug.vacuumErrorTable);
    app = updateStage14Tables(app, 'Debug6DOFTranslationComparison', debug.translationComparisonTable);
    app.DofModeLabel.Text = '6-DOF mode active';
    if debug.vacuumValidationPassed && debug.translationClose
        msg = "6-DOF debug check passed. Vacuum validation and 3-DOF equivalent comparison are within tolerance.";
    elseif debug.vacuumValidationPassed
        msg = "6-DOF vacuum validation passed, but the 3-DOF equivalent comparison needs review.";
    else
        msg = "Warning: 6-DOF debug check failed. Validate before using 6-DOF results.";
    end
    app = displayStage14Warnings(app, msg, debug.vacuumValidationPassed && debug.translationClose);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, '6-DOF debug check failed');
end
finishCallback(fig, app);
end

function runAngleSweepCallback(fig)
app = beginCallback(fig);
try
    app = readControls(app);
    [vehicle, constants, cfg] = makeStage11Config(app, 2);
    cfg.launchAngles_deg = app.SweepMinField.Value:app.SweepStepField.Value:app.SweepMaxField.Value;
    r = runAngleSweep(vehicle, constants, cfg);
    app.State.Results.angleSweep = r;
    app.State.lastRunType = 'Angle Sweep';
    T = angleSweepTable(r);
    T = standardizeCaseTableStage14(T, "AngleSweep");
    r.summaryTable = T;
    app.AngleTable.Data = T;
    app = updateStage14Tables(app, 'AngleSweep', T);
    app = updateStage14Plots(app, 'angle', r);
    app = updateAngleBestLabel(app, T);
    app = displayStage14Warnings(app, getWarnings(r), ~r.failed);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Angle sweep failed');
end
finishCallback(fig, app);
end

function runValidationCallback(fig)
app = beginCallback(fig);
try
    app = readControls(app);
    cfg = makeStage12Config(app, 1);
    r = runStage12(app.State.vehicle, app.State.constants, cfg);
    app.State.Results.validation = r;
    app.State.lastRunType = 'Stage 12 Validation';
    app.ValidationTable.Data = r.validation.summaryTable;
    app = updateStage14Tables(app, 'ValidationResults', r.validation.summaryTable);
    app = displayStage14Warnings(app, "Validation completed.", r.validation.passRate >= 0.8);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Validation failed');
end
finishCallback(fig, app);
end

function runStageComparisonCallback(fig)
app = beginCallback(fig);
try
    app = readControls(app);
    cfg = makeStage12Config(app, 2);
    r = runStage12(app.State.vehicle, app.State.constants, cfg);
    app.State.Results.stageComparison = r;
    app.State.lastRunType = 'Stage Comparison / Diagnostics';
    app.ValidationTable.Data = r.stageComparison.summaryTable;
    app = updateStage14Tables(app, 'StageComparison', r.stageComparison.summaryTable);
    if isfield(r, 'physicsDiagnostics')
        app = updateStage14Tables(app, 'PhysicsDiagnostics', r.physicsDiagnostics.summaryTable);
    end
    app = updateStage14Plots(app, 'validation', r);
    app = displayStage14Warnings(app, "Stage comparison completed.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Stage comparison failed');
end
finishCallback(fig, app);
end

function runRegressionCallback(fig)
app = beginCallback(fig);
try
    app = readControls(app);
    cfg = makeStage12Config(app, 3);
    r = runStage12(app.State.vehicle, app.State.constants, cfg);
    app.ValidationTable.Data = r.regression.summaryTable;
    app = updateStage14Tables(app, 'RegressionTests', r.regression.summaryTable);
    app = displayStage14Warnings(app, "Regression tests completed.", r.regression.passRate >= 0.8);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Regression failed');
end
finishCallback(fig, app);
end

function runPhysicsDiagnosticsCallback(fig)
app = beginCallback(fig);
try
    app = readControls(app);
    cfg = makeStage12Config(app, 7);
    r = runStage12(app.State.vehicle, app.State.constants, cfg);
    app.ValidationTable.Data = r.physicsDiagnostics.summaryTable;
    app = updateStage14Tables(app, 'PhysicsDiagnostics', r.physicsDiagnostics.summaryTable);
    app = updateStage14Plots(app, 'validation', r);
    app = displayStage14Warnings(app, "Physics diagnostics completed.", ~any(r.physicsDiagnostics.summaryTable.PhysicsError));
catch ME
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Physics diagnostics failed');
end
finishCallback(fig, app);
end

function runVerificationValidationCallback(fig)
app = beginCallback(fig);
try
    app = setRunControlsEnabled(app, false);
    app = readControls(app);
    app = updateProgress(app, 0.05, "Running verification and validation diagnostics...");
    [vehicle, constants, cfg] = makeStage11Config(app, 1);
    cfg.physicsDiagnosticAngles_deg = app.State.physics.angleMin_deg:app.State.physics.angleStep_deg:app.State.physics.angleMax_deg;
    vv = runVerificationValidationStage14(vehicle, constants, cfg);
    app.State.Results.verification = vv;
    app.State.lastRunType = 'Verification & Validation';
    app.VerificationTable.Data = vv.summaryTable;
    app.VerificationInsightsArea.Value = vv.explanation;
    app = updateStage14Tables(app, 'VerificationValidationChecks', vv.summaryTable);
    app = updateStage14Tables(app, 'VerificationDiagnosticSummary', vv.diagnosticSummaryTable);
    app = updateStage14Tables(app, 'VerificationAnalyticalComparison', vv.analyticalComparison);
    app = plotVerificationValidationStage14(app, vv);
    passed = ~any(strcmpi(string(vv.summaryTable.PassFail), "FAIL"));
    app = updateProgress(app, 1.0, "Verification and validation diagnostics complete.");
    app = displayStage14Warnings(app, "Verification & Validation diagnostics completed.", passed);
catch ME
    app = updateProgress(app, 0, "Verification and validation failed.");
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Verification & Validation failed');
end
app = setRunControlsEnabled(app, true);
finishCallback(fig, app);
end

function exportVerificationCSVCallback(fig)
app = beginCallback(fig);
try
    if ~isfield(app.State.Results, 'verification')
        error('Run Verification & Validation before exporting.');
    end
    vv = app.State.Results.verification;
    base = ['Stage14Verification_', datestr(now, 'yyyymmdd_HHMMSS')];
    writetable(vv.summaryTable, fullfile(app.State.tableDir, [base, '_Checks.csv']));
    writetable(vv.diagnosticSummaryTable, fullfile(app.State.tableDir, [base, '_DiagnosticSummary.csv']));
    writetable(vv.analyticalComparison, fullfile(app.State.tableDir, [base, '_AnalyticalComparison.csv']));
    app = displayStage14Warnings(app, "Verification CSV files exported.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function modelFidelityChangedCallback(fig)
app = beginCallback(fig);
try
    app = readControls(app);
    assumptions = buildAssumptionsListStage14(app.ModelFidelityDropDown.Value, app.State);
    app.State.assumptions = assumptions;
    app.AssumptionsIncludedTable.Data = assumptions.includedTable;
    app.AssumptionsNotIncludedTable.Data = assumptions.notIncludedTable;
    app.ModelLimitationsArea.Value = assumptions.limitationsText;
    app = updateStage14Tables(app, 'AssumptionsIncluded', assumptions.includedTable);
    app = updateStage14Tables(app, 'AssumptionsNotIncluded', assumptions.notIncludedTable);
    app = displayStage14Warnings(app, "Assumptions updated for " + string(app.ModelFidelityDropDown.Value) + ".", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function runConstraintEnvelopeCallback(fig)
app = beginCallback(fig);
try
    app = setRunControlsEnabled(app, false);
    app = readControls(app);
    app = updateProgress(app, 0.10, "Running baseline trajectory for constraint envelope...");
    [vehicle, constants, cfg] = makeStage11Config(app, 1);
    r = runSingleTrajectory(vehicle, constants, cfg);
    r.stage = 11;
    r.config = cfg;
    app.State.Results.single = r;
    app.SingleTable.Data = singleSummaryTable(r);
    app = updateProgress(app, 0.65, "Computing constraint margins...");
    constraint = computeConstraintMarginsStage14(r, app.State.constraints);
    app.State.Results.constraintEnvelope = constraint;
    app.ConstraintTable.Data = constraint.table;
    app.ConstraintInsightsArea.Value = cellstr(string(constraint.table.Message));
    app = updateStage14Tables(app, 'ConstraintEnvelope', constraint.table);
    app = plotConstraintEnvelopeStage14(app, r, app.State.constraints);
    app = updateProgress(app, 1.0, "Constraint envelope complete.");
    app = displayStage14Warnings(app, "Constraint envelope completed. Violations: " + string(constraint.violationSummary), constraint.allPassed);
catch ME
    app = updateProgress(app, 0, "Constraint envelope failed.");
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Constraint envelope failed');
end
app = setRunControlsEnabled(app, true);
finishCallback(fig, app);
end

function exportConstraintCSVCallback(fig)
app = beginCallback(fig);
try
    if ~isfield(app.State.Results, 'constraintEnvelope')
        error('Run Constraint Check before exporting.');
    end
    file = fullfile(app.State.tableDir, ['Stage14ConstraintEnvelope_', datestr(now, 'yyyymmdd_HHMMSS'), '.csv']);
    writetable(app.State.Results.constraintEnvelope.table, file);
    app = displayStage14Warnings(app, "Constraint CSV exported: " + string(file), true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function runOptimizationGridCallback(fig)
app = beginCallback(fig);
try
    app = setRunControlsEnabled(app, false);
    app = readControls(app);
    app = updateProgress(app, 0.03, "Starting grid optimization...");
    [vehicle, constants, cfg] = makeStage11Config(app, 1);
    opt = runOptimizationGridSearchStage14(vehicle, constants, cfg, app.State.optimizationMode, ...
        app.State.constraints, @(fraction, message) updateCallbackProgress(fig, fraction, message));
    app.State.Results.optimizationMode = opt;
    app.State.lastRunType = 'Optimization Mode';
    app.OptimizationGridTable.Data = opt.rankedTable;
    app.OptimizationStatusArea.Value = {opt.statusMessage};
    app = updateStage14Tables(app, 'OptimizationGrid', opt.rankedTable);
    app = plotOptimizationResultsStage14(app, opt);
    if opt.numFeasibleCases > 0
        app.ApplyBestDesignButton.Enable = 'on';
    else
        app.ApplyBestDesignButton.Enable = 'off';
    end
    app = displayStage14Warnings(app, opt.statusMessage, opt.numFeasibleCases > 0);
catch ME
    app = updateProgress(app, 0, "Grid optimization failed.");
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Grid optimization failed');
end
app = setRunControlsEnabled(app, true);
finishCallback(fig, app);
end

function applyBestDesignCallback(fig)
app = beginCallback(fig);
try
    if ~isfield(app.State.Results, 'optimizationMode') || isempty(app.State.Results.optimizationMode.bestCaseSpec)
        error('Run Optimization Mode and find a feasible best case before applying.');
    end
    spec = app.State.Results.optimizationMode.bestCaseSpec;
    app = applyCaseSpecToState(app, spec);
    finishCallback(fig, app);
    refreshControlsFromState(fig);
    app = fig.UserData;
    app = displayStage14Warnings(app, "Best optimization design applied to the baseline inputs.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function exportOptimizationGridCSVCallback(fig)
app = beginCallback(fig);
try
    if ~isfield(app.State.Results, 'optimizationMode')
        error('Run Grid Optimization before exporting.');
    end
    file = fullfile(app.State.tableDir, ['Stage14OptimizationGrid_', datestr(now, 'yyyymmdd_HHMMSS'), '.csv']);
    writetable(app.State.Results.optimizationMode.rankedTable, file);
    app = displayStage14Warnings(app, "Optimization CSV exported: " + string(file), true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function runUncertaintyBandsCallback(fig)
app = beginCallback(fig);
try
    app = setRunControlsEnabled(app, false);
    app = readControls(app);
    app = updateProgress(app, 0.03, "Running uncertainty perturbation cases...");
    [vehicle, constants, cfg] = makeStage11Config(app, 1);
    unc = computeUncertaintyBandsStage14(vehicle, constants, cfg, app.State.uncertainty, ...
        @(fraction, message) updateCallbackProgress(fig, fraction, message));
    app.State.Results.uncertainty = unc;
    app.State.lastRunType = 'Uncertainty Bands';
    app.UncertaintyTable.Data = unc.summaryTable;
    app.UncertaintyInsightsArea.Value = unc.insights;
    app = updateStage14Tables(app, 'UncertaintySummary', unc.summaryTable);
    app = updateStage14Tables(app, 'UncertaintyCases', unc.caseTable);
    app = plotUncertaintyBandsStage14(app, unc);
    app = displayStage14Warnings(app, "Uncertainty bands completed without overwriting baseline inputs.", true);
catch ME
    app = updateProgress(app, 0, "Uncertainty bands failed.");
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Uncertainty bands failed');
end
app = setRunControlsEnabled(app, true);
finishCallback(fig, app);
end

function exportUncertaintyCSVCallback(fig)
app = beginCallback(fig);
try
    if ~isfield(app.State.Results, 'uncertainty')
        error('Run Uncertainty Bands before exporting.');
    end
    base = ['Stage14Uncertainty_', datestr(now, 'yyyymmdd_HHMMSS')];
    writetable(app.State.Results.uncertainty.summaryTable, fullfile(app.State.tableDir, [base, '_Summary.csv']));
    writetable(app.State.Results.uncertainty.caseTable, fullfile(app.State.tableDir, [base, '_Cases.csv']));
    app = displayStage14Warnings(app, "Uncertainty CSV files exported.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function refreshTutorialCallback(fig)
app = beginCallback(fig);
try
    tutorial = generateTutorialContentStage14();
    app.State.Results.tutorial = tutorial;
    if isfield(app, 'TutorialTable') && isvalid(app.TutorialTable)
        app.TutorialTable.Data = tutorial.table;
    end
    if isfield(app, 'TutorialTextArea') && isvalid(app.TutorialTextArea)
        app.TutorialTextArea.Value = tutorial.text;
    end
    if isfield(app, 'TabGroup') && isfield(app, 'TutorialTab') && isvalid(app.TutorialTab)
        app.TabGroup.SelectedTab = app.TutorialTab;
    end
    app = updateStage14Tables(app, 'TutorialContent', tutorial.table);
    app = displayStage14Warnings(app, "Tutorial content refreshed.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function runMonteCarloCallback(fig)
app = beginCallback(fig);
try
    app = setRunControlsEnabled(app, false);
    app = readControls(app);
    app = updateProgress(app, 0.02, "Preparing Monte Carlo study...");
    config = makeStage13Config(app);
    config.progressCallback = @(fraction, message) updateCallbackProgress(fig, fraction, message);
    mc = runMonteCarloStudy(config);
    app = updateProgress(app, 0.90, "Standardizing Monte Carlo results...");
    app.State.Results.monteCarlo = mc;
    app.State.lastRunType = 'Monte Carlo';
    T = standardizeCaseTableStage14(mc.summaryTable, "MonteCarlo");
    mc.summaryTable = T;
    app.MonteCarloTable.Data = T;
    app = updateProgress(app, 0.95, "Updating Monte Carlo tables and plots...");
    app = updateStage14Tables(app, 'MonteCarloCases', T);
    app = updateStage14Tables(app, 'MonteCarloSummary', mc.statistics);
    app = updateStage14Plots(app, 'montecarlo', mc);
    app = updateProgress(app, 1.0, "Monte Carlo complete.");
    app = displayStage14Warnings(app, "Monte Carlo completed.", true);
catch ME
    app = updateProgress(app, 0, "Monte Carlo failed.");
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Monte Carlo failed');
end
app = setRunControlsEnabled(app, true);
finishCallback(fig, app);
end

function runOptimizationCallback(fig)
app = beginCallback(fig);
try
    app = readControls(app);
    config = makeStage13Config(app);
    studyType = app.StudyTypeDropDown.Value;
    if contains(studyType, 'launch')
        opt = runConstraintStudy(config, 'launch');
    elseif contains(studyType, 'geometry')
        opt = runConstraintStudy(config, 'geometry');
    else
        opt = runDesignOptimization(config);
    end
    app.State.Results.optimization = opt;
    T = standardizeCaseTableStage14(opt.summaryTable, "Optimization");
    opt.summaryTable = T;
    app.ParetoTable.Data = T;
    app = updateStage14Tables(app, 'OptimizationResults', T);
    app = updateStage14Plots(app, 'pareto', struct('summaryTable', T));
    app = displayStage14Warnings(app, "Optimization completed.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Optimization failed');
end
finishCallback(fig, app);
end

function runParetoCallback(fig)
app = beginCallback(fig);
try
    app = setRunControlsEnabled(app, false);
    app = readControls(app);
    app = updateProgress(app, 0.02, "Preparing Pareto study...");
    config = makeStage13Config(app);
    config.progressCallback = @(fraction, message) updateCallbackProgress(fig, fraction, message);
    pareto = runParetoStudy(config);
    app = updateProgress(app, 0.90, "Standardizing Pareto designs...");
    pareto.summaryTable = standardizeCaseTableStage14(pareto.summaryTable, "Pareto");
    app.State.Results.pareto = pareto;
    app.State.lastRunType = 'Pareto Study';
    app.ParetoTable.Data = pareto.summaryTable;
    app = updateProgress(app, 0.95, "Updating Pareto tables and plots...");
    app = updateStage14Plots(app, 'pareto', pareto);
    if isfield(app.State.Tables, 'ParetoDesigns')
        app.ParetoTable.Data = app.State.Tables.ParetoDesigns;
    end
    app = updateProgress(app, 1.0, "Pareto study complete.");
    app = displayStage14Warnings(app, "Pareto study completed.", true);
catch ME
    app = updateProgress(app, 0, "Pareto study failed.");
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Pareto failed');
end
app = setRunControlsEnabled(app, true);
finishCallback(fig, app);
end

function runDOECallback(fig)
app = beginCallback(fig);
try
    app = readControls(app);
    config = makeStage13Config(app);
    doe = runDesignOfExperiments(config);
    app.State.Results.doe = doe;
    T = standardizeCaseTableStage14(doe.summaryTable, "DOE");
    doe.summaryTable = T;
    app.ParetoTable.Data = T;
    app = updateStage14Tables(app, 'DOE', T);
    app = updateStage14Plots(app, 'pareto', struct('summaryTable', T));
    app = displayStage14Warnings(app, "DOE completed.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'DOE failed');
end
finishCallback(fig, app);
end

function generateStage11ReportCallback(fig)
app = beginCallback(fig);
try
    app = readControls(app);
    [vehicle, constants, cfg] = makeStage11Config(app, 1);
    cfg.generateReport = true;
    cfg.exportResults = true;
    r = runStage11(vehicle, constants, cfg);
    app.State.Results.single = r;
    app = displayStage14Warnings(app, "Stage 11 report generated.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function generateStage12ReportCallback(fig)
app = beginCallback(fig);
try
    cfg = makeStage12Config(app, 5);
    runStage12(app.State.vehicle, app.State.constants, cfg);
    app = displayStage14Warnings(app, "Stage 12 report generated.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function generateStage13ReportCallback(fig)
app = beginCallback(fig);
try
    config = makeStage13Config(app);
    opt = runDesignOptimization(config);
    generateStage13Report(struct('optimization', opt), config);
    app = displayStage14Warnings(app, "Stage 13 report generated.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function generateReportCallback(fig)
createPortfolioSummaryCallback(fig);
end

function createPortfolioSummaryCallback(fig)
app = beginCallback(fig);
try
    file = createStage14PortfolioSummary(app.State);
    app = displayStage14Warnings(app, "Portfolio summary written: " + string(file), true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function exportSessionCallback(fig)
app = beginCallback(fig);
try
    info = exportStage14Session(app);
    app = displayStage14Warnings(app, "Session exported: " + string(info.sessionFile), true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function saveScenarioCallback(fig)
app = beginCallback(fig);
try
    app = readControls(app);
    file = saveStage14Scenario(app.State);
    app = displayStage14Warnings(app, "Scenario saved: " + string(file), true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function loadScenarioCallback(fig)
app = beginCallback(fig);
try
    [file, path] = uigetfile('*.mat', 'Load Stage 14 Scenario', app.State.sessionDir);
    if isequal(file, 0)
        finishCallback(fig, app);
        return;
    end
    app.State = loadStage14Scenario(app.State, fullfile(path, file));
    finishCallback(fig, app);
    refreshControlsFromState(fig);
    app = fig.UserData;
    app = displayStage14Warnings(app, "Scenario loaded.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function loadDefaultDemoCallback(fig)
app = beginCallback(fig);
app.State = buildStage14DefaultState(struct(), app.State.constants);
finishCallback(fig, app);
refreshControlsFromState(fig);
end

function applyGuidedBuilderCallback(fig)
app = beginCallback(fig);
try
    app = readControls(app);
    app.State.vehicle = guidedVehiclePresetStage14(app.BuilderBodyDropDown.Value, ...
        app.BuilderMissionDropDown.Value, app.BuilderLaunchDropDown.Value, app.State.vehicle);
    app.State.launch.initialSpeed_mps = app.State.vehicle.V0;
    finishCallback(fig, app);
    refreshControlsFromState(fig);
    app = fig.UserData;
    app = updateVehiclePreviewStage14(app);
    app = displayStage14Warnings(app, "Guided vehicle preset applied. Manual overrides remain available in Vehicle Setup.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function resetDefaultsCallback(fig)
app = beginCallback(fig);
try
    app.State = buildStage14DefaultState(struct(), app.State.constants);
    finishCallback(fig, app);
    refreshControlsFromState(fig);
    app = fig.UserData;
    app = updateVehiclePreviewStage14(app);
    app = displayStage14Warnings(app, "Stage 14 defaults restored.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function runScenarioCompareCallback(fig)
app = beginCallback(fig);
try
    app = setRunControlsEnabled(app, false);
    app = readControls(app);
    app = updateProgress(app, 0.02, "Preparing scenario comparison...");
    [vehicle, constants, cfg] = makeStage11Config(app, 1);
    missionGoal = string(app.CompareMissionDropDown.Value);
    compare = runScenarioSweepStage14(vehicle, constants, cfg, ...
        app.CompareSweepDropDown.Value, missionGoal, app.CompareManualTextArea.Value, ...
        @(fraction, message) updateCallbackProgress(fig, fraction, message));
    app.State.Results.scenarioCompare = compare;
    app.State.lastRunType = 'Scenario Compare';
    app.CompareTable.Data = compare.summaryTable;
    app.CompareInsightsArea.Value = compare.insights;
    app = updateStage14Tables(app, 'ScenarioCompare', compare.summaryTable);
    app = plotScenarioCompareStage14(app, compare);
    [app, bestIndex] = highlightBestScenarioCaseStage14(app, missionGoal);
    if bestIndex >= 1 && bestIndex <= numel(compare.caseResults)
        app = updateRiskDashboardStage14(app, compare.caseResults{bestIndex}, missionGoal);
    end
    app = updateProgress(app, 1.0, "Scenario comparison complete.");
    app = displayStage14Warnings(app, "Scenario Compare completed. Best case is highlighted using the selected mission goal.", true);
catch ME
    app = updateProgress(app, 0, "Scenario Compare failed.");
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Scenario Compare failed');
end
app = setRunControlsEnabled(app, true);
finishCallback(fig, app);
end

function scenarioMissionChangedCallback(fig)
app = beginCallback(fig);
try
    [app, bestIndex] = highlightBestScenarioCaseStage14(app, app.CompareMissionDropDown.Value);
    if isfield(app.State, 'Results') && isfield(app.State.Results, 'scenarioCompare') && bestIndex >= 1
        compare = app.State.Results.scenarioCompare;
        if bestIndex <= numel(compare.caseResults)
            app = updateRiskDashboardStage14(app, compare.caseResults{bestIndex}, app.CompareMissionDropDown.Value);
        end
    end
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function sortScenarioCompareCallback(fig)
app = beginCallback(fig);
try
    T = app.CompareTable.Data;
    field = app.CompareSortDropDown.Value;
    if istable(T) && height(T) > 0 && any(strcmp(T.Properties.VariableNames, field))
        direction = 'descend';
        if any(strcmp(field, {'MaxDynamicPressure_kPa','MaxStagTemp_K','TimeToImpact_s'}))
            direction = 'ascend';
        end
        T = sortrows(T, field, direction);
        app.CompareTable.Data = T;
        app = updateStage14Tables(app, 'ScenarioCompare', T);
        app = highlightBestScenarioCaseStage14(app, app.CompareMissionDropDown.Value);
    end
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function compareTableSelectionCallback(fig, src, event)
app = beginCallback(fig);
try
    if isempty(event.Indices)
        finishCallback(fig, app);
        return;
    end
    rowIdx = event.Indices(1);
    T = src.Data;
    if istable(T) && rowIdx >= 1 && rowIdx <= height(T)
        sourceInfo = struct('sourceTableName', 'ScenarioCompare', ...
            'statusMessage', "Selected scenario compare case.");
        app = updateSelectedCaseEverywhereStage14(app, T(rowIdx, :), sourceInfo);
    end
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function exportScenarioCompareCSVCallback(fig)
app = beginCallback(fig);
try
    T = app.CompareTable.Data;
    if ~istable(T) || height(T) == 0
        error('Run Scenario Compare before exporting the comparison CSV.');
    end
    file = fullfile(app.State.tableDir, ['Stage14ScenarioCompare_', datestr(now, 'yyyymmdd_HHMMSS'), '.csv']);
    writetable(T, file);
    app = displayStage14Warnings(app, "Scenario comparison CSV exported: " + string(file), true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function runSensitivityCallback(fig)
app = beginCallback(fig);
try
    app = setRunControlsEnabled(app, false);
    app = readControls(app);
    app = updateProgress(app, 0.02, "Preparing sensitivity analysis...");
    [vehicle, constants, cfg] = makeStage11Config(app, 1);
    sensitivity = computeSensitivityAnalysisStage14(vehicle, constants, cfg, ...
        app.SensitivityPerturbField.Value, @(fraction, message) updateCallbackProgress(fig, fraction, message));
    app.State.Results.sensitivity = sensitivity;
    app.State.lastRunType = 'Sensitivity Analysis';
    app.SensitivityTable.Data = sensitivity.rankedTable;
    app.SensitivityInsightsArea.Value = sensitivity.insights;
    app = updateStage14Tables(app, 'SensitivityAnalysis', sensitivity.rankedTable);
    app = plotSensitivityStage14(app, sensitivity);
    app = updateProgress(app, 1.0, "Sensitivity analysis complete.");
    app = displayStage14Warnings(app, "Sensitivity analysis completed without overwriting baseline inputs.", true);
catch ME
    app = updateProgress(app, 0, "Sensitivity analysis failed.");
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Sensitivity analysis failed');
end
app = setRunControlsEnabled(app, true);
finishCallback(fig, app);
end

function exportSensitivityCSVCallback(fig)
app = beginCallback(fig);
try
    T = app.SensitivityTable.Data;
    if ~istable(T) || height(T) == 0
        error('Run Sensitivity Analysis before exporting the sensitivity CSV.');
    end
    file = fullfile(app.State.tableDir, ['Stage14Sensitivity_', datestr(now, 'yyyymmdd_HHMMSS'), '.csv']);
    writetable(T, file);
    app = displayStage14Warnings(app, "Sensitivity CSV exported: " + string(file), true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function exportEngineeringReportCallback(fig)
app = beginCallback(fig);
try
    info = exportStage14Report(app);
    app = displayStage14Warnings(app, "Engineering HTML report exported: " + string(info.htmlFile), true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
    safeAlert(fig, ME.message, 'Report export failed');
end
finishCallback(fig, app);
end

function exportSelectedCaseCallback(fig)
app = beginCallback(fig);
try
    files = exportSelectedCase(app);
    if files.csvFile == ""
        app = displayStage14Warnings(app, "No selected case to export.", false);
    else
        app = displayStage14Warnings(app, "Selected case exported: " + files.csvFile, true);
    end
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function jumpToCaseCallback(fig)
app = beginCallback(fig);
try
    caseId = string(app.CaseIdField.Value);
    if isfield(app, 'StatusLabel') && isvalid(app.StatusLabel)
        app.StatusLabel.Text = char("Searching CaseID: " + strtrim(caseId));
        app.StatusLabel.FontColor = [0.15 0.15 0.15];
    end
    drawnow;
    [row, sourceTableName, found, info] = findCaseByIDStage14(app, caseId);
    if found
        sourceInfo = struct();
        sourceInfo.sourceTableName = sourceTableName;
        sourceInfo.statusMessage = "Found CaseID in table: " + sourceTableName;
        app = updateSelectedCaseEverywhereStage14(app, row, sourceInfo);
        [app, highlighted] = highlightSelectedCaseOnPlotsStage14(app, row, sourceInfo);
        if isfield(app, 'StatusLabel') && isvalid(app.StatusLabel)
            if highlighted
                app.StatusLabel.Text = char("Selected CaseID: " + string(row.CaseID(1)));
            else
                app.StatusLabel.Text = char("Selected CaseID: " + string(row.CaseID(1)) + " (not visible on current plot)");
            end
            app.StatusLabel.FontColor = [0.0 0.45 0.2];
        end
    else
        message = "CaseID not found: " + strtrim(caseId);
        app = updateSelectedCaseEverywhereStage14(app, table(), struct('statusMessage', message));
        if isfield(app, 'StatusLabel') && isvalid(app.StatusLabel)
            app.StatusLabel.Text = char(message);
            app.StatusLabel.FontColor = [0.65 0.1 0.1];
        end
        if isfield(info, 'messages') && ~isempty(info.messages)
            fprintf('%s\n', info.messages(end));
        end
    end
catch ME
    message = "CaseID search failed: " + string(ME.message);
    app = displayStage14Warnings(app, message, false);
    finishCallback(fig, app);
    return;
end
finishCallback(fig, app);
end

function showSelectedTableCallback(fig)
app = beginCallback(fig);
name = app.CurrentTableDropDown.Value;
if isfield(app.State.Tables, name)
    app.ResultsTable.Data = app.State.Tables.(name);
end
finishCallback(fig, app);
end

function openCurrentTableCallback(fig)
app = beginCallback(fig);
T = currentOrBestCaseTable(app);
if isempty(T)
    T = table();
end
openFullCaseTable(T, 'Stage 14 Table');
finishCallback(fig, app);
end

function openSelectedCaseCallback(fig)
app = beginCallback(fig);
try
    if isfield(app.State, 'selectedCase') && istable(app.State.selectedCase) && height(app.State.selectedCase) > 0
        openFullCaseTable(selectedCaseDetailTableStage14(app.State.selectedCase), 'Stage 14 Selected Case');
        app = displayStage14Warnings(app, "Selected case popup opened.", true);
    else
        app = displayStage14Warnings(app, "No case selected.", false);
    end
catch ME
    app = displayStage14Warnings(app, "Case selected, but details failed to update: " + string(ME.message), false);
end
finishCallback(fig, app);
end

function exportCurrentTableCallback(fig)
app = beginCallback(fig);
try
    name = app.CurrentTableDropDown.Value;
    if ~isfield(app.State.Tables, name)
        error('No current table is selected.');
    end
    file = fullfile(app.State.tableDir, [name, '_', datestr(now, 'yyyymmdd_HHMMSS'), '.csv']);
    writetable(app.State.Tables.(name), file);
    app = displayStage14Warnings(app, "Table exported: " + string(file), true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function exportAllTablesCallback(fig)
app = beginCallback(fig);
try
    names = fieldnames(app.State.Tables);
    for k = 1:numel(names)
        writetable(app.State.Tables.(names{k}), fullfile(app.State.tableDir, [names{k}, '.csv']));
    end
    app = displayStage14Warnings(app, "All tables exported.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function exportParetoCallback(fig)
app = beginCallback(fig);
try
    if isfield(app.State.Tables, 'ParetoDesigns')
        file = fullfile(app.State.tableDir, 'Stage14ParetoDesigns.csv');
        writetable(app.State.Tables.ParetoDesigns, file);
        app = displayStage14Warnings(app, "Pareto designs exported: " + string(file), true);
    else
        app = displayStage14Warnings(app, "Run a Pareto study first.", false);
    end
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function loadPresetCallback(fig)
app = beginCallback(fig);
try
    library = vehicleLibrary_stage11(app.State.vehicle);
    idx = find(strcmpi({library.bodyType}, app.BodyTypeDropDown.Value), 1);
    if isempty(idx)
        idx = numel(library);
    end
    app.State.vehicle = library(idx);
    finishCallback(fig, app);
    refreshControlsFromState(fig);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
    finishCallback(fig, app);
end
end

function validateVehicleCallback(fig)
app = beginCallback(fig);
try
    app = readControls(app);
    v = validateVehicleInputs(buildVehicleFromGeometry_stage11(app.State.vehicle, app.BodyTypeDropDown.Value));
    app.State.vehicle = v;
    app.VehicleInfoTable.Data = vehicleInfoTable(v);
    app = displayStage14Warnings(app, "Vehicle inputs validated.", true);
catch ME
    app = displayStage14Warnings(app, ME.message, false);
end
finishCallback(fig, app);
end

function setAnglePreset(fig, angle)
app = beginCallback(fig);
app.AngleField.Value = angle;
app.SweepMinField.Value = min(app.SweepMinField.Value, angle);
app.SweepMaxField.Value = max(app.SweepMaxField.Value, angle);
finishCallback(fig, app);
end

function setSweepEnvelope(fig, lo, hi)
app = beginCallback(fig);
app.SweepMinField.Value = lo;
app.SweepMaxField.Value = hi;
app.AngleMinField.Value = lo;
app.AngleMaxField.Value = hi;
finishCallback(fig, app);
end

function app = applyCaseSpecToState(app, spec)
if isfield(spec, 'LaunchAngle_deg') && isfinite(spec.LaunchAngle_deg)
    app.State.launch.launchAngle_deg = spec.LaunchAngle_deg;
    app.State.vehicle.launchAngle = spec.LaunchAngle_deg;
end
if isfield(spec, 'InitialVelocity_mps') && isfinite(spec.InitialVelocity_mps)
    app.State.launch.initialSpeed_mps = spec.InitialVelocity_mps;
    app.State.vehicle.V0 = spec.InitialVelocity_mps;
end
if isfield(spec, 'Mass_kg') && isfinite(spec.Mass_kg)
    app.State.vehicle.mass = spec.Mass_kg;
end
if isfield(spec, 'Diameter_m') && isfinite(spec.Diameter_m)
    app.State.vehicle.diameter = spec.Diameter_m;
end
if isfield(spec, 'Length_m') && isfinite(spec.Length_m)
    app.State.vehicle.length = spec.Length_m;
end
if isfield(spec, 'CdScale') && isfinite(spec.CdScale)
    app.State.vehicle.Cd_scale = spec.CdScale;
end
if isfield(spec, 'Alpha_deg') && isfinite(spec.Alpha_deg)
    app.State.vehicle.alpha_deg = spec.Alpha_deg;
end
if isfield(spec, 'StaticMargin_percent') && isfinite(spec.StaticMargin_percent)
    length_m = getField(app.State.vehicle, 'length', 0.45);
    cg_m = getField(app.State.vehicle, 'cgLocation_m', 0.5 * length_m);
    app.State.vehicle.cpLocation_m = cg_m + (spec.StaticMargin_percent / 100) * length_m;
end
app.State.vehicle.referenceArea = pi * max(app.State.vehicle.diameter, eps)^2 / 4;
app.State.vehicle.area = app.State.vehicle.referenceArea;
app.State.vehicle.finenessRatio = app.State.vehicle.length / max(app.State.vehicle.diameter, eps);
app.State.vehicle.fineness = app.State.vehicle.finenessRatio;
app.State.vehicle = buildVehicleFromGeometry_stage11(app.State.vehicle, app.State.vehicle.bodyType);
end

function app = beginCallback(fig)
app = fig.UserData;
if isempty(app)
    error('Stage14:AppStateMissing', 'Stage 14 app state is missing.');
end
drawnow;
end

function updateCallbackProgress(fig, fraction, message)
app = fig.UserData;
if isempty(app)
    return;
end
app = updateProgress(app, fraction, message);
fig.UserData = app;
end

function finishCallback(fig, app)
fig.UserData = app;
drawnow;
end

function app = setRunControlsEnabled(app, enabled)
if enabled
    state = 'on';
else
    state = 'off';
end
fields = {'RunSingleButton', 'RunMonteCarloButton', 'RunOptimizationButton', ...
    'RunParetoButton', 'RunDOEButton', 'HomeRunSingleButton', ...
    'HomeRunAngleButton', 'HomeRunValidationButton', ...
    'HomeRunMonteCarloButton', 'HomeRunParetoButton', ...
    'RunCompareButton', 'RunSensitivityButton', 'ApplyBuilderPresetButton', ...
    'ResetDefaultsButton', 'RunVerificationButton', 'RunConstraintEnvelopeButton', ...
    'RunOptimizationGridButton', 'ApplyBestDesignButton', 'RunUncertaintyButton'};
for k = 1:numel(fields)
    if isfield(app, fields{k}) && isvalid(app.(fields{k}))
        app.(fields{k}).Enable = state;
    end
end
if enabled && isfield(app, 'ApplyBestDesignButton') && isvalid(app.ApplyBestDesignButton)
    hasBest = isfield(app.State, 'Results') && isfield(app.State.Results, 'optimizationMode') && ...
        isfield(app.State.Results.optimizationMode, 'numFeasibleCases') && ...
        app.State.Results.optimizationMode.numFeasibleCases > 0;
    if hasBest
        app.ApplyBestDesignButton.Enable = 'on';
    else
        app.ApplyBestDesignButton.Enable = 'off';
    end
end
drawnow;
end

function app = readControls(app)
v = app.State.vehicle;
v.bodyType = app.BodyTypeDropDown.Value;
v.mass = app.MassField.Value;
v.length = app.LengthField.Value;
v.diameter = app.DiameterField.Value;
v.noseRadius_m = app.NoseRadiusField.Value;
v.cgLocation_m = app.CGField.Value;
v.cpLocation_m = app.CPField.Value;
v.referenceArea = app.ReferenceAreaField.Value;
v.area = v.referenceArea;
v.Cd_scale = app.CdMultiplierField.Value;
v.CL_scale = app.CLMultiplierField.Value;
v.hasFins = app.FinCheckbox.Value;
v.V0 = app.SpeedField.Value;
v.launchAngle = app.AngleField.Value;
if ~app.LiftCheckbox.Value
    v.alpha_deg = 0;
    v.CL_scale = 0;
else
    v.alpha_deg = getField(v, 'alpha_deg', 2.0);
end
v = buildVehicleFromGeometry_stage11(v, v.bodyType);
app.State.vehicle = v;

app.State.launch.initialSpeed_mps = app.SpeedField.Value;
app.State.launch.initialMach = app.InitialMachField.Value;
app.State.launch.launchAngle_deg = app.AngleField.Value;
app.State.launch.yawAngle_deg = app.YawField.Value;
app.State.launch.initialAltitude_m = app.InitialAltitudeField.Value;
app.State.launch.initialDownrange_m = app.InitialDownrangeField.Value;
app.State.launch.initialCrossrange_m = app.InitialCrossrangeField.Value;
app.State.launch.p_deg_s = app.PRateField.Value;
app.State.launch.q_deg_s = app.QRateField.Value;
app.State.launch.r_deg_s = app.RRateField.Value;

app.State.physics.dofMode = app.DofDropDown.Value;
app.State.physics.liftEnabled = app.LiftCheckbox.Value;
app.State.physics.dragEnabled = app.DragCheckbox.Value;
app.State.physics.windEnabled = app.WindCheckbox.Value;
app.State.physics.heatingEnabled = app.HeatingCheckbox.Value;
app.State.physics.stabilityEnabled = app.StabilityCheckbox.Value;
app.State.physics.earthCurvature = app.CurvatureCheckbox.Value;
app.State.physics.earthRotation = app.RotationCheckbox.Value;
app.State.physics.lowAltitudeConstraint = app.LowAltCheckbox.Value;
app.State.physics.angleEnvelope = app.EnvelopeDropDown.Value;
app.State.physics.angleMin_deg = app.AngleMinField.Value;
app.State.physics.angleMax_deg = app.AngleMaxField.Value;
app.State.physics.angleStep_deg = app.AngleStepField.Value;

app.State.monteCarlo.N = max(1, round(app.MCNField.Value));
app.State.monteCarlo.launchSpeedUncertainty_pct = app.MCSpeedUncField.Value;
app.State.monteCarlo.launchAngleUncertainty_deg = app.MCAngleUncField.Value;
app.State.monteCarlo.massUncertainty_pct = app.MCMassUncField.Value;
app.State.monteCarlo.cdUncertainty_pct = app.MCCdUncField.Value;
app.State.monteCarlo.clUncertainty_pct = app.MCClUncField.Value;
app.State.monteCarlo.densityUncertainty_pct = app.MCDensityUncField.Value;
app.State.monteCarlo.cgUncertainty_pct = app.MCCGUncField.Value;
app.State.monteCarlo.cpUncertainty_pct = app.MCCPUncField.Value;

app.State.optimization.studyType = app.StudyTypeDropDown.Value;
app.State.optimization.objective = app.ObjectiveDropDown.Value;
app.State.optimization.constraintProfile = app.ConstraintProfileDropDown.Value;

if isfield(app, 'BuilderBodyDropDown')
    app.State.builder.bodyType = app.BuilderBodyDropDown.Value;
    app.State.builder.missionGoal = app.BuilderMissionDropDown.Value;
    app.State.builder.launchMethod = app.BuilderLaunchDropDown.Value;
end
if isfield(app, 'CompareSweepDropDown')
    app.State.compare.sweepMode = app.CompareSweepDropDown.Value;
    app.State.compare.missionGoal = app.CompareMissionDropDown.Value;
end
if isfield(app, 'SensitivityPerturbField')
    app.State.sensitivity.perturbationPct = app.SensitivityPerturbField.Value;
end
if isfield(app, 'ModelFidelityDropDown')
    app.State.fidelity.stageName = app.ModelFidelityDropDown.Value;
end
if isfield(app, 'MaxQConstraintField')
    app.State.constraints.maxQ_kPa = app.MaxQConstraintField.Value;
    app.State.constraints.maxStagTemp_K = app.MaxStagTempConstraintField.Value;
    app.State.constraints.maxMach = app.MaxMachConstraintField.Value;
    app.State.constraints.maxGLoad = app.MaxGConstraintField.Value;
    app.State.constraints.minStaticMargin_percent = app.MinStaticMarginConstraintField.Value;
    app.State.constraints.maxAlpha_deg = app.MaxAlphaConstraintField.Value;
    app.State.constraints.maxDrag_N = app.MaxDragConstraintField.Value;
    app.State.constraints.maxLift_N = app.MaxLiftConstraintField.Value;
end
if isfield(app, 'OptObjectiveDropDown')
    app.State.optimizationMode.objective = app.OptObjectiveDropDown.Value;
    app.State.optimizationMode.maxCases = app.OptMaxCasesField.Value;
    app.State.optimizationMode.useAngle = app.OptUseAngleCheckbox.Value;
    app.State.optimizationMode.angleMin = app.OptAngleMinField.Value;
    app.State.optimizationMode.angleMax = app.OptAngleMaxField.Value;
    app.State.optimizationMode.angleStep = app.OptAngleStepField.Value;
    app.State.optimizationMode.useSpeed = app.OptUseSpeedCheckbox.Value;
    app.State.optimizationMode.speedMin = app.OptSpeedMinField.Value;
    app.State.optimizationMode.speedMax = app.OptSpeedMaxField.Value;
    app.State.optimizationMode.speedStep = app.OptSpeedStepField.Value;
    app.State.optimizationMode.useMass = app.OptUseMassCheckbox.Value;
    app.State.optimizationMode.massMin = app.OptMassMinField.Value;
    app.State.optimizationMode.massMax = app.OptMassMaxField.Value;
    app.State.optimizationMode.massStep = app.OptMassStepField.Value;
    app.State.optimizationMode.useDiameter = app.OptUseDiameterCheckbox.Value;
    app.State.optimizationMode.diameterMin = app.OptDiameterMinField.Value;
    app.State.optimizationMode.diameterMax = app.OptDiameterMaxField.Value;
    app.State.optimizationMode.diameterStep = app.OptDiameterStepField.Value;
    app.State.optimizationMode.useLength = app.OptUseLengthCheckbox.Value;
    app.State.optimizationMode.lengthMin = app.OptLengthMinField.Value;
    app.State.optimizationMode.lengthMax = app.OptLengthMaxField.Value;
    app.State.optimizationMode.lengthStep = app.OptLengthStepField.Value;
    app.State.optimizationMode.useCd = app.OptUseCdCheckbox.Value;
    app.State.optimizationMode.cdMin = app.OptCdMinField.Value;
    app.State.optimizationMode.cdMax = app.OptCdMaxField.Value;
    app.State.optimizationMode.cdStep = app.OptCdStepField.Value;
    app.State.optimizationMode.useAlpha = app.OptUseAlphaCheckbox.Value;
    app.State.optimizationMode.alphaMin = app.OptAlphaMinField.Value;
    app.State.optimizationMode.alphaMax = app.OptAlphaMaxField.Value;
    app.State.optimizationMode.alphaStep = app.OptAlphaStepField.Value;
    app.State.optimizationMode.useStaticMargin = app.OptUseStaticMarginCheckbox.Value;
    app.State.optimizationMode.staticMarginMin = app.OptStaticMarginMinField.Value;
    app.State.optimizationMode.staticMarginMax = app.OptStaticMarginMaxField.Value;
    app.State.optimizationMode.staticMarginStep = app.OptStaticMarginStepField.Value;
end
if isfield(app, 'UncCdPctField')
    app.State.uncertainty.cd_pct = app.UncCdPctField.Value;
    app.State.uncertainty.speed_pct = app.UncSpeedPctField.Value;
    app.State.uncertainty.angle_deg = app.UncAngleDegField.Value;
    app.State.uncertainty.mass_pct = app.UncMassPctField.Value;
    app.State.uncertainty.diameter_pct = app.UncDiameterPctField.Value;
    app.State.uncertainty.density_pct = app.UncDensityPctField.Value;
end
end

function refreshControlsFromState(fig)
app = fig.UserData;
if isempty(app)
    return;
end
v = app.State.vehicle;
bodyTypeValue = bodyTypeForVehicleDropdown(getField(v, 'bodyType', 'Custom baseline'), app.BodyTypeDropDown.Items);
v.bodyType = bodyTypeValue;
app.State.vehicle.bodyType = bodyTypeValue;
app.BodyTypeDropDown.Value = bodyTypeValue;
app.MassField.Value = getField(v, 'mass', 5);
app.LengthField.Value = getField(v, 'length', 0.45);
app.DiameterField.Value = getField(v, 'diameter', 0.0564);
app.NoseRadiusField.Value = getField(v, 'noseRadius_m', app.DiameterField.Value / 2);
app.CGField.Value = getField(v, 'cgLocation_m', 0.5 * app.LengthField.Value);
app.CPField.Value = getField(v, 'cpLocation_m', 0.6 * app.LengthField.Value);
app.StaticMarginField.Value = 100 * (app.CPField.Value - app.CGField.Value) / max(app.LengthField.Value, eps);
app.ReferenceAreaField.Value = getField(v, 'referenceArea', pi * app.DiameterField.Value^2 / 4);
app.CdMultiplierField.Value = getField(v, 'Cd_scale', 1.0);
app.CLMultiplierField.Value = getField(v, 'CL_scale', 1.0);
app.FinCheckbox.Value = getField(v, 'hasFins', false);
app.SpeedField.Value = app.State.launch.initialSpeed_mps;
app.AngleField.Value = app.State.launch.launchAngle_deg;
app.YawField.Value = app.State.launch.yawAngle_deg;
app.InitialAltitudeField.Value = app.State.launch.initialAltitude_m;
app.DofDropDown.Value = app.State.physics.dofMode;
app.LiftCheckbox.Value = app.State.physics.liftEnabled;
app.DragCheckbox.Value = app.State.physics.dragEnabled;
app.EnvelopeDropDown.Value = app.State.physics.angleEnvelope;
app.AngleMinField.Value = app.State.physics.angleMin_deg;
app.AngleMaxField.Value = app.State.physics.angleMax_deg;
app.AngleStepField.Value = app.State.physics.angleStep_deg;
app.SweepMinField.Value = app.State.physics.angleMin_deg;
app.SweepMaxField.Value = app.State.physics.angleMax_deg;
app.SweepStepField.Value = app.State.physics.angleStep_deg;
app.VehicleInfoTable.Data = vehicleInfoTable(v);
if isfield(app, 'BuilderSummaryTable') && isvalid(app.BuilderSummaryTable)
    app.BuilderSummaryTable.Data = vehicleInfoTable(v);
end
if isfield(app.State, 'builder') && isfield(app, 'BuilderBodyDropDown')
    app.BuilderBodyDropDown.Value = getField(app.State.builder, 'bodyType', app.BuilderBodyDropDown.Value);
    app.BuilderMissionDropDown.Value = getField(app.State.builder, 'missionGoal', app.BuilderMissionDropDown.Value);
    app.BuilderLaunchDropDown.Value = getField(app.State.builder, 'launchMethod', app.BuilderLaunchDropDown.Value);
end
if isfield(app.State, 'compare') && isfield(app, 'CompareSweepDropDown')
    app.CompareSweepDropDown.Value = getField(app.State.compare, 'sweepMode', app.CompareSweepDropDown.Value);
    app.CompareMissionDropDown.Value = getField(app.State.compare, 'missionGoal', app.CompareMissionDropDown.Value);
end
if isfield(app.State, 'sensitivity') && isfield(app, 'SensitivityPerturbField')
    app.SensitivityPerturbField.Value = getField(app.State.sensitivity, 'perturbationPct', app.SensitivityPerturbField.Value);
end
if isfield(app.State, 'fidelity') && isfield(app, 'ModelFidelityDropDown')
    fidelityValue = getField(app.State.fidelity, 'stageName', app.ModelFidelityDropDown.Value);
    if any(strcmp(string(app.ModelFidelityDropDown.Items), string(fidelityValue)))
        app.ModelFidelityDropDown.Value = fidelityValue;
    end
end
if isfield(app.State, 'constraints') && isfield(app, 'MaxQConstraintField')
    c = app.State.constraints;
    app.MaxQConstraintField.Value = getField(c, 'maxQ_kPa', app.MaxQConstraintField.Value);
    app.MaxStagTempConstraintField.Value = getField(c, 'maxStagTemp_K', app.MaxStagTempConstraintField.Value);
    app.MaxMachConstraintField.Value = getField(c, 'maxMach', app.MaxMachConstraintField.Value);
    app.MaxGConstraintField.Value = getField(c, 'maxGLoad', app.MaxGConstraintField.Value);
    app.MinStaticMarginConstraintField.Value = getField(c, 'minStaticMargin_percent', app.MinStaticMarginConstraintField.Value);
    app.MaxAlphaConstraintField.Value = getField(c, 'maxAlpha_deg', app.MaxAlphaConstraintField.Value);
    app.MaxDragConstraintField.Value = getField(c, 'maxDrag_N', app.MaxDragConstraintField.Value);
    app.MaxLiftConstraintField.Value = getField(c, 'maxLift_N', app.MaxLiftConstraintField.Value);
end
if isfield(app.State, 'optimizationMode') && isfield(app, 'OptObjectiveDropDown')
    o = app.State.optimizationMode;
    if any(strcmp(string(app.OptObjectiveDropDown.Items), string(getField(o, 'objective', app.OptObjectiveDropDown.Value))))
        app.OptObjectiveDropDown.Value = getField(o, 'objective', app.OptObjectiveDropDown.Value);
    end
    app.OptMaxCasesField.Value = getField(o, 'maxCases', app.OptMaxCasesField.Value);
    app.OptUseAngleCheckbox.Value = getField(o, 'useAngle', app.OptUseAngleCheckbox.Value);
    app.OptAngleMinField.Value = getField(o, 'angleMin', app.OptAngleMinField.Value);
    app.OptAngleMaxField.Value = getField(o, 'angleMax', app.OptAngleMaxField.Value);
    app.OptAngleStepField.Value = getField(o, 'angleStep', app.OptAngleStepField.Value);
    app.OptUseSpeedCheckbox.Value = getField(o, 'useSpeed', app.OptUseSpeedCheckbox.Value);
    app.OptSpeedMinField.Value = getField(o, 'speedMin', app.OptSpeedMinField.Value);
    app.OptSpeedMaxField.Value = getField(o, 'speedMax', app.OptSpeedMaxField.Value);
    app.OptSpeedStepField.Value = getField(o, 'speedStep', app.OptSpeedStepField.Value);
    app.OptUseMassCheckbox.Value = getField(o, 'useMass', app.OptUseMassCheckbox.Value);
    app.OptMassMinField.Value = getField(o, 'massMin', app.OptMassMinField.Value);
    app.OptMassMaxField.Value = getField(o, 'massMax', app.OptMassMaxField.Value);
    app.OptMassStepField.Value = getField(o, 'massStep', app.OptMassStepField.Value);
    app.OptUseDiameterCheckbox.Value = getField(o, 'useDiameter', app.OptUseDiameterCheckbox.Value);
    app.OptDiameterMinField.Value = getField(o, 'diameterMin', app.OptDiameterMinField.Value);
    app.OptDiameterMaxField.Value = getField(o, 'diameterMax', app.OptDiameterMaxField.Value);
    app.OptDiameterStepField.Value = getField(o, 'diameterStep', app.OptDiameterStepField.Value);
    app.OptUseLengthCheckbox.Value = getField(o, 'useLength', app.OptUseLengthCheckbox.Value);
    app.OptLengthMinField.Value = getField(o, 'lengthMin', app.OptLengthMinField.Value);
    app.OptLengthMaxField.Value = getField(o, 'lengthMax', app.OptLengthMaxField.Value);
    app.OptLengthStepField.Value = getField(o, 'lengthStep', app.OptLengthStepField.Value);
    app.OptUseCdCheckbox.Value = getField(o, 'useCd', app.OptUseCdCheckbox.Value);
    app.OptCdMinField.Value = getField(o, 'cdMin', app.OptCdMinField.Value);
    app.OptCdMaxField.Value = getField(o, 'cdMax', app.OptCdMaxField.Value);
    app.OptCdStepField.Value = getField(o, 'cdStep', app.OptCdStepField.Value);
    app.OptUseAlphaCheckbox.Value = getField(o, 'useAlpha', app.OptUseAlphaCheckbox.Value);
    app.OptAlphaMinField.Value = getField(o, 'alphaMin', app.OptAlphaMinField.Value);
    app.OptAlphaMaxField.Value = getField(o, 'alphaMax', app.OptAlphaMaxField.Value);
    app.OptAlphaStepField.Value = getField(o, 'alphaStep', app.OptAlphaStepField.Value);
    app.OptUseStaticMarginCheckbox.Value = getField(o, 'useStaticMargin', app.OptUseStaticMarginCheckbox.Value);
    app.OptStaticMarginMinField.Value = getField(o, 'staticMarginMin', app.OptStaticMarginMinField.Value);
    app.OptStaticMarginMaxField.Value = getField(o, 'staticMarginMax', app.OptStaticMarginMaxField.Value);
    app.OptStaticMarginStepField.Value = getField(o, 'staticMarginStep', app.OptStaticMarginStepField.Value);
end
if isfield(app.State, 'uncertainty') && isfield(app, 'UncCdPctField')
    u = app.State.uncertainty;
    app.UncCdPctField.Value = getField(u, 'cd_pct', app.UncCdPctField.Value);
    app.UncSpeedPctField.Value = getField(u, 'speed_pct', app.UncSpeedPctField.Value);
    app.UncAngleDegField.Value = getField(u, 'angle_deg', app.UncAngleDegField.Value);
    app.UncMassPctField.Value = getField(u, 'mass_pct', app.UncMassPctField.Value);
    app.UncDiameterPctField.Value = getField(u, 'diameter_pct', app.UncDiameterPctField.Value);
    app.UncDensityPctField.Value = getField(u, 'density_pct', app.UncDensityPctField.Value);
end
if isfield(app, 'AssumptionsIncludedTable') && isvalid(app.AssumptionsIncludedTable)
    assumptions = buildAssumptionsListStage14(app.ModelFidelityDropDown.Value, app.State);
    app.State.assumptions = assumptions;
    app.AssumptionsIncludedTable.Data = assumptions.includedTable;
    app.AssumptionsNotIncludedTable.Data = assumptions.notIncludedTable;
    app.ModelLimitationsArea.Value = assumptions.limitationsText;
end
app = updateVehiclePreviewStage14(app);
fig.UserData = app;
end

function [vehicle, constants, cfg] = makeStage11Config(app, mode)
vehicle = app.State.vehicle;
constants = app.State.constants;
cfgInput = struct();
cfgInput.mode = mode;
cfgInput.showPlots = false;
cfgInput.exportResults = false;
cfgInput.generateReport = false;
cfgInput.verbose = false;
cfgInput.interactive = false;
cfgInput.figureVisible = 'off';
cfgInput.outputRoot = fullfile(app.State.outputRoot, 'Stage11Backend');
cfgInput.dofMode = app.State.physics.dofMode;
cfgInput.launchSpeed_mps = app.State.launch.initialSpeed_mps;
cfgInput.launchAngle_deg = app.State.launch.launchAngle_deg;
cfgInput.launchYaw_deg = app.State.launch.yawAngle_deg;
cfgInput.initialAltitude_m = app.State.launch.initialAltitude_m;
cfgInput.enableEarthRotation = app.State.physics.earthRotation;
if ~app.State.physics.windEnabled
    cfgInput.environment.windSpeed_mps = 0;
else
    cfgInput.environment.windSpeed_mps = 15;
end
if ~app.State.physics.dragEnabled
    cfgInput.warningLimits.maxQ_Pa = Inf;
end
cfgInput.disableDrag = ~app.State.physics.dragEnabled;
cfgInput.disableLift = ~app.State.physics.liftEnabled;
cfgInput.disableMoments = ~app.State.physics.stabilityEnabled;
cfgInput.initialP_deg_s = app.State.launch.p_deg_s;
cfgInput.initialQ_deg_s = app.State.launch.q_deg_s;
cfgInput.initialR_deg_s = app.State.launch.r_deg_s;
cfg = buildStage11Config(vehicle, constants, cfgInput);
end

function cfg = makeStage12Config(app, mode)
cfg = struct();
cfg.mode = mode;
cfg.showPlots = false;
cfg.verbose = false;
cfg.interactive = false;
cfg.figureVisible = 'off';
cfg.outputRoot = app.State.outputRoot;
cfg.physicsDiagnosticAngles_deg = app.State.physics.angleMin_deg:app.State.physics.angleStep_deg:app.State.physics.angleMax_deg;
end

function config = makeStage13Config(app)
cfg = struct();
cfg.showPlots = false;
cfg.verbose = false;
cfg.interactive = false;
cfg.figureVisible = 'off';
cfg.outputRoot = app.State.outputRoot;
cfg.monteCarlo.N = app.State.monteCarlo.N;
cfg.pareto.numCases = 120;
cfg.doe.maxCases = 96;
cfg.stage11.maxStep_s = 0.35;
config = buildStage13Config(app.State.vehicle, app.State.constants, cfg);
end

function T = singleSummaryTable(r)
energyChange = NaN;
if isfield(r, 'totalEnergy') && numel(r.totalEnergy) >= 2
    energyChange = 100 * (r.totalEnergy(end) - r.totalEnergy(1)) / max(abs(r.totalEnergy(1)), eps);
end
warnings = string(strjoin(getWarnings(r), '; '));
T = table(r.range/1000, r.maxAltitude/1000, r.timeOfFlight, r.impactSpeed, ...
    r.Mach(end), r.maxMach, r.maxQ/1000, r.maxHeatingRate/1000, ...
    r.maxStagTemp, r.totalHeatLoad, r.maxGLoad, r.minStaticMargin, energyChange, ...
    r.impactDetected, warnings, ...
    'VariableNames', {'Range_km','MaxAltitude_km','TimeOfFlight_s','ImpactSpeed_mps', ...
    'ImpactMach','MaxMach','MaxDynamicPressure_kPa','MaxHeatingRate_kW_m2', ...
    'MaxStagTemp_K','TotalHeatLoad','MaxGLoad','StaticMargin','EnergyChange_percent', ...
    'ImpactReached','Warnings'});
end

function T = angleSweepTable(inputData)
if isstruct(inputData) && isfield(inputData, 'summaryTable')
    T = standardizeCaseTableStage14(inputData.summaryTable, "AngleSweep");
    if isfield(inputData, 'cases') && numel(inputData.cases) == height(T)
        for k = 1:height(T)
            caseResult = inputData.cases{k};
            T.MaxAlpha_deg(k) = safeGetFieldStage14(caseResult, {'MaxAlpha_deg','maxAlpha_deg'}, NaN);
            T.MaxBeta_deg(k) = safeGetFieldStage14(caseResult, {'MaxBeta_deg','maxBeta_deg'}, NaN);
            T.MaxCL(k) = maxVectorOrDefault(safeGetFieldStage14(caseResult, {'CL','maxCL','MaxCL'}, NaN));
            T.MaxCD(k) = maxVectorOrDefault(safeGetFieldStage14(caseResult, {'CD','Cd','maxCD','maxCd','MaxCD'}, NaN));
            T.MaxLD(k) = maxVectorOrDefault(safeGetFieldStage14(caseResult, {'LD','maxLD','MaxLD'}, NaN));
            T.TotalHeatLoad(k) = safeGetFieldStage14(caseResult, {'TotalHeatLoad','totalHeatLoad','totalHeatLoad_J_m2'}, T.TotalHeatLoad(k));
            T.ImpactMach(k) = lastVectorOrDefault(safeGetFieldStage14(caseResult, {'Mach'}, NaN), T.ImpactMach(k));
            T.StaticMargin_percent(k) = 100 * safeGetFieldStage14(caseResult, {'minStaticMargin','staticMargin'}, T.StaticMargin_percent(k) / 100);
        end
    end
else
    T = standardizeCaseTableStage14(inputData, "AngleSweep");
end
if all(~isfinite(T.Score)) && any(isfinite(T.Range_km))
    T.Score = T.Range_km ./ max(T.Range_km, [], 'omitnan');
end
end

function value = maxVectorOrDefault(value)
if isnumeric(value) && ~isempty(value)
    value = max(value(:), [], 'omitnan');
else
    value = NaN;
end
end

function value = lastVectorOrDefault(value, defaultValue)
if isnumeric(value) && ~isempty(value)
    value = value(end);
else
    value = defaultValue;
end
end

function app = updateHomeMetrics(app, r, feasible)
metrics = buildSummaryMetrics(r);
setMetric(app, 'Range', metrics.Range);
setMetric(app, 'Max altitude', metrics.MaxAltitude);
setMetric(app, 'Impact speed', metrics.ImpactSpeed);
setMetric(app, 'Max Mach', metrics.MaxMach);
setMetric(app, 'Max q', metrics.MaxQ);
setMetric(app, 'Max stagnation temp', metrics.MaxStagnationTemp);
setMetric(app, 'Time to max altitude', metrics.TimeToMaxAltitude);
setMetric(app, 'Time to impact', metrics.TimeToImpact);
if feasible
    setMetric(app, 'Feasibility', metrics.Feasibility);
else
    setMetric(app, 'Feasibility', 'infeasible / failed');
end
end

function setMetric(app, label, textValue)
field = matlab.lang.makeValidName(label);
if isfield(app.MetricLabels, field) && isvalid(app.MetricLabels.(field))
    app.MetricLabels.(field).Text = textValue;
end
end

function app = updateAngleBestLabel(app, T)
[bestPractical, idxPractical] = max(T.Range_km(T.LaunchAngle_deg <= 45));
practicalAngles = T.LaunchAngle_deg(T.LaunchAngle_deg <= 45);
[bestAll, idxAll] = max(T.Range_km);
msg = sprintf('Best practical: %.1f deg / %.2f km. Best full sweep: %.1f deg / %.2f km.', ...
    practicalAngles(idxPractical), bestPractical, T.LaunchAngle_deg(idxAll), bestAll);
if practicalAngles(idxPractical) == 45
    msg = [msg, ' Best practical range occurred at the upper practical angle limit. A lofted trajectory may produce greater range, but it is outside the default practical envelope.'];
end
app.AngleBestLabel.Text = msg;
end

function warnings = getWarnings(r)
warnings = {};
if isstruct(r) && isfield(r, 'warnings')
    warnings = r.warnings;
end
if isempty(warnings)
    warnings = {'No warnings.'};
end
end

function tf = is6DofValidated(app)
tf = false;
if isstruct(app.State) && isfield(app.State, 'Results') && ...
        isfield(app.State.Results, 'debug6DOF')
    debug = app.State.Results.debug6DOF;
    tf = isfield(debug, 'vacuumValidationPassed') && debug.vacuumValidationPassed && ...
        isfield(debug, 'translationClose') && debug.translationClose;
end
end

function T = vehicleInfoTable(v)
staticMargin = (getField(v, 'cpLocation_m', 0) - getField(v, 'cgLocation_m', 0)) / max(getField(v, 'length', 1), eps);
Cd = 0.32 * getField(v, 'Cd_scale', 1);
ballistic = getField(v, 'mass', NaN) / max(Cd * getField(v, 'referenceArea', NaN), eps);
fields = ["Reference area m^2"; "Fineness ratio"; "Ballistic coefficient kg/m^2"; "Static margin %"; "Stability status"];
values = [string(getField(v, 'referenceArea', NaN)); ...
    string(getField(v, 'finenessRatio', NaN)); ...
    string(ballistic); ...
    string(100 * staticMargin); ...
    string(stabilityText(staticMargin))];
T = table(fields, values, 'VariableNames', {'Quantity','Value'});
end

function text = stabilityText(staticMargin)
if staticMargin < 0.05
    text = "Low/unstable margin";
elseif staticMargin > 0.25
    text = "High/stiff margin";
else
    text = "Stable educational range";
end
end

function value = bodyTypeForVehicleDropdown(rawValue, items)
value = char(string(rawValue));
itemStrings = string(items);
if any(strcmp(itemStrings, value))
    return;
end
name = lower(value);
if contains(name, 'blunt')
    value = 'Blunt nose';
elseif contains(name, 'slender') || contains(name, 'cone')
    value = 'Slender cone';
elseif contains(name, 'ogive')
    value = 'Ogive nose';
elseif contains(name, 'finned') || contains(name, 'dart')
    value = 'Finned dart';
else
    value = 'Custom baseline';
end
if ~any(strcmp(itemStrings, value))
    value = char(itemStrings(end));
end
end

function T = currentOrBestCaseTable(app)
T = table();
if isfield(app.State.Tables, app.State.currentTableName)
    T = app.State.Tables.(app.State.currentTableName);
elseif isfield(app.State.Tables, 'ScenarioCompare')
    T = app.State.Tables.ScenarioCompare;
elseif isfield(app.State.Tables, 'ParetoDesigns')
    T = app.State.Tables.ParetoDesigns;
end
end

function safeAlert(fig, message, titleText)
try
    uialert(fig, message, titleText);
catch
    warning('%s: %s', titleText, message);
end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
