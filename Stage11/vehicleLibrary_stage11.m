function vehicles = vehicleLibrary_stage11(baseVehicle)
% vehicleLibrary_stage11
% Returns educational Stage 11 vehicle body presets.
%
% CG and CP are measured aft from the nose. Positive static margin means
% CP is behind CG, which is the stable convention used by Stage 11.

if nargin < 1
    baseVehicle = struct();
end

templates = { ...
    makeTemplate('Slender cone', 5.0, 0.60, 0.045, 'sharp cone', false, 0.48, 0.58, 0.020, 0.90), ...
    makeTemplate('Ogive nose', 5.2, 0.58, 0.050, 'ogive', false, 0.47, 0.60, 0.025, 1.00), ...
    makeTemplate('Blunt nose', 5.8, 0.50, 0.065, 'blunt', false, 0.48, 0.57, 0.045, 1.20), ...
    makeTemplate('Finned dart', 4.8, 0.70, 0.042, 'finned ogive', true, 0.43, 0.62, 0.020, 0.95), ...
    makeCustom(baseVehicle)};

builtVehicles = cell(numel(templates), 1);
for k = 1:numel(templates)
    builtVehicles{k} = buildVehicleFromGeometry_stage11(templates{k}, templates{k}.bodyType);
end
vehicles = harmonizeVehicleFields(builtVehicles);
end

function v = makeTemplate(bodyType, mass, length, diameter, noseType, hasFins, cgFrac, cpFrac, noseRadius, cdScale)
v = struct();
v.bodyType = bodyType;
v.mass = mass;
v.length = length;
v.diameter = diameter;
v.noseType = noseType;
v.hasFins = hasFins;
v.cgLocation_m = cgFrac * length;
v.cpLocation_m = cpFrac * length;
v.noseRadius_m = noseRadius;
v.Cd_scale = cdScale;
v.CL_scale = 1.0 + 0.25 * double(hasFins);
v.alpha_deg = 2.0;
v.V0 = 1800;
v.launchAngle = 25;
end

function v = makeCustom(baseVehicle)
v = struct();
v.bodyType = 'Custom baseline';
v.mass = getField(baseVehicle, 'mass', 5.0);
v.length = getField(baseVehicle, 'length', 0.45);
v.diameter = getField(baseVehicle, 'diameter', 0.0564);
v.noseType = getField(baseVehicle, 'noseType', 'custom');
v.hasFins = getField(baseVehicle, 'hasFins', false);
v.cgLocation_m = getField(baseVehicle, 'cgLocation_m', 0.50 * v.length);
v.cpLocation_m = getField(baseVehicle, 'cpLocation_m', 0.60 * v.length);
v.noseRadius_m = getField(baseVehicle, 'noseRadius_m', v.diameter / 2);
v.Cd_scale = getField(baseVehicle, 'Cd_scale', 1.0);
v.CL_scale = getField(baseVehicle, 'CL_scale', 1.0);
v.alpha_deg = getField(baseVehicle, 'alpha_deg', 2.0);
v.V0 = getField(baseVehicle, 'V0', 1800);
v.launchAngle = getField(baseVehicle, 'launchAngle', 25);
end

function vehicles = harmonizeVehicleFields(vehicleCells)
allFields = {};
for k = 1:numel(vehicleCells)
    allFields = union(allFields, fieldnames(vehicleCells{k}));
end
for k = 1:numel(vehicleCells)
    for j = 1:numel(allFields)
        if ~isfield(vehicleCells{k}, allFields{j})
            vehicleCells{k}.(allFields{j}) = [];
        end
    end
    vehicleCells{k} = orderfields(vehicleCells{k}, allFields);
end
vehicles = [vehicleCells{:}].';
end

function value = getField(s, name, defaultValue)
if isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
