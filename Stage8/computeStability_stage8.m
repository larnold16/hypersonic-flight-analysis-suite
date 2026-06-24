function stability = computeStability_stage8(results, vehicle, constants, stage8Config)
% computeStability_stage8
% Estimates first-order longitudinal static stability from CG and CP.
%
% Sign convention:
% - x is measured aft from the vehicle nose.
% - staticMargin = (CP - CG) / length.
% - Positive static margin means CP is aft of CG and is treated as stable
%   for this conventional projectile/body approximation.
%
% This is a simplified trade-study estimate. It does not replace CFD,
% wind-tunnel testing, aerodynamic moment derivatives, or 6-DOF dynamics.

if nargin < 4
    stage8Config = struct();
end

length_m = getVehicleField(vehicle, 'length', 1.0);
diameter_m = getVehicleField(vehicle, 'diameter', 0.05);

cgLocation_m = getVehicleField(vehicle, 'cgLocation_m', 0.50 * length_m);
cpLocation_m = getVehicleField(vehicle, 'cpLocation_m', estimateCP(vehicle));
referenceMomentLength_m = getVehicleField(vehicle, 'referenceMomentLength_m', diameter_m);

staticMargin = (cpLocation_m - cgLocation_m) / max(length_m, eps);
staticMargin_percentLength = 100 * staticMargin;

neutralTolerance = getConfigField(stage8Config, 'neutralStaticMarginTolerance', 0.01);

if staticMargin > neutralTolerance
    classification = 'stable';
    isStable = true;
elseif abs(staticMargin) <= neutralTolerance
    classification = 'neutral';
    isStable = false;
else
    classification = 'unstable';
    isStable = false;
end

stability.cgLocation_m = cgLocation_m;
stability.cpLocation_m = cpLocation_m;
stability.referenceMomentLength_m = referenceMomentLength_m;
stability.staticMargin = staticMargin;
stability.staticMargin_percentLength = staticMargin_percentLength;
stability.isStable = isStable;
stability.classification = classification;
stability.neutralStaticMarginTolerance = neutralTolerance;
stability.mach = results.Mach(:);
stability.staticMargin_vsMach = staticMargin .* ones(size(results.Mach(:)));
stability.length_m = length_m;
stability.diameter_m = diameter_m;
stability.assumptionText = ...
    'Simplified CG/CP static margin estimate; positive margin means CP aft of CG.';
stability.constants = constants;

end

function cpLocation_m = estimateCP(vehicle)
length_m = getVehicleField(vehicle, 'length', 1.0);
finenessRatio = getVehicleField(vehicle, 'finenessRatio', length_m / getVehicleField(vehicle, 'diameter', 0.05));

% Slender bodies tend to have CP aft of mid-body; this rough placement is
% intentionally conservative and should be replaced by measured aero data.
if finenessRatio >= 7
    cpFraction = 0.60;
elseif finenessRatio >= 4
    cpFraction = 0.57;
else
    cpFraction = 0.55;
end

cpLocation_m = cpFraction * length_m;
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
