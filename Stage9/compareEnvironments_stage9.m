function comparison = compareEnvironments_stage9(environments, vehicle, constants, stage5Config, options)
% compareEnvironments_stage9
% Runs Stage 5 optimization for each simplified launch environment.

if nargin < 5
    options = struct();
end

if ~isfield(options, 'verbose')
    options.verbose = true;
end

nEnv = numel(environments);

environmentNames = cell(nEnv, 1);
notes = cell(nEnv, 1);
stage5Results = cell(nEnv, 1);
thermalResults = cell(nEnv, 1);

bestRangeAngle_deg = nan(nEnv, 1);
range_m = nan(nEnv, 1);
maxAltitude_m = nan(nEnv, 1);
impactSpeed_mps = nan(nEnv, 1);
maxMach = nan(nEnv, 1);
maxQ_Pa = nan(nEnv, 1);
maxDrag_N = nan(nEnv, 1);
maxLift_N = nan(nEnv, 1);
maxStagTemp_K = nan(nEnv, 1);
peakHeatFlux_W_m2 = nan(nEnv, 1);
totalHeatLoad_J_m2 = nan(nEnv, 1);

temperatureOffset_K = nan(nEnv, 1);
densityMultiplier = nan(nEnv, 1);
pressureMultiplier = nan(nEnv, 1);
launchAltitudeOffset_m = nan(nEnv, 1);
windSpeed_mps = nan(nEnv, 1);

for k = 1:nEnv
    environment = environments(k);
    environmentNames{k} = environment.name;
    notes{k} = environment.notes;

    constantsCase = applyEnvironment(constants, environment);
    configCase = stage5Config;
    configCase.verbose = false;
    configCase.showProgress = false;
    configCase.showPlots = false;

    if options.verbose
        fprintf('  Running environment %d/%d: %s\n', ...
            k, nEnv, environment.name);
    end

    stage5Result = runStage5(vehicle, constantsCase, configCase);
    stage5Results{k} = stage5Result;

    idxBest = stage5Result.idxBestRange;

    bestRangeAngle_deg(k) = stage5Result.bestRangeAngle_deg;
    range_m(k) = stage5Result.bestRange;
    maxAltitude_m(k) = stage5Result.maxAltitude(idxBest);
    impactSpeed_mps(k) = stage5Result.impactSpeed(idxBest);
    maxMach(k) = stage5Result.maxMach(idxBest);
    maxQ_Pa(k) = stage5Result.maxQ(idxBest);
    maxDrag_N(k) = stage5Result.maxDrag(idxBest);
    maxLift_N(k) = stage5Result.maxLift(idxBest);
    maxStagTemp_K(k) = stage5Result.maxStagTemp(idxBest);

    thermal = runBestRangeThermal(vehicle, constantsCase, bestRangeAngle_deg(k));
    thermalResults{k} = thermal;
    peakHeatFlux_W_m2(k) = thermal.peakHeatFlux_W_m2;
    totalHeatLoad_J_m2(k) = thermal.totalHeatLoad_J_m2;

    temperatureOffset_K(k) = environment.temperatureOffset_K;
    densityMultiplier(k) = environment.densityMultiplier;
    pressureMultiplier(k) = environment.pressureMultiplier;
    launchAltitudeOffset_m(k) = environment.launchAltitudeOffset_m;
    windSpeed_mps(k) = environment.windSpeed_mps;
end

baselineIdx = find(strcmp(environmentNames, 'Standard atmosphere / baseline'), 1);
if isempty(baselineIdx)
    baselineIdx = 1;
end

rangeChange_percent = percentChange(range_m, range_m(baselineIdx));
maxQChange_percent = percentChange(maxQ_Pa, maxQ_Pa(baselineIdx));
impactSpeedChange_percent = percentChange(impactSpeed_mps, impactSpeed_mps(baselineIdx));
stagnationTemperatureChange_percent = percentChange(maxStagTemp_K, maxStagTemp_K(baselineIdx));

comparison.stage5Results = stage5Results;
comparison.thermalResults = thermalResults;
comparison.baselineIndex = baselineIdx;

comparison.environment.name = environmentNames;
comparison.environment.notes = notes;
comparison.environment.bestRangeAngle_deg = bestRangeAngle_deg;
comparison.environment.range_m = range_m;
comparison.environment.maxAltitude_m = maxAltitude_m;
comparison.environment.impactSpeed_mps = impactSpeed_mps;
comparison.environment.maxMach = maxMach;
comparison.environment.maxQ_Pa = maxQ_Pa;
comparison.environment.maxDrag_N = maxDrag_N;
comparison.environment.maxLift_N = maxLift_N;
comparison.environment.maxStagTemp_K = maxStagTemp_K;
comparison.environment.peakHeatFlux_W_m2 = peakHeatFlux_W_m2;
comparison.environment.totalHeatLoad_J_m2 = totalHeatLoad_J_m2;
comparison.environment.rangeChange_percent = rangeChange_percent;
comparison.environment.maxQChange_percent = maxQChange_percent;
comparison.environment.impactSpeedChange_percent = impactSpeedChange_percent;
comparison.environment.stagnationTemperatureChange_percent = ...
    stagnationTemperatureChange_percent;
comparison.environment.temperatureOffset_K = temperatureOffset_K;
comparison.environment.densityMultiplier = densityMultiplier;
comparison.environment.pressureMultiplier = pressureMultiplier;
comparison.environment.launchAltitudeOffset_m = launchAltitudeOffset_m;
comparison.environment.windSpeed_mps = windSpeed_mps;

end

function constantsCase = applyEnvironment(constants, environment)
constantsCase = constants;
constantsCase.environment = environment;
constantsCase.launchAlt = constants.launchAlt + environment.launchAltitudeOffset_m;
end

function thermal = runBestRangeThermal(vehicle, constants, launchAngle_deg)
vehicleCase = vehicle;
vehicleCase.launchAngle = deg2rad(launchAngle_deg);

if ~isfield(vehicleCase, 'launchAzimuth') && isfield(vehicleCase, 'launchAzimuth_deg')
    vehicleCase.launchAzimuth = deg2rad(vehicleCase.launchAzimuth_deg);
end

[t, state] = runStage4(vehicleCase, constants);
trajectoryResults = postProcess_stage4(t, state, vehicleCase, constants);
thermal = computeThermalLoads_stage7(trajectoryResults, vehicleCase, constants, struct());
end

function output = percentChange(values, baselineValue)
output = 100 .* (values - baselineValue) ./ max(abs(baselineValue), eps);
end
