function results = runStage6(vehicle, constants, stage5Config, stage6Config)
% runStage6
% Vehicle/body comparison stage that reuses Stage 5 and Stage 4.

if nargin < 3
    stage5Config = struct();
end

if nargin < 4
    stage6Config = struct();
end

stage5Config = fillDefaultStage5Config(stage5Config);

if ~isfield(stage6Config, 'verbose')
    stage6Config.verbose = true;
end

if ~isfield(stage6Config, 'showPlots')
    stage6Config.showPlots = true;
end

if ~isfield(stage6Config, 'includeThermal')
    stage6Config.includeThermal = true;
end

presets = getVehiclePresets_stage6(vehicle);

fprintf('Stage 6 Vehicle/Body Comparison\n');
fprintf('Approximate engineering trade-study configurations; not CFD-accurate.\n\n');

if isfield(stage6Config, 'mode')
    mode = stage6Config.mode;
else
    printStage6Menu();
    mode = promptWithDefault('Select Stage 6 option', 1);
end

if isempty(mode) || isnan(mode) || mode < 1 || mode > 5
    warning('Stage6:InvalidMenuSelection', 'Invalid Stage 6 option. Running all presets.');
    mode = 1;
end

mode = round(mode);

switch mode
    case 1
        selectedVehicles = presets;
        configList = makeConfigList(stage5Config, numel(selectedVehicles));
    case 2
        presetIndex = selectPreset(presets);
        selectedVehicles = presets(presetIndex);
        configList = makeConfigList(stage5Config, numel(selectedVehicles));
    case 3
        [customVehicle, customConfig] = getCustomVehicle_stage6(vehicle, stage5Config);
        selectedVehicles = customVehicle;
        configList = {customConfig};
    case 4
        presetIndex = selectPreset(presets);
        [editedVehicle, editedConfig] = getCustomVehicle_stage6(presets(presetIndex), stage5Config);
        selectedVehicles = editedVehicle;
        configList = {editedConfig};
    case 5
        [customVehicle, customConfig] = getCustomVehicle_stage6(vehicle, stage5Config);
        selectedVehicles = [presets, customVehicle];
        configList = makeConfigList(stage5Config, numel(presets));
        configList{end+1} = customConfig;
end

fprintf('\nRunning Stage 5 optimization for %d vehicle configuration(s)...\n', ...
    numel(selectedVehicles));

results = compareVehicles_stage6(selectedVehicles, constants, configList, ...
    struct('verbose', stage6Config.verbose, ...
           'includeThermal', stage6Config.includeThermal));
results.stage6Mode = mode;

printStage6Summary(results);

if stage6Config.showPlots
    plotStage6Comparison(results);
end

fprintf('\nStage 6 comparison complete.\n\n');

end

function printStage6Menu()
fprintf('Stage 6 Menu:\n');
fprintf('  1 = Run all preset vehicle configurations\n');
fprintf('  2 = Select one preset vehicle\n');
fprintf('  3 = Enter a custom vehicle manually\n');
fprintf('  4 = Edit a preset vehicle and run it\n');
fprintf('  5 = Compare presets plus one custom vehicle\n\n');
end

function presetIndex = selectPreset(presets)
fprintf('\nVehicle presets:\n');
for k = 1:numel(presets)
    fprintf('  %d = %s\n', k, presets(k).name);
end

presetIndex = promptWithDefault('Select preset vehicle', 1);

if isempty(presetIndex) || isnan(presetIndex) || ...
        presetIndex < 1 || presetIndex > numel(presets)
    warning('Stage6:InvalidPresetSelection', ...
        'Invalid preset selection. Using preset 1.');
    presetIndex = 1;
end

presetIndex = round(presetIndex);
end

function configList = makeConfigList(stage5Config, nConfigs)
configList = cell(nConfigs, 1);
for k = 1:nConfigs
    configList{k} = stage5Config;
end
end

function printStage6Summary(results)
fprintf('\nStage 6 Vehicle Comparison Summary:\n');
fprintf('Vehicle count: %d\n', numel(results.vehicleNames));

printBestRange(results);
printBestAltitudeWithMinRange(results);
printBestMaxQConstrained(results);
printHighestBeta(results);
printLowestMaxQ(results);
printBestLD(results);
printThermalSummary(results);
end

