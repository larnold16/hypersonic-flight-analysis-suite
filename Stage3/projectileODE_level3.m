function dstate = projectileODE_level3(~, state, vehicle, constants)
% projectileODE_level3
% Equations of motion for Stage 3.
%
% State vector:
% state(1) = x  = downrange distance [m]
% state(2) = h  = altitude [m]
% state(3) = vx = horizontal velocity [m/s]
% state(4) = vh = vertical velocity [m/s]

% Unpack state
x  = state(1);
h  = state(2);
vx = state(3);
vh = state(4);

% Prevent atmosphere and gravity from using negative altitude
h_atm = max(h, 0);

% Velocity magnitude
V = sqrt(vx^2 + vh^2);

% Gravity at altitude
g = gravity_stage3(h_atm, constants);

% If velocity is essentially zero, only gravity acts
if V < 1e-8
    dstate = [0; 0; 0; -g];
    return;
end

% Atmosphere
[T, ~, rho, a] = atmosphere_stage3(h_atm, constants);

% Mach number
Mach = V / a;

% Aero coefficients
aero = aeroCoefficients_stage3(Mach, vehicle);

Cd = aero.Cd;
CL = aero.CL;

% Dynamic pressure
q = 0.5 * rho * V^2;

% Aerodynamic forces
D = q * vehicle.area * Cd;
L = q * vehicle.area * CL;

% Unit vector along velocity
ux = vx / V;
uh = vh / V;

% Unit vector normal to velocity
% Positive CL gives lift generally upward for positive horizontal velocity
nx = -uh;
nh = ux;

% Drag force components
Fx_drag = -D * ux;
Fh_drag = -D * uh;

% Lift force components
Fx_lift = L * nx;
Fh_lift = L * nh;

% Total force components
Fx = Fx_drag + Fx_lift;
Fh = Fh_drag + Fh_lift;

% Equations of motion
dxdt  = vx;
dhdt  = vh;
dvxdt = Fx / vehicle.mass;
dvhdt = (Fh / vehicle.mass) - g;

% Return derivative vector
dstate = [dxdt; dhdt; dvxdt; dvhdt];

end