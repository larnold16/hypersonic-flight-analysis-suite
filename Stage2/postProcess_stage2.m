function results = postProcess_stage2(t, state, vehicle, constants)
% postProcess_stage2
% Extracts and calculates Stage 2 trajectory outputs.

%% Extract State Variables
x  = state(:,1);
h  = state(:,2);
vx = state(:,3);
vh = state(:,4);

%% Velocity Magnitude
V = sqrt(vx.^2 + vh.^2);

%% Preallocate Arrays
rho  = zeros(size(t));
T    = zeros(size(t));
P    = zeros(size(t));
a    = zeros(size(t));
Mach = zeros(size(t));
q    = zeros(size(t));
g    = zeros(size(t));

%% Compute Atmosphere and Flight Quantities
h_safe = max(h, 0);
for i = 1:length(t)
    [T(i), rho(i), P(i), a(i)] = atmosphere_stage2(h_safe(i), constants);
end
Mach = V ./ a;
q    = 0.5 .* rho .* V.^2;
g    = constants.g0 .* (constants.Re ./ (constants.Re + h_safe)).^2;

% Stagnation temperature [K]
T_stag = T .* (1 + (constants.gamma - 1)/2 .* Mach.^2);

%% Store Results
results.t = t;
results.state = state;

results.x = x;
results.h = h;
results.vx = vx;
results.vh = vh;
results.V = V;

results.T = T;
results.rho = rho;
results.P = P;
results.a = a;
results.Mach = Mach;
results.q = q;
results.g = g;

results.range = max(x);
results.maxAltitude = max(h);
results.impactSpeed = V(end);
results.maxMach = max(Mach);
results.maxQ = max(q);

results.T_stag    = T_stag;
results.maxStagTemp = max(T_stag);

end