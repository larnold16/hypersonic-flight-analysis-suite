function plotStage2(results)
% plotStage2
% Creates plots for the Stage 2 trajectory model.

%% Trajectory Plot
figure;
plot(results.x, results.h, 'LineWidth', 2);
grid on;
xlabel('Downrange Distance [m]');
ylabel('Altitude [m]');
title('Stage 2 Trajectory');

%% Velocity Plot
figure;
plot(results.t, results.V, 'LineWidth', 2);
grid on;
xlabel('Time [s]');
ylabel('Velocity [m/s]');
title('Velocity vs Time');

%% Mach Number Plot
figure;
plot(results.t, results.Mach, 'LineWidth', 2);
grid on;
xlabel('Time [s]');
ylabel('Mach Number [-]');
title('Mach Number vs Time');

%% Dynamic Pressure Plot
figure;
plot(results.t, results.q / 1000, 'LineWidth', 2);
grid on;
xlabel('Time [s]');
ylabel('Dynamic Pressure [kPa]');
title('Dynamic Pressure vs Time');

%% Altitude vs Time Plot
figure;
plot(results.t, results.h, 'LineWidth', 2);
grid on;
xlabel('Time [s]');
ylabel('Altitude [m]');
title('Altitude vs Time');

end