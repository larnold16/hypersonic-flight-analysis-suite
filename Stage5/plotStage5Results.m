function plotStage5Results(results)
% plotStage5Results
% Creates Stage 5 mission-design and optimization plots.

lineWidth = 1.5;

angles = results.launchAngles_deg;
rangeKm = results.range / 1000;
altitudeKm = results.maxAltitude / 1000;
maxQKPa = results.maxQ / 1000;
maxStagTemp = results.maxStagTemp;

idxRange = results.idxBestRange;
idxMaxQ = results.idxBestMaxQConstrained;
idxMinRangeAltitude = results.idxBestMinRangeAltitude;
hasMaxQConstrained = ~isnan(idxMaxQ);
hasTargetRange = ~isempty(results.idxClosestTarget);
hasMinRangeAltitude = ~isnan(idxMinRangeAltitude);

%% Figure 1: Main performance metrics
figure;

subplot(2,2,1);
plot(angles, rangeKm, 'LineWidth', lineWidth);
hold on;
plot(angles(idxRange), rangeKm(idxRange), 'o', 'MarkerSize', 7);
grid on;
xlabel('Launch Angle [deg]');
ylabel('Range [km]');
title('Range vs Launch Angle');

subplot(2,2,2);
plot(angles, altitudeKm, 'LineWidth', lineWidth);
hold on;
plot(angles(idxRange), altitudeKm(idxRange), 'o', 'MarkerSize', 7);
legendEntries = {'Maximum Altitude', 'Best Range Angle'};
if hasMaxQConstrained
    plot(angles(idxMaxQ), altitudeKm(idxMaxQ), 's', 'MarkerSize', 7);
    legendEntries{end+1} = 'Best Max-Q Constrained';
end
if hasMinRangeAltitude
    plot(angles(idxMinRangeAltitude), altitudeKm(idxMinRangeAltitude), ...
        'd', 'MarkerSize', 7);
    legendEntries{end+1} = 'Best Min-Range Altitude';
end
grid on;
xlabel('Launch Angle [deg]');
ylabel('Maximum Altitude [km]');
title('Maximum Altitude vs Launch Angle');
legend(legendEntries, 'Location', 'best');

subplot(2,2,3);
plot(angles, results.impactSpeed, 'LineWidth', lineWidth);
grid on;
xlabel('Launch Angle [deg]');
ylabel('Impact Speed [m/s]');
title('Impact Speed vs Launch Angle');

subplot(2,2,4);
plot(angles, results.maxMach, 'LineWidth', lineWidth);
grid on;
xlabel('Launch Angle [deg]');
ylabel('Maximum Mach Number');
title('Maximum Mach vs Launch Angle');

%% Figure 2: Loads and heating metrics
figure;

subplot(2,2,1);
plot(angles, maxQKPa, 'LineWidth', lineWidth);
hold on;
plot([angles(1), angles(end)], ...
    [results.maxQ_limit, results.maxQ_limit] / 1000, '--', ...
    'LineWidth', lineWidth);
if hasMaxQConstrained
    plot(angles(idxMaxQ), maxQKPa(idxMaxQ), 'o', 'MarkerSize', 7);
    legend('Max Q', 'Max-Q Limit', 'Best Max-Q Constrained', ...
        'Location', 'best');
else
    legend('Max Q', 'Max-Q Limit', 'Location', 'best');
end
grid on;
xlabel('Launch Angle [deg]');
ylabel('Maximum Dynamic Pressure [kPa]');
title('Maximum Dynamic Pressure vs Launch Angle');

subplot(2,2,2);
plot(angles, results.maxDrag, 'LineWidth', lineWidth);
grid on;
xlabel('Launch Angle [deg]');
ylabel('Maximum Drag Force [N]');
title('Maximum Drag vs Launch Angle');

subplot(2,2,3);
plot(angles, results.maxLift, 'LineWidth', lineWidth);
grid on;
xlabel('Launch Angle [deg]');
ylabel('Maximum Lift Force [N]');
title('Maximum Lift vs Launch Angle');

subplot(2,2,4);
plot(angles, maxStagTemp, 'LineWidth', lineWidth);
grid on;
xlabel('Launch Angle [deg]');
ylabel('Maximum Stagnation Temperature [K]');
title('Maximum Stagnation Temperature vs Launch Angle');

