function design = createDesignVector(vehicle, config)
% createDesignVector
% Converts a vehicle/config baseline into a flat editable design vector.

vehicle = buildVehicleFromGeometry_stage11(vehicle, getField(vehicle, 'bodyType', 'Custom baseline'));

design = struct();
design.bodyType = string(getField(vehicle, 'bodyType', 'Custom baseline'));
design.noseType = string(getField(vehicle, 'noseType', 'custom'));
design.launchAngle_deg = getField(vehicle, 'launchAngle', 25);
design.initialSpeed_mps = getField(vehicle, 'V0', 1800);
design.initialYaw_deg = 0;
design.initialAltitude_m = 0;
design.mass_kg = getField(vehicle, 'mass', 5);
design.length_m = getField(vehicle, 'length', 0.45);
design.diameter_m = getField(vehicle, 'diameter', 0.0564);
design.noseRadius_m = getField(vehicle, 'noseRadius_m', design.diameter_m / 2);
design.finenessRatio = design.length_m / max(design.diameter_m, eps);
design.referenceArea_m2 = pi * design.diameter_m^2 / 4;
design.cgLocation_m = getField(vehicle, 'cgLocation_m', 0.50 * design.length_m);
design.staticMargin = getField(vehicle, 'staticMargin', 0.10);
design.cpLocation_m = design.cgLocation_m + design.staticMargin * design.length_m;
design.CdMultiplier = getField(vehicle, 'Cd_scale', 1.0);
design.CLalphaMultiplier = getField(vehicle, 'CL_scale', 1.0);
design.dragUncertaintyFactor = getField(vehicle, 'dragUncertaintyFactor', 1.0);
design.liftUncertaintyFactor = getField(vehicle, 'liftUncertaintyFactor', 1.0);
design.windSpeed_mps = 0;
design.windDirection_deg = 0;
design.densityMultiplier = 1.0;
design.temperatureMultiplier = 1.0;

if nargin > 1 && isfield(config, 'ranges')
    design.staticMargin = clamp(design.staticMargin, config.ranges.staticMargin(1), config.ranges.staticMargin(2));
    design.cpLocation_m = design.cgLocation_m + design.staticMargin * design.length_m;
end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end

function y = clamp(x, lo, hi)
y = min(max(x, lo), hi);
end
