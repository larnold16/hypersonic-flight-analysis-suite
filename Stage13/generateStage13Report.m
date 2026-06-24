function reportFile = generateStage13Report(results, config)
% generateStage13Report
% Writes a Stage 13 engineering trade-study report.

reportFile = fullfile(config.reportDir, 'Stage13EngineeringReport.txt');
fid = fopen(reportFile, 'w');
if fid < 0
    warning('Stage13:ReportOpenFailed', 'Could not write Stage 13 report.');
    return;
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'Stage 13 Engineering Trade Study Report\n');
fprintf(fid, 'Generated: %s\n\n', datestr(now));
fprintf(fid, 'Baseline Vehicle\n');
fprintf(fid, '  Mass: %.3f kg\n', config.baselineDesign.mass_kg);
fprintf(fid, '  Length: %.4f m\n', config.baselineDesign.length_m);
fprintf(fid, '  Diameter: %.4f m\n', config.baselineDesign.diameter_m);
fprintf(fid, '  Launch speed: %.2f m/s\n', config.baselineDesign.initialSpeed_mps);
fprintf(fid, '  Launch angle: %.2f deg\n\n', config.baselineDesign.launchAngle_deg);

fprintf(fid, 'Design Variables\n');
fprintf(fid, '  Launch angle, speed, yaw, altitude, mass, length, diameter, nose radius,\n');
fprintf(fid, '  body type, static margin, Cd/CL multipliers, wind, density, and temperature.\n\n');

fprintf(fid, 'Design Constraints\n');
fprintf(fid, '  Max q < %.1f kPa\n', config.constraints.maxQ_Pa / 1000);
fprintf(fid, '  Max g-load < %.1f g\n', config.constraints.maxGLoad);
fprintf(fid, '  Static margin %.1f%% to %.1f%% body length\n', ...
    100 * config.constraints.minStaticMargin, 100 * config.constraints.maxStaticMargin);
fprintf(fid, '  Heating rate < %.1f kW/m^2\n', config.constraints.maxHeating_W_m2 / 1000);
fprintf(fid, '  Total heat load < %.1f MJ/m^2\n\n', config.constraints.maxHeatLoad_J_m2 / 1e6);

fprintf(fid, 'Optimization Method\n');
fprintf(fid, '  Coarse grid search, random search, and local refinement using plain MATLAB.\n\n');

printStudy(fid, results, 'optimization', 'Optimization Results');
printStudy(fid, results, 'monteCarlo', 'Monte Carlo Results');
printStudy(fid, results, 'sensitivity', 'Sensitivity Results');
printStudy(fid, results, 'pareto', 'Pareto Results');
printStudy(fid, results, 'doe', 'Design of Experiments Results');

fprintf(fid, '\nAssumptions and Limitations\n');
fprintf(fid, '  Educational trade-study model only. No targeting, lethality, or guidance-to-target features.\n');
fprintf(fid, '  Aerodynamics, heating, and stability are approximate and need validation data for real design.\n');
fprintf(fid, '  Optimization is exhaustive/stochastic search, not a certified optimizer.\n\n');
fprintf(fid, 'Recommended Future Work\n');
fprintf(fid, '  Add validated aero databases, calibrated uncertainty models, improved thermal protection modeling,\n');
fprintf(fid, '  control-system dynamics, and higher-fidelity atmosphere/wind datasets.\n');
end

function printStudy(fid, results, fieldName, titleText)
if isfield(results, fieldName)
    item = results.(fieldName);
    fprintf(fid, '%s\n', titleText);
    if isfield(item, 'bestBalancedDesign') && ~isempty(item.bestBalancedDesign)
        fprintf(fid, '%s\n', evalc('disp(item.bestBalancedDesign)'));
    elseif isfield(item, 'summaryTable')
        fprintf(fid, '  Cases: %d\n', height(item.summaryTable));
        fprintf(fid, '%s\n', evalc('disp(item.summaryTable(1:min(5,height(item.summaryTable)),:))'));
    end
end
end
