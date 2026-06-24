function [eastHat, northHat, upHat] = localENU_stage4(lat, lon)
% localENU_stage4
% Returns local East, North, Up unit vectors in ECEF coordinates.

eastHat = [-sin(lon); cos(lon); 0];

northHat = [-sin(lat)*cos(lon);
    -sin(lat)*sin(lon);
    cos(lat)];

upHat = [cos(lat)*cos(lon);
    cos(lat)*sin(lon);
    sin(lat)];

end