function results = runStage12(vehicle, constants, stage12Config)
% runStage12
% Entry point for Stage 12 validation, regression testing, and portfolio
% documentation.

if nargin < 3
    stage12Config = struct();
end

config = buildStage12Config(stage12Config);

if ~isfield(config, 'mode') || isempty(config.mode)
    if config.interactive
        config.mode = stage12Dashboard();
    else
        config.mode = 1;
    end
end

config.mode = round(config.mode);

switch config.mode
    case 1
        validation = runValidationCases(vehicle, constants, config);
        regression = runRegressionTests(vehicle, constants, config);
        results.validation = validation;
        results.regression = regression;
    case 2
        results.stageComparison = compareStages(vehicle, constants, config);
        results.physicsDiagnostics = runPhysicsDiagnostics(vehicle, constants, config);
    case 3
        results.regression = runRegressionTests(vehicle, constants, config);
    case 4
        results.portfolioFigures = createPortfolioFigures(vehicle, constants, config);
    case 5
        validation = runValidationCases(vehicle, constants, config);
        regression = runRegressionTests(vehicle, constants, config);
        results.reportFile = generateFinalEngineeringReport(vehicle, constants, validation, regression, config);
    case 6
        results.packageFolder = exportPortfolioPackage(vehicle, constants, config);
    case 7
        results.physicsDiagnostics = runPhysicsDiagnostics(vehicle, constants, config);
    otherwise
        warning('Stage12:InvalidMode', ...
            'Invalid Stage 12 mode. Running all validation cases and regression tests.');
        validation = runValidationCases(vehicle, constants, config);
        regression = runRegressionTests(vehicle, constants, config);
        results.validation = validation;
        results.regression = regression;
end

results.stage = 12;
results.config = config;

if config.verbose
    fprintf('\nStage 12 complete.\n');
    if isfield(results, 'validation')
        fprintf('Validation cases complete: %d\n', numel(results.validation.caseNames));
    end
    if isfield(results, 'regression')
        fprintf('Regression pass rate: %.1f %%\n', 100 * results.regression.passRate);
    end
end
end

function config = buildStage12Config(userConfig)
config = struct();
config.mode = getField(userConfig, 'mode', []);
config.interactive = getField(userConfig, 'interactive', false);
config.verbose = getField(userConfig, 'verbose', true);
config.showPlots = getField(userConfig, 'showPlots', true);
config.figureVisible = getField(userConfig, 'figureVisible', 'on');
config.outputRoot = getField(userConfig, 'outputRoot', fullfile(pwd, 'Outputs', 'Stage12'));
config.figureDir = fullfile(config.outputRoot, 'Figures');
config.tableDir = fullfile(config.outputRoot, 'Tables');
config.reportDir = fullfile(config.outputRoot, 'Reports');
config.matDir = fullfile(config.outputRoot, 'MAT');
config.packageDir = fullfile(config.outputRoot, 'PortfolioPackage');
config.stage11OutputRoot = fullfile(config.outputRoot, 'Stage11Generated');
config.physicsDiagnosticAngles_deg = getField(userConfig, 'physicsDiagnosticAngles_deg', 5:5:75);
config.physicsDiagnosticFinalTime_s = getField(userConfig, 'physicsDiagnosticFinalTime_s', 600);
config.physicsDiagnosticMaxStep_s = getField(userConfig, 'physicsDiagnosticMaxStep_s', 0.15);
ensureFolders({config.outputRoot, config.figureDir, config.tableDir, config.reportDir, config.matDir, config.packageDir});
end

function ensureFolders(folders)
for k = 1:numel(folders)
    if ~exist(folders{k}, 'dir')
        mkdir(folders{k});
    end
end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
