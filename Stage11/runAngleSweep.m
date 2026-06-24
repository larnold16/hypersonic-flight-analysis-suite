function results = runAngleSweep(vehicle, constants, config)
% runAngleSweep
% Runs the Stage 11 solver over a vector of launch angles.

angles = config.launchAngles_deg(:);
n = numel(angles);
cases = cell(n, 1);

launchAngle = zeros(n, 1);
range = nan(n, 1);
maxAltitude = nan(n, 1);
timeOfFlight = nan(n, 1);
impactSpeed = nan(n, 1);
maxMach = nan(n, 1);
maxQ = nan(n, 1);
maxStagTemp = nan(n, 1);
maxHeating = nan(n, 1);
maxG = nan(n, 1);
maxAlpha = nan(n, 1);
stabilityWarning = false(n, 1);
failed = false(n, 1);

for k = 1:n
    caseConfig = config;
    caseConfig.launchAngle_deg = angles(k);
    caseConfig.showPlots = false;
    caseConfig.exportResults = false;
    caseConfig.generateReport = false;
    caseConfig.interactive = false;

    caseVehicle = vehicle;
    caseVehicle.launchAngle = angles(k);
    caseResult = runSingleTrajectory(caseVehicle, constants, caseConfig);
    cases{k} = caseResult;

    launchAngle(k) = angles(k);
    range(k) = getResultField(caseResult, 'range', NaN);
    maxAltitude(k) = getResultField(caseResult, 'maxAltitude', NaN);
    timeOfFlight(k) = getResultField(caseResult, 'timeOfFlight', NaN);
    impactSpeed(k) = getResultField(caseResult, 'impactSpeed', NaN);
    maxMach(k) = getResultField(caseResult, 'maxMach', NaN);
    maxQ(k) = getResultField(caseResult, 'maxQ', NaN);
    maxStagTemp(k) = getResultField(caseResult, 'maxStagTemp', NaN);
    maxHeating(k) = getResultField(caseResult, 'maxHeatingRate', NaN);
    maxG(k) = getResultField(caseResult, 'maxGLoad', NaN);
    maxAlpha(k) = getResultField(caseResult, 'maxAlpha_deg', NaN);
    minStaticMargin = getResultField(caseResult, 'minStaticMargin', NaN);
    stabilityWarning(k) = isfinite(minStaticMargin) && minStaticMargin < config.warningLimits.minStaticMargin;
    failed(k) = getResultField(caseResult, 'failed', true) || ~getResultField(caseResult, 'impactDetected', false);
end

function value = getResultField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end

summaryTable = table(launchAngle, range, maxAltitude, timeOfFlight, impactSpeed, ...
    maxMach, maxQ, maxStagTemp, maxHeating, maxG, maxAlpha, stabilityWarning, failed, ...
    'VariableNames', {'LaunchAngle_deg','Range_m','MaxAltitude_m','TimeOfFlight_s', ...
    'ImpactSpeed_mps','MaxMach','MaxQ_Pa','MaxStagnationTemp_K','MaxHeating_W_m2', ...
    'MaxGLoad_g','MaxAlpha_deg','StabilityWarning','Failed'});

results.mode = 'AngleSweep';
results.cases = cases;
results.summaryTable = summaryTable;
results.launchAngles_deg = launchAngle;
results.range = range;
results.maxAltitude = maxAltitude;
results.timeOfFlight = timeOfFlight;
results.impactSpeed = impactSpeed;
results.maxMach = maxMach;
results.maxQ = maxQ;
results.maxHeatingRate = maxHeating;
results.maxGLoad = maxG;
results.failed = any(failed);
results.warnings = {};

if any(failed)
    results.warnings{end+1} = sprintf('%d launch-angle cases failed or did not impact.', sum(failed));
end
end
