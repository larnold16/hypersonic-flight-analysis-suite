function results = parameterSweep_stage5(vehicle, constants, stage5Config)
% parameterSweep_stage5
% Sweeps launch angle and records Stage 4 trajectory performance metrics.

launchAngles_deg = stage5Config.launchAngles_deg(:);
nCases = length(launchAngles_deg);

if ~isfield(stage5Config, 'showProgress')
    stage5Config.showProgress = true;
end

range = zeros(nCases,1);
maxAltitude = zeros(nCases,1);
impactSpeed = zeros(nCases,1);
maxMach = zeros(nCases,1);
maxQ = zeros(nCases,1);
maxDrag = zeros(nCases,1);
maxLift = zeros(nCases,1);
maxLD = zeros(nCases,1);
maxStagTemp = zeros(nCases,1);
beta_initial = zeros(nCases,1);
beta_average = zeros(nCases,1);
beta_min = zeros(nCases,1);

% Make the Stage 4 aliases robust in case Stage 5 is called directly.
if ~isfield(vehicle, 'referenceArea')
    vehicle.referenceArea = vehicle.area;
end

if ~isfield(vehicle, 'finenessRatio')
    vehicle.finenessRatio = vehicle.fineness;
end

if ~isfield(vehicle, 'alpha')
    vehicle.alpha = deg2rad(vehicle.alpha_deg);
end

if ~isfield(vehicle, 'launchAzimuth')
    vehicle.launchAzimuth = deg2rad(vehicle.launchAzimuth_deg);
end

if ~isfield(vehicle, 'M_table') && isfield(vehicle, 'M_table_stage3')
    vehicle.M_table = vehicle.M_table_stage3;
end

if ~isfield(vehicle, 'Cd_table') && isfield(vehicle, 'Cd0_table_stage3')
    vehicle.Cd_table = vehicle.Cd0_table_stage3;
end

for k = 1:nCases
    vehicleCase = vehicle;
    vehicleCase.launchAngle = deg2rad(launchAngles_deg(k));

    if stage5Config.showProgress
        fprintf('  Case %2d/%2d: launch angle = %.2f deg\n', ...
            k, nCases, launchAngles_deg(k));
    end

    [t, state] = runStage4(vehicleCase, constants);
    caseResults = postProcess_stage4(t, state, vehicleCase, constants);

    range(k) = caseResults.range;
    maxAltitude(k) = caseResults.maxAltitude;
    impactSpeed(k) = caseResults.impactSpeed;
    maxMach(k) = caseResults.maxMach;
    maxQ(k) = caseResults.maxQ;
    maxDrag(k) = caseResults.maxDrag;
    maxLift(k) = caseResults.maxLift;
    maxLD(k) = caseResults.maxLD;
    maxStagTemp(k) = caseResults.maxStagTemp;
    beta_initial(k) = caseResults.beta_initial;
    beta_average(k) = caseResults.beta_average;
    beta_min(k) = caseResults.beta_min;
end

[bestRange, idxBestRange] = max(range);
[bestAltitude, idxBestAltitude] = max(maxAltitude);

feasibleMaxQ = maxQ <= stage5Config.maxQ_limit;
idxFeasible = find(feasibleMaxQ);

if any(feasibleMaxQ)
    [bestMaxQConstrainedRange, idxLocalBest] = max(range(feasibleMaxQ));
    idxBestMaxQConstrained = idxFeasible(idxLocalBest);
    bestMaxQConstrainedAngle_deg = launchAngles_deg(idxBestMaxQConstrained);
    bestMaxQConstrainedAltitude = maxAltitude(idxBestMaxQConstrained);
else
    bestMaxQConstrainedRange = NaN;
    idxBestMaxQConstrained = NaN;
    bestMaxQConstrainedAngle_deg = NaN;
    bestMaxQConstrainedAltitude = NaN;
end

if isfield(stage5Config, 'minRangeForAltitude_m')
    minRangeForAltitude_m = stage5Config.minRangeForAltitude_m;
else
    minRangeForAltitude_m = 30000;
end

if ~isempty(minRangeForAltitude_m)
    feasibleMinRange = range >= minRangeForAltitude_m;
    idxRangeFeasible = find(feasibleMinRange);

    if any(feasibleMinRange)
        [bestMinRangeAltitude, idxLocalBest] = max(maxAltitude(feasibleMinRange));
        idxBestMinRangeAltitude = idxRangeFeasible(idxLocalBest);
        bestMinRangeAltitudeAngle_deg = launchAngles_deg(idxBestMinRangeAltitude);
    else
        bestMinRangeAltitude = NaN;
        idxBestMinRangeAltitude = NaN;
        bestMinRangeAltitudeAngle_deg = NaN;
    end
else
    feasibleMinRange = false(nCases,1);
    bestMinRangeAltitude = NaN;
    idxBestMinRangeAltitude = NaN;
    bestMinRangeAltitudeAngle_deg = NaN;
