function thermal = computeThermalLoads_stage7(results, vehicle, constants, stage7Config)
% computeThermalLoads_stage7
% Estimates simplified stagnation-point convective heat flux and heat load.
%
% The heat-flux relation is an approximate Sutton-Graves-style engineering
% estimate:
%
%   q_dot = k * sqrt(rho / R_n) * V^3
%
% where rho is atmospheric density, R_n is nose radius, and V is
% atmosphere-relative speed. The coefficient below is representative for
% Earth-entry order-of-magnitude trade studies only. This is not a CFD or
% flight-qualified aero-heating model.

if nargin < 4
    stage7Config = struct();
end

t = results.t(:);
V = results.V(:);
h = results.h(:);
Mach = results.Mach(:);
qDynamic = results.q(:);

rho = getDensity(results, h, constants);
stagnationTemp = getStagnationTemperature(results, V, Mach, h, constants);
noseRadius_m = getNoseRadius(vehicle);

if isfield(stage7Config, 'heatingCoefficient')
    heatingCoefficient = stage7Config.heatingCoefficient;
else
    heatingCoefficient = 1.83e-4;
end

heatFlux_W_m2 = heatingCoefficient .* sqrt(max(rho, 0) ./ noseRadius_m) .* max(V, 0).^3;
heatFlux_kW_m2 = heatFlux_W_m2 / 1000;
cumulativeHeatLoad_J_m2 = cumulativeTrapzLocal(t, heatFlux_W_m2);
totalHeatLoad_J_m2 = cumulativeHeatLoad_J_m2(end);

[peakHeatFlux_W_m2, idxPeakHeatFlux] = max(heatFlux_W_m2);
[peakStagnationTemp_K, idxPeakStagTemp] = max(stagnationTemp);

thermal.heatFlux_W_m2 = heatFlux_W_m2;
thermal.heatFlux_kW_m2 = heatFlux_kW_m2;
thermal.cumulativeHeatLoad_J_m2 = cumulativeHeatLoad_J_m2;
thermal.cumulativeHeatLoad_MJ_m2 = cumulativeHeatLoad_J_m2 / 1e6;
thermal.totalHeatLoad_J_m2 = totalHeatLoad_J_m2;
thermal.totalHeatLoad_MJ_m2 = totalHeatLoad_J_m2 / 1e6;
thermal.peakHeatFlux_W_m2 = peakHeatFlux_W_m2;
thermal.peakHeatFluxTime_s = t(idxPeakHeatFlux);
thermal.peakStagnationTemp_K = peakStagnationTemp_K;
thermal.peakStagnationTempTime_s = t(idxPeakStagTemp);
thermal.stagnationTemp_K = stagnationTemp;
thermal.rho = rho;
thermal.noseRadius_m = noseRadius_m;
thermal.heatingCoefficient = heatingCoefficient;

thermal.wallTemp_K = estimateWallTemperature(t, heatFlux_W_m2, stagnationTemp, vehicle);
thermal.maxWallTemp_K = max(thermal.wallTemp_K);

thermal.inputTime_s = t;
thermal.inputVelocity_m_s = V;
thermal.inputAltitude_m = h;
thermal.inputMach = Mach;
thermal.inputDynamicPressure_Pa = qDynamic;

end

function rho = getDensity(results, h, constants)
if isfield(results, 'rho')
    rho = results.rho(:);
else
    [~, rho, ~, ~] = standardAtmosphere_stage4(max(h, 0), constants);
    rho = rho(:);
end
end

function stagnationTemp = getStagnationTemperature(results, V, Mach, h, constants)
if isfield(results, 'Tstag')
    stagnationTemp = results.Tstag(:);
elseif isfield(results, 'stagTemp')
    stagnationTemp = results.stagTemp(:);
else
    [T, ~, ~, a] = standardAtmosphere_stage4(max(h, 0), constants);
    MachFromSpeed = zeros(size(V));
    validSoundSpeed = a(:) > 0;
    MachFromSpeed(validSoundSpeed) = V(validSoundSpeed) ./ a(validSoundSpeed);
    if any(Mach > 0)
        MachUse = Mach;
    else
        MachUse = MachFromSpeed;
    end
    stagnationTemp = T(:) .* (1 + ((constants.gamma - 1) / 2) .* MachUse.^2);
end
end

function noseRadius_m = getNoseRadius(vehicle)
if isfield(vehicle, 'noseRadius_m') && vehicle.noseRadius_m > 0
    noseRadius_m = vehicle.noseRadius_m;
elseif isfield(vehicle, 'diameter') && vehicle.diameter > 0
    noseRadius_m = vehicle.diameter / 2;
else
    noseRadius_m = 0.025;
end
end

function wallTemp_K = estimateWallTemperature(t, heatFlux_W_m2, stagnationTemp, vehicle)
initialWallTemp_K = getVehicleField(vehicle, 'initialWallTemp_K', 288.15);
wallArealMass_kg_m2 = getVehicleField(vehicle, 'wallArealMass_kg_m2', 8.0);
materialCp_J_kgK = getVehicleField(vehicle, 'materialCp_J_kgK', 900);
emissivity = getVehicleField(vehicle, 'emissivity', 0.0);

thermalMass_J_m2K = max(wallArealMass_kg_m2 * materialCp_J_kgK, eps);
sigma = 5.670374419e-8;
ambientRadiationTemp_K = 288.15;

wallTemp_K = zeros(size(t));
wallTemp_K(1) = initialWallTemp_K;

for k = 2:numel(t)
    dt = max(t(k) - t(k-1), 0);
    qIn = max(heatFlux_W_m2(k-1), 0);
    qRad = emissivity * sigma * max(wallTemp_K(k-1)^4 - ambientRadiationTemp_K^4, 0);
    dT = (qIn - qRad) * dt / thermalMass_J_m2K;
    wallTemp_K(k) = wallTemp_K(k-1) + dT;

    if wallTemp_K(k) > stagnationTemp(k)
        wallTemp_K(k) = stagnationTemp(k);
    end
end
end

function value = getVehicleField(vehicle, fieldName, defaultValue)
if isfield(vehicle, fieldName) && ~isempty(vehicle.(fieldName))
    value = vehicle.(fieldName);
else
    value = defaultValue;
end
end

function yInt = cumulativeTrapzLocal(x, y)
yInt = zeros(size(y));
for k = 2:numel(y)
    dx = x(k) - x(k-1);
    yInt(k) = yInt(k-1) + 0.5 * (y(k) + y(k-1)) * dx;
end
end
