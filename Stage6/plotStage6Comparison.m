function plotStage6Comparison(comparison)
% plotStage6Comparison
% Creates Stage 6 vehicle comparison plots.

lineWidth = 1.5;
names = comparison.vehicleNames;
x = 1:numel(names);

%% Figure 1: Vehicle performance comparison
figure('Name', 'Stage 6 Vehicle Performance Comparison');

subplot(2,2,1);
barWithVehicleLabels(x, comparison.maxRange_m / 1000, names);
ylabel('Maximum Range [km]');
title('Maximum Range by Vehicle');

subplot(2,2,2);
barWithVehicleLabels(x, comparison.maxAltitudeAtBestRange_m / 1000, names);
ylabel('Max Altitude [km]');
title('Altitude at Best-Range Angle');

subplot(2,2,3);
barWithVehicleLabels(x, comparison.bestRangeAngle_deg, names);
ylabel('Best Launch Angle [deg]');
title('Best Launch Angle by Vehicle');

subplot(2,2,4);
barWithVehicleLabels(x, comparison.impactSpeedAtBestRange_mps, names);
ylabel('Impact Speed [m/s]');
title('Impact Speed at Best Range');

%% Figure 2: Loads and constraints by vehicle
figure('Name', 'Stage 6 Vehicle Loads and Constraints');

subplot(2,2,1);
barWithVehicleLabels(x, comparison.maxQAtBestRange_Pa / 1000, names);
ylabel('Max Dynamic Pressure [kPa]');
title('Max-Q at Best Range');

subplot(2,2,2);
barWithVehicleLabels(x, comparison.maxDragAtBestRange_N, names);
ylabel('Max Drag [N]');
title('Max Drag at Best Range');

subplot(2,2,3);
barWithVehicleLabels(x, comparison.maxLiftAtBestRange_N, names);
ylabel('Max Lift [N]');
title('Max Lift at Best Range');

subplot(2,2,4);
barWithVehicleLabels(x, comparison.maxStagTempAtBestRange_K, names);
ylabel('Max Stagnation Temperature [K]');
title('Max Stagnation Temperature at Best Range');

%% Figure 3: Design metrics by vehicle
figure('Name', 'Stage 6 Vehicle Design Metrics');

subplot(2,2,1);
barWithVehicleLabels(x, comparison.beta_average_kgpm2, names);
ylabel('Ballistic Coefficient [kg/m^2]');
title('Average Ballistic Coefficient');

subplot(2,2,2);
barWithVehicleLabels(x, comparison.finenessRatio, names);
ylabel('Fineness Ratio [-]');
title('Fineness Ratio by Vehicle');

subplot(2,2,3);
barWithVehicleLabels(x, comparison.referenceArea_m2, names);
ylabel('Reference Area [m^2]');
title('Reference Area by Vehicle');

subplot(2,2,4);
barWithVehicleLabels(x, comparison.maxLDAtBestRange, names);
ylabel('Maximum L/D [-]');
title('L/D at Best Range');

%% Figure 4: Range trade study
figure('Name', 'Stage 6 Range Trade Study');
hold on;

for k = 1:numel(comparison.stage5Results)
    stage5Result = comparison.stage5Results{k};
    plot(stage5Result.launchAngles_deg, stage5Result.range / 1000, ...
        'LineWidth', lineWidth);
end

grid on;
xlabel('Launch Angle [deg]');
ylabel('Range [km]');
title('Range vs Launch Angle by Vehicle');
legend(names, 'Location', 'best', 'Interpreter', 'none');

if isfield(comparison, 'stage7ThermalIncluded') && comparison.stage7ThermalIncluded
    %% Figure 5: Stage 7 thermal comparison at best-range trajectory
    figure('Name', 'Stage 6 / Stage 7 Thermal Comparison');

    subplot(2,2,1);
    barWithVehicleLabels(x, comparison.peakHeatFluxAtBestRange_W_m2 / 1000, names);
    ylabel('Peak Heat Flux [kW/m^2]');
    title('Peak Heat Flux at Best Range');

    subplot(2,2,2);
    barWithVehicleLabels(x, comparison.totalHeatLoadAtBestRange_J_m2 / 1e6, names);
    ylabel('Total Heat Load [MJ/m^2]');
    title('Total Heat Load at Best Range');

    subplot(2,2,3);
    barWithVehicleLabels(x, comparison.maxWallTempAtBestRange_K, names);
    ylabel('Max Wall Temperature [K]');
    title('Estimated Max Wall Temperature');

    subplot(2,2,4);
    barWithVehicleLabels(x, comparison.thermalMarginAtBestRange_K, names);
    ylabel('Thermal Margin [K]');
    title('Wall Temperature Margin');
end

end

function barWithVehicleLabels(x, y, names)
bar(x, y);
grid on;
set(gca, 'XTick', x, 'XTickLabel', names, 'XTickLabelRotation', 30, ...
    'TickLabelInterpreter', 'none');
end
