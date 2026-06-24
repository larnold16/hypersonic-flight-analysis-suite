function aero = computeAeroForcesMoments_stage10(~, state, vehicle, constants)
% computeAeroForcesMoments_stage10
% Simplified body-axis aerodynamic force and moment model.
%
% High-fidelity 6-DOF simulation requires aerodynamic derivative tables,
% CFD/wind-tunnel moment data, control-surface models, and validation.

z = max(state(3), 0);
u = state(4);
v = state(5);
w = state(6);
p = state(10);
q = state(11);
r = state(12);

velocityBody = [u; v; w];
V = norm(velocityBody);

[~, rho, ~, a] = standardAtmosphere_stage4(z, constants);

if a > 0
    Mach = V / a;
else
    Mach = 0;
end

if V > 1e-8
    alpha = atan2(w, max(u, 1e-8));
    beta = asin(max(min(v / V, 1), -1));
else
    alpha = 0;
    beta = 0;
end

Cd = getDragCoefficient(Mach, vehicle);
CLalpha = getLiftCurveSlope(Mach, vehicle);
CL = clamp(CLalpha * alpha, -vehicle.maxForceCoefficient, vehicle.maxForceCoefficient);
CY = clamp(vehicle.CYbeta_per_rad * beta, -vehicle.maxForceCoefficient, vehicle.maxForceCoefficient);

qbar = 0.5 * rho * V^2;
S = vehicle.referenceArea;
Lref = vehicle.referenceMomentLength_m;

drag_N = qbar * S * Cd;
lift_N = qbar * S * CL;
side_N = qbar * S * CY;

% Body z is positive upward in this prototype, so positive lift is +z body.
forceBody_N = [-drag_N; side_N; lift_N];

staticMargin = vehicle.staticMargin;
CmAlpha = -vehicle.Cm_alpha_scale * staticMargin * CLalpha;
CnBeta = vehicle.Cn_beta_scale * staticMargin * max(abs(vehicle.CYbeta_per_rad), 0.05);

rateScale = max(V, 1.0);
pHat = p * Lref / (2 * rateScale);
qHat = q * Lref / (2 * rateScale);
rHat = r * Lref / (2 * rateScale);

Cl = vehicle.Clp_per_rad * pHat;
Cm = CmAlpha * alpha + vehicle.Cmq_per_rad * qHat;
Cn = -CnBeta * beta + vehicle.Cnr_per_rad * rHat;

Cl = clamp(Cl, -vehicle.maxMomentCoefficient, vehicle.maxMomentCoefficient);
Cm = clamp(Cm, -vehicle.maxMomentCoefficient, vehicle.maxMomentCoefficient);
Cn = clamp(Cn, -vehicle.maxMomentCoefficient, vehicle.maxMomentCoefficient);

momentBody_Nm = qbar * S * Lref .* [Cl; Cm; Cn];

aero.forceBody_N = forceBody_N;
aero.momentBody_Nm = momentBody_Nm;
aero.V = V;
aero.Mach = Mach;
aero.alpha_rad = alpha;
aero.beta_rad = beta;
aero.qbar = qbar;
aero.Cd = Cd;
aero.CL = CL;
aero.CY = CY;
aero.Cl = Cl;
aero.Cm = Cm;
aero.Cn = Cn;
aero.lift_N = lift_N;
aero.drag_N = drag_N;
aero.side_N = side_N;
end

function Cd = getDragCoefficient(Mach, vehicle)
if isfield(vehicle, 'M_table') && isfield(vehicle, 'Cd_table')
    Cd = interp1(vehicle.M_table, vehicle.Cd_table, Mach, 'linear', 'extrap');
else
    Cd = 0.35;
end

Cd = max(Cd, 0.05);
end

function CLalpha = getLiftCurveSlope(Mach, vehicle)
if isfield(vehicle, 'M_CLalpha_table') && isfield(vehicle, 'CLalpha_table')
    CLalpha = interp1(vehicle.M_CLalpha_table, vehicle.CLalpha_table, ...
        Mach, 'linear', 'extrap');
else
    fineness = getField(vehicle, 'finenessRatio', 8);
    CLalpha = 2.0 + 3.0 / (fineness + 1.0);
end

if isfield(vehicle, 'CL_scale') && ~isempty(vehicle.CL_scale)
    CLalpha = CLalpha * vehicle.CL_scale;
end
end

function value = getField(inputStruct, fieldName, defaultValue)
if isfield(inputStruct, fieldName) && ~isempty(inputStruct.(fieldName))
    value = inputStruct.(fieldName);
else
    value = defaultValue;
end
end

function y = clamp(x, lowerLimit, upperLimit)
y = min(max(x, lowerLimit), upperLimit);
end
