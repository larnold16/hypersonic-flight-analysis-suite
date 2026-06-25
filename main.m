%% main.m
% Hypersonic Trajectory Calculator - Version 1.0
% Central entry point for staged conceptual trajectory analysis.
%
% This is an educational / portfolio engineering tool. It does not contain
% targeting, guidance, interception logic, classified data, flight-test data,
% or validated high-fidelity CFD/aerodynamic coefficients.

clc; close all;

projectRoot = fileparts(mfilename('fullpath'));
setupProjectPaths(projectRoot);

%% ================================================================
%  USER SETTINGS - EDIT THESE VALUES FOR NORMAL USE
%  ================================================================
% stage = 0  -> polished Version 1.0 demo
% stage = 1  -> baseline 2D projectile with drag
% stage = 2  -> atmosphere, Mach, dynamic pressure, stagnation temperature
% stage = 3  -> vehicle geometry, lift/drag, angle of attack
% stage = 4  -> spherical Earth and rotation effects
% stage = 5  -> launch angle sweep
% stage = 6  -> vehicle/body comparison
% stage = 7  -> simplified thermal loading estimate
% stage = 8  -> stability, trim, static margin
% stage = 9  -> environmental sensitivity
% stage = 10 -> simplified 6-DOF baseline
% stage = 11 -> integrated analysis suite backend
% stage = 12 -> diagnostics / validation / portfolio outputs
% stage = 13 -> Pareto / Monte Carlo / optimization studies
% stage = 14 -> MATLAB app / GUI

if ~exist('stage', 'var'), stage = 0; end
if ~exist('initialSpeed_mps', 'var'), initialSpeed_mps = 1800; end
if ~exist('launchAngle_deg', 'var'), launchAngle_deg = 25; end
if ~exist('mass_kg', 'var'), mass_kg = 5.0; end
if ~exist('length_m', 'var'), length_m = 0.45; end
if ~exist('diameter_m', 'var'), diameter_m = 0.0564; end
if ~exist('bodyType', 'var'), bodyType = 'Generic slender body'; end
if ~exist('showPlots', 'var'), showPlots = true; end
if ~exist('exportOutputs', 'var'), exportOutputs = true; end
if ~exist('figureVisible', 'var'), figureVisible = 'on'; end

%% ================================================================
%  MODEL SETUP
%  ================================================================
constants = buildConstants();
vehicle = buildVehicle(mass_kg, length_m, diameter_m, initialSpeed_mps, launchAngle_deg, bodyType);
validateV1Inputs(vehicle);
outputDirs = ensureOutputFolders(projectRoot);

fprintf('Hypersonic Trajectory Calculator - Version 1.0\n');
fprintf('Project root: %s\n', projectRoot);
fprintf('Selected stage: %d\n\n', stage);

%% ================================================================
%  RUN SELECTED STAGE
%  ================================================================
try
    if stage == 0
        results = runVersion10Demo(vehicle, constants, showPlots, exportOutputs, outputDirs, figureVisible);
    else
        results = runSelectedStage(stage, vehicle, constants, showPlots, exportOutputs, outputDirs, figureVisible);
    end
catch ME
    fprintf(2, '\nSimulation stopped with an error.\n');
    fprintf(2, 'Identifier: %s\n', ME.identifier);
    fprintf(2, 'Message: %s\n', ME.message);
    rethrow(ME);
end

%% ================================================================
%  SHARED HELPERS
%  ================================================================
function setupProjectPaths(projectRoot)
stageFolders = {'Stage1','Stage2','Stage3','Stage4','Stage5','Stage6','Stage7', ...
    'Stage8','Stage9','Stage10','Stage11','Stage12','Stage13','Stage14','Shared'};
for k = 1:numel(stageFolders)
    folder = fullfile(projectRoot, stageFolders{k});
    if exist(folder, 'dir')
        addpath(folder);
    end
end
end