function printBestRange(results)
idx = results.idxBestRange;
fprintf('\nBest overall vehicle for maximum range:\n');
fprintf('  %s\n', results.vehicleNames{idx});
fprintf('  Range: %.2f km at %.2f deg\n', ...
    results.maxRange_m(idx) / 1000, results.bestRangeAngle_deg(idx));
fprintf('  Altitude at best range: %.2f km\n', ...
    results.maxAltitudeAtBestRange_m(idx) / 1000);
end

function printBestAltitudeWithMinRange(results)
idx = results.idxBestAltitudeWithMinRange;
fprintf('\nBest overall vehicle for altitude while satisfying minimum range:\n');
if isnan(idx)
    fprintf('  No vehicle satisfied the minimum range requirement.\n');
else
    fprintf('  %s\n', results.vehicleNames{idx});
    fprintf('  Altitude: %.2f km\n', results.bestMinRangeAltitude_m(idx) / 1000);
end
end

function printBestMaxQConstrained(results)
idx = results.idxBestMaxQConstrained;
fprintf('\nBest vehicle under max-Q constraint:\n');
if isnan(idx)
    fprintf('  No vehicle satisfied the max-Q constraint.\n');
else
    fprintf('  %s\n', results.vehicleNames{idx});
    fprintf('  Constrained range: %.2f km at %.2f deg\n', ...
        results.bestMaxQConstrainedRange_m(idx) / 1000, ...
        results.bestMaxQConstrainedAngle_deg(idx));
end
end

function printHighestBeta(results)
idx = results.idxHighestBeta;
fprintf('\nVehicle with highest ballistic coefficient:\n');
fprintf('  %s\n', results.vehicleNames{idx});
fprintf('  Average ballistic coefficient: %.2f kg/m^2\n', ...
    results.beta_average_kgpm2(idx));
fprintf('  Initial/minimum ballistic coefficient: %.2f / %.2f kg/m^2\n', ...
    results.beta_initial_kgpm2(idx), results.beta_min_kgpm2(idx));
end

function printLowestMaxQ(results)
idx = results.idxLowestMaxQ;
fprintf('\nVehicle with lowest max-Q at best-range trajectory:\n');
fprintf('  %s\n', results.vehicleNames{idx});
fprintf('  Max-Q: %.2f kPa\n', results.maxQAtBestRange_Pa(idx) / 1000);
end

function printBestLD(results)
idx = results.idxBestLD;
fprintf('\nVehicle with best L/D if available:\n');
if isnan(idx)
    fprintf('  L/D was not available in the Stage 5 results.\n');
else
    fprintf('  %s\n', results.vehicleNames{idx});
    fprintf('  Maximum L/D at best-range trajectory: %.3f\n', ...
        results.maxLDAtBestRange(idx));
end
end

function printThermalSummary(results)
if ~isfield(results, 'stage7ThermalIncluded') || ~results.stage7ThermalIncluded
    return;
end

fprintf('\nStage 7 thermal comparison at each vehicle''s best-range trajectory:\n');

idx = results.idxLowestPeakHeatFlux;
if isnan(idx)
    fprintf('  Thermal metrics were not available.\n');
    return;
end

fprintf('  Lowest peak heat flux: %s\n', results.vehicleNames{idx});
fprintf('    Peak heat flux: %.2f kW/m^2\n', ...
    results.peakHeatFluxAtBestRange_W_m2(idx) / 1000);
fprintf('    Total heat load: %.4f MJ/m^2\n', ...
    results.totalHeatLoadAtBestRange_J_m2(idx) / 1e6);

idx = results.idxLowestTotalHeatLoad;
fprintf('  Lowest total heat load: %s\n', results.vehicleNames{idx});
fprintf('    Total heat load: %.4f MJ/m^2\n', ...
    results.totalHeatLoadAtBestRange_J_m2(idx) / 1e6);

idx = results.idxLowestMaxWallTemp;
if ~isnan(idx)
    fprintf('  Lowest estimated max wall temperature: %s\n', results.vehicleNames{idx});
    fprintf('    Max wall temperature: %.2f K\n', ...
        results.maxWallTempAtBestRange_K(idx));
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
