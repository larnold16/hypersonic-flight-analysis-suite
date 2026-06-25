%% main.m
% Hypersonic Trajectory Calculator
% Stage 1: Baseline 2D projectile with drag
% Stage 2: Variable atmosphere, variable gravity, Mach-dependent aero,
%          dynamic pressure, and stagnation temperature
% Stage 3: Vehicle body geometry, reference area from diameter,
%          angle of attack, lift/drag aero model, and L/D tracking
% Stage 4: Spherical Earth, Earth rotation, inertial-frame trajectory,
%          rotating atmosphere, and higher-altitude atmosphere model
% Stage 5: Mission design sweep using the Stage 4 trajectory model
% Stage 6: Vehicle/body comparison using the Stage 5 optimization layer
% Stage 7: Simplified thermal loading estimate using Stage 4 trajectory outputs
% Stage 8: Simplified stability, trim, and maneuverability estimate
% Stage 9: Launch environment / weather sensitivity analysis
% Stage 10: Simplified 6-DOF flight dynamics prototype
% Stage 11: Hypersonic trajectory analysis suite
% Stage 12: Validation, testing, portfolio polish, and documentation
% Stage 13: Optimization, Monte Carlo, sensitivity, and trade studies
% Stage 14: Interactive MATLAB engineering app / GUI

clear; clc; close all;

addpath('Stage1')
addpath('Stage2')
addpath('Stage3')
addpath('Stage4')
addpath('Stage5')
addpath('Stage6')
addpath('Stage7')
addpath('Stage8')
addpath('Stage9')
addpath('Stage10')
addpath('Stage11')
addpath('Stage12')
addpath('Stage13')
addpath('Stage14')
addpath('Shared')

%% =========================
%  Select Model Stage
%  =========================
% stage = 1 --> baseline Stage 1 model
% stage = 2 --> upgraded Stage 2 model
% stage = 3 --> vehicle geometry + lift/drag aero model
% stage = 4 --> spherical Earth + Earth rotation + high-altitude atmosphere
% stage = 5 --> Stage 4 launch-condition sweep / mission design
% stage = 6 --> vehicle/body comparison and custom input stage
% stage = 7 --> simplified thermal loading / aero-heating estimate
% stage = 8 --> simplified stability / trim / maneuverability estimate
% stage = 9 --> simplified launch environment / weather sensitivity analysis
% stage = 10 --> simplified 6-DOF flight dynamics prototype
% stage = 11 --> hypersonic trajectory analysis suite
% stage = 12 --> validation, regression testing, and portfolio documentation
% stage = 13 --> optimization, Monte Carlo, sensitivity, and trade studies
% stage = 14 --> interactive MATLAB engineering app / GUI

stage = 14;   % Change to 1 through 14

fprintf('Hypersonic Trajectory Calculator\n');
fprintf('Select model stage:\n');
fprintf('  1 = Baseline 2D projectile with drag\n');
fprintf('  2 = Variable atmosphere, gravity, Mach aero, dynamic pressure, and stagnation temperature\n');
fprintf('  3 = Vehicle geometry, lift/drag aero model, L/D, and ballistic coefficient\n');
fprintf('  4 = Highest-fidelity trajectory model: spherical Earth, Earth rotation, and high-altitude atmosphere\n');
fprintf('  5 = Launch-condition optimization using the Stage 4 trajectory model\n');
fprintf('  6 = Vehicle/body comparison using Stage 5, with Stage 7 thermal metrics\n');
fprintf('  7 = Simplified thermal loading / aero-heating estimate for one Stage 4 trajectory\n');
fprintf('  8 = Simplified stability, trim, and maneuverability estimate\n');
fprintf('  9 = Launch environment / weather sensitivity analysis\n');
fprintf(' 10 = Simplified 6-DOF flight dynamics prototype\n');
fprintf(' 11 = Hypersonic trajectory analysis suite\n');
fprintf(' 12 = Validation, regression testing, and portfolio documentation\n');
fprintf(' 13 = Optimization, Monte Carlo, sensitivity, and trade studies\n');
fprintf(' 14 = Interactive MATLAB engineering app / GUI\n\n');