function constants = buildConstants()
constants.g     = 9.80665;
constants.rho0  = 1.225;
constants.H     = 8500;
constants.g0    = 9.80665;
constants.Re    = 6371000;
constants.mu    = 3.986004418e14;
constants.omegaEarth = 7.2921159e-5;
constants.gamma = 1.4;
constants.R     = 287.05;
constants.T0    = 288.15;
constants.P0    = 101325;
constants.L     = 0.0065;
constants.atmLayerHeights = [0, 11000, 20000, 32000, 47000];
constants.atmLapseRates   = [-0.0065, 0.0, 0.0010, 0.0028];
constants.launchLat = deg2rad(28.5);
constants.launchLon = deg2rad(-80.6);
constants.launchAlt = 0;
end

function vehicle = buildVehicle(mass_kg, length_m, diameter_m, speed_mps, angle_deg, bodyType)
vehicle = struct();
vehicle.mass = mass_kg;
vehicle.Cd = 0.35;
vehicle.shape = bodyType;
vehicle.bodyType = bodyType;
vehicle.diameter = diameter_m;
vehicle.length = length_m;
vehicle.area = pi * vehicle.diameter^2 / 4;
vehicle.fineness = vehicle.length / max(vehicle.diameter, eps);
vehicle.referenceArea = vehicle.area;
vehicle.finenessRatio = vehicle.fineness;
vehicle.V0 = speed_mps;
vehicle.launchAngle = angle_deg;
vehicle.launchAzimuth_deg = 90;
vehicle.CL = 0.00;
vehicle.M_table  = [0.3 0.8 1.0 1.2 2.0 5.0 10.0];
vehicle.Cd_table = [0.25 0.30 0.55 0.45 0.35 0.32 0.30];
vehicle.alpha_deg = 2.0;
vehicle.Cd_scale  = bodyDragScale(bodyType);
vehicle.CL_scale  = 1.00;
vehicle.k_induced = 0.08;
vehicle.CL_max    = 0.80;
vehicle.alpha = deg2rad(vehicle.alpha_deg);
vehicle.M_table_stage3 = [0.3 0.8 1.0 1.2 2.0 3.0 5.0 8.0 10.0];
vehicle.Cd0_table_stage3 = [0.25 0.30 0.60 0.50 0.38 0.34 0.31 0.30 0.30];
vehicle.M_CLalpha_table = [0.3 0.8 1.2 2.0 3.0 5.0 8.0 10.0];
vehicle.CLalpha_table   = [2.0 2.4 2.2 1.8 1.5 1.1 0.9 0.85];
vehicle.noseRadius_m = vehicle.diameter / 2;
vehicle.wallArealMass_kg_m2 = 8.0;
vehicle.materialCp_J_kgK = 900;
vehicle.initialWallTemp_K = 288.15;
vehicle.maxAllowableWallTemp_K = 900;
vehicle.emissivity = 0.80;
vehicle.cgLocation_m = 0.50 * vehicle.length;
vehicle.cpLocation_m = 0.60 * vehicle.length;
vehicle.referenceMomentLength_m = vehicle.diameter;
vehicle.pitchMomentSlope_per_rad = [];
vehicle.trimMomentCoefficient = 0.01;
vehicle.maxAllowableAlpha_deg = 10;
vehicle.maxNormalLoad_g = 15;
end

function scale = bodyDragScale(bodyType)
switch lower(strtrim(bodyType))
    case {'slender cone','cone'}
        scale = 0.92;
    case {'ogive nose','ogive'}
        scale = 0.88;
    case {'blunt nose','blunt'}
        scale = 1.18;
    case {'finned dart','dart'}
        scale = 1.05;
    otherwise
        scale = 1.00;
end
end

function validateV1Inputs(vehicle)
if vehicle.mass <= 0 || vehicle.length <= 0 || vehicle.diameter <= 0 || vehicle.area <= 0
    error('V1:InvalidVehicleGeometry', 'Mass, length, diameter, and area must be positive.');
end
if vehicle.V0 <= 0
    error('V1:InvalidInitialSpeed', 'Initial speed must be positive.');
end
if ~isfinite(vehicle.launchAngle) || vehicle.launchAngle < -5 || vehicle.launchAngle > 89
    error('V1:InvalidLaunchAngle', 'Launch angle must be finite and between -5 and 89 degrees.');
end
end

