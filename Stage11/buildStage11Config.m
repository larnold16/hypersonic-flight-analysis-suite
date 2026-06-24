function config = buildStage11Config(vehicle, constants, userConfig)
% buildStage11Config
% Builds one configuration struct for all Stage 11 modes.
%
% The defaults are deliberately conservative so a demo run completes quickly
% but still exercises hypersonic aero, heating, stability, warnings, plotting,
% export, and event termination.

if nargin < 3
    userConfig = struct();
end

config = struct();
config.stageName = 'Stage 11 Hypersonic Trajectory Analysis Suite';
config.mode = getField(userConfig, 'mode', []);
config.interactive = getField(userConfig, 'interactive', false);
config.verbose = getField(userConfig, 'verbose', true);
config.showPlots = getField(userConfig, 'showPlots', true);
config.exportResults = getField(userConfig, 'exportResults', false);
config.generateReport = getField(userConfig, 'generateReport', false);
config.figureVisible = getField(userConfig, 'figureVisible', 'on');

config.dofMode = getField(userConfig, 'dofMode', '3DOF');
config.tFinal_s = getField(userConfig, 'tFinal_s', 500);
config.maxStep_s = getField(userConfig, 'maxStep_s', 0.25);
config.relTol = getField(userConfig, 'relTol', 1e-7);
config.absTol = getField(userConfig, 'absTol', 1e-9);
config.disableDrag = getField(userConfig, 'disableDrag', false);
config.disableLift = getField(userConfig, 'disableLift', false);
config.disableAero = getField(userConfig, 'disableAero', false);
config.disableMoments = getField(userConfig, 'disableMoments', false);
config.useThreeDofForceModel = getField(userConfig, 'useThreeDofForceModel', false);
config.debug6DOFInitialPrint = getField(userConfig, 'debug6DOFInitialPrint', false);

config.initialAltitude_m = getField(userConfig, 'initialAltitude_m', ...
    getField(constants, 'launchAlt', 0));
config.launchAngle_deg = getField(userConfig, 'launchAngle_deg', ...
    getField(vehicle, 'launchAngle', 25));
config.launchYaw_deg = getField(userConfig, 'launchYaw_deg', 0);
config.launchSpeed_mps = getField(userConfig, 'launchSpeed_mps', ...
    getField(vehicle, 'V0', 1800));
config.initialP_deg_s = getField(userConfig, 'initialP_deg_s', 0);
config.initialQ_deg_s = getField(userConfig, 'initialQ_deg_s', 0);
config.initialR_deg_s = getField(userConfig, 'initialR_deg_s', 0);

config.launchAngles_deg = getField(userConfig, 'launchAngles_deg', 5:5:45);
config.bodyNames = getField(userConfig, 'bodyNames', ...
    {'Slender cone', 'Ogive nose', 'Blunt nose', 'Finned dart', 'Custom baseline'});

config.environment.windSpeed_mps = getNestedField(userConfig, {'environment', 'windSpeed_mps'}, 0);
config.environment.windDirection_deg = getNestedField(userConfig, {'environment', 'windDirection_deg'}, 0);
config.environment.verticalWind_mps = getNestedField(userConfig, {'environment', 'verticalWind_mps'}, 0);
config.environment.densityMultiplier = getNestedField(userConfig, {'environment', 'densityMultiplier'}, 1.0);
config.environment.temperatureMultiplier = getNestedField(userConfig, {'environment', 'temperatureMultiplier'}, 1.0);

config.enableEarthRotation = getField(userConfig, 'enableEarthRotation', false);

config.warningLimits.maxQ_Pa = getNestedField(userConfig, {'warningLimits', 'maxQ_Pa'}, 2500e3);
config.warningLimits.maxHeating_W_m2 = getNestedField(userConfig, {'warningLimits', 'maxHeating_W_m2'}, 2.5e6);
config.warningLimits.maxHeatLoad_J_m2 = getNestedField(userConfig, {'warningLimits', 'maxHeatLoad_J_m2'}, 150e6);
config.warningLimits.maxGLoad = getNestedField(userConfig, {'warningLimits', 'maxGLoad'}, 75);
config.warningLimits.minStaticMargin = getNestedField(userConfig, {'warningLimits', 'minStaticMargin'}, 0.05);
config.warningLimits.maxStaticMargin = getNestedField(userConfig, {'warningLimits', 'maxStaticMargin'}, 0.25);

config.outputRoot = getField(userConfig, 'outputRoot', fullfile(pwd, 'Outputs', 'Stage11'));
config.figureDir = fullfile(config.outputRoot, 'Figures');
config.tableDir = fullfile(config.outputRoot, 'Tables');
config.reportDir = fullfile(config.outputRoot, 'Reports');
config.matDir = fullfile(config.outputRoot, 'MAT');

vehicle.V0 = config.launchSpeed_mps;
vehicle.launchAngle = config.launchAngle_deg;
vehicle = buildVehicleFromGeometry_stage11(vehicle, 'Custom baseline');
config.vehicle = validateVehicleInputs(vehicle);

config.assumptions = { ...
    'Flat-Earth translational dynamics with altitude-varying gravity.', ...
    'Layered 1976-style atmosphere approximation, not full standard atmosphere.', ...
    'Empirical Mach-dependent aerodynamic coefficients for education/trade studies.', ...
    'Heating uses a Sutton-Graves-style stagnation estimate for trend analysis only.', ...
    'Simplified 6-DOF mode is educational and not flight qualified.'};

ensureOutputFolders(config);
end

function ensureOutputFolders(config)
folders = {config.outputRoot, config.figureDir, config.tableDir, config.reportDir, config.matDir};
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
    name = pathParts{k};
    if isstruct(cursor) && isfield(cursor, name) && ~isempty(cursor.(name))
        cursor = cursor.(name);
    else
        return;
    end
end
value = cursor;
end
