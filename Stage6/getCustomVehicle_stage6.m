function [vehicle, stage5Config] = getCustomVehicle_stage6(defaultVehicle, defaultStage5Config)
% getCustomVehicle_stage6
% Prompts for a custom vehicle and Stage 5 sweep settings.

if nargin < 2
    defaultStage5Config = struct();
end

defaultStage5Config = fillDefaultStage5Config(defaultStage5Config);

defaultName = getFieldWithDefault(defaultVehicle, 'name', 'Custom vehicle');
defaultType = getFieldWithDefault(defaultVehicle, 'bodyType', 'Custom approximate body');

fprintf('\nEnter custom vehicle values. Press Enter to use the default.\n');

vehicle = defaultVehicle;
vehicle.name = promptWithDefault('Vehicle name', defaultName);
vehicle.bodyType = defaultType;
vehicle.shape = defaultType;
vehicle.mass = promptWithDefault('Mass [kg]', defaultVehicle.mass);
vehicle.diameter = promptWithDefault('Diameter [m]', defaultVehicle.diameter);
vehicle.length = promptWithDefault('Length [m]', defaultVehicle.length);
vehicle.alpha_deg = promptWithDefault('Angle of attack [deg]', defaultVehicle.alpha_deg);
vehicle.V0 = promptWithDefault('Launch speed [m/s]', defaultVehicle.V0);

vehicle.area = pi * vehicle.diameter^2 / 4;
vehicle.referenceArea = vehicle.area;
vehicle.fineness = vehicle.length / vehicle.diameter;
vehicle.finenessRatio = vehicle.fineness;
vehicle.alpha = deg2rad(vehicle.alpha_deg);
vehicle.noseRadius_m = vehicle.diameter / 2;

if isfield(vehicle, 'M_table_stage3')
    vehicle.M_table = vehicle.M_table_stage3;
end

if isfield(vehicle, 'Cd0_table_stage3')
    vehicle.Cd_table = vehicle.Cd0_table_stage3;
end

defaultAngles = defaultStage5Config.launchAngles_deg(:);
if numel(defaultAngles) > 1
    defaultStep = defaultAngles(2) - defaultAngles(1);
else
    defaultStep = 1;
end

angleMin = promptWithDefault('Launch angle sweep minimum [deg]', min(defaultAngles));
angleMax = promptWithDefault('Launch angle sweep maximum [deg]', max(defaultAngles));
angleStep = promptWithDefault('Launch angle step [deg]', defaultStep);
maxQ_kPa = promptWithDefault('Max-Q limit [kPa]', defaultStage5Config.maxQ_limit / 1000);
minRange = promptWithDefault('Minimum range requirement [m], optional', ...
    defaultStage5Config.minRangeForAltitude_m, @parseOptionalNumber);
targetRange = promptWithDefault('Target range [m], optional', ...
    defaultStage5Config.targetRange, @parseOptionalNumber);

if angleStep <= 0
    warning('Stage6:InvalidAngleStep', 'Launch angle step must be positive. Using 1 deg.');
    angleStep = 1;
end

if angleMax < angleMin
    warning('Stage6:InvalidAngleRange', ...
        'Launch angle maximum is below minimum. Swapping values.');
    temp = angleMin;
    angleMin = angleMax;
    angleMax = temp;
end

stage5Config = defaultStage5Config;
stage5Config.launchAngles_deg = angleMin:angleStep:angleMax;
stage5Config.maxAllowableAngle_deg = angleMax;
stage5Config.maxQ_limit = maxQ_kPa * 1000;
stage5Config.minRangeForAltitude_m = minRange;
stage5Config.targetRange = targetRange;

end

function config = fillDefaultStage5Config(config)
if ~isfield(config, 'launchAngles_deg')
    config.launchAngles_deg = 1:1:60;
end

if ~isfield(config, 'maxAllowableAngle_deg')
    config.maxAllowableAngle_deg = max(config.launchAngles_deg);
end

if ~isfield(config, 'maxQ_limit')
    config.maxQ_limit = 2000e3;
end

if ~isfield(config, 'minRangeForAltitude_m')
    config.minRangeForAltitude_m = 30000;
end

if ~isfield(config, 'targetRange')
    config.targetRange = [];
end
end

function value = getFieldWithDefault(inputStruct, fieldName, defaultValue)
if isfield(inputStruct, fieldName)
    value = inputStruct.(fieldName);
else
    value = defaultValue;
end
end

function value = parseOptionalNumber(rawValue)
rawValue = strtrim(rawValue);

if isempty(rawValue) || strcmpi(rawValue, 'disabled') || ...
        strcmpi(rawValue, 'none') || strcmp(rawValue, '[]')
    value = [];
else
    value = str2double(rawValue);
end
end
