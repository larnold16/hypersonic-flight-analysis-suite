function results = postProcess_stage3(t, state, vehicle, constants)
% postProcess_stage3
% Computes trajectory outputs and Stage 3 aero/thermal diagnostics.

% Extract states
x  = state(:,1);
h  = state(:,2);
vx = state(:,3);
vh = state(:,4);

% Prevent tiny negative altitudes after event detection
h = max(h, 0);

% Velocity
V = sqrt(vx.^2 + vh.^2);

% Allocate arrays
n = length(t);

Mach     = zeros(n,1);
q        = zeros(n,1);
stagTemp = zeros(n,1);
Cd       = zeros(n,1);
CL       = zeros(n,1);
LD       = zeros(n,1);
rho      = zeros(n,1);
temp     = zeros(n,1);
pressure = zeros(n,1);
speedSound = zeros(n,1);
gravity  = zeros(n,1);
drag     = zeros(n,1);
lift     = zeros(n,1);
beta     = zeros(n,1);

% Loop through trajectory
for i = 1:n

    hi = max(h(i), 0);
    Vi = V(i);

    % Atmosphere
    [Ti, Pi, rhoi, ai] = atmosphere_stage3(hi, constants);

    temp(i) = Ti;
    pressure(i) = Pi;
    rho(i) = rhoi;
    speedSound(i) = ai;

    % Gravity
    gravity(i) = gravity_stage3(hi, constants);

    % Mach number
    if Vi < 1e-8
        Mach(i) = 0;
    else
        Mach(i) = Vi / ai;
    end

    % Aero
    aero = aeroCoefficients_stage3(Mach(i), vehicle);

    Cd(i) = aero.Cd;
    CL(i) = aero.CL;
    beta(i) = vehicle.mass / (Cd(i) * vehicle.area);

    % Dynamic pressure
    q(i) = 0.5 * rhoi * Vi^2;

    % Forces
    drag(i) = q(i) * vehicle.area * Cd(i);
    lift(i) = q(i) * vehicle.area * CL(i);

    % Lift-to-drag ratio
    if drag(i) > 1e-8
        LD(i) = lift(i) / drag(i);
    else
        LD(i) = 0;
    end

    % Stagnation temperature
    stagTemp(i) = Ti * (1 + ((constants.gamma - 1) / 2) * Mach(i)^2);

end

% Main trajectory results
results.t = t;
results.state = state;

results.x = x;
results.h = h;
results.vx = vx;
results.vh = vh;
results.V = V;

results.range = max(x);
results.maxAltitude = max(h);
results.impactSpeed = V(end);

% Stage 2/3 environment results
results.Mach = Mach;
results.q = q;
results.stagTemp = stagTemp;
results.rho = rho;
results.temp = temp;
results.pressure = pressure;
results.speedSound = speedSound;
results.gravity = gravity;

results.maxMach = max(Mach);
results.maxQ = max(q);
results.maxStagTemp = max(stagTemp);

% Stage 3 aero results
results.Cd = Cd;
results.CL = CL;
results.LD = LD;
results.drag = drag;
results.lift = lift;
results.beta = beta;

results.maxCd = max(Cd);
results.maxCL = max(CL);
results.maxLD = max(LD);
results.maxDrag = max(drag);
results.maxLift = max(lift);

Cd_average = trapz(t, Cd) / max(t(end) - t(1), eps);

results.beta_initial = beta(1);
results.beta_average = vehicle.mass / (Cd_average * vehicle.area);
results.beta_min = min(beta);

end