stageDefault = stage;
stage = round(promptWithDefault('Select stage', stageDefault));

if isempty(stage) || isnan(stage) || stage < 1 || stage > 14
    warning('main:InvalidStageSelection', ...
        'Invalid stage selection. Using default stage %d.', stageDefault);
    stage = stageDefault;
end


%% =========================
%  Constants
%  =========================

% Stage 1 constants
constants.g     = 9.80665;     % constant gravity [m/s^2]
constants.rho0  = 1.225;       % sea-level density [kg/m^3]
constants.H     = 8500;        % exponential atmosphere scale height [m]

% Stage 2 / Stage 3 / Stage 4 gravity constants
constants.g0    = 9.80665;         % sea-level gravity [m/s^2]
constants.Re    = 6371000;         % Earth radius [m]
constants.mu    = 3.986004418e14;  % Earth gravitational parameter [m^3/s^2]

% Stage 4 Earth rotation constant
constants.omegaEarth = 7.2921159e-5;    % Earth rotation rate [rad/s]

% Stage 2 / Stage 3 / Stage 4 atmosphere / Mach constants
constants.gamma = 1.4;         % ratio of specific heats for air [-]
constants.R     = 287.05;      % gas constant for air [J/kg-K]
constants.T0    = 288.15;      % sea-level temperature [K]
constants.P0    = 101325;      % sea-level pressure [Pa]
constants.L     = 0.0065;      % Stage 2 lapse rate magnitude [K/m]

% Stage 3 layered atmosphere information
% 0-11 km: temperature decreases
% 11-20 km: approximately isothermal
% 20-32 km: temperature increases
% 32-47 km: temperature increases faster
constants.atmLayerHeights = [0, 11000, 20000, 32000, 47000];     % [m]
constants.atmLapseRates   = [-0.0065, 0.0, 0.0010, 0.0028];     % [K/m]

% Stage 4 launch site
% Example launch site: Cape Canaveral area
constants.launchLat = deg2rad(28.5);     % latitude [rad]
constants.launchLon = deg2rad(-80.6);    % longitude [rad]
constants.launchAlt = 0;                 % launch altitude [m]


%% =========================
%  Vehicle Parameters
%  =========================

vehicle.mass = 5.0;            % mass [kg]

% Stage 1 / Stage 2 baseline aero value
vehicle.Cd = 0.35;             % Stage 1 constant drag coefficient [-]

% Stage 3 / Stage 4 vehicle shape assumption
% The vehicle is modeled as a generic slender axisymmetric hypersonic
% projectile/body of revolution. The model does not explicitly define
% nose shape, tail shape, fins, center of pressure, center of gravity,
% or static stability. Geometry effects are included through diameter,
% length, reference area, and fineness ratio.

vehicle.shape = 'Generic slender axisymmetric hypersonic projectile/body of revolution';

% Stage 3 / Stage 4 body geometry
vehicle.diameter = 0.0564;     % body diameter [m]
vehicle.length   = 0.45;       % body length [m]

% Reference area based on circular frontal area
vehicle.area = pi * vehicle.diameter^2 / 4;    % reference area [m^2]

% Fineness ratio = length / diameter
vehicle.fineness = vehicle.length / vehicle.diameter;

% Stage 4 aliases for cleaner naming inside Stage 4 functions
vehicle.referenceArea = vehicle.area;
vehicle.finenessRatio = vehicle.fineness;

% Launch conditions
vehicle.V0 = 1800;             % launch speed [m/s]
vehicle.launchAngle = 25;      % launch angle [deg]

% Stage 4 launch direction
vehicle.launchAzimuth_deg = 90;    % 90 deg = due east

% Stage 2 aero parameters
vehicle.CL = 0.00;             % lift coefficient [-], keep 0 for no-lift baseline

