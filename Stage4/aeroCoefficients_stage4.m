function [Cd, CL] = aeroCoefficients_stage4(Mach, vehicle)
% aeroCoefficients_stage4
% Computes simple Mach-dependent drag and geometry-based lift.
%
% This keeps Stage 4 tied to the Stage 3 vehicle geometry.

M = max(Mach, 0);

% Drag coefficient from table if available.
if isfield(vehicle, 'M_table') && isfield(vehicle, 'Cd_table')
    Cd = interp1(vehicle.M_table, vehicle.Cd_table, M, 'linear', 'extrap');
else
    % Backup drag model.
    Cd = zeros(size(M));

    lowSubsonic = M < 0.8;
    transonic = M >= 0.8 & M < 1.2;
    supersonic = M >= 1.2 & M < 3;
    hypersonic = M >= 3;

    Cd(lowSubsonic) = 0.28 + 0.03.*M(lowSubsonic).^2;
    Cd(transonic) = 0.32 + 0.70.*(M(transonic) - 0.8);
    Cd(supersonic) = 0.60 - 0.15.*(M(supersonic) - 1.2)./(3 - 1.2);
    Cd(hypersonic) = 0.45 - 0.08.*(M(hypersonic) - 3)./(8 - 3);
end

Cd = max(Cd, 0.05);

% Lift coefficient from angle of attack and fineness ratio.
if isfield(vehicle, 'alpha')
    alpha = vehicle.alpha;
else
    alpha = 0;
end

if isfield(vehicle, 'finenessRatio')
    fineness = vehicle.finenessRatio;
else
    fineness = 8;
end

CLalpha = 2.0 + 3.0/(fineness + 1.0);
CL = CLalpha * alpha;

% Keep the simplified model from becoming unrealistic.
CL = max(min(CL, 0.6), -0.6);
CL = CL + zeros(size(M));

end
