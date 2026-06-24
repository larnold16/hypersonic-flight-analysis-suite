function plotStage10SweepResults_stage10(sweepResults)
% plotStage10SweepResults_stage10
% Creates Stage 10 launch-angle sweep plots.

lineWidth = 1.5;
angles = sweepResults.launchAngles_deg;

%% Figure 1: 6-DOF launch-angle trajectory comparison
figure('Name', 'Stage 10 6-DOF Launch-Angle Trajectory Comparison');
hold on;

legendEntries = cell(numel(angles), 1);
for k = 1:numel(angles)
    caseResult = sweepResults.caseResults{k};
    plot(caseResult.x / 1000, caseResult.z / 1000, 'LineWidth', lineWidth);
    if caseResult.impactDetected
        plot(caseResult.x(end) / 1000, caseResult.z(end) / 1000, ...
            'o', 'MarkerSize', 6);
    end
    legendEntries{k} = sprintf('%.0f deg', angles(k));
end

grid on;
xlabel('Downrange [km]');
ylabel('Altitude [km]');
title('6-DOF Trajectory vs Launch Angle');
legend(legendEntries, 'Location', 'best');

%% Figure 2: Launch-angle performance summary
figure('Name', 'Stage 10 Launch-Angle Performance Summary');

subplot(2,2,1);
plot(angles, sweepResults.impactRange_m / 1000, 'o-', 'LineWidth', lineWidth);
grid on;
xlabel('Launch Angle [deg]');
ylabel('Impact Range [km]');
title('Impact Range vs Launch Angle');

subplot(2,2,2);
plot(angles, sweepResults.maxAltitude_m / 1000, 'o-', 'LineWidth', lineWidth);
grid on;
xlabel('Launch Angle [deg]');
ylabel('Maximum Altitude [km]');
title('Maximum Altitude vs Launch Angle');

subplot(2,2,3);
plot(angles, sweepResults.impactSpeed_mps, 'o-', 'LineWidth', lineWidth);
grid on;
xlabel('Launch Angle [deg]');
ylabel('Impact Speed [m/s]');
title('Impact Speed vs Launch Angle');

subplot(2,2,4);
plot(angles, sweepResults.impactMach, 'o-', 'LineWidth', lineWidth);
grid on;
xlabel('Launch Angle [deg]');
ylabel('Impact Mach Number');
title('Impact Mach vs Launch Angle');

%% Figure 3: Attitude/dynamics summary
figure('Name', 'Stage 10 Launch-Angle Attitude and Dynamics Summary');

subplot(2,2,1);
plot(angles, sweepResults.maxAlpha_deg, 'o-', 'LineWidth', lineWidth);
grid on;
xlabel('Launch Angle [deg]');
ylabel('Maximum AoA [deg]');
title('Max Angle of Attack');

subplot(2,2,2);
plot(angles, sweepResults.maxPitchRate_deg_s, 'o-', 'LineWidth', lineWidth);
grid on;
xlabel('Launch Angle [deg]');
ylabel('Max Pitch Rate [deg/s]');
title('Max Pitch Rate');

subplot(2,2,3);
plot(angles, sweepResults.maxYawRate_deg_s, 'o-', 'LineWidth', lineWidth);
grid on;
xlabel('Launch Angle [deg]');
ylabel('Max Yaw Rate [deg/s]');
title('Max Yaw Rate');

subplot(2,2,4);
bar(angles, double(sweepResults.attitudeBounded));
grid on;
ylim([0, 1.2]);
xlabel('Launch Angle [deg]');
ylabel('Within Bounds [-]');
title('Attitude/Rate Bounds Flag');

end