% Representative Mach-dependent Cd table for Stage 2
vehicle.M_table  = [0.3 0.8 1.0 1.2 2.0 5.0 10.0];
vehicle.Cd_table = [0.25 0.30 0.55 0.45 0.35 0.32 0.30];

% Stage 3 / Stage 4 aero parameters
vehicle.alpha_deg = 2.0;       % angle of attack [deg]
vehicle.Cd_scale  = 1.00;      % drag scaling factor [-]
vehicle.CL_scale  = 1.00;      % lift scaling factor [-]
vehicle.k_induced = 0.08;      % induced drag factor [-]
vehicle.CL_max    = 0.80;      % simple lift coefficient limit [-]

% Stage 4 also uses alpha in radians
vehicle.alpha = deg2rad(vehicle.alpha_deg);

% Stage 3 zero-lift drag table
vehicle.M_table_stage3 = [0.3 0.8 1.0 1.2 2.0 3.0 5.0 8.0 10.0];
vehicle.Cd0_table_stage3 = [0.25 0.30 0.60 0.50 0.38 0.34 0.31 0.30 0.30];

% Stage 3 lift-curve slope table, per radian
vehicle.M_CLalpha_table = [0.3 0.8 1.2 2.0 3.0 5.0 8.0 10.0];
vehicle.CLalpha_table   = [2.0 2.4 2.2 1.8 1.5 1.1 0.9 0.85];

% Stage 7 simplified thermal properties.
% These are approximate trade-study defaults, not flight-qualified TPS inputs.
vehicle.noseRadius_m = vehicle.diameter / 2;       % rounded-nose estimate [m]
vehicle.wallArealMass_kg_m2 = 8.0;                 % effective thermal mass [kg/m^2]
vehicle.materialCp_J_kgK = 900;                    % representative metal/composite cp [J/kg-K]
vehicle.initialWallTemp_K = 288.15;                % initial wall temperature [K]
vehicle.maxAllowableWallTemp_K = 900;              % optional comparison limit [K]
vehicle.emissivity = 0.80;                         % optional radiation cooling [-]

% Stage 8 simplified stability / trim / maneuverability properties.
% These are first-order trade-study inputs, not 6-DOF or CFD-derived data.
vehicle.cgLocation_m = 0.50 * vehicle.length;              % measured aft from nose [m]
vehicle.cpLocation_m = 0.60 * vehicle.length;              % measured aft from nose [m]
vehicle.referenceMomentLength_m = vehicle.diameter;        % reference length for Cm [-]
vehicle.pitchMomentSlope_per_rad = [];                     % [] estimates from static margin
vehicle.trimMomentCoefficient = 0.01;                      % simplified Cm0 estimate [-]
vehicle.maxAllowableAlpha_deg = 10;                        % allowed trim AoA magnitude [deg]
vehicle.maxNormalLoad_g = 15;                              % target maneuver load [g]


%% =========================
%  Run Selected Stage
%  =========================

if stage == 1

    fprintf('Running Stage 1: Baseline projectile model...\n\n');

    [t, state] = runStage1(vehicle, constants);

    results = postProcess_stage1(t, state, vehicle, constants);

    plotStage1(results);

elseif stage == 2

    fprintf('Running Stage 2: Mach-dependent aero and flight environment model...\n\n');

    [t, state] = runStage2(vehicle, constants);

    results = postProcess_stage2(t, state, vehicle, constants);

    plotStage2(results);

elseif stage == 3

    fprintf('Running Stage 3: Vehicle geometry and lift/drag aero model...\n\n');

    [t, state] = runStage3(vehicle, constants);

    results = postProcess_stage3(t, state, vehicle, constants);

    plotStage3(results);

