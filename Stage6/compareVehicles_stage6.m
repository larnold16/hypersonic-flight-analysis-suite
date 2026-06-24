function comparison = compareVehicles_stage6(vehicles, constants, stage5Configs, options)
% compareVehicles_stage6
% Runs each vehicle through Stage 5 and collects comparison metrics.

if nargin < 4
    options = struct();
end

if ~isfield(options, 'verbose')
    options.verbose = true;
end

if ~isfield(options, 'includeThermal')
    options.includeThermal = true;
end

nVehicles = numel(vehicles);

if ~iscell(stage5Configs)
    baseConfig = stage5Configs;
    stage5Configs = cell(nVehicles, 1);
    for k = 1:nVehicles
        stage5Configs{k} = baseConfig;
    end
end

vehicleNames = cell(nVehicles, 1);
bodyTypes = cell(nVehicles, 1);
stage5Results = cell(nVehicles, 1);
stage7ThermalResults = cell(nVehicles, 1);

mass_kg = nan(nVehicles, 1);
diameter_m = nan(nVehicles, 1);
length_m = nan(nVehicles, 1);
referenceArea_m2 = nan(nVehicles, 1);
finenessRatio = nan(nVehicles, 1);
alpha_deg = nan(nVehicles, 1);

bestRangeAngle_deg = nan(nVehicles, 1);
maxRange_m = nan(nVehicles, 1);
maxAltitudeAtBestRange_m = nan(nVehicles, 1);
impactSpeedAtBestRange_mps = nan(nVehicles, 1);
maxMachAtBestRange = nan(nVehicles, 1);
maxQAtBestRange_Pa = nan(nVehicles, 1);
maxDragAtBestRange_N = nan(nVehicles, 1);
maxLiftAtBestRange_N = nan(nVehicles, 1);
maxStagTempAtBestRange_K = nan(nVehicles, 1);
maxLDAtBestRange = nan(nVehicles, 1);

peakHeatFluxAtBestRange_W_m2 = nan(nVehicles, 1);
peakHeatFluxTimeAtBestRange_s = nan(nVehicles, 1);
totalHeatLoadAtBestRange_J_m2 = nan(nVehicles, 1);
peakThermalStagTempAtBestRange_K = nan(nVehicles, 1);
peakThermalStagTempTimeAtBestRange_s = nan(nVehicles, 1);
maxWallTempAtBestRange_K = nan(nVehicles, 1);
thermalMarginAtBestRange_K = nan(nVehicles, 1);

beta_initial_kgpm2 = nan(nVehicles, 1);
beta_average_kgpm2 = nan(nVehicles, 1);
beta_min_kgpm2 = nan(nVehicles, 1);

bestMaxQConstrainedAngle_deg = nan(nVehicles, 1);
bestMaxQConstrainedRange_m = nan(nVehicles, 1);
bestMinRangeAltitude_m = nan(nVehicles, 1);
closestTargetAngle_deg = nan(nVehicles, 1);

