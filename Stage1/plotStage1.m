function plotStage1(results)
% plotStage1
% Creates Stage 1 trajectory plots.

t = results.t;
x = results.x;
h = results.h;
V = results.V;

% Trajectory
figure;
plot(x, h, 'LineWidth', 2);
grid on;
xlabel('Downrange Distance [m]');
ylabel('Altitude [m]');
title('Stage 1 Trajectory');

% Altitude vs time
figure;
plot(t, h, 'LineWidth', 2);
grid on;
xlabel('Time [s]');
ylabel('Altitude [m]');
title('Stage 1 Altitude vs Time');

% Speed vs time
figure;
plot(t, V, 'LineWidth', 2);
grid on;
xlabel('Time [s]');
ylabel('Speed [m/s]');
title('Stage 1 Speed vs Time');

end