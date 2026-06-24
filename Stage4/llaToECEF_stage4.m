function rECEF = llaToECEF_stage4(lat, lon, h, Re)
% llaToECEF_stage4
% Converts spherical latitude, longitude, altitude to ECEF position.

r = Re + h;

x = r * cos(lat) * cos(lon);
y = r * cos(lat) * sin(lon);
z = r * sin(lat);

rECEF = [x; y; z];

end