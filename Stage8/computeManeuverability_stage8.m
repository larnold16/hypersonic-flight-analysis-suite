function maneuver = computeManeuverability_stage8(results, vehicle, constants, stage8Config)
% computeManeuverability_stage8
% Estimates normal acceleration and target-g lift requirements.
%
% The normal acceleration estimate uses the point-mass trajectory lift force:
%   n_g = Lift / (mass * g0)
% This is an aerodynamic load estimate, not a 6-DOF maneuver simulation.

if nargin < 4
    stage8Config = struct();
end

mass = getVehicleField(vehicle, 'mass', 1.0);
area = getVehicleField(vehicle, 'referenceArea', getVehicleField(vehicle, 'area', 1.0));
targetNormalLoad_g = getVehicleField(vehicle, 'maxNormalLoad_g', ...
    getConfigField(stage8Config, 'targetNormalLoad_g', 15));

gRef = getConstantField(constants, 'g0', 9.80665);
lift = results.lift(:);
qDynamic = results.q(:);
CLAvailable = results.CL(:);

normalAcceleration_g = lift ./ max(mass * gRef, eps);
[maxNormalAcceleration_g, idxMaxNormalAcceleration] = max(normalAcceleration_g);

CLRequiredForTarget = targetNormalLoad_g .* mass .* gRef ./ ...
    max(qDynamic .* area, eps);
CLMarginForTarget = CLAvailable - CLRequiredForTarget;

[~, idxMaxQ] = max(qDynamic);
meetsTargetNormalLoad = maxNormalAcceleration_g >= targetNormalLoad_g;

representativeAltitude_m = getConfigField(stage8Config, 'representativeAltitude_m', 30000);
[~, idxRepresentativeAltitude] = min(abs(results.h(:) - representativeAltitude_m));

maneuver.normalAcceleration_g = normalAcceleration_g;
maneuver.maxNormalAcceleration_g = maxNormalAcceleration_g;
maneuver.maxNormalAccelerationTime_s = results.t(idxMaxNormalAcceleration);
maneuver.idxMaxNormalAcceleration = idxMaxNormalAcceleration;
maneuver.targetNormalLoad_g = targetNormalLoad_g;
maneuver.meetsTargetNormalLoad = meetsTargetNormalLoad;
maneuver.CLRequiredForTarget = CLRequiredForTarget;
maneuver.CLAvailable = CLAvailable;
maneuver.CLMarginForTarget = CLMarginForTarget;
maneuver.idxMaxQ = idxMaxQ;
maneuver.normalAccelerationAtMaxQ_g = normalAcceleration_g(idxMaxQ);
maneuver.CLRequiredAtMaxQ = CLRequiredForTarget(idxMaxQ);
maneuver.representativeAltitude_m = representativeAltitude_m;
maneuver.idxRepresentativeAltitude = idxRepresentativeAltitude;
maneuver.normalAccelerationAtRepresentativeAltitude_g = ...
    normalAcceleration_g(idxRepresentativeAltitude);

end

function value = getVehicleField(vehicle, fieldName, defaultValue)
if isfield(vehicle, fieldName) && ~isempty(vehicle.(fieldName))
    value = vehicle.(fieldName);
else
    value = defaultValue;
end
end

function value = getConfigField(config, fieldName, defaultValue)
if isfield(config, fieldName) && ~isempty(config.(fieldName))
    value = config.(fieldName);
else
    value = defaultValue;
end
end

function value = getConstantField(constants, fieldName, defaultValue)
if isfield(constants, fieldName) && ~isempty(constants.(fieldName))
    value = constants.(fieldName);
else
    value = defaultValue;
end
end
