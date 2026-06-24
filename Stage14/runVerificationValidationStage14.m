function verification = runVerificationValidationStage14(vehicle, constants, baseConfig)
% runVerificationValidationStage14
% Stage 14 wrapper around the Stage 12/11 physics diagnostics.
%
% Runs vacuum, drag-only, and full-aero cases, then summarizes analytical
% comparison, energy behavior, max-Q sanity, impact behavior, and input
% sanity warnings for the app/report layer.

if nargin < 3
    baseConfig = struct();
end
if exist('runPhysicsDiagnostics', 'file') ~= 2
    error('Stage14:MissingStage12Diagnostics', ...
        'runPhysicsDiagnostics.m was not found on the MATLAB path.');
end

vehicle = normalizeLaunchVehicle(vehicle, baseConfig);
diagnosticConfig = buildDiagnosticConfig(baseConfig);
diagnostics = runPhysicsDiagnostics(vehicle, constants, diagnosticConfig);

checks = buildCheckTable(diagnostics, vehicle, constants);
dragComparison = buildDragComparisonTable(diagnostics);
energyTable = buildEnergyTable(diagnostics);
maxQTable = buildMaxQTable(diagnostics);
impactTable = buildImpactTable(diagnostics);
inputWarningTable = buildInputWarningTable(vehicle, constants);
explanation = buildExplanation(checks, diagnostics, inputWarningTable);

verification = struct();
verification.summaryTable = checks;
verification.diagnosticSummaryTable = diagnostics.summaryTable;
verification.analyticalComparison = diagnostics.analyticalComparison;
verification.dragComparisonTable = dragComparison;
verification.energyTable = energyTable;
verification.maxQTable = maxQTable;
verification.impactTable = impactTable;
verification.inputWarningTable = inputWarningTable;
verification.explanation = explanation;
verification.cases = diagnostics.cases;
verification.sweep = diagnostics.sweep;
verification.rawDiagnostics = diagnostics;
end

function vehicle = normalizeLaunchVehicle(vehicle, baseConfig)
vehicle.V0 = getField(baseConfig, 'launchSpeed_mps', getField(vehicle, 'V0', 1800));
vehicle.launchAngle = getField(baseConfig, 'launchAngle_deg', getField(vehicle, 'launchAngle', 25));
if ~isfield(vehicle, 'alpha_deg') || isempty(vehicle.alpha_deg)
    vehicle.alpha_deg = 2.0;
end
if ~isfield(vehicle, 'referenceArea') || isempty(vehicle.referenceArea)
    vehicle.referenceArea = pi * max(getField(vehicle, 'diameter', 0.0564), eps)^2 / 4;
end
if exist('buildVehicleFromGeometry_stage11', 'file') == 2
    vehicle = buildVehicleFromGeometry_stage11(vehicle, getField(vehicle, 'bodyType', 'Custom baseline'));
end
end

function cfg = buildDiagnosticConfig(baseConfig)
outputRoot = getField(baseConfig, 'outputRoot', fullfile(pwd, 'Outputs', 'Stage14', 'VerificationValidation'));
cfg = struct();
cfg.showPlots = false;
cfg.figureVisible = 'off';
cfg.verbose = false;
cfg.outputRoot = fullfile(outputRoot, 'VerificationValidation');
cfg.figureDir = fullfile(cfg.outputRoot, 'Figures');
cfg.tableDir = fullfile(cfg.outputRoot, 'Tables');
cfg.matDir = fullfile(cfg.outputRoot, 'MAT');
cfg.initialAltitude_m = getField(baseConfig, 'initialAltitude_m', 0);
cfg.physicsDiagnosticAngles_deg = getField(baseConfig, 'physicsDiagnosticAngles_deg', 5:5:75);
cfg.physicsDiagnosticFinalTime_s = getField(baseConfig, 'physicsDiagnosticFinalTime_s', 600);
cfg.physicsDiagnosticMaxStep_s = getField(baseConfig, 'physicsDiagnosticMaxStep_s', 0.2);
if isfield(baseConfig, 'environment')
    cfg.environment = baseConfig.environment;
end
end