elseif stage == 4

    fprintf('Running Stage 4: Spherical Earth, Earth rotation, and high-altitude atmosphere model...\n\n');

    % Stage 4 uses radians for launch angle and launch azimuth.
    % This prevents Stage 1-3 from breaking, since they use launchAngle in degrees.
    vehicle.launchAngle = deg2rad(vehicle.launchAngle);
    vehicle.launchAzimuth = deg2rad(vehicle.launchAzimuth_deg);

    % Stage 4 uses the more detailed Stage 3 drag table.
    vehicle.M_table = vehicle.M_table_stage3;
    vehicle.Cd_table = vehicle.Cd0_table_stage3;

    [t, state] = runStage4(vehicle, constants);

    results = postProcess_stage4(t, state, vehicle, constants);

    plotStage4(results);

elseif stage == 5

    fprintf('Running Stage 5: Mission design sweep using the Stage 4 model...\n\n');

    % Stage 5 sweeps launch angle in degrees and converts each case to
    % radians before calling Stage 4.
    vehicle.launchAzimuth = deg2rad(vehicle.launchAzimuth_deg);

    % Stage 5 reuses the Stage 4 vehicle/aero setup.
    vehicle.M_table = vehicle.M_table_stage3;
    vehicle.Cd_table = vehicle.Cd0_table_stage3;

    stage5Config.launchAngles_deg = 1:1:60;
    stage5Config.maxAllowableAngle_deg = 60;       % intentional upper angle cap [deg]
    stage5Config.maxQ_limit = 2000e3;              % user-defined max-Q limit [Pa]
    stage5Config.minRangeForAltitude_m = 30000;    % [m], set [] to disable
    stage5Config.targetRange = [];                 % optional target range [m]
    stage5Config.showPlots = true;
    results = runStage5(vehicle, constants, stage5Config);

    if stage5Config.showPlots
        plotStage5Results(results);
    end

elseif stage == 6

    fprintf('Running Stage 6: Vehicle/body comparison using Stage 5 optimization...\n\n');

    % Stage 6 compares vehicle inputs but reuses Stage 5 and Stage 4.
    vehicle.launchAzimuth = deg2rad(vehicle.launchAzimuth_deg);
    vehicle.M_table = vehicle.M_table_stage3;
    vehicle.Cd_table = vehicle.Cd0_table_stage3;

    stage5Config.launchAngles_deg = 1:1:60;
    stage5Config.maxAllowableAngle_deg = 60;
    stage5Config.maxQ_limit = 2000e3;
    stage5Config.minRangeForAltitude_m = 30000;
    stage5Config.targetRange = [];

    results = runStage6(vehicle, constants, stage5Config);

elseif stage == 7

    fprintf('Running Stage 7: Simplified thermal loading estimate using Stage 4 trajectory outputs...\n\n');

    % Stage 7 reuses Stage 4 trajectory outputs and does not modify the
    % Stage 4 equations of motion or aerodynamic model.
    vehicle.launchAngle = deg2rad(vehicle.launchAngle);
    vehicle.launchAzimuth = deg2rad(vehicle.launchAzimuth_deg);
    vehicle.M_table = vehicle.M_table_stage3;
    vehicle.Cd_table = vehicle.Cd0_table_stage3;

    stage7Config.showPlots = true;
    stage7Config.verbose = true;

    results = runStage7(vehicle, constants, stage7Config);

elseif stage == 8

    fprintf('Running Stage 8: Simplified stability, trim, and maneuverability estimate...\n\n');

    % Stage 8 reuses Stage 4 trajectory outputs and does not modify the
    % Stage 4 equations of motion or aerodynamic model.
    vehicle.launchAngle = deg2rad(vehicle.launchAngle);
    vehicle.launchAzimuth = deg2rad(vehicle.launchAzimuth_deg);
    vehicle.M_table = vehicle.M_table_stage3;
    vehicle.Cd_table = vehicle.Cd0_table_stage3;

    stage8Config.showPlots = true;
    stage8Config.verbose = true;

    results = runStage8(vehicle, constants, stage8Config);

