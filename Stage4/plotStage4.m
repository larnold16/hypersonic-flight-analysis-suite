function plotStage4(results)
% plotStage4
% Creates Stage 4 trajectory, loads, aero, and ground-track plots.

lineWidth = 1.5;

t = results.t;
xKm = results.x / 1000;
hKm = results.h / 1000;
latDeg = rad2deg(results.lat);
lonDeg = rad2deg(results.lon);
qKPa = results.q / 1000;

%% Figure 1: Main trajectory and flight history
figure;

subplot(2,2,1);
plot(xKm, hKm, 'LineWidth', lineWidth);
hold on;
plot(xKm(results.idxMaxAlt), hKm(results.idxMaxAlt), 'o', 'MarkerSize', 7);
grid on;
xlabel('Downrange Distance [km]');
ylabel('Altitude [km]');
title('Stage 4 Trajectory');

subplot(2,2,2);
plot(t, hKm, 'LineWidth', lineWidth);
hold on;
plot(t(results.idxMaxAlt), hKm(results.idxMaxAlt), 'o', 'MarkerSize', 7);
grid on;
xlabel('Time [s]');
ylabel('Altitude [km]');
title('Altitude vs Time');

subplot(2,2,3);
plot(t, results.V, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Velocity [m/s]');
title('Velocity vs Time');

subplot(2,2,4);
plot(t, results.Mach, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Mach Number');
title('Mach Number vs Time');

%% Figure 2: Loads and heating
figure;

subplot(2,2,1);
plot(t, qKPa, 'LineWidth', lineWidth);
hold on;
plot(t(results.idxMaxQ), qKPa(results.idxMaxQ), 'o', 'MarkerSize', 7);
grid on;
xlabel('Time [s]');
ylabel('Dynamic Pressure [kPa]');
title('Dynamic Pressure vs Time');

subplot(2,2,2);
plot(t, results.drag, 'LineWidth', lineWidth);
hold on;
plot(t(results.idxMaxDrag), results.drag(results.idxMaxDrag), 'o', 'MarkerSize', 7);
grid on;
xlabel('Time [s]');
ylabel('Drag Force [N]');
title('Drag Force vs Time');

subplot(2,2,3);
plot(t, results.lift, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Lift Force [N]');
title('Lift Force vs Time');

subplot(2,2,4);
plot(t, results.stagTemp, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Stagnation Temperature [K]');
title('Stagnation Temperature vs Time');

%% Figure 3: Aerodynamic behavior
figure;

subplot(2,2,1);
plot(t, results.Cd, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('C_D');
title('Drag Coefficient vs Time');

subplot(2,2,2);
plot(t, results.CL, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('C_L');
title('Lift Coefficient vs Time');

subplot(2,2,3);
plot(t, results.LD, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('L/D');
title('Lift-to-Drag Ratio vs Time');

subplot(2,2,4);
plot(results.Mach, results.Cd, 'LineWidth', lineWidth);
hold on;
plot(results.Mach, results.CL, 'LineWidth', lineWidth);
grid on;
xlabel('Mach Number');
ylabel('Coefficient');
title('Aero Coefficients vs Mach');
legend('C_D', 'C_L', 'Location', 'best');

%% Figure 4: Earth rotation and ground track outputs
figure;

subplot(2,2,1);
plot(lonDeg, latDeg, 'LineWidth', lineWidth);
hold on;
plot(lonDeg(1), latDeg(1), 'o', 'MarkerSize', 7);
plot(lonDeg(end), latDeg(end), 'x', 'MarkerSize', 8);
grid on;
xlabel('Longitude [deg]');
ylabel('Latitude [deg]');
title('Ground Track');
legend('Ground Track', 'Launch', 'Impact', 'Location', 'best');

subplot(2,2,2);
plot(t, latDeg, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Latitude [deg]');
title('Latitude vs Time');

subplot(2,2,3);
plot(t, lonDeg, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Longitude [deg]');
title('Longitude vs Time');

subplot(2,2,4);
plot(xKm, hKm, 'LineWidth', lineWidth);
hold on;
plot(xKm(results.idxMaxAlt), hKm(results.idxMaxAlt), 'o', 'MarkerSize', 7);
grid on;
xlabel('Ground-Track Distance [km]');
ylabel('Altitude [km]');
title('Altitude vs Ground-Track Distance');

end