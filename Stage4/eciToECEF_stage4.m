function rECEF = eciToECEF_stage4(t, rECI, constants)
% eciToECEF_stage4
% Converts ECI vector to ECEF vector using simple Earth rotation.

theta = constants.omegaEarth * t;

R = [ cos(theta),  sin(theta), 0;
    -sin(theta),  cos(theta), 0;
    0,           0,         1];

rECEF = R * rECI;

end