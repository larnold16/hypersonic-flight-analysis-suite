function [T, rho, P, a] = standardAtmosphere_stage4(h, constants)
% standardAtmosphere_stage4
% Simplified 1976 Standard Atmosphere up to about 85 km.
%
% Includes:
% - Troposphere
% - Tropopause
% - Lower stratosphere
% - Higher-altitude temperature changes

h = max(h, 0);

Re = constants.Re;
R = constants.R;
gamma = constants.gamma;
g0 = constants.g0;

% Convert geometric altitude to geopotential altitude.
H = Re.*h ./ (Re + h);

% Base layer data are persistent because this function is called many times
% by the ODE solver and postprocessor.
persistent Hb Tb Pb Lb
if isempty(Hb)
    % Base geopotential altitudes [m]
    Hb = [0; 11000; 20000; 32000; 47000; 51000; 71000; 84852];

    % Base temperatures [K]
    Tb = [288.15; 216.65; 216.65; 228.65; 270.65; 270.65; 214.65; 186.946];

    % Base pressures [Pa]
    Pb = [101325; 22632.06; 5474.889; 868.0187; 110.9063; 66.93887; 3.95642; 0.3734];

    % Temperature lapse rates [K/m]
    Lb = [-0.0065; 0.0000; 0.0010; 0.0028; 0.0000; -0.0028; -0.0020; 0.0000];
end

% Clamp to highest modeled layer.
H = min(H, Hb(end) - 1e-6);

idx = ones(size(H));
for k = 2:(length(Hb) - 1)
    idx(H >= Hb(k)) = k;
end

Hbase = Hb(idx);
Tbase = Tb(idx);
Pbase = Pb(idx);
L = Lb(idx);

T = zeros(size(H));
P = zeros(size(H));

isothermal = abs(L) < 1e-12;

if any(isothermal(:))
    T(isothermal) = Tbase(isothermal);
    P(isothermal) = Pbase(isothermal) .* ...
        exp(-g0.*(H(isothermal) - Hbase(isothermal))./(R.*Tbase(isothermal)));
end

gradientLayer = ~isothermal;
if any(gradientLayer(:))
    T(gradientLayer) = Tbase(gradientLayer) + ...
        L(gradientLayer).*(H(gradientLayer) - Hbase(gradientLayer));
    P(gradientLayer) = Pbase(gradientLayer) .* ...
        (Tbase(gradientLayer)./T(gradientLayer)).^(g0./(R.*L(gradientLayer)));
end

rho = P ./ (R.*T);
a = sqrt(gamma.*R.*T);

% Optional Stage 9 launch-environment sensitivity modifiers. These are
% deliberately simple engineering multipliers/offsets and default to no
% change when constants.environment is absent.
if isfield(constants, 'environment')
    environment = constants.environment;

    if isfield(environment, 'temperatureMultiplier') && ...
            ~isempty(environment.temperatureMultiplier)
        T = T .* environment.temperatureMultiplier;
    end

    if isfield(environment, 'temperatureOffset_K') && ...
            ~isempty(environment.temperatureOffset_K)
        T = T + environment.temperatureOffset_K;
    end

    T = max(T, 1.0);

    if isfield(environment, 'pressureMultiplier') && ...
            ~isempty(environment.pressureMultiplier)
        P = P .* environment.pressureMultiplier;
    end

    rho = P ./ (R.*T);

    if isfield(environment, 'densityMultiplier') && ...
            ~isempty(environment.densityMultiplier)
        rho = rho .* environment.densityMultiplier;
    end

    a = sqrt(gamma.*R.*T);
end

end
