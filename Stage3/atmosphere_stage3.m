function [T, P, rho, a] = atmosphere_stage3(h, constants)
% atmosphere_stage3
% Layered standard-atmosphere-style model.
%
% Layers:
% 0-11 km: temperature decreases
% 11-20 km: approximately isothermal
% 20-32 km: temperature increases
% 32-47 km: temperature increases faster
% above 47 km: simple isothermal extension

% Prevent negative altitude
h = max(h, 0);

% Constants
g = constants.g0;
R = constants.R;
gamma = constants.gamma;

% Sea-level conditions
h0 = 0;
T0 = constants.T0;
P0 = constants.P0;

% Layer 1: 0 to 11 km
h1 = 11000;
L0 = -0.0065;

T1 = T0 + L0 * (h1 - h0);
P1 = P0 * (T1 / T0)^(-g / (L0 * R));

% Layer 2: 11 to 20 km, isothermal
h2 = 20000;

T2 = T1;
P2 = P1 * exp(-g * (h2 - h1) / (R * T1));

% Layer 3: 20 to 32 km, warming
h3 = 32000;
L2 = 0.0010;

T3 = T2 + L2 * (h3 - h2);
P3 = P2 * (T3 / T2)^(-g / (L2 * R));

% Layer 4: 32 to 47 km, stronger warming
h4 = 47000;
L3 = 0.0028;

T4 = T3 + L3 * (h4 - h3);
P4 = P3 * (T4 / T3)^(-g / (L3 * R));

% Select atmospheric layer
if h <= h1

    % 0-11 km
    T = T0 + L0 * (h - h0);
    P = P0 * (T / T0)^(-g / (L0 * R));

elseif h <= h2

    % 11-20 km
    T = T1;
    P = P1 * exp(-g * (h - h1) / (R * T1));

elseif h <= h3

    % 20-32 km
    T = T2 + L2 * (h - h2);
    P = P2 * (T / T2)^(-g / (L2 * R));

elseif h <= h4

    % 32-47 km
    T = T3 + L3 * (h - h3);
    P = P3 * (T / T3)^(-g / (L3 * R));

else

    % Above 47 km: simple isothermal extension
    T = T4;
    P = P4 * exp(-g * (h - h4) / (R * T4));

end

% Density and speed of sound
rho = P / (R * T);
a = sqrt(gamma * R * T);

end