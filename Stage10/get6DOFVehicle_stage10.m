function vehicle6dof = get6DOFVehicle_stage10(vehicle)
% get6DOFVehicle_stage10
% Fills in simplified 6-DOF vehicle properties.

vehicle6dof = vehicle;

vehicle6dof.area = pi * vehicle.diameter^2 / 4;
vehicle6dof.referenceArea = vehicle6dof.area;
vehicle6dof.fineness = vehicle.length / vehicle.diameter;
vehicle6dof.finenessRatio = vehicle6dof.fineness;
vehicle6dof.referenceLength_m = getField(vehicle, 'referenceLength_m', vehicle.diameter);
vehicle6dof.referenceMomentLength_m = getField(vehicle, ...
    'referenceMomentLength_m', vehicle.diameter);

vehicle6dof.cgLocation_m = getField(vehicle, 'cgLocation_m', 0.50 * vehicle.length);
vehicle6dof.cpLocation_m = getField(vehicle, 'cpLocation_m', 0.60 * vehicle.length);
vehicle6dof.staticMargin = ...
    (vehicle6dof.cpLocation_m - vehicle6dof.cgLocation_m) / max(vehicle.length, eps);

radius = vehicle.diameter / 2;
mass = vehicle.mass;
length = vehicle.length;

vehicle6dof.Ix = getField(vehicle, 'Ix', 0.5 * mass * radius^2);
vehicle6dof.Iy = getField(vehicle, 'Iy', (1/12) * mass * (3 * radius^2 + length^2));
vehicle6dof.Iz = getField(vehicle, 'Iz', vehicle6dof.Iy);

vehicle6dof.CYbeta_per_rad = getField(vehicle, 'CYbeta_per_rad', -0.35);
vehicle6dof.Clp_per_rad = getField(vehicle, 'Clp_per_rad', -0.08);
vehicle6dof.Cmq_per_rad = getField(vehicle, 'Cmq_per_rad', -1.20);
vehicle6dof.Cnr_per_rad = getField(vehicle, 'Cnr_per_rad', -0.60);
vehicle6dof.Cm_alpha_scale = getField(vehicle, 'Cm_alpha_scale', 0.75);
vehicle6dof.Cn_beta_scale = getField(vehicle, 'Cn_beta_scale', 0.50);
vehicle6dof.maxForceCoefficient = getField(vehicle, 'maxForceCoefficient', 1.2);
vehicle6dof.maxMomentCoefficient = getField(vehicle, 'maxMomentCoefficient', 0.5);

if isfield(vehicle6dof, 'M_table_stage3')
    vehicle6dof.M_table = vehicle6dof.M_table_stage3;
end

if isfield(vehicle6dof, 'Cd0_table_stage3')
    vehicle6dof.Cd_table = vehicle6dof.Cd0_table_stage3;
end

end

function value = getField(inputStruct, fieldName, defaultValue)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = inputStruct.(fieldName);
else
    value = defaultValue;
end
end
