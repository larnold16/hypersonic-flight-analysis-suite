function plotStage9EnvironmentResults(results)
% plotStage9EnvironmentResults
% Creates Stage 9 launch-environment sensitivity plots.

lineWidth = 1.5;
env = results.environment;
names = env.name;
x = 1:numel(names);

%% Figure 1: Environment performance comparison
figure('Name', 'Stage 9 Environment Performance Comparison');

subplot(2,2,1);
barWithEnvironmentLabels(x, env.range_m / 1000, names);
ylabel('Maximum Range [km]');
title('Maximum Range by Environment');

subplot(2,2,2);
barWithEnvironmentLabels(x, env.maxAltitude_m / 1000, names);
ylabel('Max Altitude [km]');
title('Max Altitude at Best Range');

subplot(2,2,3);
barWithEnvironmentLabels(x, env.bestRangeAngle_deg, names);
ylabel('Best Launch Angle [deg]');
title('Best Launch Angle by Environment');

subplot(2,2,4);
barWithEnvironmentLabels(x, env.impactSpeed_mps, names);
ylabel('Impact Speed [m/s]');
title('Impact Speed at Best Range');

%% Figure 2: Loads and heating by environment
figure('Name', 'Stage 9 Loads and Heating by Environment');

subplot(2,2,1);
barWithEnvironmentLabels(x, env.maxQ_Pa / 1000, names);
ylabel('Max Dynamic Pressure [kPa]');
title('Max-Q by Environment');

subplot(2,2,2);
barWithEnvironmentLabels(x, env.maxDrag_N, names);
ylabel('Max Drag [N]');
title('Max Drag by Environment');

subplot(2,2,3);
barWithEnvironmentLabels(x, env.maxLift_N, names);
ylabel('Max Lift [N]');
title('Max Lift by Environment');

subplot(2,2,4);
barWithEnvironmentLabels(x, env.maxStagTemp_K, names);
ylabel('Max Stagnation Temperature [K]');
title('Max Stagnation Temperature');

%% Figure 3: Percent change from baseline
figure('Name', 'Stage 9 Percent Change From Baseline');

subplot(2,2,1);
barWithEnvironmentLabels(x, env.rangeChange_percent, names);
ylabel('Range Change [%]');
title('Range Change From Baseline');

subplot(2,2,2);
barWithEnvironmentLabels(x, env.maxQChange_percent, names);
ylabel('Max-Q Change [%]');
title('Max-Q Change From Baseline');

subplot(2,2,3);
barWithEnvironmentLabels(x, env.impactSpeedChange_percent, names);
ylabel('Impact Speed Change [%]');
title('Impact Speed Change From Baseline');

subplot(2,2,4);
barWithEnvironmentLabels(x, env.stagnationTemperatureChange_percent, names);
ylabel('Stagnation Temp Change [%]');
title('Stagnation Temperature Change');

%% Figure 4: Range trade study by environment
figure('Name', 'Stage 9 Range Trade Study by Environment');
hold on;

for k = 1:numel(results.stage5Results)
    stage5Result = results.stage5Results{k};
    plot(stage5Result.launchAngles_deg, stage5Result.range / 1000, ...
        'LineWidth', lineWidth);
end

grid on;
xlabel('Launch Angle [deg]');
ylabel('Range [km]');
title('Range vs Launch Angle by Environment');
legend(names, 'Location', 'best', 'Interpreter', 'none');

end

function barWithEnvironmentLabels(x, y, names)
bar(x, y);
grid on;
set(gca, 'XTick', x, 'XTickLabel', names, 'XTickLabelRotation', 30, ...
    'TickLabelInterpreter', 'none');
end
