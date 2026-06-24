function state = buildStage14DefaultState(vehicle, constants)
% buildStage14DefaultState
% Builds the state struct used by the Stage 14 GUI and session exports.

if nargin < 1 || isempty(vehicle)
    vehicle = defaultVehicle();
end
if nargin < 2 || isempty(constants)
    constants = defaultConstants();
end

if exist('buildVehicleFromGeometry_stage11', 'file') == 2
    vehicle = buildVehicleFromGeometry_stage11(vehicle, getField(vehicle, 'bodyType', 'Custom baseline'));
end
if exist('validateVehicleInputs', 'file') == 2
    vehicle = validateVehicleInputs(vehicle);
end

state = struct();
state.vehicle = vehicle;
state.constants = constants;
state.lastRunType = 'None';
state.lastSuccess = false;
state.lastWarningText = "No runs yet.";
state.selectedCase = table();
state.currentTableName = '';
state.Tables = struct();
state.Results = struct();
state.savedRuns = struct([]);
state.savedRunCounter = 0;

state.launch.initialSpeed_mps = getField(vehicle, 'V0', 1800);
state.launch.initialMach = 0;
state.launch.launchAngle_deg = getField(vehicle, 'launchAngle', 25);
state.launch.yawAngle_deg = 0;
state.launch.initialAltitude_m = getField(constants, 'launchAlt', 0);
state.launch.initialDownrange_m = 0;
state.launch.initialCrossrange_m = 0;
state.launch.p_deg_s = 0;
state.launch.q_deg_s = 0;
state.launch.r_deg_s = 0;

state.physics.dofMode = '3DOF';
state.physics.liftEnabled = true;
state.physics.dragEnabled = true;
state.physics.windEnabled = false;
state.physics.heatingEnabled = true;
state.physics.stabilityEnabled = true;
state.physics.earthCurvature = false;
state.physics.earthRotation = false;
state.physics.lowAltitudeConstraint = false;
state.physics.angleEnvelope = 'Practical envelope: 5 to 45 deg';
state.physics.angleMin_deg = 5;
state.physics.angleMax_deg = 45;
state.physics.angleStep_deg = 5;

state.monteCarlo.N = 200;
state.monteCarlo.launchSpeedUncertainty_pct = 2;
state.monteCarlo.launchAngleUncertainty_deg = 1;
state.monteCarlo.massUncertainty_pct = 5;
state.monteCarlo.cdUncertainty_pct = 10;
state.monteCarlo.clUncertainty_pct = 10;
state.monteCarlo.densityUncertainty_pct = 5;
state.monteCarlo.cgUncertainty_pct = 2;
state.monteCarlo.cpUncertainty_pct = 2;
state.monteCarlo.windUncertainty_mps = 15;

state.optimization.studyType = 'Pareto trade study';
state.optimization.objective = 'best balanced score';
state.optimization.constraintProfile = 'generic';

state.builder.bodyType = 'Slender cone-cylinder';
state.builder.missionGoal = 'Balanced';
state.builder.launchMethod = 'Gun launch / initial velocity only';

state.compare.sweepMode = 'Launch angle sweep';
state.compare.missionGoal = 'Balanced';

state.sensitivity.perturbationPct = 5;

state.fidelity.stageName = 'Stage 14: MATLAB App / interactive interface';

state.constraints.maxQ_kPa = 2000;
state.constraints.maxStagTemp_K = 2500;
state.constraints.maxMach = 8;
state.constraints.maxGLoad = 75;
state.constraints.minStaticMargin_percent = 5;
state.constraints.maxAlpha_deg = 10;
state.constraints.maxDrag_N = 6000;
state.constraints.maxLift_N = 2500;

state.optimizationMode.objective = 'Best balanced design';
state.optimizationMode.maxCases = 120;
state.optimizationMode.useAngle = true;
state.optimizationMode.angleMin = 5;
state.optimizationMode.angleMax = 45;
state.optimizationMode.angleStep = 5;
state.optimizationMode.useSpeed = false;
state.optimizationMode.speedMin = 1600;
state.optimizationMode.speedMax = 2200;
state.optimizationMode.speedStep = 200;
state.optimizationMode.useMass = false;
state.optimizationMode.massMin = 3;
state.optimizationMode.massMax = 10;
state.optimizationMode.massStep = 1;
state.optimizationMode.useDiameter = false;
state.optimizationMode.diameterMin = 0.04;
state.optimizationMode.diameterMax = 0.09;
state.optimizationMode.diameterStep = 0.01;
state.optimizationMode.useLength = false;
state.optimizationMode.lengthMin = 0.35;
state.optimizationMode.lengthMax = 0.75;
state.optimizationMode.lengthStep = 0.1;
state.optimizationMode.useCd = false;
state.optimizationMode.cdMin = 0.8;
state.optimizationMode.cdMax = 1.2;
state.optimizationMode.cdStep = 0.1;
state.optimizationMode.useAlpha = false;
state.optimizationMode.alphaMin = 0;
state.optimizationMode.alphaMax = 6;
state.optimizationMode.alphaStep = 1;
state.optimizationMode.useStaticMargin = false;
state.optimizationMode.staticMarginMin = 5;
state.optimizationMode.staticMarginMax = 20;
state.optimizationMode.staticMarginStep = 5;

state.uncertainty.cd_pct = 10;
state.uncertainty.speed_pct = 2;
state.uncertainty.angle_deg = 1;
state.uncertainty.mass_pct = 5;
state.uncertainty.diameter_pct = 2;
state.uncertainty.density_pct = 10;

state.outputRoot = fullfile(pwd, 'Outputs', 'Stage14');
state.figureDir = fullfile(state.outputRoot, 'Figures');
state.tableDir = fullfile(state.outputRoot, 'Tables');
state.reportDir = fullfile(state.outputRoot, 'Reports');
state.matDir = fullfile(state.outputRoot, 'MAT');
state.sessionDir = fullfile(state.outputRoot, 'Sessions');
ensureStage14Folders(state);
end

function vehicle = defaultVehicle()
vehicle.mass = 5.0;
vehicle.Cd = 0.35;
vehicle.diameter = 0.0564;
vehicle.length = 0.45;
vehicle.referenceArea = pi * vehicle.diameter^2 / 4;
vehicle.area = vehicle.referenceArea;
vehicle.finenessRatio = vehicle.length / vehicle.diameter;
vehicle.fineness = vehicle.finenessRatio;
vehicle.V0 = 1800;
vehicle.launchAngle = 25;
vehicle.alpha_deg = 2;
vehicle.noseRadius_m = vehicle.diameter / 2;
vehicle.cgLocation_m = 0.50 * vehicle.length;
vehicle.cpLocation_m = 0.60 * vehicle.length;
vehicle.bodyType = 'Custom baseline';
vehicle.noseType = 'custom';
vehicle.hasFins = false;
end

function constants = defaultConstants()
constants.g = 9.80665;
constants.g0 = 9.80665;
constants.Re = 6371000;
constants.mu = 3.986004418e14;
constants.gamma = 1.4;
constants.R = 287.05;
constants.rho0 = 1.225;
constants.H = 8500;
constants.launchAlt = 0;
constants.omegaEarth = 7.2921159e-5;
end

function ensureStage14Folders(state)
folders = {state.outputRoot, state.figureDir, state.tableDir, ...
    state.reportDir, state.matDir, state.sessionDir};
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
