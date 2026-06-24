function [t, state] = runStage3(vehicle, constants)
% runStage3
% Runs the Stage 3 trajectory model.
%
% Stage 3 assumptions:
% - 2D trajectory
% - Variable gravity with altitude
% - Layered atmosphere model
% - Mach-dependent drag
% - Angle-of-attack-based lift
% - Vehicle geometry included through reference area and fineness ratio

% Initial conditions
V0 = vehicle.V0;
theta0 = deg2rad(vehicle.launchAngle);

x0  = 0;
h0  = 0;
vx0 = V0 * cos(theta0);
vh0 = V0 * sin(theta0);

state0 = [x0; h0; vx0; vh0];

% Time span
tspan = [0 500];

% ODE solver options
options = odeset( ...
    'RelTol', 1e-8, ...
    'AbsTol', 1e-10, ...
    'Events', @groundEvent);

% Run simulation
[t, state] = ode45(@(t, state) projectileODE_level3(t, state, vehicle, constants), ...
                   tspan, state0, options);

end