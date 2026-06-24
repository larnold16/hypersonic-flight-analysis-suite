function sensitivity = computeSensitivityAnalysisStage14(vehicle, constants, baseConfig, perturbationPct, progressCallback)
% computeSensitivityAnalysisStage14
% One-at-a-time perturbation study around the baseline case.

if nargin < 4 || isempty(perturbationPct)
    perturbationPct = 5;
end
if nargin < 5
    progressCallback = [];
end

baseline = runSingleScenarioStage14(vehicle, constants, baseConfig, struct('CaseName', "Baseline", 'OutputSuffix', "sensitivity_baseline"), "Balanced");
variables = sensitivityVariables(vehicle, baseConfig, perturbationPct);
n = numel(variables);
caseResults = cell(n * 2, 1);
rows = repmat(emptySensitivityRow(), n, 1);

for k = 1:n
    reportProgress(progressCallback, 0.05 + 0.80 * (k - 1) / max(n, 1), ...
        sprintf('Sensitivity variable %d of %d: %s', k, n, variables(k).Name));
    lowResult = runSingleScenarioStage14(vehicle, constants, baseConfig, variables(k).LowCase, "Balanced");
    highResult = runSingleScenarioStage14(vehicle, constants, baseConfig, variables(k).HighCase, "Balanced");
    caseResults{2*k-1} = lowResult;
    caseResults{2*k} = highResult;
    rows(k) = sensitivityRow(variables(k), baseline, lowResult, highResult);
end

summaryTable = struct2table(rows);
[~, order] = sort(summaryTable.SensitivityScore, 'descend');
rankedTable = summaryTable(order, :);

sensitivity = struct();
sensitivity.baselineResult = baseline;
sensitivity.caseResults = caseResults;
sensitivity.summaryTable = summaryTable;
sensitivity.rankedTable = rankedTable;
sensitivity.perturbationPct = perturbationPct;
sensitivity.insights = sensitivityInsightsStage14(rankedTable);
reportProgress(progressCallback, 1.0, "Sensitivity analysis complete.");
end

function variables = sensitivityVariables(vehicle, baseConfig, pct)
baseAngle = getConfigField(baseConfig, 'launchAngle_deg', getVehicleField(vehicle, 'launchAngle', 25));
baseSpeed = getConfigField(baseConfig, 'launchSpeed_mps', getVehicleField(vehicle, 'V0', 1800));
baseMass = getVehicleField(vehicle, 'mass', 5);
baseDiameter = getVehicleField(vehicle, 'diameter', 0.0564);
baseCd = getVehicleField(vehicle, 'Cd_scale', 1.0);
baseCl = getVehicleField(vehicle, 'CL_scale', 1.0);
baseAlpha = getVehicleField(vehicle, 'alpha_deg', 2.0);
baseStaticMarginPct = 100 * (getVehicleField(vehicle, 'cpLocation_m', 0.6 * getVehicleField(vehicle, 'length', 0.45)) - ...
    getVehicleField(vehicle, 'cgLocation_m', 0.5 * getVehicleField(vehicle, 'length', 0.45))) / max(getVehicleField(vehicle, 'length', 0.45), eps);

variables = repmat(struct('Name',"", 'LowCase',struct(), 'HighCase',struct()), 7, 1);
variables(1) = makeVariable("Launch angle", baseCase("Launch angle low", "sens_angle_low", 'LaunchAngle_deg', baseAngle - 2), baseCase("Launch angle high", "sens_angle_high", 'LaunchAngle_deg', baseAngle + 2));
variables(2) = makeVariable("Initial velocity", baseCase("Velocity low", "sens_velocity_low", 'InitialVelocity_mps', baseSpeed * (1 - pct/100)), baseCase("Velocity high", "sens_velocity_high", 'InitialVelocity_mps', baseSpeed * (1 + pct/100)));
variables(3) = makeVariable("Mass", baseCase("Mass low", "sens_mass_low", 'Mass_kg', baseMass * (1 - pct/100)), baseCase("Mass high", "sens_mass_high", 'Mass_kg', baseMass * (1 + pct/100)));
variables(4) = makeVariable("Diameter", baseCase("Diameter low", "sens_diameter_low", 'Diameter_m', baseDiameter * (1 - pct/100)), baseCase("Diameter high", "sens_diameter_high", 'Diameter_m', baseDiameter * (1 + pct/100)));
variables(5) = makeVariable("Drag coefficient scale", baseCase("Cd low", "sens_cd_low", 'CdScale', baseCd * (1 - pct/100)), baseCase("Cd high", "sens_cd_high", 'CdScale', baseCd * (1 + pct/100)));
variables(6) = makeVariable("Lift / angle of attack", mergeCase(baseCase("AoA low", "sens_lift_low", 'CLScale', baseCl * (1 - pct/100)), 'Alpha_deg', max(0, baseAlpha - 0.5)), mergeCase(baseCase("AoA high", "sens_lift_high", 'CLScale', baseCl * (1 + pct/100)), 'Alpha_deg', baseAlpha + 0.5));
variables(7) = makeVariable("Static margin", baseCase("Static margin low", "sens_static_low", 'StaticMargin_percent', max(1, baseStaticMarginPct - 2)), baseCase("Static margin high", "sens_static_high", 'StaticMargin_percent', baseStaticMarginPct + 2));
end

