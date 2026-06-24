function uncertainty = computeUncertaintyBandsStage14(vehicle, constants, baseConfig, options, progressCallback)
% computeUncertaintyBandsStage14
% Runs deterministic low/high perturbation cases and creates envelopes for
% selected trajectory plots without overwriting the baseline simulation.

if nargin < 4 || isempty(options)
    options = struct();
end
if nargin < 5
    progressCallback = [];
end

baseline = runSingleScenarioStage14(vehicle, constants, baseConfig, ...
    struct('CaseName', 'UNC-baseline', 'OutputSuffix', 'UNC_baseline'), "Balanced");
perturbations = buildPerturbations(options);
cases = cell(numel(perturbations) + 1, 1);
caseNames = strings(numel(cases), 1);
cases{1} = baseline;
caseNames(1) = "Baseline";

for k = 1:numel(perturbations)
    callProgress(progressCallback, 0.05 + 0.85 * k / max(numel(perturbations), 1), ...
        sprintf('Uncertainty case %d of %d', k, numel(perturbations)));
    cases{k+1} = runPerturbedCase(vehicle, constants, baseConfig, perturbations(k));
    caseNames(k+1) = perturbations(k).name;
end

bands = buildBands(baseline, cases);
summaryTable = buildSummaryTable(baseline, cases, caseNames);
caseTable = buildCaseTable(cases, caseNames);
insights = buildInsights(summaryTable, caseTable);

uncertainty = struct();
uncertainty.baseline = baseline;
uncertainty.cases = cases;
uncertainty.caseNames = caseNames;
uncertainty.caseTable = caseTable;
uncertainty.summaryTable = summaryTable;
uncertainty.bands = bands;
uncertainty.insights = insights;
callProgress(progressCallback, 1.0, 'Uncertainty bands complete.');
end

function perturbations = buildPerturbations(options)
perturbations = struct('name', {}, 'field', {}, 'scale', {}, 'delta', {});
addPct('Cd -', 'CdScale', -getField(options, 'cd_pct', 10));
addPct('Cd +', 'CdScale', getField(options, 'cd_pct', 10));
addPct('Initial velocity -', 'InitialVelocity_mps', -getField(options, 'speed_pct', 2));
addPct('Initial velocity +', 'InitialVelocity_mps', getField(options, 'speed_pct', 2));
addAbs('Launch angle -', 'LaunchAngle_deg', -getField(options, 'angle_deg', 1));
addAbs('Launch angle +', 'LaunchAngle_deg', getField(options, 'angle_deg', 1));
addPct('Mass -', 'Mass_kg', -getField(options, 'mass_pct', 5));
addPct('Mass +', 'Mass_kg', getField(options, 'mass_pct', 5));
addPct('Diameter -', 'Diameter_m', -getField(options, 'diameter_pct', 2));
addPct('Diameter +', 'Diameter_m', getField(options, 'diameter_pct', 2));
addPct('Density -', 'DensityMultiplier', -getField(options, 'density_pct', 10));
addPct('Density +', 'DensityMultiplier', getField(options, 'density_pct', 10));

    function addPct(name, field, pct)
        if isfinite(pct) && abs(pct) > 0
            perturbations(end+1).name = string(name); %#ok<AGROW>
            perturbations(end).field = field;
            perturbations(end).scale = true;
            perturbations(end).delta = pct / 100;
        end
    end
    function addAbs(name, field, delta)
        if isfinite(delta) && abs(delta) > 0
            perturbations(end+1).name = string(name); %#ok<AGROW>
            perturbations(end).field = field;
            perturbations(end).scale = false;
            perturbations(end).delta = delta;
        end
    end
end

function result = runPerturbedCase(vehicle, constants, baseConfig, perturbation)
v = vehicle;
cfg = baseConfig;
safeName = matlab.lang.makeValidName(char(perturbation.name));
spec = struct('CaseName', ['UNC-', safeName], 'OutputSuffix', ['UNC_', safeName]);

field = perturbation.field;
if strcmp(field, 'DensityMultiplier')
    current = getNestedField(cfg, {'environment','densityMultiplier'}, 1.0);
    cfg.environment.densityMultiplier = max(0.01, current * (1 + perturbation.delta));
elseif strcmp(field, 'CdScale')
    current = getField(v, 'Cd_scale', 1.0);
    spec.CdScale = max(0.01, current * (1 + perturbation.delta));
elseif strcmp(field, 'InitialVelocity_mps')
    current = getField(cfg, 'launchSpeed_mps', getField(v, 'V0', 1800));
    spec.InitialVelocity_mps = max(1, current * (1 + perturbation.delta));
elseif strcmp(field, 'LaunchAngle_deg')
    current = getField(cfg, 'launchAngle_deg', getField(v, 'launchAngle', 25));
    spec.LaunchAngle_deg = max(0.1, current + perturbation.delta);
elseif strcmp(field, 'Mass_kg')
    current = getField(v, 'mass', 5);
    spec.Mass_kg = max(0.01, current * (1 + perturbation.delta));
elseif strcmp(field, 'Diameter_m')
    current = getField(v, 'diameter', 0.0564);
    spec.Diameter_m = max(0.001, current * (1 + perturbation.delta));
end

result = runSingleScenarioStage14(v, constants, cfg, spec, "Balanced");
result.uncertaintyCaseName = perturbation.name;
end

function bands = buildBands(baseline, cases)
xRange = vectorField(baseline, 'x') / 1000;
if isempty(xRange)
    xRange = vectorField(baseline, 'range') / 1000;
end
t = vectorField(baseline, 't');

