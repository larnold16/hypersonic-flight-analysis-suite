function wind = windModel_stage11(~, altitude_m, config)
% windModel_stage11
% Returns a simple inertial wind vector [downrange; crossrange; vertical].
%
% Direction is measured in the x-y plane from downrange toward crossrange.
% A mild altitude decay keeps high-altitude winds from dominating the demo.

if nargin < 3 || ~isfield(config, 'environment')
    wind = [0; 0; 0];
    return;
end

speed = getField(config.environment, 'windSpeed_mps', 0);
direction = deg2rad(getField(config.environment, 'windDirection_deg', 0));
vertical = getField(config.environment, 'verticalWind_mps', 0);
shear = exp(-max(altitude_m, 0) / 12000);

wind = shear * [speed * cos(direction); speed * sin(direction); vertical];
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