elseif stage == 9

    fprintf('Running Stage 9: Launch environment / weather sensitivity analysis...\n\n');

    % Stage 9 reuses Stage 5, Stage 4, and Stage 7. Environment modifiers
    % are optional inputs to the Stage 4 atmosphere/relative-wind model.
    vehicle.launchAzimuth = deg2rad(vehicle.launchAzimuth_deg);
    vehicle.M_table = vehicle.M_table_stage3;
    vehicle.Cd_table = vehicle.Cd0_table_stage3;

    stage5Config.launchAngles_deg = 1:1:60;
    stage5Config.maxAllowableAngle_deg = 60;
    stage5Config.maxQ_limit = 2000e3;
    stage5Config.minRangeForAltitude_m = 30000;
    stage5Config.targetRange = [];

    stage9Config.showPlots = true;
    stage9Config.verbose = true;

    results = runStage9(vehicle, constants, stage5Config, stage9Config);

elseif stage == 10

    fprintf('Running Stage 10: Simplified 6-DOF flight dynamics prototype...\n\n');

    % Stage 10 is an optional flat-Earth 6-DOF prototype. It does not
    % replace the Stage 4 point-mass trajectory model.
    vehicle.M_table = vehicle.M_table_stage3;
    vehicle.Cd_table = vehicle.Cd0_table_stage3;

    stage10Config.showPlots = true;
    stage10Config.verbose = true;
    stage10Config.tFinal_s = 300;

    results = runStage10(vehicle, constants, stage10Config);

elseif stage == 11

    fprintf('Running Stage 11: Hypersonic trajectory analysis suite...\n\n');

    stage11Config.interactive = true;
    stage11Config.showPlots = true;
    stage11Config.verbose = true;
    stage11Config.figureVisible = 'on';
    results = runStage11(vehicle, constants, stage11Config);

elseif stage == 12

    fprintf('Running Stage 12: Validation, testing, portfolio polish, and documentation...\n\n');

    stage12Config.interactive = true;
    stage12Config.showPlots = true;
    stage12Config.verbose = true;
    stage12Config.figureVisible = 'on';
    results = runStage12(vehicle, constants, stage12Config);

elseif stage == 13

    fprintf('Running Stage 13: Optimization, Monte Carlo, sensitivity, and trade studies...\n\n');

    stage13Config.interactive = true;
    stage13Config.showPlots = true;
    stage13Config.verbose = true;
    stage13Config.figureVisible = 'on';
    results = runStage13(vehicle, constants, stage13Config);

elseif stage == 14

    fprintf('Running Stage 14: Interactive MATLAB engineering app / GUI...\n\n');

    results = runStage14(vehicle, constants);

else

    error('Invalid stage selected. Choose a stage from 1 through 14.');

end


%% =========================
%  Display Key Results
%  =========================

if ~ismember(stage, [5 6 9 10 11 12 13 14])

fprintf('Simulation complete.\n\n');

fprintf('Range: %.2f m\n', results.range);
fprintf('Maximum altitude: %.2f m\n', results.maxAltitude);
fprintf('Impact speed: %.2f m/s\n', results.impactSpeed);

if stage >= 2
    fprintf('Maximum Mach number: %.2f\n', results.maxMach);
    fprintf('Maximum dynamic pressure: %.2f kPa\n', results.maxQ / 1000);
    fprintf('Maximum stagnation temperature: %.2f K\n', results.maxStagTemp);
end

