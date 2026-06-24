function compare = runScenarioSweepStage14(vehicle, constants, baseConfig, sweepMode, missionGoal, manualText, progressCallback)
% runScenarioSweepStage14
% Runs multiple Stage 11 cases side-by-side for Scenario Compare mode.

if nargin < 4 || strlength(string(sweepMode)) == 0
    sweepMode = "Launch angle sweep";
end
if nargin < 5 || strlength(string(missionGoal)) == 0
    missionGoal = "Balanced";
end
if nargin < 6
    manualText = "";
end
if nargin < 7
    progressCallback = [];
end

cases = buildScenarioCases(vehicle, baseConfig, sweepMode, manualText);
n = numel(cases);
caseResults = cell(n, 1);
for k = 1:n
    reportProgress(progressCallback, 0.05 + 0.82 * (k - 1) / max(n, 1), ...
        sprintf('Scenario Compare case %d of %d: %s', k, n, char(cases(k).CaseName)));
    caseResults{k} = runSingleScenarioStage14(vehicle, constants, baseConfig, cases(k), missionGoal);
end

reportProgress(progressCallback, 0.90, "Summarizing scenario comparison...");
summaryTable = scenarioComparisonTableStage14(caseResults, missionGoal);
bestIndex = selectBestCase(summaryTable, missionGoal);
if bestIndex >= 1 && bestIndex <= height(summaryTable)
    summaryTable.BestCase(:) = false;
    summaryTable.BestCase(bestIndex) = true;
end

compare = struct();
compare.sweepMode = string(sweepMode);
compare.missionGoal = string(missionGoal);
compare.caseSpecs = cases;
compare.caseResults = caseResults;
compare.summaryTable = summaryTable;
compare.bestCaseIndex = bestIndex;
compare.bestCaseName = "";
if bestIndex >= 1 && bestIndex <= height(summaryTable)
    compare.bestCaseName = summaryTable.CaseName(bestIndex);
end
compare.insights = scenarioCompareInsightsStage14(compare);
reportProgress(progressCallback, 1.0, "Scenario comparison complete.");
end

function cases = buildScenarioCases(vehicle, baseConfig, sweepMode, manualText)
mode = lower(string(sweepMode));
base = baselineCase(vehicle, baseConfig);
cases = base;

if contains(mode, "launch angle")
    values = [5 10 15 20 25];
    cases = repmat(base, numel(values), 1);
    for k = 1:numel(values)
        cases(k).CaseName = sprintf('Angle %d deg', values(k));
        cases(k).LaunchAngle_deg = values(k);
        cases(k).OutputSuffix = sprintf('angle_%02d', values(k));
    end
elseif contains(mode, "velocity")
    values = [1200 1500 1800 2100];
    cases = repmat(base, numel(values), 1);
    for k = 1:numel(values)
        cases(k).CaseName = sprintf('Velocity %d mps', values(k));
        cases(k).InitialVelocity_mps = values(k);
        cases(k).OutputSuffix = sprintf('velocity_%04d', values(k));
    end
elseif contains(mode, "mass")
    factors = [0.8 1.0 1.2];
    labels = ["Low mass"; "Baseline mass"; "High mass"];
    cases = repmat(base, numel(factors), 1);
    for k = 1:numel(factors)
        cases(k).CaseName = labels(k);
        cases(k).Mass_kg = base.Mass_kg * factors(k);
        cases(k).OutputSuffix = matlab.lang.makeValidName(char(labels(k)));
    end
elseif contains(mode, "diameter")
    factors = [0.85 1.0 1.15];
    labels = ["Low diameter"; "Baseline diameter"; "High diameter"];
    cases = repmat(base, numel(factors), 1);
    for k = 1:numel(factors)
        cases(k).CaseName = labels(k);
        cases(k).Diameter_m = base.Diameter_m * factors(k);
        cases(k).OutputSuffix = matlab.lang.makeValidName(char(labels(k)));
    end
elseif contains(mode, "body type")
    names = ["Slender cone"; "Blunt body"; "Custom baseline"];
    cases = repmat(base, numel(names), 1);
    for k = 1:numel(names)
        cases(k).CaseName = names(k);
        cases(k).BodyType = names(k);
        cases(k).OutputSuffix = matlab.lang.makeValidName(char(names(k)));
    end
