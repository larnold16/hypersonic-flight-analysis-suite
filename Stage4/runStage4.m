function [t, state] = runStage4(vehicle, constants)
% runStage4
% Runs Stage 4 trajectory model.
%
% Stage 4 additions:
% - Spherical Earth
% - Earth rotation
% - ECI/ECEF coordinate handling
% - Higher-altitude standard atmosphere
% - Gravity varies with distance from Earth's center
%
% State vector:
% state = [rx; ry; rz; vx; vy; vz]
%
% Position and velocity are in an Earth-centered inertial frame.

lat0 = constants.launchLat;
lon0 = constants.launchLon;
h0 = constants.launchAlt + 1e-3;   % small offset to avoid event at t = 0

% Initial position in ECEF.
r0_ecef = llaToECEF_stage4(lat0, lon0, h0, constants.Re);

% At t = 0, define ECI and ECEF as aligned.
r0_eci = r0_ecef;

% Local launch basis vectors.
[eastHat, northHat, upHat] = localENU_stage4(lat0, lon0);

% Launch direction.
az = vehicle.launchAzimuth;
el = vehicle.launchAngle;

horizontalDir = cos(az)*northHat + sin(az)*eastHat;
vRel0 = vehicle.V0*cos(el)*horizontalDir + vehicle.V0*sin(el)*upHat;

% Add Earth's rotational velocity at launch site.
omegaVec = [0; 0; constants.omegaEarth];
vEarth0 = cross(omegaVec, r0_eci);

v0_eci = vEarth0 + vRel0;

state0 = [r0_eci; v0_eci];

tspan = [0 1000];

options = odeset( ...
    'Events', @(t, state) groundEvent_stage4(t, state, constants), ...
    'RelTol', 1e-8, ...
    'AbsTol', 1e-10, ...
    'MaxStep', 0.2);

[t, state] = ode45(@(t, state) projectileODE_level4(t, state, vehicle, constants), ...
    tspan, state0, options);

end