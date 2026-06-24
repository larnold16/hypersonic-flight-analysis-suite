function [T, rho, P, a] = atmosphere_stage2(h, constants)
% atmosphere_stage2
% Simple layered standard atmosphere model.
%
% Outputs:
% T   = temperature [K]
% rho = density [kg/m^3]
% P   = pressure [Pa]
% a   = speed of sound [m/s]

%% Constants
R = constants.R;
gamma = constants.gamma;
g0 = constants.g0;

%% Sea-Level Conditions
T0 = constants.T0;     % K
P0 = constants.P0;     % Pa

%% Layer Boundary Conditions (fixed values, computed once)
T11 = T0 + (-0.0065) * 11000;          % 216.65 K
P11 = P0 * (T11/T0)^(-g0/(-0.0065*R));
T20 = T11;                              % isothermal 11-20 km
P20 = P11 * exp(-g0 * 9000 / (R*T20));

%% Troposphere: 0 to 11 km
if h <= 11000
    L = -0.0065;
    T = T0 + L*h;
    P = P0 * (T/T0)^(-g0/(L*R));

elseif h <= 20000
    T = T11;
    P = P11 * exp(-g0*(h - 11000)/(R*T11));

else
    % Simplified: isothermal above 20 km
    T = T20;
    P = P20 * exp(-g0*(h - 20000)/(R*T20));
end

%% Density and Speed of Sound
rho = P / (R*T);
a = sqrt(gamma * R * T);

end