function dstate = trajectoryODE_3DOF_stage11(t, state, vehicle, constants, config)
% trajectoryODE_3DOF_stage11
% Flat-Earth 3-DOF translational dynamics for Stage 11.
%
% State vector:
%   x  = downrange position [m]
%   y  = crossrange position [m]
%   h  = altitude above ground [m]
%   vx = downrange inertial velocity [m/s]
%   vy = crossrange inertial velocity [m/s]
%   vh = vertical inertial velocity, positive upward [m/s]

h = state(3);
velocity = state(4:6);
hAtm = max(h, 0);

[T, P, rho, a, mu] = atmosphere1976_simple(hAtm);
if isfield(config, 'environment')
    T = T * config.environment.temperatureMultiplier;
    rho = rho * config.environment.densityMultiplier;
    a = sqrt(1.4 * 287.05 * max(T, 1));
end

wind = windModel_stage11(t, hAtm, config);
vRel = velocity - wind;
V = norm(vRel);

g = getGravity(hAtm, constants);

if V < 1e-8
    dstate = [velocity; 0; 0; -g];
    return;
end

alpha = deg2rad(getVehicleField(vehicle, 'alpha_deg', 2.0));
horizontalSpeed = max(norm(vRel(1:2)), 1e-8);
beta = atan2(vRel(2), horizontalSpeed);
Mach = V / max(a, 1e-8);

atmosphere.T = T;
atmosphere.P = P;
atmosphere.rho = rho;
atmosphere.a = a;
atmosphere.mu = mu;
aero = aeroModel_stage11(Mach, alpha, beta, vehicle, atmosphere);

qbar = 0.5 * rho * V^2;
D = qbar * vehicle.referenceArea * aero.CD;
L = qbar * vehicle.referenceArea * aero.CL;
Y = qbar * vehicle.referenceArea * aero.CY;
if getConfigFlag(config, 'disableAero', false) || getConfigFlag(config, 'disableDrag', false)
    D = 0;
end
if getConfigFlag(config, 'disableAero', false) || getConfigFlag(config, 'disableLift', false)
    L = 0;
    Y = 0;
end

u = vRel / V;
dragForce = -D * u;

% Lift is modeled as the component perpendicular to velocity and as close
% to "up" as possible. This is a useful 3-DOF approximation for trajectory
% trade studies, not a substitute for full aerodynamic force resolution.
liftDir = [-u(3) * u(1) / horizontalSpeed; ...
           -u(3) * u(2) / horizontalSpeed; ...
            horizontalSpeed];
liftDir = liftDir / max(norm(liftDir), 1e-8);

sideDir = [-u(2); u(1); 0];
sideDir = sideDir / max(norm(sideDir), 1e-8);

force = dragForce + L * liftDir + Y * sideDir;

% Optional first-order Coriolis term. It is disabled by default to keep the
% flat-Earth educational model easy to interpret.
earthRotationAccel = [0; 0; 0];
if isfield(config, 'enableEarthRotation') && config.enableEarthRotation && isfield(constants, 'omegaEarth')
    omega = [0; constants.omegaEarth * cos(getField(constants, 'launchLat', 0)); ...
        constants.omegaEarth * sin(getField(constants, 'launchLat', 0))];
    earthRotationAccel = -2 * cross(omega, velocity);
end

accel = force / max(vehicle.mass, eps) + [0; 0; -g] + earthRotationAccel;
dstate = [velocity; accel];
end

function g = getGravity(h, constants)
if isfield(constants, 'g0') && isfield(constants, 'Re')
    g = constants.g0 * (constants.Re / (constants.Re + max(h, 0)))^2;
elseif isfield(constants, 'g')
    g = constants.g;
else
    g = 9.80665;
end
end

function value = getVehicleField(vehicle, fieldName, defaultValue)
if isfield(vehicle, fieldName) && ~isempty(vehicle.(fieldName))
    value = vehicle.(fieldName);
else
    value = defaultValue;
end
end

function value = getConfigFlag(config, fieldName, defaultValue)
if isstruct(config) && isfield(config, fieldName) && ~isempty(config.(fieldName))
    value = logical(config.(fieldName));
else
    value = defaultValue;
end
end

function value = getField(s, fieldName, defaultValue)
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    value = s.(fieldName);
else
    value = defaultValue;
end
end
