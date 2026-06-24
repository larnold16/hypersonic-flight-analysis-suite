function diagnostics = runPhysicsDiagnostics(vehicle, constants, config)
% runPhysicsDiagnostics
% Quantitative Stage 12 diagnostics for the Stage 11 physics model.
%
% This diagnostic intentionally runs the same launch condition three ways:
%   1. vacuum / no drag / no lift
%   2. drag only / lift disabled
%   3. full aero / lift enabled
%
% The vacuum case is compared against the closed-form projectile solution.
% Drag and full-aero cases are checked for decreasing total mechanical
% energy. A positive energy change in a dissipative case is flagged as a
% physics error because aerodynamic drag should remove mechanical energy.

if nargin < 3
    config = defaultConfig();
end

ensureFolders(config);

modes = { ...
    makeMode('Stage 12/11 vacuum - no drag/no lift', 'vacuum', false, false), ...
    makeMode('Stage 12/11 drag only - lift disabled', 'dragOnly', true, false), ...
    makeMode('Stage 12/11 full aero - lift enabled', 'fullAero', true, true)};

cases = cell(numel(modes), 1);
for k = 1:numel(modes)
    cases{k} = runDiagnosticCase(vehicle, constants, config, modes{k}, ...
        getField(vehicle, 'launchAngle', 25));
end

summaryTable = buildSummaryTable(cases);
analyticalComparison = buildVacuumAnalyticalComparison(cases{1}, vehicle, constants);

angles = getField(config, 'physicsDiagnosticAngles_deg', 5:5:75);
sweep = runModeSweeps(vehicle, constants, config, modes, angles);

csvFile = fullfile(config.tableDir, 'Stage12Stage11PhysicsDiagnostics.csv');
writetable(summaryTable, csvFile);
writetable(analyticalComparison, fullfile(config.tableDir, 'Stage12VacuumAnalyticalComparison.csv'));
writetable(sweep.summaryTable, fullfile(config.tableDir, 'Stage12PhysicsModeAngleSweep.csv'));
save(fullfile(config.matDir, 'Stage12PhysicsDiagnostics.mat'), ...
    'summaryTable', 'analyticalComparison', 'sweep', 'cases');

if config.showPlots
    plotPhysicsSweep(sweep, config);
end

diagnostics.summaryTable = summaryTable;
diagnostics.analyticalComparison = analyticalComparison;
diagnostics.sweep = sweep;
diagnostics.cases = cases;
diagnostics.csvFile = csvFile;
diagnostics.figureFile = fullfile(config.figureDir, 'Stage12_PhysicsModeRangeSweep.png');

if getField(config, 'verbose', true)
    fprintf('\nStage 12 / Stage 11 Physics Diagnostic Summary:\n');
    disp(summaryTable);
    fprintf('\nVacuum analytical comparison:\n');
    disp(analyticalComparison);
    if any(summaryTable.PhysicsError)
        warning('Stage12:PhysicsEnergyIncrease', ...
            'At least one drag/lift case increased total mechanical energy.');
    end
end
end

function config = defaultConfig()
config = struct();
config.showPlots = true;
config.figureVisible = 'on';
config.verbose = true;
config.outputRoot = fullfile(pwd, 'Outputs', 'Stage12');
config.figureDir = fullfile(config.outputRoot, 'Figures');
config.tableDir = fullfile(config.outputRoot, 'Tables');
config.matDir = fullfile(config.outputRoot, 'MAT');
end

function mode = makeMode(stageName, modeName, dragEnabled, liftEnabled)
mode.stageName = stageName;
mode.modeName = modeName;
mode.dragEnabled = dragEnabled;
mode.liftEnabled = liftEnabled;
end

function result = runDiagnosticCase(vehicle, constants, config, mode, launchAngle_deg)
vehicle = buildVehicleFromGeometry_stage11(vehicle, 'Custom baseline');
vehicle.alpha_deg = getField(vehicle, 'alpha_deg', 2.0);

V0 = getField(vehicle, 'V0', 1800);
gamma0 = deg2rad(launchAngle_deg);
h0 = max(getField(config, 'initialAltitude_m', getField(constants, 'launchAlt', 0)), 0) + 1e-6;
state0 = [0; 0; h0; V0 * cos(gamma0); 0; V0 * sin(gamma0)];

