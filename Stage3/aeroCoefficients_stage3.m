function aero = aeroCoefficients_stage3(Mach, vehicle)
% aeroCoefficients_stage3
% Computes Stage 3 aerodynamic coefficients.
%
% Includes:
% - Mach-dependent zero-lift drag
% - Geometry correction from fineness ratio
% - Angle-of-attack-based lift
% - Induced drag from lift

% Keep Mach nonnegative
M = max(Mach, 0);

%% Drag coefficient interpolation

M_drag_table = vehicle.M_table_stage3;
Cd0_table = vehicle.Cd0_table_stage3;

% Clamp Mach to table range
M_drag = min(max(M, min(M_drag_table)), max(M_drag_table));

Cd0 = interp1(M_drag_table, Cd0_table, M_drag, 'linear');

%% Geometry correction

% Fineness ratio correction
% This is a simplified correction, not a CFD-level model.
fineness = vehicle.fineness;

finenessFactor = 1 + 0.02 * (fineness - 8);

% Limit correction to reasonable bounds
finenessFactor = max(0.90, min(1.15, finenessFactor));

%% Lift coefficient interpolation

M_lift_table = vehicle.M_CLalpha_table;
CLalpha_table = vehicle.CLalpha_table;

% Clamp Mach to table range
M_lift = min(max(M, min(M_lift_table)), max(M_lift_table));

CLalpha = interp1(M_lift_table, CLalpha_table, M_lift, 'linear');

% Convert angle of attack to radians
alpha_rad = deg2rad(vehicle.alpha_deg);

% Lift coefficient
CL = vehicle.CL_scale * CLalpha * alpha_rad;

% Limit CL to avoid unrealistic values
CL = max(-vehicle.CL_max, min(vehicle.CL_max, CL));

%% Final drag coefficient

% Add induced drag from lift
Cd = vehicle.Cd_scale * Cd0 * finenessFactor + vehicle.k_induced * CL^2;

%% Output structure

aero.Cd = Cd;
aero.Cd0 = Cd0;
aero.CL = CL;
aero.CLalpha = CLalpha;
aero.alpha_rad = alpha_rad;
aero.finenessFactor = finenessFactor;

end