function aero = aeroModel_stage11(Mach, alpha, beta, vehicle, atmosphere)
% aeroModel_stage11
% Educational Mach/angle-dependent aerodynamic model.
%
% Inputs:
%   Mach       flight Mach number [-]
%   alpha      angle of attack [rad]
%   beta       sideslip angle [rad]
%   vehicle    completed Stage 11 vehicle struct
%   atmosphere local atmosphere struct, included for future extensions
%
% Outputs are coefficients, not forces. The model includes transonic drag
% rise, body-type drag scaling, alpha lift, induced drag, side force, and
% first-order static-stability moments.

if nargin < 5
    atmosphere = struct(); %#ok<NASGU>
end

Mach = max(Mach, 0);
alpha = max(min(alpha, deg2rad(20)), deg2rad(-20));
beta = max(min(beta, deg2rad(20)), deg2rad(-20));

Mtab = getField(vehicle, 'MachTable', getField(vehicle, 'M_table', [0.1 0.8 1.0 1.2 2 5 8 12]));
Cdtab = getField(vehicle, 'CdTable', getField(vehicle, 'Cd_table', [0.25 0.30 0.60 0.50 0.38 0.32 0.30 0.30]));

CD0 = interp1(Mtab, Cdtab, min(Mach, max(Mtab)), 'pchip', 'extrap');
transonicRise = 0.08 * exp(-((Mach - 1.05) / 0.22)^2);
hypersonicTrim = 0.015 * max(Mach - 5, 0) / 5;
noseScale = noseDragScale(getField(vehicle, 'noseType', 'custom'));
CD0 = max(0.05, (CD0 + transonicRise + hypersonicTrim) * noseScale);

CLalpha = getField(vehicle, 'CLalpha', 1.15) * getField(vehicle, 'CL_scale', 1.0) * ...
    getField(vehicle, 'liftUncertaintyFactor', 1.0);
CL = CLalpha * alpha;
CL = max(-getField(vehicle, 'CL_max', 0.8), min(getField(vehicle, 'CL_max', 0.8), CL));

CYbeta = getField(vehicle, 'CYbeta', -0.55);
CY = CYbeta * beta;

induced = getField(vehicle, 'k_induced', 0.08) * (CL^2 + CY^2);
CD = (CD0 + induced) * getField(vehicle, 'Cd_scale', 1.0) * ...
    getField(vehicle, 'dragUncertaintyFactor', 1.0);

staticMargin = (getField(vehicle, 'cpLocation_m', 0.58 * vehicle.length) - ...
    getField(vehicle, 'cgLocation_m', 0.48 * vehicle.length)) / max(vehicle.length, eps);

% Positive static margin produces restoring pitch/yaw moments for the sign
% convention used in Stage 11.
CmAlpha = -max(staticMargin, -0.2) * max(CLalpha, 0.1);
CnBeta = -max(staticMargin, -0.2) * max(abs(CYbeta), 0.1);
Cm = CmAlpha * alpha;
Cn = CnBeta * beta;
Cl = -0.04 * beta;

aero.CD = max(CD, 0.02);
aero.CL = CL;
aero.CY = CY;
aero.Cm = Cm;
aero.Cn = Cn;
aero.Cl = Cl;
aero.LD = CL / max(aero.CD, eps);
aero.CD0 = CD0;
aero.CLalpha = CLalpha;
aero.CYbeta = CYbeta;
end

function scale = noseDragScale(noseType)
name = lower(char(noseType));
if contains(name, 'blunt')
    scale = 1.15;
elseif contains(name, 'ogive')
    scale = 0.95;
elseif contains(name, 'cone') || contains(name, 'sharp')
    scale = 0.92;
else
    scale = 1.0;
end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
