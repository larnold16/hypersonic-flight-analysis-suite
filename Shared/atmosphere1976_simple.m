function [T, P, rho, a, mu] = atmosphere1976_simple(h)
% atmosphere1976_simple
% Robust low-complexity 1976-style atmosphere approximation.
%
% Returns:
%   T   static temperature [K]
%   P   static pressure [Pa]
%   rho density [kg/m^3]
%   a   speed of sound [m/s]
%   mu  dynamic viscosity [Pa-s]
%
% The model uses a tropospheric lapse rate to 11 km, an isothermal lower
% stratosphere to 20 km, and a mild positive lapse above that. It is intended
% for trajectory education and validation sanity checks, not certification.

h = max(h, 0);
T = zeros(size(h));
P = zeros(size(h));

g0 = 9.80665;
R = 287.05;
gamma = 1.4;
T0 = 288.15;
P0 = 101325;
L1 = -0.0065;

h11 = 11000;
T11 = T0 + L1 * h11;
P11 = P0 * (T11 / T0)^(-g0 / (L1 * R));

h20 = 20000;
P20 = P11 * exp(-g0 * (h20 - h11) / (R * T11));
L3 = 0.0010;

idx1 = h <= h11;
idx2 = h > h11 & h <= h20;
idx3 = h > h20;

T(idx1) = T0 + L1 .* h(idx1);
P(idx1) = P0 .* (T(idx1) ./ T0).^(-g0 / (L1 * R));

T(idx2) = T11;
P(idx2) = P11 .* exp(-g0 .* (h(idx2) - h11) ./ (R * T11));

T(idx3) = T11 + L3 .* (h(idx3) - h20);
T(idx3) = min(T(idx3), 320);
P(idx3) = P20 .* (T(idx3) ./ T11).^(-g0 / (L3 * R));

rho = P ./ (R .* max(T, 1));
a = sqrt(gamma * R .* max(T, 1));

% Sutherland viscosity estimate.
S = 110.4;
mu0 = 1.716e-5;
Tref = 273.15;
mu = mu0 .* (T ./ Tref).^(3/2) .* (Tref + S) ./ (T + S);

rho = max(rho, 0);
P = max(P, 0);
mu = max(mu, 1e-8);
end