function T = buildCheckTable(diagnostics, vehicle, constants)
rows = {};
analytical = diagnostics.analyticalComparison;
rangeRow = analytical(strcmpi(string(analytical.Metric), "Range"), :);
rangeError = rangeRow.PercentError(1);
rows(end+1, :) = {'Vacuum analytic range', ...
    sprintf('Numerical %.3f km, analytical %.3f km, error %.4g%%', ...
    rangeRow.Numerical(1) / 1000, rangeRow.Analytical(1) / 1000, rangeError), ...
    'Drag-free trajectory should match R = V0^2 sin(2 theta) / g.', ...
    warningText(rangeError <= 0.25, 'Vacuum range error is larger than the 0.25% tolerance.'), ...
    passFail(rangeError <= 0.25)};

summary = diagnostics.summaryTable;
vac = summary(contains(summary.StageName, "vacuum", 'IgnoreCase', true), :);
drag = summary(contains(summary.StageName, "drag only", 'IgnoreCase', true), :);
full = summary(contains(summary.StageName, "full aero", 'IgnoreCase', true), :);

vacEnergyOk = abs(vac.PercentEnergyChange(1)) <= 0.5;
rows(end+1, :) = {'Vacuum energy conservation', sprintf('Energy change %.4g%%', vac.PercentEnergyChange(1)), ...
    'Total mechanical energy should remain nearly constant when drag and lift are disabled.', ...
    warningText(vacEnergyOk, 'Vacuum total mechanical energy changed more than 0.5%.'), passFail(vacEnergyOk)};

dragEnergyOk = drag.PercentEnergyChange(1) <= 0.05 && ~drag.PhysicsError(1);
rows(end+1, :) = {'Drag-only energy behavior', sprintf('Energy change %.4g%%', drag.PercentEnergyChange(1)), ...
    'Aerodynamic drag should remove total mechanical energy.', ...
    warningText(dragEnergyOk, 'Physics error: drag-only case increased total mechanical energy.'), passFail(dragEnergyOk)};

fullEnergyOk = full.PercentEnergyChange(1) <= 0.05 && ~full.PhysicsError(1);
rows(end+1, :) = {'Full-aero energy behavior', sprintf('Energy change %.4g%%', full.PercentEnergyChange(1)), ...
    'Full aero with drag should not add total mechanical energy.', ...
    warningText(fullEnergyOk, 'Physics error: full-aero case increased total mechanical energy.'), passFail(fullEnergyOk)};

dragRangeOk = drag.Range_km(1) <= vac.Range_km(1);
rows(end+1, :) = {'Drag-off vs drag-on range', sprintf('Vacuum %.3f km, drag-only %.3f km', vac.Range_km(1), drag.Range_km(1)), ...
    'For the same launch condition, drag should reduce range relative to vacuum.', ...
    warningText(dragRangeOk, 'Drag-only range exceeded vacuum range; inspect settings.'), passFail(dragRangeOk)};

fullRangeReasonable = full.Range_km(1) <= vac.Range_km(1) || full.PercentEnergyChange(1) <= 0;
rows(end+1, :) = {'Full aero range sanity', sprintf('Vacuum %.3f km, full aero %.3f km', vac.Range_km(1), full.Range_km(1)), ...
    'Lift can reshape the path, but drag should still dissipate energy.', ...
    warningText(fullRangeReasonable, 'Full-aero result needs review.'), passFail(fullRangeReasonable)};

maxQ = maxQEvent(diagnostics.cases{3});
highSpeedLowAltitude = getField(vehicle, 'V0', 0) > 1000 && getField(constants, 'launchAlt', 0) < 3000;
maxQOk = ~highSpeedLowAltitude || maxQ.timeFraction <= 0.35;
rows(end+1, :) = {'Max-Q timing sanity', ...
    sprintf('t=%.3f s, h=%.3f km, Mach=%.2f, q=%.2f kPa', ...
    maxQ.time_s, maxQ.altitude_m / 1000, maxQ.mach, maxQ.q_kPa), ...
    'For high-speed low-altitude launches, max-Q should usually occur early while density is still high.', ...
    warningText(maxQOk, 'Max-Q did not occur early; review trajectory and aero assumptions.'), passFail(maxQOk)};

