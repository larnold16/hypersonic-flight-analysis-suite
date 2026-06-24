function diagnostics = debug6DOF_stage11(vehicle, constants, userConfig)
% debug6DOF_stage11
% Quantitative 6-DOF diagnostic for the Stage 11/Stage 14 path.
%
% Cases:
%   A. 3-DOF baseline with normal aero.
%   B. 6-DOF translational equivalent with no moments.
%   C. 6-DOF vacuum with no drag, lift, or moments, compared to analytical
%      constant-g projectile motion.

if nargin < 1 || ~isstruct(vehicle)
    vehicle = struct();
end
if nargin < 2 || ~isstruct(constants)
    constants = struct();
end
if nargin < 3 || ~isstruct(userConfig)
    userConfig = struct();
end

baseInput = userConfig;
baseInput.mode = 1;
baseInput.showPlots = false;
baseInput.exportResults = false;
baseInput.generateReport = false;
baseInput.interactive = false;
baseInput.verbose = getField(userConfig, 'verbose', true);
baseInput.figureVisible = getField(userConfig, 'figureVisible', 'off');
baseInput.outputRoot = getField(userConfig, 'outputRoot', fullfile(pwd, 'Outputs', 'Stage11', 'Debug6DOF'));
baseInput.launchSpeed_mps = getField(userConfig, 'launchSpeed_mps', getField(vehicle, 'V0', 1800));
baseInput.launchAngle_deg = getField(userConfig, 'launchAngle_deg', getField(vehicle, 'launchAngle', 25));
baseInput.launchYaw_deg = getField(userConfig, 'launchYaw_deg', 0);
baseInput.initialAltitude_m = getField(userConfig, 'initialAltitude_m', getField(constants, 'launchAlt', 0));
baseInput.tFinal_s = getField(userConfig, 'tFinal_s', 300);
baseInput.maxStep_s = min(getField(userConfig, 'maxStep_s', 0.05), 0.05);

base = buildStage11Config(vehicle, constants, baseInput);
safeMkdir(base.figureDir);
safeMkdir(base.tableDir);

cfg3 = base;
cfg3.dofMode = '3DOF';
cfg3.disableAero = false;
cfg3.disableDrag = false;
cfg3.disableLift = false;
cfg3.disableMoments = false;
cfg3.useThreeDofForceModel = false;
cfg3.debug6DOFInitialPrint = false;

cfg6 = base;
cfg6.dofMode = '6DOF';
cfg6.disableAero = false;
cfg6.disableDrag = false;
cfg6.disableLift = false;
cfg6.disableMoments = true;
cfg6.useThreeDofForceModel = true;
cfg6.debug6DOFInitialPrint = true;
cfg6.initialP_deg_s = 0;
cfg6.initialQ_deg_s = 0;
cfg6.initialR_deg_s = 0;

constantsVac = constantGravityConstants(constants);
cfgVac = buildStage11Config(vehicle, constantsVac, baseInput);
cfgVac.dofMode = '6DOF';
cfgVac.disableAero = true;
cfgVac.disableDrag = true;
cfgVac.disableLift = true;
cfgVac.disableMoments = true;
cfgVac.useThreeDofForceModel = false;
cfgVac.debug6DOFInitialPrint = true;
cfgVac.initialP_deg_s = 0;
cfgVac.initialQ_deg_s = 0;
cfgVac.initialR_deg_s = 0;

fprintf('\nStage 11 6-DOF debug check\n');
fprintf('Launch: V0 = %.3f m/s, angle = %.3f deg, yaw = %.3f deg\n', ...
    base.launchSpeed_mps, base.launchAngle_deg, base.launchYaw_deg);

case3 = runSingleTrajectory(base.vehicle, constants, cfg3);
case6 = runSingleTrajectory(base.vehicle, constants, cfg6);
caseVac = runSingleTrajectory(cfgVac.vehicle, constantsVac, cfgVac);

analytical = analyticalProjectile(base, constantsVac);
initial = initialVelocityTable(base);

summaryTable = makeSummaryTable({ ...
    'Stage 11 3-DOF baseline', ...
    'Stage 11 6-DOF translational equivalent', ...
    'Stage 11 6-DOF vacuum'}, ...
    {case3, case6, caseVac});

vacuumErrors = makeVacuumErrorTable(caseVac, analytical);
translationComparison = compareTrajectories(case3, case6);
vacuumValidationPassed = all(vacuumErrors.PercentError < 1.0 | isnan(vacuumErrors.PercentError)) && ...
    abs(summaryTable.EnergyChange_percent(3)) < 0.5 && caseVac.impactDetected;
translationClose = translationComparison.Close;

summaryTable.PhysicsFlag = strings(height(summaryTable), 1);
summaryTable.PhysicsFlag(:) = "OK";
if ~vacuumValidationPassed
    summaryTable.PhysicsFlag(3) = "ERROR: vacuum does not match analytical projectile";
end
if ~translationClose
    summaryTable.PhysicsFlag(2) = "WARNING: 6-DOF equivalent differs from 3-DOF baseline";
end

