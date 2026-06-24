function reportFile = generateStage11Report(results, config)
% generateStage11Report
% Writes a plain-text engineering report for Stage 11.

if nargin < 2
    config = results.config;
end

if ~exist(config.reportDir, 'dir')
    mkdir(config.reportDir);
end

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
reportFile = fullfile(config.reportDir, ['Stage11EngineeringReport_', timestamp, '.txt']);
fid = fopen(reportFile, 'w');
if fid < 0
    warning('Stage11:ReportOpenFailed', 'Could not open Stage 11 report for writing.');
    return;
end

cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'Stage 11 Engineering Report\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now));
fprintf(fid, 'Mode: %s\n', describeMode(results));
fprintf(fid, 'DOF mode: %s\n\n', getField(results, 'dofMode', config.dofMode));

vehicle = getField(results, 'vehicle', config.vehicle);
fprintf(fid, 'Vehicle Parameters\n');
fprintf(fid, '  Body type: %s\n', getField(vehicle, 'bodyType', 'custom'));
fprintf(fid, '  Mass: %.3f kg\n', getField(vehicle, 'mass', NaN));
fprintf(fid, '  Length: %.4f m\n', getField(vehicle, 'length', NaN));
fprintf(fid, '  Diameter: %.4f m\n', getField(vehicle, 'diameter', NaN));
fprintf(fid, '  Reference area: %.6f m^2\n', getField(vehicle, 'referenceArea', NaN));
fprintf(fid, '  Nose type: %s\n', getField(vehicle, 'noseType', 'custom'));
fprintf(fid, '  CG location: %.4f m\n', getField(vehicle, 'cgLocation_m', NaN));
fprintf(fid, '  CP location: %.4f m\n', getField(vehicle, 'cpLocation_m', NaN));
fprintf(fid, '  Static margin: %.2f %% body length\n\n', 100 * getField(vehicle, 'staticMargin', NaN));

fprintf(fid, 'Initial Conditions\n');
fprintf(fid, '  Launch speed: %.2f m/s\n', config.launchSpeed_mps);
fprintf(fid, '  Launch angle: %.2f deg\n', config.launchAngle_deg);
fprintf(fid, '  Launch yaw: %.2f deg\n', config.launchYaw_deg);
fprintf(fid, '  Initial altitude: %.2f m\n\n', config.initialAltitude_m);

fprintf(fid, 'Assumptions\n');
for k = 1:numel(config.assumptions)
    fprintf(fid, '  - %s\n', config.assumptions{k});
end
fprintf(fid, '\n');

if isfield(results, 'summaryTable')
    fprintf(fid, 'Comparison Summary\n');
    fprintf(fid, '  Cases run: %d\n', height(results.summaryTable));
    if isfield(results, 'recommendedCase')
        fprintf(fid, '  Recommended case based on simple score:\n');
        fprintf(fid, '%s\n', evalc('disp(results.recommendedCase)'));
    else
        fprintf(fid, '%s\n', evalc('disp(results.summaryTable)'));
    end
else
    fprintf(fid, 'Key Results\n');
    fprintf(fid, '  Range: %.2f km\n', results.range / 1000);
    fprintf(fid, '  Max altitude: %.2f km\n', results.maxAltitude / 1000);
    fprintf(fid, '  Time of flight: %.2f s\n', results.timeOfFlight);
    fprintf(fid, '  Impact speed: %.2f m/s\n', results.impactSpeed);
    fprintf(fid, '  Max Mach: %.2f\n', results.maxMach);
    fprintf(fid, '  Max q: %.2f kPa\n', results.maxQ / 1000);
    fprintf(fid, '  Max stagnation temperature: %.2f K\n', results.maxStagTemp);
    fprintf(fid, '  Max heating rate: %.2f kW/m^2\n', results.maxHeatingRate / 1000);
    fprintf(fid, '  Total heat load: %.2f MJ/m^2\n', results.totalHeatLoad / 1e6);
    fprintf(fid, '  Max g-load: %.2f g\n\n', results.maxGLoad);

    fprintf(fid, 'Peak Event Times\n');
    printPeak(fid, 'Max Mach', results.t, results.Mach);
    printPeak(fid, 'Max q', results.t, results.q);
    printPeak(fid, 'Max heating', results.t, results.heatingRate);
    printPeak(fid, 'Max altitude', results.t, results.h);
    fprintf(fid, '\n');
end

fprintf(fid, 'Warnings\n');
if isfield(results, 'warnings') && ~isempty(results.warnings)
    for k = 1:numel(results.warnings)
        fprintf(fid, '  - %s\n', results.warnings{k});
    end
else
    fprintf(fid, '  None\n');
end

fprintf(fid, '\nLimitations\n');
fprintf(fid, '  - Educational trade-study model only.\n');
fprintf(fid, '  - Aerodynamics are empirical approximations, not CFD or wind-tunnel data.\n');
fprintf(fid, '  - Heating is a stagnation trend estimate, not TPS qualification.\n');
fprintf(fid, '  - Simplified 6-DOF mode omits control systems, detailed derivative tables, and flexible-body effects.\n');
end

function printPeak(fid, label, t, values)
[peak, idx] = max(values);
fprintf(fid, '  %s: %.3g at t = %.2f s\n', label, peak, t(idx));
end

function text = describeMode(results)
if isfield(results, 'mode')
    text = results.mode;
else
    text = 'SingleTrajectory';
end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