for k = 1:nVehicles
    vehicleCase = prepareVehicleForStage5(vehicles(k));
    configCase = stage5Configs{k};
    configCase.verbose = false;
    configCase.showProgress = false;
    configCase.showPlots = false;

    vehicleNames{k} = vehicleCase.name;
    bodyTypes{k} = vehicleCase.bodyType;

    if options.verbose
        fprintf('  Running Stage 5 for %s (%d/%d)...\n', ...
            vehicleNames{k}, k, nVehicles);
    end

    stage5Result = runStage5(vehicleCase, constants, configCase);
    stage5Results{k} = stage5Result;

    idxBest = stage5Result.idxBestRange;

    mass_kg(k) = vehicleCase.mass;
    diameter_m(k) = vehicleCase.diameter;
    length_m(k) = vehicleCase.length;
    referenceArea_m2(k) = vehicleCase.referenceArea;
    finenessRatio(k) = vehicleCase.finenessRatio;
    alpha_deg(k) = vehicleCase.alpha_deg;

    bestRangeAngle_deg(k) = stage5Result.bestRangeAngle_deg;
    maxRange_m(k) = stage5Result.bestRange;
    maxAltitudeAtBestRange_m(k) = stage5Result.maxAltitude(idxBest);
    impactSpeedAtBestRange_mps(k) = stage5Result.impactSpeed(idxBest);
    maxMachAtBestRange(k) = stage5Result.maxMach(idxBest);
    maxQAtBestRange_Pa(k) = stage5Result.maxQ(idxBest);
    maxDragAtBestRange_N(k) = stage5Result.maxDrag(idxBest);
    maxLiftAtBestRange_N(k) = stage5Result.maxLift(idxBest);
    maxStagTempAtBestRange_K(k) = stage5Result.maxStagTemp(idxBest);

    if isfield(stage5Result, 'maxLD')
        maxLDAtBestRange(k) = stage5Result.maxLD(idxBest);
    end

    beta_initial_kgpm2(k) = stage5Result.bestRange_beta_initial;
    beta_average_kgpm2(k) = stage5Result.bestRange_beta_average;
    beta_min_kgpm2(k) = stage5Result.bestRange_beta_min;

    if ~isnan(stage5Result.idxBestMaxQConstrained)
        bestMaxQConstrainedAngle_deg(k) = stage5Result.bestMaxQConstrainedAngle_deg;
        bestMaxQConstrainedRange_m(k) = stage5Result.bestMaxQConstrainedRange;
    end

    if ~isnan(stage5Result.idxBestMinRangeAltitude)
        bestMinRangeAltitude_m(k) = stage5Result.bestMinRangeAltitude;
    end

    if ~isempty(stage5Result.idxClosestTarget)
        closestTargetAngle_deg(k) = stage5Result.closestTargetAngle_deg;
    end

    if options.includeThermal
        if options.verbose
            fprintf('  Running Stage 7 thermal estimate for %s best-range case...\n', ...
                vehicleNames{k});
        end

        thermalResult = computeBestRangeThermal(vehicleCase, constants, ...
            bestRangeAngle_deg(k));
        stage7ThermalResults{k} = thermalResult;

        peakHeatFluxAtBestRange_W_m2(k) = thermalResult.peakHeatFlux_W_m2;
        peakHeatFluxTimeAtBestRange_s(k) = thermalResult.peakHeatFluxTime_s;
        totalHeatLoadAtBestRange_J_m2(k) = thermalResult.totalHeatLoad_J_m2;
        peakThermalStagTempAtBestRange_K(k) = thermalResult.peakStagnationTemp_K;
        peakThermalStagTempTimeAtBestRange_s(k) = thermalResult.peakStagnationTempTime_s;

        if isfield(thermalResult, 'maxWallTemp_K')
            maxWallTempAtBestRange_K(k) = thermalResult.maxWallTemp_K;
        end

        if isfield(vehicleCase, 'maxAllowableWallTemp_K') && ...
                ~isnan(maxWallTempAtBestRange_K(k))
            thermalMarginAtBestRange_K(k) = ...
                vehicleCase.maxAllowableWallTemp_K - maxWallTempAtBestRange_K(k);
        end
    end
end

comparison.vehicleNames = vehicleNames;
comparison.bodyTypes = bodyTypes;
comparison.stage5Results = stage5Results;
comparison.stage7ThermalResults = stage7ThermalResults;

comparison.mass_kg = mass_kg;
comparison.diameter_m = diameter_m;
comparison.length_m = length_m;
comparison.referenceArea_m2 = referenceArea_m2;
comparison.finenessRatio = finenessRatio;
comparison.alpha_deg = alpha_deg;

comparison.bestRangeAngle_deg = bestRangeAngle_deg;
comparison.maxRange_m = maxRange_m;
comparison.maxAltitudeAtBestRange_m = maxAltitudeAtBestRange_m;
comparison.impactSpeedAtBestRange_mps = impactSpeedAtBestRange_mps;
comparison.maxMachAtBestRange = maxMachAtBestRange;
comparison.maxQAtBestRange_Pa = maxQAtBestRange_Pa;
comparison.maxDragAtBestRange_N = maxDragAtBestRange_N;
comparison.maxLiftAtBestRange_N = maxLiftAtBestRange_N;
comparison.maxStagTempAtBestRange_K = maxStagTempAtBestRange_K;
comparison.maxLDAtBestRange = maxLDAtBestRange;

