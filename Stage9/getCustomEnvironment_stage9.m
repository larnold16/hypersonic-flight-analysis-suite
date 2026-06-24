function environment = getCustomEnvironment_stage9(defaultEnvironment)
% getCustomEnvironment_stage9
% Prompts for a simplified custom launch environment.

if nargin < 1 || isempty(defaultEnvironment)
    presets = getEnvironmentPresets_stage9();
    defaultEnvironment = presets(1);
end

fprintf('\nEnter custom environment values. Press Enter to use the default.\n');

environment = defaultEnvironment;
environment.name = promptWithDefault('Environment name', 'Custom environment');
environment.temperatureOffset_K = promptWithDefault( ...
    'Temperature offset [K]', defaultEnvironment.temperatureOffset_K);
environment.temperatureMultiplier = promptWithDefault( ...
    'Temperature multiplier [-]', defaultEnvironment.temperatureMultiplier);
environment.densityMultiplier = promptWithDefault( ...
    'Density multiplier [-]', defaultEnvironment.densityMultiplier);
environment.pressureMultiplier = promptWithDefault( ...
    'Pressure multiplier [-]', defaultEnvironment.pressureMultiplier);
environment.launchAltitudeOffset_m = promptWithDefault( ...
    'Launch altitude offset [m]', defaultEnvironment.launchAltitudeOffset_m);

windEast = promptWithDefault('Wind east component [m/s]', defaultEnvironment.windENU_mps(1));
windNorth = promptWithDefault('Wind north component [m/s]', defaultEnvironment.windENU_mps(2));
windUp = promptWithDefault('Wind up component [m/s]', defaultEnvironment.windENU_mps(3));
environment.windENU_mps = [windEast; windNorth; windUp];
environment.windSpeed_mps = norm(environment.windENU_mps);
environment.notes = 'User-entered simplified environment. Not real weather data.';

end
