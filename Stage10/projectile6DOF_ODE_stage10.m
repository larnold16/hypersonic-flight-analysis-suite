function dstate = projectile6DOF_ODE_stage10(t, state, vehicle, constants)
% projectile6DOF_ODE_stage10
% Simplified flat-Earth rigid-body 6-DOF equations.
%
% State = [x; y; z; u; v; w; phi; theta; psi; p; q; r]
% Position is inertial/downrange-lateral-altitude. Velocity is body-axis.

u = state(4);
v = state(5);
w = state(6);
phi = state(7);
theta = state(8);
psi = state(9);
p = state(10);
q = state(11);
r = state(12);

R_bi = bodyToInertialDCM(phi, theta, psi);
R_ib = R_bi.';

aero = computeAeroForcesMoments_stage10(t, state, vehicle, constants);
g0 = getConstantField(constants, 'g0', 9.80665);

gravityInertial = [0; 0; -g0];
gravityBody = R_ib * gravityInertial;

omegaBody = [p; q; r];
velocityBody = [u; v; w];
forceBody = aero.forceBody_N;

velocityDotBody = forceBody ./ vehicle.mass + gravityBody - cross(omegaBody, velocityBody);
positionDotInertial = R_bi * velocityBody;

eulerRates = eulerRates321(phi, theta, omegaBody);

Ix = vehicle.Ix;
Iy = vehicle.Iy;
Iz = vehicle.Iz;
momentBody = aero.momentBody_Nm;

pDot = (momentBody(1) - (Iz - Iy) * q * r) / Ix;
qDot = (momentBody(2) - (Ix - Iz) * p * r) / Iy;
rDot = (momentBody(3) - (Iy - Ix) * p * q) / Iz;

dstate = [positionDotInertial; velocityDotBody; eulerRates; pDot; qDot; rDot];

end

function R_bi = bodyToInertialDCM(phi, theta, psi)
cphi = cos(phi); sphi = sin(phi);
cth = cos(theta); sth = sin(theta);
cpsi = cos(psi); spsi = sin(psi);

% Local frame uses z positive upward, so positive pitch points the body x
% axis upward. This is Rz(psi)*Ry(-theta)*Rx(phi).
R_bi = [cth*cpsi, -sphi*sth*cpsi - cphi*spsi, -cphi*sth*cpsi + sphi*spsi; ...
        cth*spsi, -sphi*sth*spsi + cphi*cpsi, -cphi*sth*spsi - sphi*cpsi; ...
        sth,       sphi*cth,                    cphi*cth];
end

function eulerDot = eulerRates321(phi, theta, omegaBody)
p = omegaBody(1);
q = omegaBody(2);
r = omegaBody(3);

cth = cos(theta);
if abs(cth) < 1e-6
    cth = sign(cth + eps) * 1e-6;
end

tanTheta = sin(theta) / cth;

phiDot = p - tanTheta * (q*sin(phi) + r*cos(phi));
thetaDot = -q*cos(phi) + r*sin(phi);
psiDot = (q*sin(phi) + r*cos(phi)) / cth;

eulerDot = [phiDot; thetaDot; psiDot];
end

function value = getConstantField(constants, fieldName, defaultValue)
if isfield(constants, fieldName) && ~isempty(constants.(fieldName))
    value = constants.(fieldName);
else
    value = defaultValue;
end
end