function variable = makeVariable(name, lowCase, highCase)
variable = struct('Name', string(name), 'LowCase', lowCase, 'HighCase', highCase);
end

function c = baseCase(name, suffix, fieldName, value)
c = struct('CaseName', string(name), 'OutputSuffix', string(suffix));
c.(fieldName) = value;
end

function c = mergeCase(c, fieldName, value)
c.(fieldName) = value;
end

function row = emptySensitivityRow()
row = struct('Variable',"", 'RangeChange_pct',NaN, 'MaxAltitudeChange_pct',NaN, ...
    'ImpactSpeedChange_pct',NaN, 'MaxMachChange_pct',NaN, ...
    'MaxQChange_pct',NaN, 'MaxStagTempChange_pct',NaN, ...
    'TimeToImpactChange_pct',NaN, 'SensitivityScore',NaN);
end

function row = sensitivityRow(variable, baseline, lowResult, highResult)
row = emptySensitivityRow();
row.Variable = variable.Name;
row.RangeChange_pct = spanChangePct(baseline, lowResult, highResult, 'range');
row.MaxAltitudeChange_pct = spanChangePct(baseline, lowResult, highResult, 'maxAltitude');
row.ImpactSpeedChange_pct = spanChangePct(baseline, lowResult, highResult, 'impactSpeed');
row.MaxMachChange_pct = spanChangePct(baseline, lowResult, highResult, 'maxMach');
row.MaxQChange_pct = spanChangePct(baseline, lowResult, highResult, 'maxQ');
row.MaxStagTempChange_pct = spanChangePct(baseline, lowResult, highResult, 'maxStagTemp');
row.TimeToImpactChange_pct = spanChangePct(baseline, lowResult, highResult, 'timeOfFlight');
row.SensitivityScore = mean(abs([row.RangeChange_pct, row.MaxAltitudeChange_pct, ...
    row.ImpactSpeedChange_pct, row.MaxMachChange_pct, row.MaxQChange_pct, ...
    row.MaxStagTempChange_pct, row.TimeToImpactChange_pct]), 'omitnan');
end

function pct = spanChangePct(baseline, lowResult, highResult, fieldName)
base = safeScalar(baseline, fieldName);
lo = safeScalar(lowResult, fieldName);
hi = safeScalar(highResult, fieldName);
if ~isfinite(base) || abs(base) <= eps || ~isfinite(lo) || ~isfinite(hi)
    pct = NaN;
else
    pct = 100 * (hi - lo) / abs(base);
end
end

function insights = sensitivityInsightsStage14(rankedTable)
lines = strings(0, 1);
lines(end+1, 1) = "Sensitivity analysis perturbs one variable at a time and does not permanently overwrite the baseline inputs.";
if istable(rankedTable) && height(rankedTable) > 0
    top = rankedTable(1, :);
    lines(end+1, 1) = sprintf('The strongest overall driver in this local study appears to be %s.', char(top.Variable));
    [~, idx] = max(abs([top.RangeChange_pct, top.MaxQChange_pct, top.MaxStagTempChange_pct]));
    if idx == 1
        lines(end+1, 1) = "Range is the largest response for the top variable in this small perturbation set.";
    elseif idx == 2
        lines(end+1, 1) = "Dynamic pressure is a major response; this is plausible because q scales with velocity squared and density.";
    else
        lines(end+1, 1) = "Stagnation temperature is a major response, so thermal assumptions should be reviewed carefully.";
    end
end
lines(end+1, 1) = "These rankings are local to the baseline and perturbation size, so large design changes may reorder the sensitivities.";
insights = cellstr(lines);
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

function value = safeScalar(s, fieldName)
value = NaN;
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName)) && isnumeric(s.(fieldName))
    value = s.(fieldName)(1);
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