bands.range_km = xRange(:);
bands.time_s = t(:);
bands.altitude_km = matrixEnvelope(cases, 'x', 'h', xRange, 1000, 1000);
bands.mach = matrixEnvelope(cases, 't', 'Mach', t, 1, 1);
bands.q_kPa = matrixEnvelope(cases, 't', 'q', t, 1, 1000);
bands.stagTemp_K = matrixEnvelope(cases, 't', {'stagTemp','Tstag'}, t, 1, 1);
bands.velocity_mps = matrixEnvelope(cases, 't', 'V', t, 1, 1);
end

function envelope = matrixEnvelope(cases, xField, yField, xCommon, xScale, yScale)
Y = nan(numel(xCommon), numel(cases));
for k = 1:numel(cases)
    x = vectorField(cases{k}, xField) ./ xScale;
    y = vectorField(cases{k}, yField) ./ yScale;
    if numel(x) >= 2 && numel(y) == numel(x)
        [xu, ia] = unique(x, 'stable');
        yu = y(ia);
        Y(:, k) = interp1(xu, yu, xCommon, 'linear', NaN);
    end
end
envelope.min = min(Y, [], 2, 'omitnan');
envelope.max = max(Y, [], 2, 'omitnan');
envelope.baseline = Y(:, 1);
end

function T = buildSummaryTable(baseline, cases, caseNames)
metrics = ["Range_km"; "MaxAltitude_km"; "MaxQ_kPa"; "MaxStagTemp_K"; "ImpactSpeed_mps"];
baselineValues = [metricValue(baseline, 'range') / 1000; metricValue(baseline, 'maxAltitude') / 1000; ...
    metricValue(baseline, 'maxQ') / 1000; metricValue(baseline, 'maxStagTemp'); metricValue(baseline, 'impactSpeed')];
values = nan(numel(metrics), numel(cases));
for k = 1:numel(cases)
    values(:, k) = [metricValue(cases{k}, 'range') / 1000; metricValue(cases{k}, 'maxAltitude') / 1000; ...
        metricValue(cases{k}, 'maxQ') / 1000; metricValue(cases{k}, 'maxStagTemp'); metricValue(cases{k}, 'impactSpeed')];
end
[minimum, idxMin] = min(values, [], 2, 'omitnan');
[maximum, idxMax] = max(values, [], 2, 'omitnan');
spread = maximum - minimum;
minCase = caseNames(idxMin);
maxCase = caseNames(idxMax);
T = table(metrics, baselineValues, minimum, maximum, spread, minCase, maxCase, ...
    'VariableNames', {'Metric','Baseline','Minimum','Maximum','Spread','MinimumCase','MaximumCase'});
end

function T = buildCaseTable(cases, caseNames)
n = numel(cases);
range_km = nan(n, 1);
maxAltitude_km = nan(n, 1);
maxQ_kPa = nan(n, 1);
maxStagTemp_K = nan(n, 1);
impactSpeed_mps = nan(n, 1);
impactReached = false(n, 1);
for k = 1:n
    r = cases{k};
    range_km(k) = metricValue(r, 'range') / 1000;
    maxAltitude_km(k) = metricValue(r, 'maxAltitude') / 1000;
    maxQ_kPa(k) = metricValue(r, 'maxQ') / 1000;
    maxStagTemp_K(k) = metricValue(r, 'maxStagTemp');
    impactSpeed_mps(k) = metricValue(r, 'impactSpeed');
    impactReached(k) = logical(getField(r, 'impactDetected', false));
end
T = table(caseNames(:), range_km, maxAltitude_km, maxQ_kPa, maxStagTemp_K, ...
    impactSpeed_mps, impactReached, 'VariableNames', {'CaseName','Range_km', ...
    'MaxAltitude_km','MaxQ_kPa','MaxStagTemp_K','ImpactSpeed_mps','ImpactReached'});
end

function insights = buildInsights(summaryTable, caseTable)
rangeRow = summaryTable(strcmpi(summaryTable.Metric, "Range_km"), :);
if ~isempty(rangeRow)
    first = sprintf('With the selected uncertainty assumptions, predicted range varies from %.3f to %.3f km.', ...
        rangeRow.Minimum(1), rangeRow.Maximum(1));
else
    first = 'Range uncertainty could not be summarized for this run.';
end
[~, idx] = max(abs(caseTable.Range_km - caseTable.Range_km(1)));
driver = caseTable.CaseName(idx);
insights = {
    first
    sprintf('The largest one-at-a-time range shift in this run came from: %s.', driver)
    'Uncertainty bands are deterministic low/high perturbations, not a probabilistic Monte Carlo result.'
    'The baseline inputs are not overwritten by this analysis.'};
end

function value = metricValue(s, name)
value = getField(s, name, NaN);
if isnumeric(value) && numel(value) > 1
    value = value(end);
end
end

function x = vectorField(s, names)
if ischar(names) || isstring(names)
    names = cellstr(string(names));
end
x = [];
for k = 1:numel(names)
    name = names{k};
    if isstruct(s) && isfield(s, name) && isnumeric(s.(name)) && ~isempty(s.(name))
        x = s.(name)(:);
        return;
    end
end
end

function callProgress(callback, fraction, message)
if isa(callback, 'function_handle')
    callback(fraction, message);
end
end

function value = getNestedField(s, pathParts, defaultValue)
value = defaultValue;
cursor = s;
for k = 1:numel(pathParts)
    if isstruct(cursor) && isfield(cursor, pathParts{k}) && ~isempty(cursor.(pathParts{k}))
        cursor = cursor.(pathParts{k});
    else
        return;
    end
end
value = cursor;
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
