function dstate = trajectoryODE_6DOF_stage11(t, state, vehicle, constants, config)
% trajectoryODE_6DOF_stage11
% Simplified rigid-body 6-DOF dynamics for Stage 11.
%
% State vector:
%   [x; y; h; u; v; w; phi; theta; psi; p; q; r]
%
% Inertial axes:
%   x = downrange, y = crossrange, h = altitude, positive upward.
%
% Body-axis convention in this educational model:
%   u = body-forward velocity, v = body-lateral velocity, w = body-up
%   velocity. Body velocity is converted to inertial velocity with
%   eulerBodyToInertial_stage11(phi, theta, psi); positive theta is nose-up.
%
% This is not a flight-qualified 6-DOF model. It is a stable teaching model
% with approximate aerodynamic moments, damping, and inertia coupling.

x = state(1); %#ok<NASGU>
y = state(2); %#ok<NASGU>
h = state(3);
uvw = state(4:6);
phi = state(7);
theta = state(8);
psi = state(9);
p = clamp(state(10), -20, 20);
qRate = clamp(state(11), -20, 20);
r = clamp(state(12), -20, 20);

hAtm = max(h, 0);
[T, P, rho, a, mu] = atmosphere1976_simple(hAtm);
if isfield(config, 'environment')
    T = T * config.environment.temperatureMultiplier;
    rho = rho * config.environment.densityMultiplier;
    a = sqrt(1.4 * 287.05 * max(T, 1));
end

V = max(norm(uvw), 1e-8);
alpha = atan2(uvw(3), max(abs(uvw(1)), 1e-8));
beta = asin(max(-1, min(1, uvw(2) / V)));
Mach = V / max(a, 1e-8);
if getConfigFlag(config, 'useThreeDofForceModel', false)
    alpha = deg2rad(getVehicleField(vehicle, 'alpha_deg', 2.0));
    beta = 0;
end

atmosphere.T = T;
atmosphere.P = P;
atmosphere.rho = rho;
atmosphere.a = a;
atmosphere.mu = mu;
aero = aeroModel_stage11(Mach, alpha, beta, vehicle, atmosphere);
stability = stabilityModel_stage11(vehicle);

qbar = 0.5 * rho * V^2;
S = vehicle.referenceArea;
Lref = vehicle.length;
D = qbar * S * aero.CD;
Lift = qbar * S * aero.CL;
Side = qbar * S * aero.CY;
if getConfigFlag(config, 'disableAero', false) || getConfigFlag(config, 'disableDrag', false)
    D = 0;
end
if getConfigFlag(config, 'disableAero', false) || getConfigFlag(config, 'disableLift', false)
    Lift = 0;
    Side = 0;
end

Cbi = eulerBodyToInertial_stage11(phi, theta, psi);
if getConfigFlag(config, 'useThreeDofForceModel', false)
    forceBody = Cbi.' * threeDofEquivalentForce(t, Cbi * uvw, D, Lift, Side, config);
else
    % Resolve approximate aerodynamic forces in the body frame. Drag is
    % opposite body-relative velocity. Lift acts along the body-up axis in
    % this simplified model.
    dragBody = -D * uvw / V;
    liftBody = [-Lift * sin(alpha); 0; Lift * cos(alpha)];
    sideBody = [0; Side; 0];
    forceBody = dragBody + liftBody + sideBody;
end
gravityBody = Cbi.' * [0; 0; -getGravity(hAtm, constants)];
omega = [p; qRate; r];
uvwDot = forceBody / max(vehicle.mass, eps) + gravityBody - cross(omega, uvw);

% Static stability gives restoring pitch/yaw moments. Damping terms keep the
% educational model bounded for broad trade-study inputs.
Cl = aero.Cl - stability.rollDamping * p * Lref / max(2 * V, 1e-8);
Cm = aero.Cm - stability.pitchDamping * qRate * Lref / max(2 * V, 1e-8);
Cn = aero.Cn - stability.yawDamping * r * Lref / max(2 * V, 1e-8);

momentBody = qbar * S * Lref * [Cl; Cm; Cn];
if getConfigFlag(config, 'disableAero', false) || getConfigFlag(config, 'disableMoments', false)
    momentBody = [0; 0; 0];
end
I = [vehicle.Ix; vehicle.Iy; vehicle.Iz];
I = max(I, 1e-6);
pDot = (momentBody(1) - (I(3) - I(2)) * qRate * r) / I(1);
qDot = (momentBody(2) - (I(1) - I(3)) * p * r) / I(2);
rDot = (momentBody(3) - (I(2) - I(1)) * p * qRate) / I(3);

posDot = Cbi * uvw;
eulerDot = eulerRates(phi, theta, [p; qRate; r]);

dstate = [posDot; uvwDot; eulerDot; clamp(pDot, -200, 200); ...
    clamp(qDot, -200, 200); clamp(rDot, -200, 200)];
end

function force = threeDofEquivalentForce(t, inertialVelocity, D, Lift, Side, config)
wind = windModel_stage11(t, 0, config);
vRel = inertialVelocity - wind;
Vrel = norm(vRel);
if Vrel < 1e-8
    force = [0; 0; 0];
    return;
end
u = vRel / Vrel;
horizontalSpeed = max(norm(vRel(1:2)), 1e-8);
dragForce = -D * u;
liftDir = [-u(3) * u(1) / horizontalSpeed; ...
           -u(3) * u(2) / horizontalSpeed; ...
            horizontalSpeed];
liftDir = liftDir / max(norm(liftDir), 1e-8);
sideDir = [-u(2); u(1); 0];
sideDir = sideDir / max(norm(sideDir), 1e-8);
force = dragForce + Lift * liftDir + Side * sideDir;
end

function rates = eulerRates(phi, theta, omega)
theta = clamp(theta, -deg2rad(85), deg2rad(85));
p = omega(1);
q = omega(2);
r = omega(3);
rates = [1, -sin(phi) * tan(theta), -cos(phi) * tan(theta); ...
         0, -cos(phi),              sin(phi); ...
         0, sin(phi) / cos(theta), cos(phi) / cos(theta)] * [p; q; r];
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

function y = clamp(x, lo, hi)
y = min(max(x, lo), hi);
end

function value = getConfigFlag(config, fieldName, defaultValue)
if isstruct(config) && isfield(config, fieldName) && ~isempty(config.(fieldName))
    value = logical(config.(fieldName));
else
    value = defaultValue;
end
end

function value = getVehicleField(vehicle, fieldName, defaultValue)
if isstruct(vehicle) && isfield(vehicle, fieldName) && ~isempty(vehicle.(fieldName))
    value = vehicle.(fieldName);
else
    value = defaultValue;
end
end
