function plotStage7ThermalResults(results)
% plotStage7ThermalResults
% Creates Stage 7 simplified thermal loading plots.

lineWidth = 1.5;

t = results.t;
hKm = results.h / 1000;
Mach = results.Mach;
qKPa = results.q / 1000;
thermal = results.thermal;
heatFlux_kW_m2 = thermal.heatFlux_kW_m2;
cumulativeHeatLoad_MJ_m2 = thermal.cumulativeHeatLoad_MJ_m2;

[~, idxPeakHeatFlux] = max(thermal.heatFlux_W_m2);

%% Figure 1: Thermal time histories
figure;

subplot(2,2,1);
plot(t, heatFlux_kW_m2, 'LineWidth', lineWidth);
hold on;
plot(t(idxPeakHeatFlux), heatFlux_kW_m2(idxPeakHeatFlux), 'o', 'MarkerSize', 7);
grid on;
xlabel('Time [s]');
ylabel('Heat Flux [kW/m^2]');
title('Simplified Convective Heat Flux vs Time');
legend('Heat Flux', 'Peak Heat Flux', 'Location', 'best');

subplot(2,2,2);
plot(t, thermal.stagnationTemp_K, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Stagnation Temperature [K]');
title('Stagnation Temperature vs Time');

subplot(2,2,3);
plot(t, thermal.wallTemp_K, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Wall Temperature [K]');
title('Lumped Wall Temperature Estimate');

subplot(2,2,4);
plot(t, hKm, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Altitude [km]');
title('Altitude vs Time');

%% Figure 2: Thermal loading relationships
figure;

subplot(2,2,1);
plot(Mach, heatFlux_kW_m2, 'LineWidth', lineWidth);
hold on;
plot(Mach(idxPeakHeatFlux), heatFlux_kW_m2(idxPeakHeatFlux), 'o', 'MarkerSize', 7);
grid on;
xlabel('Mach Number');
ylabel('Heat Flux [kW/m^2]');
title('Heat Flux vs Mach Number');

subplot(2,2,2);
plot(hKm, heatFlux_kW_m2, 'LineWidth', lineWidth);
hold on;
plot(hKm(idxPeakHeatFlux), heatFlux_kW_m2(idxPeakHeatFlux), 'o', 'MarkerSize', 7);
grid on;
xlabel('Altitude [km]');
ylabel('Heat Flux [kW/m^2]');
title('Heat Flux vs Altitude');

subplot(2,2,3);
plot(qKPa, heatFlux_kW_m2, 'LineWidth', lineWidth);
hold on;
plot(qKPa(idxPeakHeatFlux), heatFlux_kW_m2(idxPeakHeatFlux), 'o', 'MarkerSize', 7);
grid on;
xlabel('Dynamic Pressure [kPa]');
ylabel('Heat Flux [kW/m^2]');
title('Heat Flux vs Dynamic Pressure');

subplot(2,2,4);
plot(t, cumulativeHeatLoad_MJ_m2, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Cumulative Heat Load [MJ/m^2]');
title('Cumulative Heat Load vs Time');

%% Figure 3: Flight/thermal combined summary
figure;

subplot(2,2,1);
plot(t, Mach, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Mach Number');
title('Mach Number vs Time');

subplot(2,2,2);
plot(t, qKPa, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Dynamic Pressure [kPa]');
title('Dynamic Pressure vs Time');

subplot(2,2,3);
plot(t, results.V, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Velocity [m/s]');
title('Velocity vs Time');

subplot(2,2,4);
plot(t, heatFlux_kW_m2, 'LineWidth', lineWidth);
hold on;
plot(t(idxPeakHeatFlux), heatFlux_kW_m2(idxPeakHeatFlux), 'o', 'MarkerSize', 7);
grid on;
xlabel('Time [s]');
ylabel('Heat Flux [kW/m^2]');
title('Simplified Heat Flux vs Time');
legend('Heat Flux', 'Peak Heat Flux', 'Location', 'best');

end
