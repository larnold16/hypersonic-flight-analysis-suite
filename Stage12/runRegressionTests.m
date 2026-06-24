function regression = runRegressionTests(vehicle, constants, config)
% runRegressionTests
% Runs focused pass/fail tests across Stage 11 and Stage 12 support code.

names = {};
passed = [];
messages = {};

[r, msg] = safeStage11Single(vehicle, constants, config);
addTest('Stage 11 simulation reaches impact', isstruct(r) && isfield(r, 'impactDetected') && r.impactDetected, msg);
addTest('Altitude does not go wildly negative', isstruct(r) && min(r.h) > -1, '');
addTest('Velocity remains finite', isstruct(r) && all(isfinite(r.V)), '');
addTest('Mach remains finite', isstruct(r) && all(isfinite(r.Mach)), '');
addTest('Dynamic pressure remains finite', isstruct(r) && all(isfinite(r.q)), '');

try
    [T, P, rho, a, mu] = atmosphere1976_simple([0; 10000; 50000]);
    addTest('Atmosphere returns valid values', all(isfinite([T; P; rho; a; mu])) && all(rho >= 0), '');
catch ME
    addTest('Atmosphere returns valid values', false, ME.message);
end

try
    v = buildVehicleFromGeometry_stage11(vehicle, 'Custom baseline');
    atm = struct('T', 288.15, 'P', 101325, 'rho', 1.225, 'a', 340.3, 'mu', 1.8e-5);
    aero = aeroModel_stage11(3, deg2rad(2), 0, v, atm);
    addTest('Aero model returns valid coefficients', all(isfinite([aero.CD aero.CL aero.CY aero.Cm aero.Cn aero.Cl])), '');
catch ME
    addTest('Aero model returns valid coefficients', false, ME.message);
end

try
    stage11Cfg = stage11Config(config, 'RegressionExport');
    exportStage11Results(r, stage11Cfg);
    addTest('Export functions work', true, '');
catch ME
    addTest('Export functions work', false, ME.message);
end

try
    reportFile = generateStage11Report(r, stage11Config(config, 'RegressionReport'));
    addTest('Report functions work', exist(reportFile, 'file') == 2, '');
catch ME
    addTest('Report functions work', false, ME.message);
end

try
    sweepCfg = stage11Config(config, 'RegressionSweep');
    sweepCfg.launchAngles_deg = [10 20 30];
    sweep = runAngleSweep(vehicle, constants, sweepCfg);
    addTest('Angle sweep returns correct number of cases', height(sweep.summaryTable) == 3, '');
catch ME
    addTest('Angle sweep returns correct number of cases', false, ME.message);
end

try
    bodyCfg = stage11Config(config, 'RegressionBody');
    bodyCfg.bodyNames = {'Slender cone','Ogive nose','Blunt nose','Finned dart','Custom baseline'};
    bodies = runBodyComparison(vehicle, constants, bodyCfg);
    addTest('Body comparison returns correct number of cases', height(bodies.summaryTable) == 5, '');
catch ME
    addTest('Body comparison returns correct number of cases', false, ME.message);
end

summaryTable = table(string(names(:)), logical(passed(:)), string(messages(:)), ...
    'VariableNames', {'Test','Passed','Message'});
regression.summaryTable = summaryTable;
regression.passRate = mean(passed);
regression.passed = all(passed);

writetable(summaryTable, fullfile(config.tableDir, 'Stage12RegressionTests.csv'));
save(fullfile(config.matDir, 'Stage12RegressionTests.mat'), 'regression');

fprintf('\nStage 12 Regression Tests:\n');
for k = 1:numel(names)
    if passed(k)
        fprintf('PASSED: %s\n', names{k});
    else
        fprintf('FAILED: %s -- %s\n', names{k}, messages{k});
    end
end
fprintf('Total pass rate: %.1f %%\n\n', 100 * regression.passRate);

    function addTest(name, passValue, message)
        names{end+1} = name; %#ok<AGROW>
        passed(end+1) = logical(passValue); %#ok<AGROW>
        messages{end+1} = char(string(message)); %#ok<AGROW>
    end
end

function [r, msg] = safeStage11Single(vehicle, constants, config)
try
    cfg = stage11Config(config, 'RegressionSingle');
    r = runSingleTrajectory(vehicle, constants, cfg);
    msg = '';
catch ME
    r = struct();
    msg = ME.message;
end
end

function cfg = stage11Config(config, subfolder)
cfg = buildStage11Config(struct(), struct(), struct( ...
    'showPlots', false, ...
    'exportResults', false, ...
    'generateReport', false, ...
    'verbose', false, ...
    'interactive', false, ...
    'figureVisible', 'off', ...
    'outputRoot', fullfile(config.outputRoot, subfolder)));
end