function outputDirs = ensureOutputFolders(projectRoot)
outputDirs.root = fullfile(projectRoot, 'outputs');
outputDirs.csv = fullfile(outputDirs.root, 'csv');
outputDirs.plots = fullfile(outputDirs.root, 'plots');
outputDirs.screenshots = fullfile(outputDirs.root, 'screenshots');
outputDirs.reports = fullfile(outputDirs.root, 'reports');
folders = struct2cell(outputDirs);
for k = 1:numel(folders)
    if ~exist(folders{k}, 'dir')
        mkdir(folders{k});
    end
end
end

function results = runSelectedStage(stage, vehicle, constants, showPlots, exportOutputs, outputDirs, figureVisible)
baseVehicle = vehicle;
results = struct();
fprintf('Running Stage %d...\n\n', stage);

switch stage
    case 1
        [t, state] = runStage1(baseVehicle, constants);
        results = postProcess_stage1(t, state, baseVehicle, constants);
        if showPlots, plotStage1(results); end
    case 2
        [t, state] = runStage2(baseVehicle, constants);
        results = postProcess_stage2(t, state, baseVehicle, constants);
        if showPlots, plotStage2(results); end
    case 3
        [t, state] = runStage3(baseVehicle, constants);
        results = postProcess_stage3(t, state, baseVehicle, constants);
        if showPlots, plotStage3(results); end
    case 4
        v = prepareStage4Vehicle(baseVehicle);
        [t, state] = runStage4(v, constants);
        results = postProcess_stage4(t, state, v, constants);
        if showPlots, plotStage4(results); end
    case 5
        v = prepareStage4Vehicle(baseVehicle);
        cfg = defaultStage5Config(showPlots, true);
        results = runStage5(v, constants, cfg);
        if showPlots, plotStage5Results(results); end
    case 6
        v = prepareStage4Vehicle(baseVehicle);
        cfg5 = defaultStage5Config(false, false);
        cfg6 = struct('mode', 1, 'showPlots', showPlots, 'verbose', true, 'includeThermal', false);
        results = runStage6(v, constants, cfg5, cfg6);
    case 7
        v = prepareStage4Vehicle(baseVehicle);
        results = runStage7(v, constants, struct('showPlots', showPlots, 'verbose', true));
    case 8
        v = prepareStage4Vehicle(baseVehicle);
        results = runStage8(v, constants, struct('showPlots', showPlots, 'verbose', true));
    case 9
        v = prepareStage4Vehicle(baseVehicle);
        cfg5 = defaultStage5Config(false, false);
        results = runStage9(v, constants, cfg5, struct('mode', 1, 'showPlots', showPlots, 'verbose', true));
    case 10
        cfg10 = struct('showPlots', showPlots, 'verbose', true, 'tFinal_s', 300, 'mode', 1);
        results = runStage10(baseVehicle, constants, cfg10);
    case 11
        cfg11 = struct('interactive', false, 'showPlots', showPlots, 'verbose', true, 'figureVisible', figureVisible, 'mode', 1);
        results = runStage11(baseVehicle, constants, cfg11);
    case 12
        cfg12 = struct('interactive', false, 'showPlots', showPlots, 'verbose', true, 'figureVisible', figureVisible, 'mode', 1);
        results = runStage12(baseVehicle, constants, cfg12);
    case 13
        cfg13 = defaultStage13Config(showPlots, true, figureVisible, outputDirs.root);
        cfg13.mode = 4;
        results = runStage13(baseVehicle, constants, cfg13);
    case 14
        results = runStage14(baseVehicle, constants);
    otherwise
        error('V1:InvalidStage', 'Choose stage 0 or a stage from 1 through 14.');
end

if stage == 14
    fprintf('Stage 14 MATLAB app launched successfully. Use the app window to run simulations, inspect plots, and export results.\n\n');
    return;
end

standard = standardizeResults(results);
printStandardSummary(standard, baseVehicle, sprintf('Stage %d Summary', stage));
if showPlots && isfield(standard, 't') && ~isempty(standard.t)
    plotPortfolioTrajectory(standard, outputDirs, exportOutputs, sprintf('stage%d', stage));
end
if exportOutputs
    exportStandardResults(standard, outputDirs, sprintf('stage%d', stage));
    writeSummaryText(standard, baseVehicle, outputDirs, sprintf('stage%d_summary.txt', stage));