tFinal = getField(config, 'physicsDiagnosticFinalTime_s', 600);
options = odeset('Events', @impactEvent, ...
    'RelTol', getField(config, 'physicsDiagnosticRelTol', 1e-8), ...
    'AbsTol', getField(config, 'physicsDiagnosticAbsTol', 1e-10), ...
    'MaxStep', getField(config, 'physicsDiagnosticMaxStep_s', 0.15));

try
    [t, state, te, ~, ie] = ode45(@(t, s) diagnosticODE(t, s, vehicle, constants, config, mode), ...
        [0 tFinal], state0, options);
    impactReached = ~isempty(te) && any(ie == 1);
    result = postProcessDiagnostic(t, state, vehicle, constants, config, mode, impactReached);
catch ME
    result = failedDiagnostic(mode, ME.message);
end
end

function dstate = diagnosticODE(t, state, vehicle, constants, config, mode)
h = max(state(3), 0);
v = state(4:6);
V = norm(v);
g = diagnosticGravity(constants);

force = [0; 0; 0];
if mode.dragEnabled && V > 1e-8
    [T, P, rho, a, mu] = atmosphere1976_simple(h);
    rho = rho * getNestedField(config, {'environment','densityMultiplier'}, 1.0);
    T = T * getNestedField(config, {'environment','temperatureMultiplier'}, 1.0);
    a = sqrt(1.4 * 287.05 * max(T, 1));

    alpha = deg2rad(getField(vehicle, 'alpha_deg', 2.0));
    beta = 0;
    atmosphere = struct('T', T, 'P', P, 'rho', rho, 'a', a, 'mu', mu);
    aero = aeroModel_stage11(V / max(a, 1e-8), alpha, beta, vehicle, atmosphere);

    qbar = 0.5 * rho * V^2;
    drag = qbar * vehicle.referenceArea * aero.CD;
    u = v / V;
    force = force - drag * u;

    if mode.liftEnabled
        lift = qbar * vehicle.referenceArea * aero.CL;
        horizontalSpeed = max(norm(v(1:2)), 1e-8);
        liftDir = [-u(3) * u(1) / horizontalSpeed; ...
                   -u(3) * u(2) / horizontalSpeed; ...
                    horizontalSpeed];
        liftDir = liftDir / max(norm(liftDir), 1e-8);
        force = force + lift * liftDir;
    end
end

accel = force / max(vehicle.mass, eps) + [0; 0; -g];
dstate = [v; accel];
end

function result = postProcessDiagnostic(t, state, vehicle, constants, config, mode, impactReached)
x = state(:,1);
y = state(:,2);
h = max(state(:,3), 0);
v = state(:,4:6);
V = sqrt(sum(v.^2, 2));
n = numel(t);

Mach = zeros(n, 1);
qbar = zeros(n, 1);
CD = zeros(n, 1);
CL = zeros(n, 1);
LD = zeros(n, 1);
drag = zeros(n, 1);
lift = zeros(n, 1);

for k = 1:n
    hk = max(h(k), 0);
    [T, P, rho, a, mu] = atmosphere1976_simple(hk);
    rho = rho * getNestedField(config, {'environment','densityMultiplier'}, 1.0);
    T = T * getNestedField(config, {'environment','temperatureMultiplier'}, 1.0);
    a = sqrt(1.4 * 287.05 * max(T, 1));

    Mach(k) = V(k) / max(a, 1e-8);
    if mode.dragEnabled
        alpha = deg2rad(getField(vehicle, 'alpha_deg', 2.0));
        if ~mode.liftEnabled
            alpha = 0;
        end
        atmosphere = struct('T', T, 'P', P, 'rho', rho, 'a', a, 'mu', mu);
        aero = aeroModel_stage11(Mach(k), alpha, 0, vehicle, atmosphere);
        CD(k) = aero.CD;
        CL(k) = aero.CL * double(mode.liftEnabled);
        LD(k) = CL(k) / max(CD(k), eps);
        qbar(k) = 0.5 * rho * V(k)^2;
        drag(k) = qbar(k) * vehicle.referenceArea * CD(k);
        lift(k) = qbar(k) * vehicle.referenceArea * CL(k);
    end
end

