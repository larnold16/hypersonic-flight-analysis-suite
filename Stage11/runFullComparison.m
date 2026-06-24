function results = runFullComparison(vehicle, constants, config)
% runFullComparison
% Runs every selected body type over every selected launch angle.

library = vehicleLibrary_stage11(vehicle);
angles = config.launchAngles_deg(:);
caseRows = {};
cases = {};

for b = 1:numel(library)
    for a = 1:numel(angles)
        caseVehicle = library(b);
        caseVehicle.launchAngle = angles(a);
        caseConfig = config;
        caseConfig.launchAngle_deg = angles(a);
        caseConfig.showPlots = false;
        caseConfig.exportResults = false;
        caseConfig.generateReport = false;

        caseResult = runSingleTrajectory(caseVehicle, constants, caseConfig);
        cases{end+1, 1} = caseResult; %#ok<AGROW>
        caseRows(end+1, :) = {string(caseVehicle.bodyType), angles(a), ...
            caseResult.range, caseResult.maxAltitude, caseResult.timeOfFlight, ...
            caseResult.impactSpeed, caseResult.maxMach, caseResult.maxQ, ...
            caseResult.maxHeatingRate, caseResult.totalHeatLoad, caseResult.maxGLoad, ...
            caseVehicle.staticMargin, caseResult.failed || ~caseResult.impactDetected}; %#ok<AGROW>
    end
end

summaryTable = cell2table(caseRows, 'VariableNames', {'BodyType','LaunchAngle_deg', ...
    'Range_m','MaxAltitude_m','TimeOfFlight_s','ImpactSpeed_mps','MaxMach', ...
    'MaxQ_Pa','MaxHeating_W_m2','TotalHeatLoad_J_m2','MaxGLoad_g', ...
    'StaticMargin','Failed'});

score = normalizeHigh(summaryTable.Range_m) + normalizeHigh(summaryTable.MaxAltitude_m) + ...
    normalizeLow(summaryTable.MaxHeating_W_m2) + normalizeLow(summaryTable.MaxQ_Pa) + ...
    normalizeLow(summaryTable.MaxGLoad_g) + normalizeHigh(summaryTable.StaticMargin);
score(summaryTable.Failed) = -Inf;
summaryTable.Score = score;

[~, idxRange] = max(summaryTable.Range_m);
[~, idxAltitude] = max(summaryTable.MaxAltitude_m);
[~, idxHeating] = min(summaryTable.MaxHeating_W_m2);
[~, idxQ] = min(summaryTable.MaxQ_Pa);
[~, idxStable] = max(summaryTable.StaticMargin);
[~, idxScore] = max(summaryTable.Score);

results.mode = 'FullComparison';
results.cases = cases;
results.summaryTable = summaryTable;
results.bestRangeCase = summaryTable(idxRange,:);
results.bestAltitudeCase = summaryTable(idxAltitude,:);
results.lowestHeatingCase = summaryTable(idxHeating,:);
results.lowestMaxQCase = summaryTable(idxQ,:);
results.mostStableCase = summaryTable(idxStable,:);
results.recommendedCase = summaryTable(idxScore,:);
results.failed = any(summaryTable.Failed);
results.warnings = {};
end

function y = normalizeHigh(x)
x = x(:);
finite = isfinite(x);
y = zeros(size(x));
if any(finite)
    xmin = min(x(finite));
    xmax = max(x(finite));
    y(finite) = (x(finite) - xmin) ./ max(xmax - xmin, eps);
end
end

function y = normalizeLow(x)
y = 1 - normalizeHigh(x);
end
