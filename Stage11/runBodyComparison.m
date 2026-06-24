function results = runBodyComparison(vehicle, constants, config)
% runBodyComparison
% Compares preset body geometries using one launch condition.

library = vehicleLibrary_stage11(vehicle);
selected = selectVehicles(library, config.bodyNames);
n = numel(selected);
cases = cell(n, 1);

bodyType = strings(n, 1);
range = nan(n, 1);
maxAltitude = nan(n, 1);
impactSpeed = nan(n, 1);
maxMach = nan(n, 1);
maxQ = nan(n, 1);
maxHeating = nan(n, 1);
maxG = nan(n, 1);
staticMargin = nan(n, 1);
ballisticCoefficient = nan(n, 1);
failed = false(n, 1);

for k = 1:n
    caseVehicle = selected(k);
    caseConfig = config;
    caseConfig.showPlots = false;
    caseConfig.exportResults = false;
    caseConfig.generateReport = false;

    caseResult = runSingleTrajectory(caseVehicle, constants, caseConfig);
    cases{k} = caseResult;

    bodyType(k) = string(caseVehicle.bodyType);
    range(k) = caseResult.range;
    maxAltitude(k) = caseResult.maxAltitude;
    impactSpeed(k) = caseResult.impactSpeed;
    maxMach(k) = caseResult.maxMach;
    maxQ(k) = caseResult.maxQ;
    maxHeating(k) = caseResult.maxHeatingRate;
    maxG(k) = caseResult.maxGLoad;
    staticMargin(k) = caseVehicle.staticMargin;
    ballisticCoefficient(k) = caseResult.ballisticCoefficient(1);
    failed(k) = caseResult.failed || ~caseResult.impactDetected;
end

summaryTable = table(bodyType, range, maxAltitude, impactSpeed, maxMach, maxQ, ...
    maxHeating, maxG, staticMargin, ballisticCoefficient, failed, ...
    'VariableNames', {'BodyType','Range_m','MaxAltitude_m','ImpactSpeed_mps', ...
    'MaxMach','MaxQ_Pa','MaxHeating_W_m2','MaxGLoad_g','StaticMargin', ...
    'BallisticCoefficient_kg_m2','Failed'});

results.mode = 'BodyComparison';
results.cases = cases;
results.summaryTable = summaryTable;
results.bodyType = bodyType;
results.range = range;
results.maxAltitude = maxAltitude;
results.impactSpeed = impactSpeed;
results.maxMach = maxMach;
results.maxQ = maxQ;
results.maxHeatingRate = maxHeating;
results.maxGLoad = maxG;
results.staticMargin = staticMargin;
results.failed = any(failed);
results.warnings = {};

if any(failed)
    results.warnings{end+1} = sprintf('%d body comparison cases failed or did not impact.', sum(failed));
end
end

function selected = selectVehicles(library, names)
selected = repmat(library(1), 0, 1);
for k = 1:numel(names)
    for j = 1:numel(library)
        if strcmpi(library(j).bodyType, names{k})
            selected(end+1, 1) = library(j); %#ok<AGROW>
            break;
        end
    end
end
if isempty(selected)
    selected = library(:);
end
end