end
end

function demo = runVersion10Demo(vehicle, constants, showPlots, exportOutputs, outputDirs, figureVisible)
fprintf('Running Version 1.0 polished demo...\n\n');
v = prepareStage4Vehicle(vehicle);
[t, state] = runStage4(v, constants);
trajectory = postProcess_stage4(t, state, v, constants);
standard = standardizeResults(trajectory);

cfg5 = defaultStage5Config(false, false);
cfg5.launchAngles_deg = 5:5:60;
angleSweep = runStage5(v, constants, cfg5);

cfg6 = defaultStage5Config(false, false);
cfg6.launchAngles_deg = 10:10:50;
bodyComparison = runStage6(v, constants, cfg6, struct('mode', 1, 'showPlots', false, 'verbose', false, 'includeThermal', false));

stability = runStage8(v, constants, struct('showPlots', false, 'verbose', false, 'trajectoryResults', trajectory));

cfg13 = defaultStage13Config(false, false, figureVisible, outputDirs.root);
cfg13.mode = 4;
cfg13.monteCarlo.N = 40;
mcResults = runStage13(vehicle, constants, cfg13);

demo = struct();
demo.trajectory = trajectory;
demo.standard = standard;
demo.angleSweep = angleSweep;
demo.bodyComparison = bodyComparison;
demo.stability = stability;
demo.monteCarlo = mcResults;

printVersion10DemoSummary(demo, vehicle);

if showPlots
    plotPortfolioTrajectory(standard, outputDirs, exportOutputs, 'v1_demo');
    plotDemoComparisons(demo, outputDirs, exportOutputs);
end
if exportOutputs
    exportStandardResults(standard, outputDirs, 'v1_demo');
    writeDemoSummaryText(demo, vehicle, outputDirs);
end
end

function v = prepareStage4Vehicle(vehicle)
v = vehicle;
if abs(v.launchAngle) > pi
    v.launchAngle = deg2rad(v.launchAngle);
end
v.launchAzimuth = deg2rad(v.launchAzimuth_deg);
v.M_table = v.M_table_stage3;
v.Cd_table = v.Cd0_table_stage3;
v.referenceArea = v.area;
v.finenessRatio = v.fineness;
v.alpha = deg2rad(v.alpha_deg);
end

function cfg = defaultStage5Config(showPlots, verbose)
cfg.launchAngles_deg = 1:1:60;
cfg.maxAllowableAngle_deg = 60;
cfg.maxQ_limit = 2000e3;
cfg.minRangeForAltitude_m = 30000;
cfg.targetRange = [];
cfg.showPlots = showPlots;
cfg.verbose = verbose;
cfg.showProgress = verbose;
end

function cfg = defaultStage13Config(showPlots, verbose, figureVisible, outputRoot)
cfg = struct();
cfg.interactive = false;
cfg.showPlots = showPlots;
cfg.verbose = verbose;
cfg.figureVisible = figureVisible;
cfg.outputRoot = fullfile(outputRoot, 'Stage13');
cfg.monteCarlo.N = 40;
cfg.pareto.numCases = 50;
cfg.doe.maxCases = 40;
cfg.optimization.randomCount = 12;
cfg.stage11.tFinal_s = 350;
cfg.stage11.maxStep_s = 0.5;
end

function s = standardizeResults(results)
s = struct();
s.t = getAnyField(results, {'t','time_s'}, []);
s.x = getAnyField(results, {'x','downrange_m','rangeHistory_m'}, []);
s.h = getAnyField(results, {'h','z','altitude_m','altitude'}, []);
s.V = getAnyField(results, {'V','speed_mps','speed','velocity'}, []);
s.Mach = getAnyField(results, {'Mach','mach'}, []);
s.q = getAnyField(results, {'q','qbar_Pa','dynamicPressure_Pa','maxQ'}, []);
s.T0 = getAnyField(results, {'T0','stagnationTemperature_K','stagTemp','stagnationTemperature'}, []);
s.range = summaryScalar(getAnyField(results, {'range','downrange_m','bestRange'}, NaN), 'max');
s.maxAltitude = summaryScalar(getAnyField(results, {'maxAltitude','maxAltitude_m','bestMinRangeAltitude'}, maxOrNaN(s.h)), 'max');
s.impactSpeed = summaryScalar(getAnyField(results, {'impactSpeed','finalSpeed_mps'}, lastOrNaN(s.V)), 'last');
s.maxMach = summaryScalar(getAnyField(results, {'maxMach'}, maxOrNaN(s.Mach)), 'max');
s.maxQ = summaryScalar(getAnyField(results, {'maxQ','maxQ_Pa'}, maxOrNaN(s.q)), 'max');
s.maxT0 = summaryScalar(getAnyField(results, {'maxT0','maxStagTemp','maxStagnationTemperature_K'}, maxOrNaN(s.T0)), 'max');
if isscalar(s.range) && isnan(s.range) && ~isempty(s.x)
    s.range = s.x(end);
