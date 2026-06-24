function results = runStage9(vehicle, constants, stage5Config, stage9Config)
% runStage9
% Launch-environment sensitivity analysis using Stage 5 / Stage 4 / Stage 7.
%
% Stage 9 uses simplified engineering environment presets. It does not call
% live weather APIs and does not represent a full atmospheric science model.

if nargin < 3
    stage5Config = struct();
end

if nargin < 4
    stage9Config = struct();
end

stage5Config = fillDefaultStage5Config(stage5Config);

if ~isfield(stage9Config, 'verbose')
    stage9Config.verbose = true;
end

if ~isfield(stage9Config, 'showPlots')
    stage9Config.showPlots = true;
end

presets = getEnvironmentPresets_stage9();

fprintf('Stage 9 Launch Environment Sensitivity\n');
fprintf('Simplified engineering environment perturbations; not real weather forecasts.\n\n');

if isfield(stage9Config, 'mode')
    mode = stage9Config.mode;
else
    printStage9Menu();
    mode = promptWithDefault('Select Stage 9 option', 1);
end

if isempty(mode) || isnan(mode) || mode < 1 || mode > 4
    warning('Stage9:InvalidMenuSelection', 'Invalid Stage 9 option. Running all presets.');
    mode = 1;
end

mode = round(mode);

switch mode
    case 1
        environments = presets;
    case 2
        presetIndex = selectPreset(presets);
        environments = presets(presetIndex);
    case 3
        environments = getCustomEnvironment_stage9(presets(1));
    case 4
        environments = [presets(1), getCustomEnvironment_stage9(presets(1))];
end

fprintf('\nRunning Stage 5/Stage 4 cases for %d environment(s)...\n', ...
    numel(environments));

results = compareEnvironments_stage9(environments, vehicle, constants, ...
    stage5Config, struct('verbose', stage9Config.verbose));
results.stage9Mode = mode;

printStage9Summary(results);

if stage9Config.showPlots
    plotStage9EnvironmentResults(results);
end

fprintf('\nStage 9 environment sensitivity complete.\n\n');

end

function printStage9Menu()
fprintf('Stage 9 Menu:\n');
fprintf('  1 = Run all environment presets\n');
fprintf('  2 = Select one environment preset\n');
fprintf('  3 = Enter custom environment manually\n');
fprintf('  4 = Compare baseline against one custom environment\n\n');
end

function presetIndex = selectPreset(presets)
fprintf('\nEnvironment presets:\n');
for k = 1:numel(presets)
    fprintf('  %d = %s\n', k, presets(k).name);
end

presetIndex = promptWithDefault('Select environment preset', 1);

if isempty(presetIndex) || isnan(presetIndex) || ...
        presetIndex < 1 || presetIndex > numel(presets)
    warning('Stage9:InvalidPresetSelection', ...
        'Invalid environment preset. Using preset 1.');
    presetIndex = 1;
end

presetIndex = round(presetIndex);
end

function printStage9Summary(results)
fprintf('\nStage 9 Environment Sensitivity Summary:\n');
fprintf('Environment count: %d\n', numel(results.environment.name));

printBestWorstRange(results);
printLoadExtremes(results);
printBaselineChanges(results);

fprintf('\nSimplified assumptions:\n');
fprintf('  Temperature offsets are applied uniformly to the Stage 4 atmosphere.\n');
fprintf('  Density and pressure multipliers are scalar engineering perturbations.\n');
fprintf('  Winds are constant launch-site ENU vectors, not altitude-varying wind profiles.\n');
fprintf('  Thermal metrics reuse the simplified Stage 7 heating estimate.\n');
fprintf('  Future work: real atmospheric profiles, wind profiles with altitude, live weather data, and uncertainty analysis.\n');
end

function printBestWorstRange(results)
[~, idxBest] = max(results.environment.range_m);
[~, idxWorst] = min(results.environment.range_m);

fprintf('\nBest environment for maximum range:\n');
fprintf('  %s: %.2f km\n', results.environment.name{idxBest}, ...
    results.environment.range_m(idxBest) / 1000);

fprintf('Worst environment for maximum range:\n');
fprintf('  %s: %.2f km\n', results.environment.name{idxWorst}, ...
    results.environment.range_m(idxWorst) / 1000);
end

function printLoadExtremes(results)
[~, idxHighQ] = max(results.environment.maxQ_Pa);
[~, idxLowQ] = min(results.environment.maxQ_Pa);
[~, idxHighStag] = max(results.environment.maxStagTemp_K);
[~, idxHighHeat] = max(results.environment.totalHeatLoad_J_m2);

fprintf('\nLoad and heating extremes:\n');
fprintf('  Highest max-Q: %s (%.2f kPa)\n', ...
    results.environment.name{idxHighQ}, results.environment.maxQ_Pa(idxHighQ) / 1000);
fprintf('  Lowest max-Q: %s (%.2f kPa)\n', ...
    results.environment.name{idxLowQ}, results.environment.maxQ_Pa(idxLowQ) / 1000);
fprintf('  Highest stagnation temperature: %s (%.2f K)\n', ...
    results.environment.name{idxHighStag}, results.environment.maxStagTemp_K(idxHighStag));
fprintf('  Highest total heat load: %s (%.4f MJ/m^2)\n', ...
    results.environment.name{idxHighHeat}, results.environment.totalHeatLoad_J_m2(idxHighHeat) / 1e6);
end

function printBaselineChanges(results)
fprintf('\nRange change relative to baseline:\n');
for k = 1:numel(results.environment.name)
    fprintf('  %s: %+6.2f %%\n', results.environment.name{k}, ...
        results.environment.rangeChange_percent(k));
end
end

function config = fillDefaultStage5Config(config)
if ~isfield(config, 'launchAngles_deg')
    config.launchAngles_deg = 1:1:60;
end

if ~isfield(config, 'maxAllowableAngle_deg')
    config.maxAllowableAngle_deg = max(config.launchAngles_deg);
end

if ~isfield(config, 'maxQ_limit')
    config.maxQ_limit = 2000e3;
end

if ~isfield(config, 'minRangeForAltitude_m')
    config.minRangeForAltitude_m = 30000;
end

if ~isfield(config, 'targetRange')
    config.targetRange = [];
end
end