fprintf('\nInitial inertial velocity check:\n');
disp(initial);
fprintf('\n6-DOF diagnostic summary:\n');
disp(summaryTable);
fprintf('\nVacuum analytical comparison:\n');
disp(vacuumErrors);
fprintf('\n3-DOF vs 6-DOF translational-equivalent comparison:\n');
disp(translationComparison.Table);

plotFiles = createDebugPlots(case3, case6, caseVac, analytical, base);

diagnostics = struct();
diagnostics.case3DOF = case3;
diagnostics.case6DOFEquivalent = case6;
diagnostics.case6DOFVacuum = caseVac;
diagnostics.analyticalVacuum = analytical;
diagnostics.initialVelocityTable = initial;
diagnostics.summaryTable = summaryTable;
diagnostics.vacuumErrorTable = vacuumErrors;
diagnostics.translationComparisonTable = translationComparison.Table;
diagnostics.vacuumValidationPassed = vacuumValidationPassed;
diagnostics.translationClose = translationClose;
diagnostics.plotFiles = plotFiles;
diagnostics.config = base;
end

function T = initialVelocityTable(config)
phi0 = 0;
theta0 = deg2rad(config.launchAngle_deg);
psi0 = deg2rad(config.launchYaw_deg);
bodyVelocity = [config.launchSpeed_mps; 0; 0];
inertialVelocity = eulerBodyToInertial_stage11(phi0, theta0, psi0) * bodyVelocity;
T = table(config.launchSpeed_mps, config.launchAngle_deg, rad2deg(theta0), ...
    bodyVelocity(1), bodyVelocity(2), bodyVelocity(3), ...
    inertialVelocity(1), inertialVelocity(2), inertialVelocity(3), ...
    'VariableNames', {'V0_mps','LaunchAngle_deg','Theta0_deg', ...
    'InitialU_mps','InitialV_mps','InitialW_mps', ...
    'InitialVx_mps','InitialVy_mps','InitialVh_mps'});
end

function T = makeSummaryTable(names, cases)
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
initialTotalEnergy_J = nan(n, 1);
finalTotalEnergy_J = nan(n, 1);
energyChange_percent = nan(n, 1);
impactReached = false(n, 1);
for k = 1:n
    r = cases{k};
    stageName(k) = string(names{k});
    range_km(k) = safeScalar(r, 'range') / 1000;
    maxAltitude_km(k) = safeScalar(r, 'maxAltitude') / 1000;
    timeOfFlight_s(k) = safeScalar(r, 'timeOfFlight');
    impactSpeed_mps(k) = safeScalar(r, 'impactSpeed');
    maxMach(k) = safeScalar(r, 'maxMach');
    maxDynamicPressure_kPa(k) = safeScalar(r, 'maxQ') / 1000;
    maxCD(k) = safeScalar(r, 'maxCD');
    maxCL(k) = safeScalar(r, 'maxCL');
    maxLD(k) = safeScalar(r, 'maxLD');
    if isfield(r, 'totalEnergy') && numel(r.totalEnergy) >= 2
        initialTotalEnergy_J(k) = r.totalEnergy(1);
        finalTotalEnergy_J(k) = r.totalEnergy(end);
        energyChange_percent(k) = 100 * (r.totalEnergy(end) - r.totalEnergy(1)) / ...
            max(abs(r.totalEnergy(1)), eps);
    end
    impactReached(k) = isfield(r, 'impactDetected') && r.impactDetected;
end
T = table(stageName, range_km, maxAltitude_km, timeOfFlight_s, impactSpeed_mps, ...
    maxMach, maxDynamicPressure_kPa, maxCD, maxCL, maxLD, ...
    initialTotalEnergy_J, finalTotalEnergy_J, energyChange_percent, impactReached, ...
    'VariableNames', {'StageName','Range_km','MaxAltitude_km','TimeOfFlight_s', ...
    'ImpactSpeed_mps','MaxMach','MaxDynamicPressure_kPa','MaxCD','MaxCL','MaxLD', ...
    'InitialTotalMechanicalEnergy_J','FinalTotalMechanicalEnergy_J', ...
    'EnergyChange_percent','ImpactReached'});
end

function T = makeVacuumErrorTable(result, analytical)
metric = ["Range"; "Max altitude"; "Time of flight"; "Impact speed"];
analyticalValue = [analytical.range_m; analytical.maxAltitude_m; ...
    analytical.timeOfFlight_s; analytical.impactSpeed_mps];
simulatedValue = [result.range; result.maxAltitude; result.timeOfFlight; result.impactSpeed];
absoluteError = simulatedValue - analyticalValue;
percentError = 100 * abs(absoluteError) ./ max(abs(analyticalValue), eps);
T = table(metric, analyticalValue, simulatedValue, absoluteError, percentError, ...
    'VariableNames', {'Metric','AnalyticalValue','SimulatedValue','AbsoluteError','PercentError'});
end

