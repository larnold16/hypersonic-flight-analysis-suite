function windECI = environmentWind_stage4(t, constants)
% environmentWind_stage4
% Optional constant launch-site wind vector for Stage 9 sensitivity studies.
%
% The wind is specified in local ENU coordinates at the launch site using
% constants.environment.windENU_mps = [east; north; up]. It is converted
% from Earth-fixed coordinates into ECI at time t. If no environment wind is
% supplied, this returns zero and preserves the baseline Stage 4 behavior.

windECI = [0; 0; 0];

if ~isfield(constants, 'environment')
    return;
end

environment = constants.environment;

if ~isfield(environment, 'windENU_mps') || isempty(environment.windENU_mps)
    return;
end

windENU = environment.windENU_mps(:);

if numel(windENU) ~= 3
    return;
end

[eastHat, northHat, upHat] = localENU_stage4(constants.launchLat, constants.launchLon);
windECEF = windENU(1).*eastHat + windENU(2).*northHat + windENU(3).*upHat;

theta = constants.omegaEarth .* t;
cosTheta = cos(theta);
sinTheta = sin(theta);

% ECEF to ECI rotation for the same convention used in postProcess_stage4.
windECI = [cosTheta.*windECEF(1) - sinTheta.*windECEF(2); ...
           sinTheta.*windECEF(1) + cosTheta.*windECEF(2); ...
           windECEF(3)];

end
