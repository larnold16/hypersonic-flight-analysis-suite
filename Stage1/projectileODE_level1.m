function dstate = projectileODE_level1(~, state, vehicle, constants)

% Unpack state variables
x  = state(1); 
h  = state(2);
vx = state(3);
vh = state(4);

% Total velocity magnitude
V_sq = vx^2 + vh^2;
V = sqrt(V_sq);

% Prevent density from increasing below ground level
h = max(h, 0);

% Simple exponential atmosphere
rho = constants.rho0 * exp(-h/constants.H);

% Drag magnitude
D = 0.5 * rho * V_sq * vehicle.Cd * vehicle.area;

% Drag components oppose velocity direction
if V > 1e-6
    Dx = D * (vx / V);
    Dh = D * (vh / V);
else
    Dx = 0;
    Dh = 0;
end

% Equations of motion
dxdt  = vx;
dhdt  = vh;
dvxdt = -Dx / vehicle.mass;
dvhdt = -constants.g - Dh / vehicle.mass;

% Return derivatives
dstate = [dxdt; dhdt; dvxdt; dvhdt];

end