function out = compareTrajectories(case3, case6)
names = ["Range"; "Max altitude"; "Time of flight"; "Impact speed"];
value3 = [case3.range; case3.maxAltitude; case3.timeOfFlight; case3.impactSpeed];
value6 = [case6.range; case6.maxAltitude; case6.timeOfFlight; case6.impactSpeed];
percentDifference = 100 * abs(value6 - value3) ./ max(abs(value3), eps);
T = table(names, value3, value6, percentDifference, ...
    'VariableNames', {'Metric','ThreeDOF','SixDOFEquivalent','PercentDifference'});
out = struct();
out.Table = T;
out.Close = all(percentDifference < 2.0 | isnan(percentDifference));
end

function analytical = analyticalProjectile(config, constants)
g = getField(constants, 'g', getField(constants, 'g0', 9.80665));
V0 = config.launchSpeed_mps;
theta = deg2rad(config.launchAngle_deg);
h0 = max(config.initialAltitude_m, 0) + 1e-3;
vx0 = V0 * cos(theta);
vh0 = V0 * sin(theta);
tof = (vh0 + sqrt(vh0^2 + 2 * g * h0)) / g;
analytical = struct();
analytical.range_m = vx0 * tof;
analytical.maxAltitude_m = h0 + max(vh0, 0)^2 / (2 * g);
analytical.timeOfFlight_s = tof;
analytical.impactSpeed_mps = sqrt(V0^2 + 2 * g * h0);
analytical.x = [0; analytical.range_m];
analytical.h = [h0; 0];
end

function files = createDebugPlots(case3, case6, caseVac, analytical, config)
figVisible = getField(config, 'figureVisible', 'off');
files = strings(2, 1);

fig1 = figure('Visible', figVisible, 'Name', 'Stage 11 6-DOF Debug Translational Comparison');
tiledlayout(fig1, 3, 1);
nexttile;
hold on; grid on;
plot(case3.x ./ 1000, case3.h ./ 1000, 'LineWidth', 1.4);
plot(case6.x ./ 1000, case6.h ./ 1000, '--', 'LineWidth', 1.4);
plot(caseVac.x ./ 1000, caseVac.h ./ 1000, ':', 'LineWidth', 1.4);
xlabel('Downrange (km)'); ylabel('Altitude (km)'); title('Trajectory');
legend({'3-DOF baseline','6-DOF equivalent','6-DOF vacuum'}, 'Location', 'best');
nexttile;
hold on; grid on;
plot(case3.t, case3.h ./ 1000, 'LineWidth', 1.4);
plot(case6.t, case6.h ./ 1000, '--', 'LineWidth', 1.4);
plot(caseVac.t, caseVac.h ./ 1000, ':', 'LineWidth', 1.4);
xlabel('Time (s)'); ylabel('Altitude (km)'); title('Altitude vs Time');
nexttile;
hold on; grid on;
plot(case3.t, case3.V, 'LineWidth', 1.4);
plot(case6.t, case6.V, '--', 'LineWidth', 1.4);
plot(caseVac.t, caseVac.V, ':', 'LineWidth', 1.4);
yline(analytical.impactSpeed_mps, 'k:', 'Analytical impact speed');
xlabel('Time (s)'); ylabel('Speed (m/s)'); title('Velocity vs Time');
files(1) = string(fullfile(config.figureDir, 'Stage11_Debug6DOF_Translational.png'));
saveas(fig1, files(1));

fig2 = figure('Visible', figVisible, 'Name', 'Stage 11 6-DOF Debug Attitude');
tiledlayout(fig2, 2, 1);
nexttile;
hold on; grid on;
plot(case6.t, case6.phi_deg, 'LineWidth', 1.2);
plot(case6.t, case6.theta_deg, 'LineWidth', 1.2);
plot(case6.t, case6.psi_deg, 'LineWidth', 1.2);
xlabel('Time (s)'); ylabel('Euler angle (deg)'); title('6-DOF Euler Angles');
legend({'phi','theta','psi'}, 'Location', 'best');
nexttile;
hold on; grid on;
plot(case6.t, case6.p_deg_s, 'LineWidth', 1.2);
plot(case6.t, case6.q_deg_s, 'LineWidth', 1.2);
plot(case6.t, case6.r_deg_s, 'LineWidth', 1.2);
xlabel('Time (s)'); ylabel('Angular rate (deg/s)'); title('6-DOF Angular Rates');
legend({'p','q','r'}, 'Location', 'best');
files(2) = string(fullfile(config.figureDir, 'Stage11_Debug6DOF_Attitude.png'));
saveas(fig2, files(2));

if strcmpi(figVisible, 'off')
    close(fig1);
    close(fig2);
end
end

function constantsOut = constantGravityConstants(constantsIn)
constantsOut = constantsIn;
if ~isfield(constantsOut, 'g') && isfield(constantsOut, 'g0')
    constantsOut.g = constantsOut.g0;
elseif ~isfield(constantsOut, 'g')
    constantsOut.g = 9.80665;
end
if isfield(constantsOut, 'Re')
    constantsOut = rmfield(constantsOut, 'Re');
end
end

function value = safeScalar(s, fieldName)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
    if numel(value) > 1
        value = value(1);
    end
else
    value = NaN;
end
end

function safeMkdir(folder)
if ~exist(folder, 'dir')
    mkdir(folder);
end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
