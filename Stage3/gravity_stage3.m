function g = gravity_stage3(h, constants)
% gravity_stage3
% Computes gravitational acceleration as a function of altitude.

h = max(h, 0);

g = constants.g0 * (constants.Re / (constants.Re + h))^2;

end