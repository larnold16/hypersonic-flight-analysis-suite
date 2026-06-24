function stability = stabilityModel_stage11(vehicle)
% stabilityModel_stage11
% Computes first-order static and damping stability data.
%
% Sign convention:
%   CG and CP are measured aft from the nose. Positive static margin means
%   CP is behind CG, which produces restoring aerodynamic moments in this
%   simplified model. Very small margins are unstable/weakly stable; very
%   large margins can make the vehicle stiff and high-load.

length = max(getField(vehicle, 'length', 0.45), eps);
cg = getField(vehicle, 'cgLocation_m', 0.48 * length);
cp = getField(vehicle, 'cpLocation_m', 0.58 * length);
staticMargin = (cp - cg) / length;

stability.staticMargin = staticMargin;
stability.isStable = staticMargin >= 0.05;
stability.isOverstable = staticMargin > 0.25;
stability.warning = '';
if staticMargin < 0
    stability.warning = 'CP is ahead of CG; static instability for this convention.';
elseif staticMargin < 0.05
    stability.warning = 'Static margin is low; stability may be weak.';
elseif staticMargin > 0.25
    stability.warning = 'Static margin is high; response may be stiff with high loads.';
end

finFactor = 1 + 0.35 * double(getField(vehicle, 'hasFins', false));
stability.pitchDamping = 0.25 * finFactor * max(staticMargin, 0.02);
stability.yawDamping = 0.22 * finFactor * max(staticMargin, 0.02);
stability.rollDamping = 0.06 * finFactor;
stability.CmAlpha = -max(staticMargin, -0.2) * getField(vehicle, 'CLalpha', 1.15);
stability.CnBeta = -max(staticMargin, -0.2) * abs(getField(vehicle, 'CYbeta', -0.55));
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