%% Figure 3: Optimization summary
figure;

subplot(2,2,1);
plot(angles, rangeKm, 'LineWidth', lineWidth);
hold on;
plot(angles(idxRange), rangeKm(idxRange), 'o', 'MarkerSize', 7);
legendEntries = {'Range', 'Best Range'};
if hasMaxQConstrained
    plot(angles(idxMaxQ), rangeKm(idxMaxQ), 's', 'MarkerSize', 7);
    legendEntries{end+1} = 'Best Max-Q Constrained';
end
if hasTargetRange
    idxTarget = results.idxClosestTarget;
    plot(angles(idxTarget), rangeKm(idxTarget), '^', 'MarkerSize', 7);
    plot([angles(1), angles(end)], ...
        [results.targetRange, results.targetRange] / 1000, '--', ...
        'LineWidth', lineWidth);
    legendEntries{end+1} = 'Closest Target Range';
    legendEntries{end+1} = 'Target Range';
end
if ~isempty(results.minRangeForAltitude_m)
    plot([angles(1), angles(end)], ...
        [results.minRangeForAltitude_m, results.minRangeForAltitude_m] / 1000, ...
        ':', 'LineWidth', lineWidth);
    legendEntries{end+1} = 'Min Range for Altitude';
end
grid on;
xlabel('Launch Angle [deg]');
ylabel('Range [km]');
title('Range Optimization');
legend(legendEntries, 'Location', 'best');

subplot(2,2,2);
plot(angles, altitudeKm, 'LineWidth', lineWidth);
hold on;
plot(angles(idxRange), altitudeKm(idxRange), 'o', 'MarkerSize', 7);
legendEntries = {'Maximum Altitude', 'Best Range Angle'};
if hasMaxQConstrained
    plot(angles(idxMaxQ), altitudeKm(idxMaxQ), 's', 'MarkerSize', 7);
    legendEntries{end+1} = 'Best Max-Q Constrained';
end
if hasMinRangeAltitude
    plot(angles(idxMinRangeAltitude), altitudeKm(idxMinRangeAltitude), ...
        'd', 'MarkerSize', 7);
    legendEntries{end+1} = 'Best Min-Range Altitude';
end
grid on;
xlabel('Launch Angle [deg]');
ylabel('Maximum Altitude [km]');
title('Altitude at Useful Mission Cases');
legend(legendEntries, 'Location', 'best');

subplot(2,2,3);
plot(angles, maxQKPa, 'LineWidth', lineWidth);
hold on;
plot([angles(1), angles(end)], ...
    [results.maxQ_limit, results.maxQ_limit] / 1000, '--', ...
    'LineWidth', lineWidth);
if hasMaxQConstrained
    plot(angles(idxMaxQ), maxQKPa(idxMaxQ), 's', 'MarkerSize', 7);
    legend('Max Q', 'Max-Q Limit', 'Best Max-Q Constrained', ...
        'Location', 'best');
else
    legend('Max Q', 'Max-Q Limit', 'Location', 'best');
end
grid on;
xlabel('Launch Angle [deg]');
ylabel('Maximum Dynamic Pressure [kPa]');
title('Max-Q Constraint');

subplot(2,2,4);
plot(rangeKm, altitudeKm, 'LineWidth', lineWidth);
hold on;
plot(rangeKm(idxRange), altitudeKm(idxRange), 'o', 'MarkerSize', 7);
legendEntries = {'Sweep', 'Best Range'};
if hasMaxQConstrained
    plot(rangeKm(idxMaxQ), altitudeKm(idxMaxQ), 's', 'MarkerSize', 7);
    legendEntries{end+1} = 'Best Max-Q Constrained';
end
if hasMinRangeAltitude
    plot(rangeKm(idxMinRangeAltitude), altitudeKm(idxMinRangeAltitude), ...
        'd', 'MarkerSize', 7);
    legendEntries{end+1} = 'Best Min-Range Altitude';
end
grid on;
xlabel('Range [km]');
ylabel('Maximum Altitude [km]');
title('Range-Altitude Trade');
legend(legendEntries, 'Location', 'best');

end