if stage == 3

    fprintf('\nStage 3 Vehicle/Aero Data:\n');
    fprintf('Vehicle shape assumption: %s\n', vehicle.shape);
    fprintf('Vehicle diameter: %.4f m\n', vehicle.diameter);
    fprintf('Vehicle length: %.4f m\n', vehicle.length);
    fprintf('Fineness ratio: %.2f\n', vehicle.fineness);
    fprintf('Reference area: %.6f m^2\n', vehicle.area);
    fprintf('Angle of attack: %.2f deg\n', vehicle.alpha_deg);
    fprintf('Initial ballistic coefficient: %.2f kg/m^2\n', results.beta_initial);
    fprintf('Average ballistic coefficient: %.2f kg/m^2\n', results.beta_average);
    fprintf('Minimum ballistic coefficient: %.2f kg/m^2\n', results.beta_min);

    fprintf('\nStage 3 Aero Results:\n');
    fprintf('Maximum C_D: %.3f\n', results.maxCd);
    fprintf('Maximum C_L: %.3f\n', results.maxCL);
    fprintf('Maximum L/D: %.3f\n', results.maxLD);
    fprintf('Maximum drag force: %.2f N\n', results.maxDrag);
    fprintf('Maximum lift force: %.2f N\n', results.maxLift);

    % Peak event timing
    [~, idxMaxQ] = max(results.q);
    [~, idxMaxMach] = max(results.Mach);
    [~, idxMaxAlt] = max(results.h);
    [~, idxMaxDrag] = max(results.drag);

    fprintf('\nPeak Event Times:\n');
    fprintf('Max Mach occurs at t = %.2f s\n', results.t(idxMaxMach));
    fprintf('Max dynamic pressure occurs at t = %.2f s\n', results.t(idxMaxQ));
    fprintf('Max altitude occurs at t = %.2f s\n', results.t(idxMaxAlt));
    fprintf('Max drag occurs at t = %.2f s\n', results.t(idxMaxDrag));

end

if stage == 4

    fprintf('\nStage 4 Vehicle/Aero Data:\n');
    fprintf('Vehicle shape assumption: %s\n', vehicle.shape);
    fprintf('Vehicle diameter: %.4f m\n', vehicle.diameter);
    fprintf('Vehicle length: %.4f m\n', vehicle.length);
    fprintf('Fineness ratio: %.2f\n', vehicle.finenessRatio);
    fprintf('Reference area: %.6f m^2\n', vehicle.referenceArea);
    fprintf('Angle of attack: %.2f deg\n', vehicle.alpha_deg);
    fprintf('Launch azimuth: %.2f deg\n', vehicle.launchAzimuth_deg);
    fprintf('Initial ballistic coefficient: %.2f kg/m^2\n', results.beta_initial);
    fprintf('Average ballistic coefficient: %.2f kg/m^2\n', results.beta_average);
    fprintf('Minimum ballistic coefficient: %.2f kg/m^2\n', results.beta_min);

    fprintf('\nStage 4 Model Additions:\n');
    fprintf('Spherical Earth gravity using mu: %.4e m^3/s^2\n', constants.mu);
    fprintf('Earth rotation rate: %.7e rad/s\n', constants.omegaEarth);
    fprintf('Launch latitude: %.2f deg\n', rad2deg(constants.launchLat));
    fprintf('Launch longitude: %.2f deg\n', rad2deg(constants.launchLon));

    fprintf('\nStage 4 Aero Results:\n');
    fprintf('Maximum C_D: %.3f\n', max(results.Cd));
    fprintf('Maximum C_L: %.3f\n', max(results.CL));
    fprintf('Maximum drag force: %.2f N\n', results.maxDrag);
    fprintf('Maximum lift force: %.2f N\n', results.maxLift);

    LD = results.lift ./ max(results.drag, eps);
    fprintf('Maximum L/D: %.3f\n', max(LD));

    % Peak event timing
    [~, idxMaxQ] = max(results.q);
    [~, idxMaxMach] = max(results.Mach);
    [~, idxMaxAlt] = max(results.h);
    [~, idxMaxDrag] = max(results.drag);

    fprintf('\nPeak Event Times:\n');
    fprintf('Max Mach occurs at t = %.2f s\n', results.t(idxMaxMach));
    fprintf('Max dynamic pressure occurs at t = %.2f s\n', results.t(idxMaxQ));
    fprintf('Max altitude occurs at t = %.2f s\n', results.t(idxMaxAlt));
    fprintf('Max drag occurs at t = %.2f s\n', results.t(idxMaxDrag));

    fprintf('\nFinal Ground Track:\n');
    fprintf('Final latitude: %.4f deg\n', rad2deg(results.lat(end)));
    fprintf('Final longitude: %.4f deg\n', rad2deg(results.lon(end)));

end

end