elseif contains(mode, "custom")
    cases = parseManualCases(manualText, base);
else
    cases = base;
end
end

function base = baselineCase(vehicle, baseConfig)
base = struct();
base.CaseName = "Baseline";
base.LaunchAngle_deg = getConfigField(baseConfig, 'launchAngle_deg', getVehicleField(vehicle, 'launchAngle', 25));
base.InitialVelocity_mps = getConfigField(baseConfig, 'launchSpeed_mps', getVehicleField(vehicle, 'V0', 1800));
base.Mass_kg = getVehicleField(vehicle, 'mass', 5);
base.Diameter_m = getVehicleField(vehicle, 'diameter', 0.0564);
base.Length_m = getVehicleField(vehicle, 'length', 0.45);
base.CdScale = getVehicleField(vehicle, 'Cd_scale', 1.0);
base.CLScale = getVehicleField(vehicle, 'CL_scale', 1.0);
base.BodyType = string(getVehicleField(vehicle, 'bodyType', 'Custom baseline'));
base.StaticMargin_percent = 100 * (getVehicleField(vehicle, 'cpLocation_m', 0.6 * base.Length_m) - ...
    getVehicleField(vehicle, 'cgLocation_m', 0.5 * base.Length_m)) / max(base.Length_m, eps);
base.Alpha_deg = getVehicleField(vehicle, 'alpha_deg', 2.0);
base.OutputSuffix = "baseline";
end

function cases = parseManualCases(manualText, base)
lines = splitlines(string(manualText));
cases = repmat(base, 0, 1);
for k = 1:numel(lines)
    line = strtrim(lines(k));
    if strlength(line) == 0
        continue;
    end
    parts = strtrim(split(line, ','));
    c = base;
    c.CaseName = parts(1);
    c.OutputSuffix = matlab.lang.makeValidName(char(c.CaseName));
    if numel(parts) >= 2, c.LaunchAngle_deg = str2numDefault(parts(2), c.LaunchAngle_deg); end %#ok<ST2NM>
    if numel(parts) >= 3, c.InitialVelocity_mps = str2numDefault(parts(3), c.InitialVelocity_mps); end
    if numel(parts) >= 4, c.Mass_kg = str2numDefault(parts(4), c.Mass_kg); end
    if numel(parts) >= 5, c.Diameter_m = str2numDefault(parts(5), c.Diameter_m); end
    if numel(parts) >= 6, c.Length_m = str2numDefault(parts(6), c.Length_m); end
    if numel(parts) >= 7, c.CdScale = str2numDefault(parts(7), c.CdScale); end
    if numel(parts) >= 8 && strlength(parts(8)) > 0, c.BodyType = parts(8); end
    if numel(parts) >= 9, c.StaticMargin_percent = str2numDefault(parts(9), c.StaticMargin_percent); end
    if numel(parts) >= 10, c.Alpha_deg = str2numDefault(parts(10), c.Alpha_deg); end
    cases(end+1, 1) = c; %#ok<AGROW>
end
if isempty(cases)
    cases = base;
end
end

function T = scenarioComparisonTableStage14(caseResults, missionGoal)
n = numel(caseResults);
CaseID = strings(n, 1);
CaseName = strings(n, 1);
LaunchAngle_deg = nan(n, 1);
InitialVelocity_mps = nan(n, 1);
BodyType = strings(n, 1);
Range_km = nan(n, 1);
MaxAltitude_km = nan(n, 1);
ImpactSpeed_mps = nan(n, 1);
TimeToImpact_s = nan(n, 1);
MaxMach = nan(n, 1);
MaxDynamicPressure_kPa = nan(n, 1);
MaxDrag_N = nan(n, 1);
MaxLift_N = nan(n, 1);
MaxStagTemp_K = nan(n, 1);
MaxLD = nan(n, 1);
HeatingRisk = strings(n, 1);
StructuralLoadRisk = strings(n, 1);
OverallDesignScore = nan(n, 1);
BestCase = false(n, 1);