end
s = fillAggregateSummary(s, results);
end

function s = fillAggregateSummary(s, results)
if ~isstruct(results)
    return;
end
if isBadScalar(s.range) && isfield(results, 'maxRange_m')
    s.range = summaryScalar(results.maxRange_m, 'max');
end
if isBadScalar(s.maxAltitude) && isfield(results, 'maxAltitudeAtBestRange_m')
    s.maxAltitude = summaryScalar(results.maxAltitudeAtBestRange_m, 'max');
end
if isBadScalar(s.impactSpeed) && isfield(results, 'impactSpeedAtBestRange_mps')
    s.impactSpeed = summaryScalar(results.impactSpeedAtBestRange_mps, 'max');
end
if isBadScalar(s.maxMach) && isfield(results, 'maxMachAtBestRange')
    s.maxMach = summaryScalar(results.maxMachAtBestRange, 'max');
end
if isBadScalar(s.maxQ) && isfield(results, 'maxQAtBestRange_Pa')
    s.maxQ = summaryScalar(results.maxQAtBestRange_Pa, 'max');
end
if isBadScalar(s.maxT0) && isfield(results, 'maxStagTempAtBestRange_K')
    s.maxT0 = summaryScalar(results.maxStagTempAtBestRange_K, 'max');
end
if isfield(results, 'environment')
    env = results.environment;
    if isBadScalar(s.range) && isfield(env, 'range_m'), s.range = summaryScalar(env.range_m, 'max'); end
    if isBadScalar(s.maxAltitude) && isfield(env, 'maxAltitude_m'), s.maxAltitude = summaryScalar(env.maxAltitude_m, 'max'); end
    if isBadScalar(s.impactSpeed) && isfield(env, 'impactSpeed_mps'), s.impactSpeed = summaryScalar(env.impactSpeed_mps, 'max'); end
    if isBadScalar(s.maxMach) && isfield(env, 'maxMach'), s.maxMach = summaryScalar(env.maxMach, 'max'); end
    if isBadScalar(s.maxQ) && isfield(env, 'maxQ_Pa'), s.maxQ = summaryScalar(env.maxQ_Pa, 'max'); end
    if isBadScalar(s.maxT0) && isfield(env, 'maxStagTemp_K'), s.maxT0 = summaryScalar(env.maxStagTemp_K, 'max'); end
end
if isfield(results, 'monteCarlo') && isfield(results.monteCarlo, 'summaryTable') && istable(results.monteCarlo.summaryTable)
    T = results.monteCarlo.summaryTable;
    if isBadScalar(s.range) && any(strcmp(T.Properties.VariableNames, 'range_m')), s.range = meanFinite(T.range_m); end
    if isBadScalar(s.maxAltitude) && any(strcmp(T.Properties.VariableNames, 'maxAltitude_m')), s.maxAltitude = meanFinite(T.maxAltitude_m); end
    if isBadScalar(s.impactSpeed) && any(strcmp(T.Properties.VariableNames, 'impactSpeed_mps')), s.impactSpeed = meanFinite(T.impactSpeed_mps); end
    if isBadScalar(s.maxMach) && any(strcmp(T.Properties.VariableNames, 'maxMach')), s.maxMach = meanFinite(T.maxMach); end
    if isBadScalar(s.maxQ) && any(strcmp(T.Properties.VariableNames, 'maxQ_Pa')), s.maxQ = meanFinite(T.maxQ_Pa); end
