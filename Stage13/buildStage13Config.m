function config = buildStage13Config(vehicle, constants, userConfig)
% buildStage13Config
% Central editable configuration for Stage 13 design studies.

if nargin < 3
    userConfig = struct();
end

config = struct();
config.mode = getField(userConfig, 'mode', []);
config.interactive = getField(userConfig, 'interactive', false);
config.verbose = getField(userConfig, 'verbose', true);
config.showPlots = getField(userConfig, 'showPlots', true);
config.figureVisible = getField(userConfig, 'figureVisible', 'on');
config.baseVehicle = buildVehicleFromGeometry_stage11(vehicle, 'Custom baseline');
config.constants = constants;

config.outputRoot = getField(userConfig, 'outputRoot', fullfile(pwd, 'Outputs', 'Stage13'));
config.figureDir = fullfile(config.outputRoot, 'Figures');
config.tableDir = fullfile(config.outputRoot, 'Tables');
config.reportDir = fullfile(config.outputRoot, 'Reports');
config.matDir = fullfile(config.outputRoot, 'MAT');
config.packageDir = fullfile(config.outputRoot, 'PortfolioPackage');
ensureFolders({config.outputRoot, config.figureDir, config.tableDir, config.reportDir, config.matDir, config.packageDir});

% Design variable ranges. These are intentionally easy to edit.
config.ranges.launchAngle_deg = getNested(userConfig, {'ranges','launchAngle_deg'}, [5 45]);
config.ranges.initialSpeed_mps = getNested(userConfig, {'ranges','initialSpeed_mps'}, [1200 2200]);
config.ranges.initialYaw_deg = getNested(userConfig, {'ranges','initialYaw_deg'}, [-5 5]);
config.ranges.initialAltitude_m = getNested(userConfig, {'ranges','initialAltitude_m'}, [0 1000]);
config.ranges.mass_kg = getNested(userConfig, {'ranges','mass_kg'}, [3 8]);
config.ranges.length_m = getNested(userConfig, {'ranges','length_m'}, [0.3 0.8]);
config.ranges.diameter_m = getNested(userConfig, {'ranges','diameter_m'}, [0.035 0.08]);
config.ranges.staticMargin = getNested(userConfig, {'ranges','staticMargin'}, [0.05 0.25]);
config.ranges.CdMultiplier = getNested(userConfig, {'ranges','CdMultiplier'}, [0.85 1.20]);
config.ranges.CLalphaMultiplier = getNested(userConfig, {'ranges','CLalphaMultiplier'}, [0.85 1.20]);
config.ranges.windSpeed_mps = getNested(userConfig, {'ranges','windSpeed_mps'}, [-30 30]);
config.ranges.densityMultiplier = getNested(userConfig, {'ranges','densityMultiplier'}, [0.95 1.05]);
config.ranges.temperatureMultiplier = getNested(userConfig, {'ranges','temperatureMultiplier'}, [0.97 1.03]);
config.ranges.bodyTypes = getNested(userConfig, {'ranges','bodyTypes'}, ...
    {'Slender cone','Ogive nose','Blunt nose','Finned dart','Custom baseline'});

config.constraints.maxQ_Pa = getNested(userConfig, {'constraints','maxQ_Pa'}, 2500e3);
config.constraints.maxGLoad = getNested(userConfig, {'constraints','maxGLoad'}, 75);
config.constraints.minStaticMargin = getNested(userConfig, {'constraints','minStaticMargin'}, 0.05);
config.constraints.maxStaticMargin = getNested(userConfig, {'constraints','maxStaticMargin'}, 0.25);
config.constraints.maxHeating_W_m2 = getNested(userConfig, {'constraints','maxHeating_W_m2'}, 8.0e6);
config.constraints.maxHeatLoad_J_m2 = getNested(userConfig, {'constraints','maxHeatLoad_J_m2'}, 250e6);

config.score.weights.range = 0.30;
config.score.weights.lowHeating = 0.20;
config.score.weights.lowQ = 0.20;
config.score.weights.stability = 0.15;
config.score.weights.lowG = 0.10;
config.score.weights.success = 0.05;
config.score.referenceRange_m = getNested(userConfig, {'score','referenceRange_m'}, 60000);

config.optimization.gridAngles_deg = getNested(userConfig, {'optimization','gridAngles_deg'}, [10 25 40]);
config.optimization.gridSpeeds_mps = getNested(userConfig, {'optimization','gridSpeeds_mps'}, [1400 1800 2200]);
config.optimization.gridMasses_kg = getNested(userConfig, {'optimization','gridMasses_kg'}, [4 6]);
config.optimization.randomCount = getNested(userConfig, {'optimization','randomCount'}, 24);
config.optimization.localStepFraction = getNested(userConfig, {'optimization','localStepFraction'}, 0.10);

config.monteCarlo.N = getNested(userConfig, {'monteCarlo','N'}, 200);
config.pareto.numCases = getNested(userConfig, {'pareto','numCases'}, 120);
config.doe.maxCases = getNested(userConfig, {'doe','maxCases'}, 96);

config.stage11.tFinal_s = getNested(userConfig, {'stage11','tFinal_s'}, 500);
config.stage11.maxStep_s = getNested(userConfig, {'stage11','maxStep_s'}, 0.35);
config.stage11.dofMode = getNested(userConfig, {'stage11','dofMode'}, '3DOF');

config.baselineDesign = createDesignVector(config.baseVehicle, config);
end

function ensureFolders(folders)
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

function value = getNested(s, pathParts, defaultValue)
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