end

targetRange = stage5Config.targetRange;

if ~isempty(targetRange)
    [closestTargetError, idxClosestTarget] = min(abs(range - targetRange));
    closestTargetAngle_deg = launchAngles_deg(idxClosestTarget);
    closestTargetRange = range(idxClosestTarget);
else
    closestTargetError = [];
    idxClosestTarget = [];
    closestTargetAngle_deg = [];
    closestTargetRange = [];
end

results.launchAngles_deg = launchAngles_deg;
results.range = range;
results.maxAltitude = maxAltitude;
results.impactSpeed = impactSpeed;
results.maxMach = maxMach;
results.maxQ = maxQ;
results.maxDrag = maxDrag;
results.maxLift = maxLift;
results.maxLD = maxLD;
results.maxStagTemp = maxStagTemp;
results.beta_initial = beta_initial;
results.beta_average = beta_average;
results.beta_min = beta_min;

results.range_m = range;
results.maxAltitude_m = maxAltitude;
results.impactSpeed_mps = impactSpeed;
results.maxQ_Pa = maxQ;
results.maxDrag_N = maxDrag;
results.maxLift_N = maxLift;
results.maxLD_ratio = maxLD;
results.maxStagTemp_K = maxStagTemp;
results.beta_initial_kgpm2 = beta_initial;
results.beta_average_kgpm2 = beta_average;
results.beta_min_kgpm2 = beta_min;

results.maxQ_limit = stage5Config.maxQ_limit;
results.minRangeForAltitude_m = minRangeForAltitude_m;
results.targetRange = targetRange;

results.idxBestRange = idxBestRange;
results.bestRangeAngle_deg = launchAngles_deg(idxBestRange);
results.bestRange = bestRange;
results.bestRange_beta_initial = beta_initial(idxBestRange);
results.bestRange_beta_average = beta_average(idxBestRange);
results.bestRange_beta_min = beta_min(idxBestRange);

results.idxBestAltitude = idxBestAltitude;
results.bestAltitudeAngle_deg = launchAngles_deg(idxBestAltitude);
results.bestAltitude = bestAltitude;
results.bestAltitude_beta_initial = beta_initial(idxBestAltitude);
results.bestAltitude_beta_average = beta_average(idxBestAltitude);
results.bestAltitude_beta_min = beta_min(idxBestAltitude);

results.feasibleMaxQ = feasibleMaxQ;
results.idxBestMaxQConstrained = idxBestMaxQConstrained;
results.bestMaxQConstrainedAngle_deg = bestMaxQConstrainedAngle_deg;
results.bestMaxQConstrainedRange = bestMaxQConstrainedRange;
results.bestMaxQConstrainedAltitude = bestMaxQConstrainedAltitude;
if ~isnan(idxBestMaxQConstrained)
    results.bestMaxQConstrained_beta_initial = beta_initial(idxBestMaxQConstrained);
    results.bestMaxQConstrained_beta_average = beta_average(idxBestMaxQConstrained);
    results.bestMaxQConstrained_beta_min = beta_min(idxBestMaxQConstrained);
else
    results.bestMaxQConstrained_beta_initial = NaN;
    results.bestMaxQConstrained_beta_average = NaN;
    results.bestMaxQConstrained_beta_min = NaN;
end

results.feasibleMinRange = feasibleMinRange;
results.idxBestMinRangeAltitude = idxBestMinRangeAltitude;
results.bestMinRangeAltitudeAngle_deg = bestMinRangeAltitudeAngle_deg;
results.bestMinRangeAltitude = bestMinRangeAltitude;
if ~isnan(idxBestMinRangeAltitude)
    results.bestMinRangeAltitude_beta_initial = beta_initial(idxBestMinRangeAltitude);
    results.bestMinRangeAltitude_beta_average = beta_average(idxBestMinRangeAltitude);
    results.bestMinRangeAltitude_beta_min = beta_min(idxBestMinRangeAltitude);
else
    results.bestMinRangeAltitude_beta_initial = NaN;
    results.bestMinRangeAltitude_beta_average = NaN;
    results.bestMinRangeAltitude_beta_min = NaN;
end

results.idxClosestTarget = idxClosestTarget;
results.closestTargetAngle_deg = closestTargetAngle_deg;
results.closestTargetRange = closestTargetRange;
results.closestTargetError = closestTargetError;
if ~isempty(idxClosestTarget)
    results.closestTarget_beta_initial = beta_initial(idxClosestTarget);
    results.closestTarget_beta_average = beta_average(idxClosestTarget);
    results.closestTarget_beta_min = beta_min(idxClosestTarget);
else
    results.closestTarget_beta_initial = [];
    results.closestTarget_beta_average = [];
    results.closestTarget_beta_min = [];
end

end
