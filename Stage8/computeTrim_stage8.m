function trim = computeTrim_stage8(stability, vehicle, stage8Config)
% computeTrim_stage8
% Estimates trim behavior using a simplified linear pitching-moment model.
%
% Cm(alpha, Mach) = Cm0 + Cm_alpha(Mach) * alpha
%
% Cm_alpha is either supplied by the vehicle or estimated from static margin
% and lift-curve slope. This is a trim screening method only; real trim
% requires aerodynamic moment data, control authority, and 6-DOF validation.

if nargin < 3
    stage8Config = struct();
end

machGrid = getConfigField(stage8Config, 'trimMachGrid', 5:0.25:8);
alphaGrid_deg = getConfigField(stage8Config, 'trimAlphaGrid_deg', -5:0.25:10);
maxAllowableAlpha_deg = getVehicleField(vehicle, 'maxAllowableAlpha_deg', 10);
Cm0 = getVehicleField(vehicle, 'trimMomentCoefficient', 0.01);

CLalpha = estimateCLalpha(machGrid, vehicle);

if isfield(vehicle, 'pitchMomentSlope_per_rad') && ...
        ~isempty(vehicle.pitchMomentSlope_per_rad)
    CmAlpha = vehicle.pitchMomentSlope_per_rad .* ones(size(machGrid));
    CmAlphaSource = 'vehicle.pitchMomentSlope_per_rad';
else
    CmAlpha = -stability.staticMargin .* CLalpha;
    CmAlphaSource = 'estimated from static margin and CL_alpha';
end

trimAlpha_rad = nan(size(machGrid));
validSlope = abs(CmAlpha) > eps;
trimAlpha_rad(validSlope) = -Cm0 ./ CmAlpha(validSlope);
trimAlpha_deg = rad2deg(trimAlpha_rad);

trimFeasibleByMach = abs(trimAlpha_deg) <= maxAllowableAlpha_deg;
trimFeasible = any(trimFeasibleByMach);

nominalTrimMach = machGrid(round(numel(machGrid) / 2));
[~, nominalIdx] = min(abs(machGrid - nominalTrimMach));
nominalTrimAlpha_deg = trimAlpha_deg(nominalIdx);

alphaGrid_rad = deg2rad(alphaGrid_deg);
CmGrid = zeros(numel(alphaGrid_deg), numel(machGrid));
for k = 1:numel(machGrid)
    CmGrid(:,k) = Cm0 + CmAlpha(k) .* alphaGrid_rad(:);
end

trim.machGrid = machGrid(:);
trim.alphaGrid_deg = alphaGrid_deg(:);
trim.CmGrid = CmGrid;
trim.Cm0 = Cm0;
trim.CmAlpha_per_rad = CmAlpha(:);
trim.CmAlphaSource = CmAlphaSource;
trim.CLalpha_per_rad = CLalpha(:);
trim.trimAlpha_deg = trimAlpha_deg(:);
trim.trimFeasibleByMach = trimFeasibleByMach(:);
trim.trimFeasible = trimFeasible;
trim.nominalTrimMach = nominalTrimMach;
trim.nominalTrimAlpha_deg = nominalTrimAlpha_deg;
trim.maxAllowableAlpha_deg = maxAllowableAlpha_deg;

end

function CLalpha = estimateCLalpha(machGrid, vehicle)
if isfield(vehicle, 'M_CLalpha_table') && isfield(vehicle, 'CLalpha_table')
    CLalpha = interp1(vehicle.M_CLalpha_table, vehicle.CLalpha_table, ...
        machGrid, 'linear', 'extrap');
else
    CLalpha = 1.0 .* ones(size(machGrid));
end

if isfield(vehicle, 'CL_scale') && ~isempty(vehicle.CL_scale)
    CLalpha = CLalpha .* vehicle.CL_scale;
end
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
