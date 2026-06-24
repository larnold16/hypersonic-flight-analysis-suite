function vehicle = guidedVehiclePresetStage14(bodyType, missionGoal, launchMethod, currentVehicle)
% guidedVehiclePresetStage14
% Educational vehicle presets for the Guided Vehicle Builder.

if nargin < 4 || ~isstruct(currentVehicle)
    currentVehicle = struct();
end
vehicle = currentVehicle;
bodyType = string(bodyType);
missionGoal = lower(string(missionGoal));
launchMethod = string(launchMethod);

switch lower(bodyType)
    case "slender cone-cylinder"
        vehicle.bodyType = 'Slender cone';
        vehicle.length = 0.55;
        vehicle.diameter = 0.050;
        vehicle.mass = 4.8;
        vehicle.Cd_scale = 0.92;
        vehicle.CL_scale = 1.00;
        vehicle.alpha_deg = 2.0;
        staticMargin = 0.10;
    case "blunt body"
        vehicle.bodyType = 'Blunt nose';
        vehicle.length = 0.40;
        vehicle.diameter = 0.075;
        vehicle.mass = 6.5;
        vehicle.Cd_scale = 1.18;
        vehicle.CL_scale = 0.85;
        vehicle.alpha_deg = 1.5;
        vehicle.noseRadius_m = 0.60 * vehicle.diameter;
        staticMargin = 0.12;
    case "long slender projectile"
        vehicle.bodyType = 'Slender cone';
        vehicle.length = 0.80;
        vehicle.diameter = 0.042;
        vehicle.mass = 5.8;
        vehicle.Cd_scale = 0.88;
        vehicle.CL_scale = 1.10;
        vehicle.alpha_deg = 2.5;
        staticMargin = 0.14;
    otherwise
        vehicle.bodyType = char(getField(vehicle, 'bodyType', 'Custom baseline'));
        vehicle.length = getField(vehicle, 'length', 0.45);
        vehicle.diameter = getField(vehicle, 'diameter', 0.0564);
        vehicle.mass = getField(vehicle, 'mass', 5.0);
        vehicle.Cd_scale = getField(vehicle, 'Cd_scale', 1.0);
        vehicle.CL_scale = getField(vehicle, 'CL_scale', 1.0);
        vehicle.alpha_deg = getField(vehicle, 'alpha_deg', 2.0);
        staticMargin = 0.10;
end

if contains(missionGoal, "range")
    vehicle.Cd_scale = vehicle.Cd_scale * 0.95;
elseif contains(missionGoal, "altitude")
    vehicle.alpha_deg = vehicle.alpha_deg + 0.5;
elseif contains(missionGoal, "heating")
    vehicle.noseRadius_m = 0.60 * vehicle.diameter;
elseif contains(missionGoal, "balanced")
    vehicle.Cd_scale = vehicle.Cd_scale * 0.98;
end

if contains(lower(launchMethod), "rocket")
    vehicle.V0 = 1600;
else
    vehicle.V0 = getField(vehicle, 'V0', 1800);
end

vehicle.referenceArea = pi * vehicle.diameter^2 / 4;
vehicle.area = vehicle.referenceArea;
vehicle.finenessRatio = vehicle.length / max(vehicle.diameter, eps);
vehicle.fineness = vehicle.finenessRatio;
vehicle.cgLocation_m = 0.50 * vehicle.length;
vehicle.cpLocation_m = vehicle.cgLocation_m + staticMargin * vehicle.length;
vehicle.noseRadius_m = getField(vehicle, 'noseRadius_m', vehicle.diameter / 2);
vehicle = buildVehicleFromGeometry_stage11(vehicle, vehicle.bodyType);
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
