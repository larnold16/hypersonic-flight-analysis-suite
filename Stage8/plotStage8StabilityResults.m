function plotStage8StabilityResults(results)
% plotStage8StabilityResults
% Creates Stage 8 simplified stability, trim, and maneuverability plots.

lineWidth = 1.5;

t = results.t;
hKm = results.h / 1000;
Mach = results.Mach;
qKPa = results.q / 1000;
stability = results.stability;
trim = stability.trim;
maneuver = stability.maneuverability;

%% Figure 1: Static stability summary
figure('Name', 'Stage 8 Static Stability Summary');

subplot(2,2,1);
plot([0, stability.length_m], [0, 0], 'k-', 'LineWidth', lineWidth);
hold on;
plot(stability.cgLocation_m, 0, 'o', 'MarkerSize', 8, 'LineWidth', lineWidth);
plot(stability.cpLocation_m, 0, 's', 'MarkerSize', 8, 'LineWidth', lineWidth);
xlim([0, stability.length_m]);
ylim([-0.2, 0.2]);
grid on;
xlabel('Distance Aft From Nose [m]');
yticks([]);
title('CG and CP Location');
legend('Body Length', 'CG', 'CP', 'Location', 'best');

subplot(2,2,2);
bar(1, stability.staticMargin_percentLength);
grid on;
set(gca, 'XTick', 1, 'XTickLabel', {'Static Margin'});
ylabel('Static Margin [% Body Length]');
title('Static Margin');

subplot(2,2,3);
plot(Mach, stability.staticMargin_vsMach .* 100, 'LineWidth', lineWidth);
grid on;
xlabel('Mach Number');
ylabel('Static Margin [% Body Length]');
title('Static Margin vs Mach Number');

subplot(2,2,4);
classificationValue = double(stability.staticMargin > stability.neutralStaticMarginTolerance) - ...
    double(stability.staticMargin < -stability.neutralStaticMarginTolerance);
bar(1, classificationValue);
grid on;
ylim([-1.2, 1.2]);
set(gca, 'XTick', 1, 'XTickLabel', {stability.classification}, ...
    'YTick', [-1, 0, 1], 'YTickLabel', {'Unstable', 'Neutral', 'Stable'});
title('Pitch Stability Classification');

%% Figure 2: Trim behavior
figure('Name', 'Stage 8 Trim Behavior');

subplot(2,2,1);
idxMidMach = round(numel(trim.machGrid) / 2);
plot(trim.alphaGrid_deg, trim.CmGrid(:,idxMidMach), 'LineWidth', lineWidth);
hold on;
plot([trim.alphaGrid_deg(1), trim.alphaGrid_deg(end)], [0, 0], 'k--', ...
    'LineWidth', lineWidth);
grid on;
xlabel('Angle of Attack [deg]');
ylabel('Pitching Moment Coefficient C_m');
title(sprintf('C_m vs AoA at Mach %.1f', trim.machGrid(idxMidMach)));
legend('C_m', 'Trim C_m = 0', 'Location', 'best');

subplot(2,2,2);
plot(trim.machGrid, trim.trimAlpha_deg, 'LineWidth', lineWidth);
hold on;
plot([trim.machGrid(1), trim.machGrid(end)], ...
    [trim.maxAllowableAlpha_deg, trim.maxAllowableAlpha_deg], 'k--', ...
    'LineWidth', lineWidth);
plot([trim.machGrid(1), trim.machGrid(end)], ...
    [-trim.maxAllowableAlpha_deg, -trim.maxAllowableAlpha_deg], 'k--', ...
    'LineWidth', lineWidth);
grid on;
xlabel('Mach Number');
ylabel('Trim Angle of Attack [deg]');
title('Estimated Trim AoA vs Mach Number');
legend('Trim AoA', 'AoA Limit', 'Location', 'best');

subplot(2,2,3);
plot(trim.machGrid, trim.CmAlpha_per_rad, 'LineWidth', lineWidth);
grid on;
xlabel('Mach Number');
ylabel('C_{m_\alpha} [1/rad]');
title('Simplified Pitch Moment Slope');

subplot(2,2,4);
bar(trim.machGrid, double(trim.trimFeasibleByMach));
grid on;
ylim([0, 1.2]);
xlabel('Mach Number');
ylabel('Trim Feasible [-]');
title('Trim Feasibility Across Mach');

%% Figure 3: Maneuverability
figure('Name', 'Stage 8 Maneuverability');

subplot(2,2,1);
plot(t, maneuver.normalAcceleration_g, 'LineWidth', lineWidth);
hold on;
plot(t(maneuver.idxMaxNormalAcceleration), maneuver.maxNormalAcceleration_g, ...
    'o', 'MarkerSize', 7);
grid on;
xlabel('Time [s]');
ylabel('Normal Acceleration [g]');
title('Estimated Normal Acceleration vs Time');

subplot(2,2,2);
plot(Mach, maneuver.normalAcceleration_g, 'LineWidth', lineWidth);
grid on;
xlabel('Mach Number');
ylabel('Normal Acceleration [g]');
title('Estimated Normal Acceleration vs Mach');

subplot(2,2,3);
plot(t, maneuver.CLRequiredForTarget, 'LineWidth', lineWidth);
hold on;
plot(t, maneuver.CLAvailable, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Lift Coefficient [-]');
title('Required vs Available C_L');
legend('Required for Target g', 'Available C_L', 'Location', 'best');

subplot(2,2,4);
plot(t, qKPa, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Dynamic Pressure [kPa]');
title('Dynamic Pressure vs Time');

%% Figure 4: Combined trajectory/stability context
figure('Name', 'Stage 8 Trajectory and Stability Context');

subplot(2,2,1);
plot(t, hKm, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Altitude [km]');
title('Altitude vs Time');

subplot(2,2,2);
plot(t, Mach, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Mach Number');
title('Mach Number vs Time');

subplot(2,2,3);
plot(t, results.lift, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Lift Force [N]');
title('Lift Force vs Time');

subplot(2,2,4);
plot(t, maneuver.normalAcceleration_g, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Normal Acceleration [g]');
title('Normal Acceleration vs Time');

end
