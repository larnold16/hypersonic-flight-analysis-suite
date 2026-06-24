function dstate = projectileODE_level2(~, state, vehicle, constants)
% projectileODE_level2
% Stage 2 equations of motion.
%
% Improvements over Level 1:
% - Gravity changes with altitude
% - Density comes from a layered atmosphere model

%% Unpack State
x  = state(1);
h  = state(2);
vx = state(3);
vh = state(4);

%% Prevent Atmosphere From Going Below Ground
h_atm = max(h, 0);

%% Velocity
V_sq = vx^2 + vh^2;
V = sqrt(V_sq);

%% Atmosphere
[~, rho, ~, a] = atmosphere_stage2(h_atm, constants);
Mach = V / a;

%% Mach-dependent Cd
Cd = interp1(vehicle.M_table, vehicle.Cd_table, Mach, 'linear', vehicle.Cd_table(end));

%% Variable Gravity
g = constants.g0 * (constants.Re / (constants.Re + h_atm))^2;

%% Drag
D = 0.5 * rho * V_sq * Cd * vehicle.area;

if V > 1e-6
    Dx = D * (vx / V);
    Dh = D * (vh / V);
else
    Dx = 0;
    Dh = 0;
end

%% Equations of Motion
dxdt  = vx;
dhdt  = vh;
dvxdt = -Dx / vehicle.mass;
dvhdt = -g - Dh / vehicle.mass;

%% Return Derivatives
dstate = [dxdt; dhdt; dvxdt; dvhdt];

end