impact = diagnostics.cases{3};
finalAltitude = lastValue(impact.h);
impactOk = logical(impact.impactReached) && abs(finalAltitude) <= 5;
rows(end+1, :) = {'Impact event check', ...
    sprintf('Impact=%s, final h=%.3f m, range=%.3f km, speed=%.1f m/s, time=%.2f s', ...
    string(logical(impact.impactReached)), finalAltitude, impact.range / 1000, impact.impactSpeed, impact.timeOfFlight), ...
    'The integration should stop when altitude returns to ground level.', ...
    warningText(impactOk, 'Final altitude is not close to ground or impact was not detected.'), passFail(impactOk)};

T = cell2table(rows, 'VariableNames', {'CheckName','ResultValue','ExpectedBehavior','ErrorOrWarning','PassFail'});
end

function T = buildDragComparisonTable(diagnostics)
S = diagnostics.summaryTable;
vac = S(contains(S.StageName, "vacuum", 'IgnoreCase', true), :);
drag = S(contains(S.StageName, "drag only", 'IgnoreCase', true), :);
full = S(contains(S.StageName, "full aero", 'IgnoreCase', true), :);
metric = ["Range loss from vacuum km"; "Max altitude change from vacuum km"; ...
    "Impact speed change from vacuum m/s"; "Drag-only energy change percent"; ...
    "Full-aero energy change percent"];
dragOnly = [vac.Range_km - drag.Range_km; drag.MaxAltitude_km - vac.MaxAltitude_km; ...
    drag.ImpactSpeed_mps - vac.ImpactSpeed_mps; drag.PercentEnergyChange; NaN];
fullAero = [vac.Range_km - full.Range_km; full.MaxAltitude_km - vac.MaxAltitude_km; ...
    full.ImpactSpeed_mps - vac.ImpactSpeed_mps; NaN; full.PercentEnergyChange];
T = table(metric, dragOnly, fullAero, 'VariableNames', {'Metric','DragOnly','FullAero'});
end

function T = buildEnergyTable(diagnostics)
S = diagnostics.summaryTable;
T = S(:, {'StageName','InitialTotalMechanicalEnergy_J','FinalTotalMechanicalEnergy_J', ...
    'PercentEnergyChange','PhysicsError'});
end

function T = buildMaxQTable(diagnostics)
r = diagnostics.cases{3};
event = maxQEvent(r);
T = table(event.time_s, event.altitude_m, event.mach, event.velocity_mps, ...
    event.q_kPa, event.timeFraction, ...
    'VariableNames', {'Time_s','Altitude_m','Mach','Velocity_mps','DynamicPressure_kPa','TimeFractionOfFlight'});
end

function T = buildImpactTable(diagnostics)
rows = cell(numel(diagnostics.cases), 5);
for k = 1:numel(diagnostics.cases)
    r = diagnostics.cases{k};
    rows{k, 1} = string(r.stageName);
    rows{k, 2} = logical(r.impactReached);
    rows{k, 3} = lastValue(r.h);
    rows{k, 4} = r.range / 1000;
    rows{k, 5} = r.impactSpeed;
end
T = cell2table(rows, 'VariableNames', {'StageName','ImpactReached','FinalAltitude_m','FinalRange_km','ImpactSpeed_mps'});
end

function T = buildInputWarningTable(vehicle, constants)
rows = {};
rows = addWarning(rows, 'Mass', getField(vehicle, 'mass', NaN) > 0, ...
    sprintf('%.4g kg', getField(vehicle, 'mass', NaN)), 'Mass should be positive.');
rows = addWarning(rows, 'Diameter', getField(vehicle, 'diameter', NaN) > 0, ...
    sprintf('%.4g m', getField(vehicle, 'diameter', NaN)), 'Diameter should be positive.');
rows = addWarning(rows, 'Drag coefficient scale', getField(vehicle, 'Cd_scale', getField(vehicle, 'Cd', 0.35)) > 0, ...
    sprintf('%.4g', getField(vehicle, 'Cd_scale', getField(vehicle, 'Cd', NaN))), 'Drag coefficient or multiplier should be positive.');
rows = addWarning(rows, 'Initial velocity', getField(vehicle, 'V0', NaN) <= 3500, ...
    sprintf('%.1f m/s', getField(vehicle, 'V0', NaN)), 'Very high initial velocity; verify units and model limits.');
