function [lat, lon, h] = ecefToLLA_spherical_stage4(rECEF, Re)
% ecefToLLA_spherical_stage4
% Spherical Earth ECEF to latitude, longitude, altitude.

rMag = norm(rECEF);

lat = asin(rECEF(3) / rMag);
lon = atan2(rECEF(2), rECEF(1));
h = rMag - Re;

end