end
end

function tf = isBadScalar(x)
tf = isempty(x) || ~isnumeric(x) || ~isscalar(x) || ~isfinite(x);
end

function y = meanFinite(x)
x = x(isfinite(x));
if isempty(x)
    y = NaN;
else
    y = mean(x);
end
end

function value = getAnyField(s, names, defaultValue)
value = defaultValue;
if ~isstruct(s)
    return;
end
for k = 1:numel(names)
    if isfield(s, names{k}) && ~isempty(s.(names{k}))
        value = s.(names{k});
        return;
    end
end
end

function y = maxOrNaN(x)
if isempty(x)
    y = NaN;
else
    y = max(x(:));
end
end

function y = summaryScalar(x, mode)
if isempty(x) || ~isnumeric(x)
    y = NaN;
    return;
end
x = x(isfinite(x));
if isempty(x)
    y = NaN;
    return;
end
switch mode
    case 'last'
        y = x(end);
    otherwise
        y = max(x(:));
end
end

function y = lastOrNaN(x)
if isempty(x)
    y = NaN;
else
    y = x(end);
end
end

function printStandardSummary(s, vehicle, titleText)
fprintf('\n===== %s =====\n', titleText);
fprintf('Initial speed: %.2f m/s\n', vehicle.V0);
fprintf('Initial launch angle: %.2f deg\n', vehicle.launchAngle);
fprintf('Mass: %.3f kg\n', vehicle.mass);
fprintf('Length: %.4f m\n', vehicle.length);
fprintf('Diameter: %.4f m\n', vehicle.diameter);
fprintf('Reference area: %.6f m^2\n', vehicle.area);
fprintf('Range: %.2f km\n', s.range / 1000);
fprintf('Maximum altitude: %.2f km\n', s.maxAltitude / 1000);
fprintf('Impact speed: %.2f m/s\n', s.impactSpeed);
fprintf('Maximum Mach number: %.2f\n', s.maxMach);
fprintf('Maximum dynamic pressure: %.2f kPa\n', s.maxQ / 1000);
fprintf('Maximum stagnation temperature: %.2f K\n', s.maxT0);
fprintf('==============================\n\n');
end

function printVersion10DemoSummary(demo, vehicle)
s = demo.standard;
angle = getAnyField(demo.angleSweep, {'bestRangeAngle_deg'}, NaN);
body = bestBodyName(demo.bodyComparison);
staticMargin = getNestedField(demo.stability, {'stability','staticMargin_percentLength'}, NaN);
[mcMean, mcSpread] = monteCarloRangeStats(demo.monteCarlo);

fprintf('\n===== HYPERSONIC TRAJECTORY CALCULATOR: VERSION 1.0 DEMO =====\n\n');
fprintf('Vehicle:\n');
fprintf('Mass: %.3f kg\n', vehicle.mass);
fprintf('Length: %.4f m\n', vehicle.length);
fprintf('Diameter: %.4f m\n', vehicle.diameter);
fprintf('Reference area: %.6f m^2\n\n', vehicle.area);

fprintf('Trajectory:\n');
fprintf('Initial speed: %.2f m/s\n', vehicle.V0);
fprintf('Initial launch angle: %.2f deg\n', vehicle.launchAngle);
fprintf('Range: %.2f km\n', s.range / 1000);
fprintf('Maximum altitude: %.2f km\n', s.maxAltitude / 1000);
fprintf('Impact speed: %.2f m/s\n\n', s.impactSpeed);

fprintf('Flight environment:\n');
fprintf('Maximum Mach: %.2f\n', s.maxMach);
fprintf('Maximum dynamic pressure: %.2f kPa\n', s.maxQ / 1000);
fprintf('Maximum stagnation temperature: %.2f K\n\n', s.maxT0);

fprintf('Design comparison:\n');
fprintf('Best launch angle: %s\n', formatValue(angle, '%.2f deg'));
fprintf('Best body type: %s\n', body);
fprintf('Static margin: %s\n\n', formatValue(staticMargin, '%.2f %% body length'));

