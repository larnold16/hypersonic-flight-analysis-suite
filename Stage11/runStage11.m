function results = runStage11(vehicle, constants, stage11Config)
% runStage11
% Entry point for Stage 11: Hypersonic Trajectory Analysis Suite.
%
% Stage 11 is intentionally self-contained. Earlier stages are not modified
% and can still be run from main.m. The default configuration runs a single
% 3-DOF demo case immediately, while optional menu modes provide sweeps,
% body comparisons, and export/report generation.

if nargin < 3
    stage11Config = struct();
end

config = buildStage11Config(vehicle, constants, stage11Config);

if ~isfield(config, 'mode') || isempty(config.mode)
    if config.interactive
        config.mode = stage11Menu();
    else
        config.mode = 1;
    end
end

config.mode = round(config.mode);

switch config.mode
    case 1
        if config.verbose
            fprintf('Stage 11: running single trajectory demo (%s).\n', config.dofMode);
        end
        results = runSingleTrajectory(config.vehicle, constants, config);

    case 2
        if config.verbose
            fprintf('Stage 11: running launch-angle sweep.\n');
        end
        results = runAngleSweep(config.vehicle, constants, config);

    case 3
        if config.verbose
            fprintf('Stage 11: running vehicle body comparison.\n');
        end
        results = runBodyComparison(config.vehicle, constants, config);

    case 4
        if config.verbose
            fprintf('Stage 11: running full body/angle comparison.\n');
        end
        results = runFullComparison(config.vehicle, constants, config);

    case 5
        if config.verbose
            fprintf('Stage 11: exporting last default single-trajectory demo.\n');
        end
        results = runSingleTrajectory(config.vehicle, constants, config);
        config.exportResults = true;
        config.generateReport = true;

    otherwise
        warning('Stage11:InvalidMode', ...
            'Invalid Stage 11 mode. Running the default single trajectory.');
        config.mode = 1;
        results = runSingleTrajectory(config.vehicle, constants, config);
end

results.stage = 11;
results.config = config;

if config.showPlots
    plotStage11Dashboard(results, config);
end

if config.exportResults
    exportStage11Results(results, config);
end

if config.generateReport
    generateStage11Report(results, config);
end

if config.verbose
    printStage11Summary(results);
end

end

function printStage11Summary(results)
fprintf('\nStage 11 Summary:\n');

if isfield(results, 'summaryTable')
    disp(results.summaryTable);
elseif isfield(results, 'range')
    fprintf('  Range: %.2f km\n', results.range / 1000);
    fprintf('  Maximum altitude: %.2f km\n', results.maxAltitude / 1000);
    fprintf('  Impact speed: %.2f m/s\n', results.impactSpeed);
    fprintf('  Maximum Mach: %.2f\n', results.maxMach);
    fprintf('  Maximum dynamic pressure: %.2f kPa\n', results.maxQ / 1000);
    fprintf('  Maximum heating rate: %.2f kW/m^2\n', results.maxHeatingRate / 1000);
    fprintf('  Maximum g-load: %.2f g\n', results.maxGLoad);
    fprintf('  Impact detected: %s\n', yesNo(results.impactDetected));
end

if isfield(results, 'warnings') && ~isempty(results.warnings)
    fprintf('  Warning flags:\n');
    for k = 1:numel(results.warnings)
        fprintf('    - %s\n', results.warnings{k});
    end
else
    fprintf('  Warning flags: none\n');
end

fprintf('\n');
end

function text = yesNo(value)
if value
    text = 'yes';
else
    text = 'no';
end
end
