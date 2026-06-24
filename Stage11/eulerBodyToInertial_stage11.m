function Cbi = eulerBodyToInertial_stage11(phi, theta, psi)
% eulerBodyToInertial_stage11
% Body-to-inertial rotation for the Stage 11 educational 6-DOF model.
%
% State convention:
%   state = [x; y; h; u; v; w; phi; theta; psi; p; q; r]
%
% Inertial axes:
%   x = downrange, y = crossrange, h = altitude, positive upward.
%
% Body axes:
%   u = body-forward velocity, v = body-lateral velocity, w = body-up
%   velocity. At zero attitude, body x/y/z align with inertial x/y/h.
%
% Positive theta is nose-up. Therefore:
%   eulerBodyToInertial_stage11(0, deg2rad(25), 0) * [V; 0; 0]
% gives positive downrange velocity and positive altitude rate.

cphi = cos(phi); sphi = sin(phi);
cth = cos(theta); sth = sin(theta);
cpsi = cos(psi); spsi = sin(psi);

Rx = [1 0 0; 0 cphi -sphi; 0 sphi cphi];
RyNoseUp = [cth 0 -sth; 0 1 0; sth 0 cth];
Rz = [cpsi -spsi 0; spsi cpsi 0; 0 0 1];

Cbi = Rz * RyNoseUp * Rx;
end
