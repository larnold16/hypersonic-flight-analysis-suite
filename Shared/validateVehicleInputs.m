function vehicle = validateVehicleInputs(vehicle)
% validateVehicleInputs
% Sanitizes vehicle inputs used by Stage 11 and later stages.

vehicle.mass = positiveField(vehicle, 'mass', 5.0, 'kg');
vehicle.length = positiveField(vehicle, 'length', 0.45, 'm');
vehicle.diameter = positiveField(vehicle, 'diameter', 0.0564, 'm');

vehicle.referenceArea = getField(vehicle, 'referenceArea', pi * vehicle.diameter^2 / 4);
if ~isfinite(vehicle.referenceArea) || vehicle.referenceArea <= 0
    warning('validateVehicleInputs:BadReferenceArea', ...
        'Reference area was invalid. Recomputing from diameter.');
    vehicle.referenceArea = pi * vehicle.diameter^2 / 4;
end
vehicle.area = vehicle.referenceArea;

vehicle.finenessRatio = getField(vehicle, 'finenessRatio', vehicle.length / vehicle.diameter);
vehicle.fineness = vehicle.finenessRatio;
vehicle.noseRadius_m = getField(vehicle, 'noseRadius_m', vehicle.diameter / 2);
vehicle.noseRadius_m = max(vehicle.noseRadius_m, 1e-4);

vehicle.cgLocation_m = getField(vehicle, 'cgLocation_m', 0.48 * vehicle.length);
vehicle.cpLocation_m = getField(vehicle, 'cpLocation_m', 0.58 * vehicle.length);
vehicle.cgLocation_m = min(max(vehicle.cgLocation_m, 0), vehicle.length);
vehicle.cpLocation_m = min(max(vehicle.cpLocation_m, 0), vehicle.length);
vehicle.staticMargin = (vehicle.cpLocation_m - vehicle.cgLocation_m) / max(vehicle.length, eps);

if ~isfield(vehicle, 'bodyType') || isempty(vehicle.bodyType)
    vehicle.bodyType = 'Custom baseline';
end
if ~isfield(vehicle, 'noseType') || isempty(vehicle.noseType)
    vehicle.noseType = 'custom';
end
if ~isfield(vehicle, 'hasFins') || isempty(vehicle.hasFins)
    vehicle.hasFins = false;
end
if ~isfield(vehicle, 'V0') || isempty(vehicle.V0)
    vehicle.V0 = 1800;
end
if ~isfield(vehicle, 'launchAngle') || isempty(vehicle.launchAngle)
    vehicle.launchAngle = 25;
end

vehicle.Ix = getField(vehicle, 'Ix', 0.5 * vehicle.mass * (vehicle.diameter / 2)^2);
vehicle.Iy = getField(vehicle, 'Iy', vehicle.mass * (3 * (vehicle.diameter / 2)^2 + vehicle.length^2) / 12);
vehicle.Iz = getField(vehicle, 'Iz', vehicle.Iy);
vehicle.Ix = max(vehicle.Ix, 1e-6);
vehicle.Iy = max(vehicle.Iy, 1e-6);
vehicle.Iz = max(vehicle.Iz, 1e-6);

if vehicle.staticMargin < -0.1 || vehicle.staticMargin > 0.5
    warning('validateVehicleInputs:StaticMarginExtreme', ...
        'Static margin %.1f%% body length is outside typical educational bounds.', ...
        100 * vehicle.staticMargin);
end
end

function value = positiveField(s, name, defaultValue, units)
value = getField(s, name, defaultValue);
if ~isfinite(value) || value <= 0
    warning('validateVehicleInputs:BadInput', ...
        '%s must be positive [%s]. Using %.4g.', name, units, defaultValue);
    value = defaultValue;
end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