fprintf('Uncertainty:\n');
fprintf('Monte Carlo range mean: %s\n', formatValue(mcMean / 1000, '%.2f km'));
fprintf('Monte Carlo range spread: %s\n', formatValue(mcSpread / 1000, '%.2f km'));
fprintf('\n================================================================\n\n');
end

function text = bestBodyName(results)
text = 'not available';
if isstruct(results) && isfield(results, 'idxBestRange') && isfield(results, 'vehicleNames')
    idx = results.idxBestRange;
    if ~isnan(idx) && idx >= 1 && idx <= numel(results.vehicleNames)
        text = results.vehicleNames{idx};
    end
end
end

function value = getNestedField(s, names, defaultValue)
value = defaultValue;
cursor = s;
for k = 1:numel(names)
    if isstruct(cursor) && isfield(cursor, names{k})
        cursor = cursor.(names{k});
    else
        return;
    end
end
value = cursor;
end

function [meanRange, spreadRange] = monteCarloRangeStats(results)
meanRange = NaN;
spreadRange = NaN;
mc = getNestedField(results, {'monteCarlo'}, struct());
if isstruct(mc) && isfield(mc, 'summaryTable') && istable(mc.summaryTable) && any(strcmp(mc.summaryTable.Properties.VariableNames, 'range_m'))
    x = mc.summaryTable.range_m;
    x = x(isfinite(x));
    if ~isempty(x)
        meanRange = mean(x);
        spreadRange = max(x) - min(x);
    end
end
end

function text = formatValue(value, fmt)
if isempty(value) || ~isnumeric(value) || ~isfinite(value)
    text = 'not available';
else
    text = sprintf(fmt, value);
end
end

function exportStandardResults(s, outputDirs, prefix)
if isempty(s.t)
    return;
end
n = numel(s.t);
T = table();
T.t = columnOrNan(s.t, n);
T.x = columnOrNan(s.x, n);
T.h = columnOrNan(s.h, n);
T.V = columnOrNan(s.V, n);
T.Mach = columnOrNan(s.Mach, n);
T.q = columnOrNan(s.q, n);
T.T0 = columnOrNan(s.T0, n);
writetable(T, fullfile(outputDirs.csv, [prefix '_trajectory.csv']));
end

function x = columnOrNan(value, n)
if isempty(value)
    x = nan(n, 1);
else
    x = value(:);
    if numel(x) ~= n
        x = nan(n, 1);
    end
end
end

function writeSummaryText(s, vehicle, outputDirs, fileName)
path = fullfile(outputDirs.root, fileName);
fid = fopen(path, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'Hypersonic Trajectory Calculator Summary\n');
fprintf(fid, 'Initial speed: %.2f m/s\n', vehicle.V0);
fprintf(fid, 'Initial launch angle: %.2f deg\n', vehicle.launchAngle);
fprintf(fid, 'Mass: %.3f kg\n', vehicle.mass);
fprintf(fid, 'Length: %.4f m\n', vehicle.length);
fprintf(fid, 'Diameter: %.4f m\n', vehicle.diameter);
fprintf(fid, 'Reference area: %.6f m^2\n', vehicle.area);
fprintf(fid, 'Range: %.2f m\n', s.range);
fprintf(fid, 'Maximum altitude: %.2f m\n', s.maxAltitude);
fprintf(fid, 'Impact speed: %.2f m/s\n', s.impactSpeed);
fprintf(fid, 'Maximum Mach: %.2f\n', s.maxMach);
fprintf(fid, 'Maximum dynamic pressure: %.2f Pa\n', s.maxQ);
fprintf(fid, 'Maximum stagnation temperature: %.2f K\n', s.maxT0);
end