totalEnergy = totalMechanicalEnergy(h, V, vehicle.mass, constants);
percentEnergyChange = 100 * (totalEnergy(end) - totalEnergy(1)) / max(abs(totalEnergy(1)), eps);
physicsError = mode.dragEnabled && percentEnergyChange > 0.05;

result.stageName = string(mode.stageName);
result.modeName = string(mode.modeName);
result.t = t;
result.state = state;
result.x = x;
result.y = y;
result.h = h;
result.V = V;
result.Mach = Mach;
result.q = qbar;
result.CD = CD;
result.CL = CL;
result.LD = LD;
result.drag = drag;
result.lift = lift;
result.range = sqrt(x(end)^2 + y(end)^2);
result.maxAltitude = max(h);
result.timeOfFlight = t(end);
result.impactSpeed = V(end);
result.maxMach = max(Mach);
result.maxQ = max(qbar);
result.maxCD = max(CD);
result.maxCL = max(CL);
result.maxLD = max(LD);
result.initialTotalEnergy = totalEnergy(1);
result.finalTotalEnergy = totalEnergy(end);
result.percentEnergyChange = percentEnergyChange;
result.impactReached = impactReached;
result.physicsError = physicsError;
result.totalEnergy = totalEnergy;
result.failureMessage = "";
end

function result = failedDiagnostic(mode, message)
result.stageName = string(mode.stageName);
result.modeName = string(mode.modeName);
result.t = 0;
result.state = [];
result.x = 0;
result.y = 0;
result.h = 0;
result.V = 0;
result.Mach = 0;
result.q = 0;
result.CD = 0;
result.CL = 0;
result.LD = 0;
result.drag = 0;
result.lift = 0;
result.range = NaN;
result.maxAltitude = NaN;
result.timeOfFlight = NaN;
result.impactSpeed = NaN;
result.maxMach = NaN;
result.maxQ = NaN;
result.maxCD = NaN;
result.maxCL = NaN;
result.maxLD = NaN;
result.initialTotalEnergy = NaN;
result.finalTotalEnergy = NaN;
result.percentEnergyChange = NaN;
result.impactReached = false;
result.physicsError = true;
result.totalEnergy = NaN;
result.failureMessage = string(message);
end

function summaryTable = buildSummaryTable(cases)
n = numel(cases);
stageName = strings(n, 1);
range_km = nan(n, 1);
maxAltitude_km = nan(n, 1);
timeOfFlight_s = nan(n, 1);
impactSpeed_mps = nan(n, 1);
maxMach = nan(n, 1);
maxDynamicPressure_kPa = nan(n, 1);
maxCD = nan(n, 1);
maxCL = nan(n, 1);
maxLD = nan(n, 1);
initialTotalMechanicalEnergy_J = nan(n, 1);
finalTotalMechanicalEnergy_J = nan(n, 1);
percentEnergyChange = nan(n, 1);
impactReached = false(n, 1);
physicsError = false(n, 1);

for k = 1:n
    r = cases{k};
    stageName(k) = r.stageName;
    range_km(k) = r.range / 1000;
    maxAltitude_km(k) = r.maxAltitude / 1000;
    timeOfFlight_s(k) = r.timeOfFlight;
    impactSpeed_mps(k) = r.impactSpeed;
    maxMach(k) = r.maxMach;
    maxDynamicPressure_kPa(k) = r.maxQ / 1000;
    maxCD(k) = r.maxCD;
    maxCL(k) = r.maxCL;
    maxLD(k) = r.maxLD;
    initialTotalMechanicalEnergy_J(k) = r.initialTotalEnergy;
    finalTotalMechanicalEnergy_J(k) = r.finalTotalEnergy;
    percentEnergyChange(k) = r.percentEnergyChange;
    impactReached(k) = r.impactReached;
    physicsError(k) = r.physicsError;
end

summaryTable = table(stageName, range_km, maxAltitude_km, timeOfFlight_s, ...
    impactSpeed_mps, maxMach, maxDynamicPressure_kPa, maxCD, maxCL, maxLD, ...
    initialTotalMechanicalEnergy_J, finalTotalMechanicalEnergy_J, ...
    percentEnergyChange, impactReached, physicsError, ...
    'VariableNames', {'StageName','Range_km','MaxAltitude_km','TimeOfFlight_s', ...
    'ImpactSpeed_mps','MaxMach','MaxDynamicPressure_kPa','MaxCD','MaxCL', ...
    'MaxLD','InitialTotalMechanicalEnergy_J','FinalTotalMechanicalEnergy_J', ...
    'PercentEnergyChange','ImpactReached','PhysicsError'});
