function app = applyStage14Theme(app)
% applyStage14Theme
% Applies a consistent visual treatment to the Stage 14 UI shell.

theme = stage14Theme();
if ~isfield(app, 'Figure') || isempty(app.Figure) || ~isvalid(app.Figure)
    return;
end

setIfProperty(app.Figure, 'Color', theme.background);
setIfProperty(app.TabGroup, 'BackgroundColor', theme.background);

styleObjectTree(app.Figure, theme);
styleKnownButtons(app, theme);
styleKnownTables(app, theme);
styleKnownAxes(app);
styleStatusBar(app, theme);
end

function styleObjectTree(parent, theme)
children = getChildren(parent);
for k = 1:numel(children)
    obj = children(k);
    if isempty(obj) || ~isvalid(obj)
        continue;
    end

    styleObject(obj, theme);
    styleObjectTree(obj, theme);
end
end

function children = getChildren(parent)
try
    children = allchild(parent);
catch
    children = gobjects(0);
end
end

function styleObject(obj, theme)
className = class(obj);
setIfProperty(obj, 'FontName', theme.fontName);
setIfProperty(obj, 'FontSize', 12);

if contains(className, 'matlab.ui.container.Panel')
    setIfProperty(obj, 'BackgroundColor', theme.surface);
    setIfProperty(obj, 'ForegroundColor', theme.text);
    setIfProperty(obj, 'FontWeight', 'bold');
    setIfProperty(obj, 'HighlightColor', theme.border);
    setIfProperty(obj, 'BorderColor', theme.border);
elseif contains(className, 'matlab.ui.container.Tab')
    setIfProperty(obj, 'BackgroundColor', theme.background);
    setIfProperty(obj, 'ForegroundColor', theme.text);
elseif contains(className, 'matlab.ui.container.GridLayout')
    setIfProperty(obj, 'BackgroundColor', theme.background);
elseif contains(className, 'matlab.ui.control.Label')
    setIfProperty(obj, 'FontColor', theme.text);
elseif contains(className, 'matlab.ui.control.Button')
    setIfProperty(obj, 'BackgroundColor', theme.primarySoft);
    setIfProperty(obj, 'FontColor', theme.primary);
    setIfProperty(obj, 'FontWeight', 'bold');
elseif contains(className, 'matlab.ui.control.EditField') || ...
        contains(className, 'matlab.ui.control.NumericEditField') || ...
        contains(className, 'matlab.ui.control.DropDown')
    setIfProperty(obj, 'BackgroundColor', theme.surface);
    setIfProperty(obj, 'FontColor', theme.text);
elseif contains(className, 'matlab.ui.control.CheckBox')
    setIfProperty(obj, 'FontColor', theme.text);
elseif contains(className, 'matlab.ui.control.TextArea')
    setIfProperty(obj, 'BackgroundColor', theme.surfaceAlt);
    setIfProperty(obj, 'FontColor', theme.text);
elseif contains(className, 'matlab.ui.control.Table')
    styleTable(obj, theme);
elseif contains(className, 'matlab.ui.control.Gauge')
    setIfProperty(obj, 'FontColor', theme.text);
end
end

function styleKnownButtons(app, theme)
primaryFields = {'RunSingleButton','RunMonteCarloButton','RunOptimizationButton', ...
    'RunParetoButton','RunDOEButton','HomeRunSingleButton','HomeRunAngleButton', ...
    'HomeRunValidationButton','HomeRunMonteCarloButton','HomeRunParetoButton', ...
    'RunCompareButton','RunSensitivityButton','ApplyBuilderPresetButton', ...
    'RunVerificationButton','RunConstraintEnvelopeButton','RunOptimizationGridButton', ...
    'RunUncertaintyButton'};
for k = 1:numel(primaryFields)
    styleButtonField(app, primaryFields{k}, theme.primary, [1 1 1]);
end

secondaryFields = {'OpenSelectedCaseButton','ExportSelectedCaseButton', ...
    'HomeGenerateReportButton','HomeExportSessionButton','HomeTutorialButton', ...
    'ApplyBestDesignButton'};
for k = 1:numel(secondaryFields)
    styleButtonField(app, secondaryFields{k}, theme.accentSoft, theme.accent);
end
end

function styleButtonField(app, fieldName, backgroundColor, textColor)
if isfield(app, fieldName) && ~isempty(app.(fieldName)) && isvalid(app.(fieldName))
    setIfProperty(app.(fieldName), 'BackgroundColor', backgroundColor);
    setIfProperty(app.(fieldName), 'FontColor', textColor);
    setIfProperty(app.(fieldName), 'FontWeight', 'bold');
end
end

function styleKnownTables(app, theme)
fields = fieldnames(app);
for k = 1:numel(fields)
    value = app.(fields{k});
    if isempty(value) || ~isobject(value)
        continue;
    end
    try
        if isvalid(value) && contains(class(value), 'matlab.ui.control.Table')
            styleTable(value, theme);
        end
    catch
    end
end
end

function styleTable(tbl, theme)
setIfProperty(tbl, 'FontName', theme.fontName);
setIfProperty(tbl, 'FontSize', 11);
setIfProperty(tbl, 'ForegroundColor', theme.text);
setIfProperty(tbl, 'BackgroundColor', [theme.surface; theme.tableStripe]);
end

function styleKnownAxes(app)
axisFields = {'SingleAxes','AngleAxes','ValidationAxes','MonteCarloAxes','ParetoAxes', ...
    'CompareAxes','SensitivityAxes','VehiclePreviewAxes','VerificationAxes', ...
    'ConstraintAxes','OptimizationAxes','UncertaintyAxes'};
for k = 1:numel(axisFields)
    if isfield(app, axisFields{k})
        styleStage14Axes(app.(axisFields{k}));
    end
end
end

function styleStatusBar(app, theme)
if isfield(app, 'StatusBarPanel') && isvalid(app.StatusBarPanel)
    setIfProperty(app.StatusBarPanel, 'BackgroundColor', theme.primary);
end
if isfield(app, 'StatusBarGrid') && isvalid(app.StatusBarGrid)
    setIfProperty(app.StatusBarGrid, 'BackgroundColor', theme.primary);
end
if isfield(app, 'StatusLabel') && isvalid(app.StatusLabel)
    setIfProperty(app.StatusLabel, 'FontColor', [1 1 1]);
    setIfProperty(app.StatusLabel, 'FontWeight', 'bold');
end
if isfield(app, 'ProgressLabel') && isvalid(app.ProgressLabel)
    setIfProperty(app.ProgressLabel, 'FontColor', [1 1 1]);
    setIfProperty(app.ProgressLabel, 'FontWeight', 'bold');
end
end

function setIfProperty(obj, propName, propValue)
if isprop(obj, propName)
    try
        obj.(propName) = propValue;
    catch
    end
end
end
