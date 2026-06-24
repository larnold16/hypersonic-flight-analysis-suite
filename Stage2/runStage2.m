function [t, state] = runStage2(vehicle, constants)
% runStage2
% Runs the Stage 2 trajectory model.
%
% Stage 2 additions:
% - Variable gravity
% - Layered atmosphere
% - Mach-dependent drag handled inside projectileODE_level2

%% Initial State
theta0 = deg2rad(vehicle.launchAngle);

x0  = 0;
h0  = 0;
vx0 = vehicle.V0 * cos(theta0);
vh0 = vehicle.V0 * sin(theta0);

state0 = [x0; h0; vx0; vh0];

%% Time Span
tspan = [0 300];

%% ODE Options
options = odeset( ...
    'RelTol', 1e-8, ...
    'AbsTol', 1e-9, ...
    'Events', @groundEvent_stage2);

%% Solve ODE
[t, state] = ode45(@(t, state) projectileODE_level2(t, state, vehicle, constants), ...
                   tspan, state0, options);

end


%% Ground Event Function
function [value, isterminal, direction] = groundEvent_stage2(~, state)

h = state(2);

value = h;          % Detect altitude = 0
isterminal = 1;     % Stop integration
direction = -1;     % Only stop when coming downward

end