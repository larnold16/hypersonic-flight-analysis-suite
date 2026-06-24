function heat = heatingModel_stage11(rho, V, vehicle, constants, Mach, staticTemperature)
% heatingModel_stage11
% Simple engineering stagnation heating estimate for Stage 11.
%
% The convective heating model follows the Sutton-Graves trend:
%   q_dot ~ k * sqrt(rho / R_n) * V^3
% This is useful for relative comparisons and portfolio demonstrations. It is
% not CFD, not a real TPS sizing method, and not valid for final design.

if nargin < 6
    staticTemperature = 288.15;
end
if nargin < 5
    Mach = 0;
end

gamma = getField(constants, 'gamma', 1.4);
noseRadius = max(getField(vehicle, 'noseRadius_m', getField(vehicle, 'diameter', 0.05) / 2), 1e-4);

k = 1.83e-4; % SI Sutton-Graves-style constant for air trend estimates.
heatRate = k * sqrt(max(rho, 0) / noseRadius) * max(V, 0)^3;

heat.stagnationTemperature_K = staticTemperature * (1 + ((gamma - 1) / 2) * Mach^2);
heat.heatRate_W_m2 = max(heatRate, 0);
heat.noseRadius_m = noseRadius;
heat.modelNote = 'Approximate stagnation heating trend; not CFD or TPS qualification.';
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
