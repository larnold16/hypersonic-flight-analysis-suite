function [t, state] = runStage1(vehicle, constants)
% runStage1
% Runs the Stage 1 baseline trajectory model.

%% Initial Conditions

x0 = 0;
h0 = 0;

vx0 = vehicle.V0 * cosd(vehicle.launchAngle);
vh0 = vehicle.V0 * sind(vehicle.launchAngle);

state0 = [x0; h0; vx0; vh0];

%% Time Span

tspan = [0 300];

%% ODE Solver Options

options = odeset('Events', @groundEvent, ...
                 'RelTol', 1e-6, ...
                 'AbsTol', 1e-8);

%% Solve Equations of Motion

[t, state] = ode45(@(t, state) projectileODE_level1(t, state, vehicle, constants), ...
                   tspan, state0, options);

end