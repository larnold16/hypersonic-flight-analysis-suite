function plotStage10Results(results)
% plotStage10Results
% Creates Stage 10 simplified 6-DOF result plots.

lineWidth = 1.5;
t = results.t;

%% Figure 1: 3D trajectory / position history
figure('Name', 'Stage 10 6-DOF Position History');

subplot(2,2,1);
plot(results.x / 1000, results.z / 1000, 'LineWidth', lineWidth);
hold on;
if isfield(results, 'impactDetected') && results.impactDetected
    plot(results.x(end) / 1000, results.z(end) / 1000, 'o', 'MarkerSize', 7);
    legend('Trajectory', 'Impact', 'Location', 'best');
end
grid on;
xlabel('Downrange [km]');
ylabel('Altitude [km]');
title('x-z Trajectory');

subplot(2,2,2);
plot(results.x / 1000, results.y / 1000, 'LineWidth', lineWidth);
grid on;
xlabel('Downrange x [km]');
ylabel('Lateral y [km]');
title('Ground Track');

subplot(2,2,3);
plot(t, results.z / 1000, 'LineWidth', lineWidth);
hold on;
if isfield(results, 'impactDetected') && results.impactDetected
    plot(results.impactTime_s, results.z(end) / 1000, 'o', 'MarkerSize', 7);
    legend('Altitude', 'Impact', 'Location', 'best');
end
grid on;
xlabel('Time [s]');
ylabel('Altitude [km]');
title('Altitude vs Time');

subplot(2,2,4);
plot(t, results.V, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Speed [m/s]');
title('Speed vs Time');

%% Figure 2: Attitude history
figure('Name', 'Stage 10 Attitude History');

subplot(2,2,1);
plot(t, results.phi_deg, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Roll Angle \phi [deg]');
title('Roll Angle vs Time');

subplot(2,2,2);
plot(t, results.theta_deg, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Pitch Angle \theta [deg]');
title('Pitch Angle vs Time');

subplot(2,2,3);
plot(t, results.psi_deg, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Yaw Angle \psi [deg]');
title('Yaw Angle vs Time');

subplot(2,2,4);
plot(t, results.alpha_deg, 'LineWidth', lineWidth);
hold on;
plot(t, results.beta_deg, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Angle [deg]');
title('Angle of Attack and Sideslip');
legend('\alpha', '\beta', 'Location', 'best');

%% Figure 3: Angular rate history
figure('Name', 'Stage 10 Angular Rate History');

plot(t, results.p_deg_s, 'LineWidth', lineWidth);
hold on;
plot(t, results.q_deg_s, 'LineWidth', lineWidth);
plot(t, results.r_deg_s, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Angular Rate [deg/s]');
title('Body Angular Rates');
legend('p roll rate', 'q pitch rate', 'r yaw rate', 'Location', 'best');

%% Figure 4: Aero/flight condition history
figure('Name', 'Stage 10 Aero and Flight Conditions');

subplot(2,2,1);
plot(t, results.Mach, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Mach Number');
title('Mach vs Time');

subplot(2,2,2);
plot(t, results.qbar_Pa / 1000, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Dynamic Pressure [kPa]');
title('Dynamic Pressure vs Time');

subplot(2,2,3);
plot(t, results.lift_N, 'LineWidth', lineWidth);
hold on;
plot(t, results.drag_N, 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Force [N]');
title('Lift and Drag vs Time');
legend('Lift', 'Drag', 'Location', 'best');

subplot(2,2,4);
plot(t, results.aeroMoments(:,1), 'LineWidth', lineWidth);
hold on;
plot(t, results.aeroMoments(:,2), 'LineWidth', lineWidth);
plot(t, results.aeroMoments(:,3), 'LineWidth', lineWidth);
grid on;
xlabel('Time [s]');
ylabel('Moment [N-m]');
title('Aerodynamic Moments vs Time');
legend('L roll', 'M pitch', 'N yaw', 'Location', 'best');

end
