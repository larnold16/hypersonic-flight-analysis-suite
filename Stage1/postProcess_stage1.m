function results = postProcess_stage1(t, state, vehicle, constants)
% postProcess_stage1
% Computes key trajectory outputs for Stage 1.

% Unpack state variables
x  = state(:,1);   % downrange position [m]
h  = state(:,2);   % altitude [m]
vx = state(:,3);   % horizontal velocity [m/s]
vh = state(:,4);   % vertical velocity [m/s]

% Speed magnitude
V = sqrt(vx.^2 + vh.^2);

% Store full simulation history
results.t = t;
results.state = state;

results.x = x;
results.h = h;
results.vx = vx;
results.vh = vh;
results.V = V;

% Store key results
results.range = x(end);
results.maxAltitude = max(h);
results.impactSpeed = V(end);

end