comparison.stage7ThermalIncluded = options.includeThermal;
comparison.peakHeatFluxAtBestRange_W_m2 = peakHeatFluxAtBestRange_W_m2;
comparison.peakHeatFluxTimeAtBestRange_s = peakHeatFluxTimeAtBestRange_s;
comparison.totalHeatLoadAtBestRange_J_m2 = totalHeatLoadAtBestRange_J_m2;
comparison.peakThermalStagTempAtBestRange_K = peakThermalStagTempAtBestRange_K;
comparison.peakThermalStagTempTimeAtBestRange_s = peakThermalStagTempTimeAtBestRange_s;
comparison.maxWallTempAtBestRange_K = maxWallTempAtBestRange_K;
comparison.thermalMarginAtBestRange_K = thermalMarginAtBestRange_K;

comparison.beta_initial_kgpm2 = beta_initial_kgpm2;
comparison.beta_average_kgpm2 = beta_average_kgpm2;
comparison.beta_min_kgpm2 = beta_min_kgpm2;

comparison.bestMaxQConstrainedAngle_deg = bestMaxQConstrainedAngle_deg;
comparison.bestMaxQConstrainedRange_m = bestMaxQConstrainedRange_m;
comparison.bestMinRangeAltitude_m = bestMinRangeAltitude_m;
comparison.closestTargetAngle_deg = closestTargetAngle_deg;

comparison.idxBestRange = findBestIndex(maxRange_m);
comparison.idxBestAltitudeWithMinRange = findBestIndex(bestMinRangeAltitude_m);
comparison.idxBestMaxQConstrained = findBestIndex(bestMaxQConstrainedRange_m);
comparison.idxHighestBeta = findBestIndex(beta_average_kgpm2);
comparison.idxLowestMaxQ = findBestIndex(-maxQAtBestRange_Pa);
comparison.idxBestLD = findBestIndex(maxLDAtBestRange);
comparison.idxLowestPeakHeatFlux = findBestIndex(-peakHeatFluxAtBestRange_W_m2);
comparison.idxLowestTotalHeatLoad = findBestIndex(-totalHeatLoadAtBestRange_J_m2);
comparison.idxLowestMaxWallTemp = findBestIndex(-maxWallTempAtBestRange_K);
comparison.idxBestThermalMargin = findBestIndex(thermalMarginAtBestRange_K);

end

function vehicle = prepareVehicleForStage5(vehicle)
if ~isfield(vehicle, 'name')
    vehicle.name = 'Unnamed vehicle';
end

if ~isfield(vehicle, 'bodyType')
    vehicle.bodyType = vehicle.name;
end

vehicle.area = pi * vehicle.diameter^2 / 4;
vehicle.referenceArea = vehicle.area;
vehicle.fineness = vehicle.length / vehicle.diameter;
vehicle.finenessRatio = vehicle.fineness;
vehicle.alpha = deg2rad(vehicle.alpha_deg);

if ~isfield(vehicle, 'noseRadius_m') || isempty(vehicle.noseRadius_m) || ...
        vehicle.noseRadius_m <= 0
    vehicle.noseRadius_m = vehicle.diameter / 2;
end

if ~isfield(vehicle, 'launchAzimuth') && isfield(vehicle, 'launchAzimuth_deg')
    vehicle.launchAzimuth = deg2rad(vehicle.launchAzimuth_deg);
end

if isfield(vehicle, 'M_table_stage3')
    vehicle.M_table = vehicle.M_table_stage3;
end

if ~isfield(vehicle, 'Cd_table') && isfield(vehicle, 'Cd0_table_stage3')
    vehicle.Cd_table = vehicle.Cd0_table_stage3;
end
end

function thermal = computeBestRangeThermal(vehicle, constants, launchAngle_deg)
vehicleCase = vehicle;
vehicleCase.launchAngle = deg2rad(launchAngle_deg);

if ~isfield(vehicleCase, 'launchAzimuth') && isfield(vehicleCase, 'launchAzimuth_deg')
    vehicleCase.launchAzimuth = deg2rad(vehicleCase.launchAzimuth_deg);
end

[t, state] = runStage4(vehicleCase, constants);
trajectoryResults = postProcess_stage4(t, state, vehicleCase, constants);
thermal = computeThermalLoads_stage7(trajectoryResults, vehicleCase, constants, struct());
end

function idxBest = findBestIndex(values)
validValues = values;
validValues(isnan(validValues)) = -Inf;

if all(isinf(validValues))
    idxBest = NaN;
else
    [~, idxBest] = max(validValues);
end
end