end

function comparison = buildVacuumAnalyticalComparison(vacuumResult, vehicle, constants)
g = getField(constants, 'g', getField(constants, 'g0', 9.80665));
V0 = getField(vehicle, 'V0', 1800);
theta = deg2rad(getField(vehicle, 'launchAngle', 25));

metric = ["Range"; "MaxAltitude"; "TimeOfFlight"; "ImpactSpeed"];
numerical = [vacuumResult.range; vacuumResult.maxAltitude; ...
    vacuumResult.timeOfFlight; vacuumResult.impactSpeed];
analytical = [V0^2 * sin(2 * theta) / g; ...
    (V0 * sin(theta))^2 / (2 * g); ...
    2 * V0 * sin(theta) / g; ...
    V0];
percentError = 100 * abs(numerical - analytical) ./ max(abs(analytical), eps);
comparison = table(metric, numerical, analytical, percentError, ...
    'VariableNames', {'Metric','Numerical','Analytical','PercentError'});
end

function sweep = runModeSweeps(vehicle, constants, config, modes, angles)
rows = {};
rangeMatrix = nan(numel(angles), numel(modes));

for m = 1:numel(modes)
    for a = 1:numel(angles)
        r = runDiagnosticCase(vehicle, constants, config, modes{m}, angles(a));
        rangeMatrix(a, m) = r.range / 1000;
        rows(end+1, :) = {string(modes{m}.stageName), angles(a), r.range / 1000, ...
            r.maxAltitude / 1000, r.timeOfFlight, r.impactSpeed, ...
            r.percentEnergyChange, r.impactReached, r.physicsError}; %#ok<AGROW>
    end
end

sweep.angles_deg = angles(:);
sweep.rangeMatrix_km = rangeMatrix;
sweep.modeNames = string(cellfun(@(m) m.stageName, modes, 'UniformOutput', false));
sweep.summaryTable = cell2table(rows, 'VariableNames', {'StageName', ...
    'LaunchAngle_deg','Range_km','MaxAltitude_km','TimeOfFlight_s', ...
    'ImpactSpeed_mps','PercentEnergyChange','ImpactReached','PhysicsError'});
end

function plotPhysicsSweep(sweep, config)
fig = figure('Name', 'Stage 12 Physics Mode Range Sweep', ...
    'Visible', getField(config, 'figureVisible', 'on'));
hold on; grid on;
styles = {'-o','-s','-^'};
for k = 1:numel(sweep.modeNames)
    plot(sweep.angles_deg, sweep.rangeMatrix_km(:, k), styles{min(k, numel(styles))}, ...
        'LineWidth', 1.7, 'MarkerFaceColor', 'auto');
end
xlabel('Launch angle (deg)');
ylabel('Range (km)');
title('Range vs Launch Angle by Physics Mode');
legend(sweep.modeNames, 'Location', 'best');
saveas(fig, fullfile(config.figureDir, 'Stage12_PhysicsModeRangeSweep.png'));
end

function E = totalMechanicalEnergy(h, V, mass, constants)
% Use the constant-g mechanical energy convention for diagnostic clarity.
% With drag disabled, this matches the analytical projectile model. With
% drag enabled, the total should decrease monotonically overall.
g = getField(constants, 'g', getField(constants, 'g0', 9.80665));
E = 0.5 * mass .* V.^2 + mass .* g .* h;
end

function g = diagnosticGravity(constants)
% The diagnostic deliberately uses constant gravity so the vacuum case can
% be compared directly with the closed-form projectile solution.
if isfield(constants, 'g')
    g = constants.g;
elseif isfield(constants, 'g0')
    g = constants.g0;
else
    g = 9.80665;
end
end

function ensureFolders(config)
folders = {config.outputRoot, config.figureDir, config.tableDir, config.matDir};
for k = 1:numel(folders)
    if ~exist(folders{k}, 'dir')
        mkdir(folders{k});
    end
end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
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