for k = 1:n
    r = caseResults{k};
    score = computeDesignScoreStage14(r, missionGoal);
    CaseID(k) = "CMP-" + compose("%03d", k);
    CaseName(k) = string(getResultField(r, 'caseName', "Case " + k));
    LaunchAngle_deg(k) = inputValue(r, 'Launch angle deg');
    InitialVelocity_mps(k) = inputValue(r, 'Initial velocity m/s');
    BodyType(k) = stringInputValue(r, 'Body type');
    Range_km(k) = safeScalar(r, 'range') / 1000;
    MaxAltitude_km(k) = safeScalar(r, 'maxAltitude') / 1000;
    ImpactSpeed_mps(k) = safeScalar(r, 'impactSpeed');
    TimeToImpact_s(k) = safeScalar(r, 'timeOfFlight');
    MaxMach(k) = safeScalar(r, 'maxMach');
    MaxDynamicPressure_kPa(k) = safeScalar(r, 'maxQ') / 1000;
    MaxDrag_N(k) = safeScalar(r, 'maxDrag');
    MaxLift_N(k) = safeScalar(r, 'maxLift');
    MaxStagTemp_K(k) = safeScalar(r, 'maxStagTemp');
    MaxLD(k) = safeScalar(r, 'maxLD');
    HeatingRisk(k) = score.HeatingRisk;
    StructuralLoadRisk(k) = score.StructuralLoadRisk;
    OverallDesignScore(k) = score.OverallDesignScore;
end

T = table(CaseID, CaseName, LaunchAngle_deg, InitialVelocity_mps, BodyType, ...
    Range_km, MaxAltitude_km, ImpactSpeed_mps, TimeToImpact_s, MaxMach, ...
    MaxDynamicPressure_kPa, MaxDrag_N, MaxLift_N, MaxStagTemp_K, MaxLD, ...
    HeatingRisk, StructuralLoadRisk, OverallDesignScore, BestCase);
end

function idx = selectBestCase(T, missionGoal)
goal = lower(string(missionGoal));
idx = 1;
if isempty(T) || height(T) == 0
    idx = 0;
elseif contains(goal, "range")
    [~, idx] = max(T.Range_km);
elseif contains(goal, "altitude")
    [~, idx] = max(T.MaxAltitude_km);
elseif contains(goal, "heating")
    [~, idx] = min(T.MaxStagTemp_K);
elseif contains(goal, "structural")
    [~, idx] = min(T.MaxDynamicPressure_kPa);
else
    [~, idx] = max(T.OverallDesignScore);
end
end

function reportProgress(callback, fraction, message)
if ~isempty(callback)
    try
        callback(fraction, message);
    catch
    end
end
drawnow;
end

function value = inputValue(results, name)
value = NaN;
if isstruct(results) && isfield(results, 'inputParameters') && istable(results.inputParameters)
    idx = find(strcmpi(string(results.inputParameters.Parameter), string(name)), 1);
    if ~isempty(idx)
        value = str2double(string(results.inputParameters.Value(idx)));
    end
end
end

function value = stringInputValue(results, name)
value = "";
if isstruct(results) && isfield(results, 'inputParameters') && istable(results.inputParameters)
    idx = find(strcmpi(string(results.inputParameters.Parameter), string(name)), 1);
    if ~isempty(idx)
        value = string(results.inputParameters.Value(idx));
    end
end
end

function value = str2numDefault(text, defaultValue)
value = str2double(string(text));
if ~isfinite(value)
    value = defaultValue;
end
end

function value = safeScalar(s, fieldName)
value = NaN;
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName)) && isnumeric(s.(fieldName))
    value = s.(fieldName)(1);
end
end

function value = getResultField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end

function value = getVehicleField(vehicle, name, defaultValue)
if isstruct(vehicle) && isfield(vehicle, name) && ~isempty(vehicle.(name))
    value = vehicle.(name);
else
    value = defaultValue;
end
end

function value = getConfigField(config, name, defaultValue)
if isstruct(config) && isfield(config, name) && ~isempty(config.(name))
    value = config.(name);
else
    value = defaultValue;
end
end
