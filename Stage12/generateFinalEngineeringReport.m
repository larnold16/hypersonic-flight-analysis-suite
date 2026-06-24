function reportFile = generateFinalEngineeringReport(vehicle, constants, validation, regression, config)
% generateFinalEngineeringReport
% Writes the Stage 12 final engineering report.

if nargin < 3 || isempty(validation)
    validation = runValidationCases(vehicle, constants, config);
end
if nargin < 4 || isempty(regression)
    regression = runRegressionTests(vehicle, constants, config);
end

reportFile = fullfile(config.outputRoot, 'FinalEngineeringReport.txt');
fid = fopen(reportFile, 'w');
if fid < 0
    warning('Stage12:ReportOpenFailed', 'Could not open final engineering report.');
    return;
end
cleanup = onCleanup(@() fclose(fid));

stage11Cfg = buildStage11Config(vehicle, constants, struct( ...
    'showPlots', false, 'exportResults', false, 'generateReport', false, ...
    'verbose', false, 'interactive', false, 'figureVisible', 'off', ...
    'outputRoot', fullfile(config.outputRoot, 'ReportStage11')));
traj = runSingleTrajectory(vehicle, constants, stage11Cfg);

fprintf(fid, 'Final Engineering Report: Hypersonic Trajectory Calculator\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now));
fprintf(fid, 'Default Vehicle\n');
fprintf(fid, '  Mass: %.3f kg\n', getField(vehicle, 'mass', NaN));
fprintf(fid, '  Length: %.4f m\n', getField(vehicle, 'length', NaN));
fprintf(fid, '  Diameter: %.4f m\n', getField(vehicle, 'diameter', NaN));
fprintf(fid, '  Initial speed: %.2f m/s\n', getField(vehicle, 'V0', NaN));
fprintf(fid, '  Launch angle: %.2f deg\n\n', getField(vehicle, 'launchAngle', NaN));

fprintf(fid, 'Model Descriptions\n');
fprintf(fid, '  Atmosphere: layered 1976-style approximation from Shared/atmosphere1976_simple.m.\n');
fprintf(fid, '  Aerodynamics: Mach interpolation, transonic rise, body scaling, induced drag, alpha/beta forces.\n');
fprintf(fid, '  Heating: Sutton-Graves-style stagnation heating trend for relative trade studies.\n');
fprintf(fid, '  Stability: CP-CG static margin with simplified pitch/yaw/roll damping.\n\n');

fprintf(fid, 'Validation Results\n%s\n', evalc('disp(validation.summaryTable)'));
fprintf(fid, 'Regression Test Results\n%s\n', evalc('disp(regression.summaryTable)'));

fprintf(fid, 'Key Stage 11 Trajectory Results\n');
fprintf(fid, '  Range: %.2f km\n', traj.range / 1000);
fprintf(fid, '  Max altitude: %.2f km\n', traj.maxAltitude / 1000);
fprintf(fid, '  Impact speed: %.2f m/s\n', traj.impactSpeed);
fprintf(fid, '  Max Mach: %.2f\n', traj.maxMach);
fprintf(fid, '  Max q: %.2f kPa\n', traj.maxQ / 1000);
fprintf(fid, '  Max heating: %.2f kW/m^2\n', traj.maxHeatingRate / 1000);
fprintf(fid, '  Max g-load: %.2f g\n\n', traj.maxGLoad);

fprintf(fid, 'Warning Flags\n');
if isempty(traj.warnings)
    fprintf(fid, '  None\n');
else
    for k = 1:numel(traj.warnings)
        fprintf(fid, '  - %s\n', traj.warnings{k});
    end
end

fprintf(fid, '\nLimitations and Next Improvements\n');
fprintf(fid, '  This is an educational model. It needs validated aero databases, wind-tunnel/flight comparisons,\n');
fprintf(fid, '  higher-fidelity atmosphere and heating models, uncertainty calibration, and control-system dynamics\n');
fprintf(fid, '  before any real engineering design use.\n');
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