rows = addWarning(rows, 'Launch angle', getField(vehicle, 'launchAngle', NaN) <= 75, ...
    sprintf('%.1f deg', getField(vehicle, 'launchAngle', NaN)), 'Very high launch angle; range trend may be lofted/diagnostic.');
staticMarginPct = 100 * (getField(vehicle, 'cpLocation_m', NaN) - getField(vehicle, 'cgLocation_m', NaN)) / max(getField(vehicle, 'length', NaN), eps);
rows = addWarning(rows, 'Static margin', staticMarginPct >= 5 && staticMarginPct <= 25, ...
    sprintf('%.2f %%', staticMarginPct), 'Static margin is outside the 5-25% educational range.');
rows = addWarning(rows, 'Angle of attack', abs(getField(vehicle, 'alpha_deg', 0)) <= 10, ...
    sprintf('%.2f deg', getField(vehicle, 'alpha_deg', NaN)), 'Angle of attack is outside the simple aero model comfort range.');
rows = addWarning(rows, 'Launch altitude', getField(constants, 'launchAlt', 0) >= 0, ...
    sprintf('%.2f m', getField(constants, 'launchAlt', 0)), 'Launch altitude should be nonnegative for this app workflow.');
T = cell2table(rows, 'VariableNames', {'Input','ObservedValue','Warning','PassFail'});
end

function rows = addWarning(rows, name, ok, valueText, message)
if ok
    warningTextValue = "OK";
else
    warningTextValue = string(message);
end
rows(end+1, :) = {string(name), string(valueText), warningTextValue, string(passFail(ok))};
end

function explanation = buildExplanation(checks, diagnostics, inputWarnings)
failed = checks(~strcmpi(string(checks.PassFail), "PASS"), :);
warningRows = inputWarnings(~strcmpi(string(inputWarnings.PassFail), "PASS"), :);
rangeError = diagnostics.analyticalComparison.PercentError(strcmpi(string(diagnostics.analyticalComparison.Metric), "Range"));
explanation = {
    sprintf('Vacuum model error compared to the analytical projectile range solution is %.4g%%. A small value supports the basic integrator and equations of motion for the drag-free case.', rangeError(1))
    'Drag-only and full-aero checks are expected to reduce total mechanical energy. If either case increases energy, Stage 14 flags it as a physics error.'
    'Max-Q is checked because dynamic pressure scales with density and velocity squared, so high-speed low-altitude launches usually peak early in flight.'
    'These checks verify selected numerical and physics behavior. They do not validate the model against real flight data.'};
if isempty(failed)
    explanation{end+1} = 'All V&V table checks passed for the current baseline settings.';
else
    explanation{end+1} = sprintf('%d V&V checks need review; inspect the table rows marked FAIL.', height(failed));
end
if ~isempty(warningRows)
    explanation{end+1} = sprintf('%d input sanity warning(s) were detected; review the Unit/Sanity warning rows.', height(warningRows));
end
end

function event = maxQEvent(r)
q = vectorField(r, 'q');
if isempty(q)
    event = struct('time_s', NaN, 'altitude_m', NaN, 'mach', NaN, ...
        'velocity_mps', NaN, 'q_kPa', NaN, 'timeFraction', NaN);
    return;
end
[qMax, idx] = max(q);
t = vectorField(r, 't');
h = vectorField(r, 'h');
Mach = vectorField(r, 'Mach');
V = vectorField(r, 'V');
tof = max(lastValue(t), eps);
event.time_s = valueAt(t, idx);
event.altitude_m = valueAt(h, idx);
event.mach = valueAt(Mach, idx);
event.velocity_mps = valueAt(V, idx);
event.q_kPa = qMax / 1000;
event.timeFraction = event.time_s / tof;
end

function value = valueAt(x, idx)
if isempty(x) || idx > numel(x)
    value = NaN;
else
    value = x(idx);
end
end

function x = vectorField(s, name)
if isstruct(s) && isfield(s, name) && isnumeric(s.(name))
    x = s.(name)(:);
else
    x = [];
end
end

function value = lastValue(x)
if isempty(x) || ~isnumeric(x)
    value = NaN;
else
    value = x(end);
end
end

function text = warningText(ok, message)
if ok
    text = "OK";
else
    text = string(message);
end
end

function text = passFail(ok)
if ok
    text = "PASS";
else
    text = "FAIL";
end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
