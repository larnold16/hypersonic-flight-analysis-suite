function plotStage3(results)
% plotStage3
% Creates Stage 3 trajectory, environment, and aero plots.

%% Main trajectory plots
figure;

subplot(2,2,1);
plot(results.x / 1000, results.h / 1000, 'LineWidth', 1.8);
grid on;
xlabel('Downrange Distance [km]');
ylabel('Altitude [km]');
title('Stage 3 Trajectory');

subplot(2,2,2);
plot(results.t, results.V, 'LineWidth', 1.8);
grid on;
xlabel('Time [s]');
ylabel('Velocity [m/s]');
title('Velocity vs Time');

subplot(2,2,3);
plot(results.t, results.Mach, 'LineWidth', 1.8);
grid on;
xlabel('Time [s]');
ylabel('Mach Number');
title('Mach Number vs Time');

subplot(2,2,4);
plot(results.t, results.q / 1000, 'LineWidth', 1.8);
grid on;
xlabel('Time [s]');
ylabel('Dynamic Pressure [kPa]');
title('Dynamic Pressure vs Time');

%% Aero plots
figure;

subplot(3,1,1);
plot(results.t, results.Cd, 'LineWidth', 1.8);
grid on;
xlabel('Time [s]');
ylabel('C_D');
title('Drag Coefficient vs Time');

subplot(3,1,2);
plot(results.t, results.CL, 'LineWidth', 1.8);
grid on;
xlabel('Time [s]');
ylabel('C_L');
title('Lift Coefficient vs Time');

subplot(3,1,3);
plot(results.t, results.LD, 'LineWidth', 1.8);
grid on;
xlabel('Time [s]');
ylabel('L/D');
title('Lift-to-Drag Ratio vs Time');

%% Atmosphere and thermal plots
figure;

subplot(2,2,1);
plot(results.h / 1000, results.temp, 'LineWidth', 1.8);
grid on;
xlabel('Altitude [km]');
ylabel('Temperature [K]');
title('Temperature vs Altitude');

subplot(2,2,2);
plot(results.h / 1000, results.rho, 'LineWidth', 1.8);
grid on;
xlabel('Altitude [km]');
ylabel('Density [kg/m^3]');
title('Density vs Altitude');

subplot(2,2,3);
plot(results.t, results.stagTemp, 'LineWidth', 1.8);
grid on;
xlabel('Time [s]');
ylabel('Stagnation Temperature [K]');
title('Stagnation Temperature vs Time');

subplot(2,2,4);
plot(results.t, results.gravity, 'LineWidth', 1.8);
grid on;
xlabel('Time [s]');
ylabel('Gravity [m/s^2]');
title('Gravity vs Time');

%% Force plots
figure;

subplot(2,1,1);
plot(results.t, results.drag, 'LineWidth', 1.8);
grid on;
xlabel('Time [s]');
ylabel('Drag Force [N]');
title('Drag Force vs Time');

subplot(2,1,2);
plot(results.t, results.lift, 'LineWidth', 1.8);
grid on;
xlabel('Time [s]');
ylabel('Lift Force [N]');
title('Lift Force vs Time');

end