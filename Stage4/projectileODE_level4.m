function dstate = projectileODE_level4(t, state, vehicle, constants)
% projectileODE_level4
% 3D point-mass trajectory model in an inertial frame.
%
% Includes:
% - Central gravity
% - Rotating atmosphere
% - Drag relative to the atmosphere
% - Simple lift model
% - Spherical Earth

r = state(1:3);
v = state(4:6);

rMagSq = dot(r, r);
rMag = sqrt(rMagSq);
h = rMag - constants.Re;

% Prevent atmosphere model from seeing negative altitude.
hAtm = max(h, 0);

% Atmosphere is assumed to rotate with Earth.
omega = constants.omegaEarth;
vAtm = [-omega*r(2); omega*r(1); 0];
vAtm = vAtm + environmentWind_stage4(t, constants);

% Velocity relative to atmosphere.
vRel = v - vAtm;
VSq = dot(vRel, vRel);
V = sqrt(VSq);

% Atmospheric properties.
[T, rho, ~, a] = standardAtmosphere_stage4(hAtm, constants);

if a > 0
    Mach = V / a;
else
    Mach = 0;
end

% Aero coefficients.
[Cd, CL] = aeroCoefficients_stage4(Mach, vehicle);

% Dynamic pressure.
qbar = 0.5 * rho * VSq;

% Aero forces.
D = qbar * Cd * vehicle.referenceArea;
L = qbar * CL * vehicle.referenceArea;

if V > 1e-8
    vHat = vRel / V;

    % Drag opposes relative velocity.
    dragForce = -D * vHat;

    % Lift points mostly away from Earth and perpendicular to velocity.
    upHat = r / rMag;
    liftDir = upHat - dot(upHat, vHat)*vHat;

    liftDirMagSq = dot(liftDir, liftDir);
    if liftDirMagSq > 1e-16
        liftDir = liftDir / sqrt(liftDirMagSq);
        liftForce = L * liftDir;
    else
        liftForce = [0; 0; 0];
    end
else
    dragForce = [0; 0; 0];
    liftForce = [0; 0; 0];
end

% Gravity.
gravityAccel = -(constants.mu / (rMagSq*rMag)) * r;

% Total acceleration.
aeroAccel = (dragForce + liftForce) / vehicle.mass;
accel = gravityAccel + aeroAccel;

dstate = [v; accel];

end
