function vehicle = buildVehicleFromGeometry_stage11(vehicle, bodyType)
% buildVehicleFromGeometry_stage11
% Completes a vehicle struct from simple body geometry and aero assumptions.

if nargin < 2 || isempty(bodyType)
    bodyType = getField(vehicle, 'bodyType', 'Custom baseline');
end

vehicle.bodyType = char(bodyType);
vehicle.mass = getField(vehicle, 'mass', 5.0);
vehicle.length = getField(vehicle, 'length', 0.45);
vehicle.diameter = getField(vehicle, 'diameter', 0.0564);
vehicle.referenceArea = getField(vehicle, 'referenceArea', pi * vehicle.diameter^2 / 4);
vehicle.area = vehicle.referenceArea;
vehicle.finenessRatio = getField(vehicle, 'finenessRatio', vehicle.length / max(vehicle.diameter, eps));
vehicle.fineness = vehicle.finenessRatio;
vehicle.noseType = getField(vehicle, 'noseType', inferNoseType(vehicle.bodyType));
vehicle.hasFins = getField(vehicle, 'hasFins', contains(lower(vehicle.bodyType), 'finned'));
vehicle.noseRadius_m = getField(vehicle, 'noseRadius_m', max(vehicle.diameter / 2, 1e-4));
vehicle.alpha_deg = getField(vehicle, 'alpha_deg', 2.0);
vehicle.V0 = getField(vehicle, 'V0', 1800);
vehicle.launchAngle = getField(vehicle, 'launchAngle', 25);

vehicle.cgLocation_m = getField(vehicle, 'cgLocation_m', 0.48 * vehicle.length);
vehicle.cpLocation_m = getField(vehicle, 'cpLocation_m', 0.58 * vehicle.length);
vehicle.staticMargin = (vehicle.cpLocation_m - vehicle.cgLocation_m) / max(vehicle.length, eps);

% Slender-body inertia estimates. They are adequate for bounded educational
% 6-DOF demonstrations but are not replacement mass-property measurements.
r = vehicle.diameter / 2;
vehicle.Ix = getField(vehicle, 'Ix', 0.5 * vehicle.mass * r^2);
vehicle.Iy = getField(vehicle, 'Iy', vehicle.mass * (3 * r^2 + vehicle.length^2) / 12);
vehicle.Iz = getField(vehicle, 'Iz', vehicle.Iy);

vehicle.Cd_scale = getField(vehicle, 'Cd_scale', bodyCdScale(vehicle.bodyType));
vehicle.CL_scale = getField(vehicle, 'CL_scale', 1.0 + 0.25 * double(vehicle.hasFins));
vehicle.dragUncertaintyFactor = getField(vehicle, 'dragUncertaintyFactor', 1.0);
vehicle.liftUncertaintyFactor = getField(vehicle, 'liftUncertaintyFactor', 1.0);
vehicle.CLalpha = getField(vehicle, 'CLalpha', 1.15 + 0.55 * double(vehicle.hasFins));
vehicle.CYbeta = getField(vehicle, 'CYbeta', -0.55 - 0.20 * double(vehicle.hasFins));
vehicle.k_induced = getField(vehicle, 'k_induced', 0.08);
vehicle.CL_max = getField(vehicle, 'CL_max', 0.8);

vehicle.MachTable = getField(vehicle, 'MachTable', [0.1 0.8 1.0 1.2 2.0 5.0 8.0 12.0]);
vehicle.CdTable = getField(vehicle, 'CdTable', defaultCdTable(vehicle.bodyType));
vehicle.M_table = getField(vehicle, 'M_table', vehicle.MachTable);
vehicle.Cd_table = getField(vehicle, 'Cd_table', vehicle.CdTable);
vehicle.ballisticCoefficient = vehicle.mass / max(vehicle.CdTable(6) * vehicle.referenceArea, eps);
end

function cd = defaultCdTable(bodyType)
name = lower(char(bodyType));
if contains(name, 'blunt')
    cd = [0.34 0.42 0.78 0.68 0.55 0.48 0.46 0.45];
elseif contains(name, 'ogive')
    cd = [0.23 0.28 0.55 0.45 0.34 0.30 0.29 0.29];
elseif contains(name, 'finned')
    cd = [0.28 0.34 0.62 0.52 0.40 0.35 0.34 0.34];
elseif contains(name, 'slender')
    cd = [0.22 0.27 0.52 0.42 0.32 0.28 0.27 0.27];
else
    cd = [0.25 0.30 0.60 0.50 0.38 0.32 0.30 0.30];
end
end

function scale = bodyCdScale(bodyType)
name = lower(char(bodyType));
if contains(name, 'blunt')
    scale = 1.18;
elseif contains(name, 'slender')
    scale = 0.92;
elseif contains(name, 'ogive')
    scale = 0.98;
else
    scale = 1.0;
end
end

function noseType = inferNoseType(bodyType)
name = lower(char(bodyType));
if contains(name, 'blunt')
    noseType = 'blunt';
elseif contains(name, 'ogive')
    noseType = 'ogive';
elseif contains(name, 'cone')
    noseType = 'sharp cone';
else
    noseType = 'custom';
end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