function writeDemoSummaryText(demo, vehicle, outputDirs)
s = demo.standard;
path = fullfile(outputDirs.root, 'v1_demo_summary.txt');
fid = fopen(path, 'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid, 'HYPERSONIC TRAJECTORY CALCULATOR: VERSION 1.0 DEMO\n');
fprintf(fid, 'Mass: %.3f kg\n', vehicle.mass);
fprintf(fid, 'Length: %.4f m\n', vehicle.length);
fprintf(fid, 'Diameter: %.4f m\n', vehicle.diameter);
fprintf(fid, 'Reference area: %.6f m^2\n', vehicle.area);
fprintf(fid, 'Range: %.2f m\n', s.range);
fprintf(fid, 'Maximum altitude: %.2f m\n', s.maxAltitude);
fprintf(fid, 'Impact speed: %.2f m/s\n', s.impactSpeed);
fprintf(fid, 'Maximum Mach: %.2f\n', s.maxMach);
fprintf(fid, 'Maximum dynamic pressure: %.2f Pa\n', s.maxQ);
fprintf(fid, 'Maximum stagnation temperature: %.2f K\n', s.maxT0);
fprintf(fid, 'Best launch angle: %.2f deg\n', getAnyField(demo.angleSweep, {'bestRangeAngle_deg'}, NaN));
fprintf(fid, 'Best body type: %s\n', bestBodyName(demo.bodyComparison));
fprintf(fid, 'Static margin: %.2f %% body length\n', getNestedField(demo.stability, {'stability','staticMargin_percentLength'}, NaN));
[mcMean, mcSpread] = monteCarloRangeStats(demo.monteCarlo);
fprintf(fid, 'Monte Carlo range mean: %.2f m\n', mcMean);
fprintf(fid, 'Monte Carlo range spread: %.2f m\n', mcSpread);
end

function plotPortfolioTrajectory(s, outputDirs, exportOutputs, prefix)
if isempty(s.t) || isempty(s.h)
    return;
end
fig = figure('Name', [prefix ' portfolio trajectory']);
set(fig, 'Color', 'w');
tiledlayout(2,2, 'Padding', 'compact', 'TileSpacing', 'compact');
nexttile;
if ~isempty(s.x)
    plot(s.x / 1000, s.h / 1000, 'LineWidth', 1.8);
    xlabel('Downrange (km)'); ylabel('Altitude (km)');
else
    plot(s.t, s.h / 1000, 'LineWidth', 1.8);
    xlabel('Time (s)'); ylabel('Altitude (km)');
end
title('Altitude vs Downrange'); grid on;
nexttile; plotIfAvailable(s.t, s.Mach, 'Time (s)', 'Mach number', 'Mach vs Time');
nexttile; plotIfAvailable(s.t, s.q / 1000, 'Time (s)', 'Dynamic pressure (kPa)', 'Dynamic Pressure vs Time');
nexttile; plotIfAvailable(s.t, s.T0, 'Time (s)', 'Stagnation temperature (K)', 'Stagnation Temperature vs Time');
if exportOutputs
    exportgraphics(fig, fullfile(outputDirs.plots, [prefix '_portfolio_plots.png']), 'Resolution', 200);
end
end

function plotIfAvailable(x, y, xLabelText, yLabelText, titleText)
if isempty(x) || isempty(y)
    text(0.1, 0.5, 'Not available'); axis off; return;
end
plot(x, y, 'LineWidth', 1.8);
xlabel(xLabelText); ylabel(yLabelText); title(titleText); grid on;
end

function plotDemoComparisons(demo, outputDirs, exportOutputs)
fig = figure('Name', 'V1 Demo comparisons');
set(fig, 'Color', 'w');
tiledlayout(1,2, 'Padding', 'compact', 'TileSpacing', 'compact');
nexttile;
if isfield(demo.angleSweep, 'launchAngles_deg') && isfield(demo.angleSweep, 'range')
    plot(demo.angleSweep.launchAngles_deg, demo.angleSweep.range / 1000, 'o-', 'LineWidth', 1.6);
    xlabel('Launch angle (deg)'); ylabel('Range (km)'); title('Launch Angle Sweep'); grid on;
else
    text(0.1, 0.5, 'Angle sweep unavailable'); axis off;
end
nexttile;
if isfield(demo.bodyComparison, 'vehicleNames') && isfield(demo.bodyComparison, 'maxRange_m')
    bar(categorical(demo.bodyComparison.vehicleNames), demo.bodyComparison.maxRange_m / 1000);
    ylabel('Best range (km)'); title('Body Comparison'); grid on;
else
    text(0.1, 0.5, 'Body comparison unavailable'); axis off;
end
if exportOutputs
    exportgraphics(fig, fullfile(outputDirs.plots, 'v1_demo_comparisons.png'), 'Resolution', 200);
end
end
