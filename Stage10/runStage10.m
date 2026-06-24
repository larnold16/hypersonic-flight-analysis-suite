function results6dof = runStage10(vehicle, constants, stage10Config)
% runStage10
% Runs a simplified flat-Earth 6-DOF flight dynamics prototype.
%
% This is an optional engineering demonstration of coupled translational and
% rotational motion. It is not validated, does not replace the Stage 4
% point-mass model, and should not be used as a flight-qualified simulation.

if nargin < 3
    stage10Config = struct();
end

if ~isfield(stage10Config, 'verbose')
    stage10Config.verbose = true;
end

if ~isfield(stage10Config, 'showPlots')
    stage10Config.showPlots = true;
end

if ~isfield(stage10Config, 'tFinal_s')
    stage10Config.tFinal_s = 300;
end

if ~isfield(stage10Config, 'mode')
    if stage10Config.verbose
        printStage10Menu();
    end
    stage10Config.mode = promptWithDefault('Select Stage 10 option', 1);
end

if isempty(stage10Config.mode) || isnan(stage10Config.mode) || ...
        stage10Config.mode < 1 || stage10Config.mode > 2
    warning('Stage10:InvalidMenuSelection', ...
        'Invalid Stage 10 option. Running the single baseline 6-DOF case.');
    stage10Config.mode = 1;
end

stage10Config.mode = round(stage10Config.mode);

if stage10Config.mode == 2
    results6dof = runStage10LaunchAngleSweep_stage10(vehicle, constants, stage10Config);
    return;
end

vehicle6dof = get6DOFVehicle_stage10(vehicle);

launchAngle_rad = deg2rad(vehicle.launchAngle);
initialYaw_rad = deg2rad(getVehicleField(vehicle6dof, 'initialYaw_deg', 0));

speed0 = vehicle.V0;
u0 = speed0;
v0 = 0;
w0 = 0;

phi0 = deg2rad(getVehicleField(vehicle6dof, 'initialRoll_deg', 0));
theta0 = launchAngle_rad;
psi0 = initialYaw_rad;
p0 = deg2rad(getVehicleField(vehicle6dof, 'initialRollRate_deg_s', 0));
q0 = deg2rad(getVehicleField(vehicle6dof, 'initialPitchRate_deg_s', 0));
r0 = deg2rad(getVehicleField(vehicle6dof, 'initialYawRate_deg_s', 0));

z0 = max(getConstantField(constants, 'launchAlt', 0), 0) + 1e-3;
state0 = [0; 0; z0; u0; v0; w0; phi0; theta0; psi0; p0; q0; r0];

options = odeset( ...
    'Events', @groundEvent_stage10, ...
    'RelTol', 1e-7, ...
    'AbsTol', 1e-9, ...
    'MaxStep', 0.05);

[t, state, te, ye, ie] = ode45(@(t, state) projectile6DOF_ODE_stage10(t, state, vehicle6dof, constants), ...
    [0, stage10Config.tFinal_s], state0, options);

impactDetected = ~isempty(te) && any(ie == 1);
results6dof = postProcessStage10(t, state, vehicle6dof, constants, ...
    impactDetected, te, ye, stage10Config.tFinal_s);
results6dof.vehicle = vehicle6dof;
results6dof.initialState = state0;
results6dof.modelNote = ['Simplified 6-DOF prototype using approximate force/moment ', ...
    'coefficients; not validated against CFD, wind tunnel, or flight data.'];

printStage10Summary(results6dof, vehicle6dof, stage10Config.verbose);

if stage10Config.showPlots
    plotStage10Results(results6dof);
end

end

function printStage10Menu()
fprintf('Stage 10 Menu:\n');
fprintf('  1 = Run single 6-DOF baseline case\n');
fprintf('  2 = Run small 6-DOF launch-angle sweep\n\n');
end

function results = postProcessStage10(t, state, vehicle, constants, ...
        impactDetected, te, ye, tFinal_s)
n = numel(t);

V = zeros(n, 1);
Mach = zeros(n, 1);
alpha_deg = zeros(n, 1);
beta_deg = zeros(n, 1);
qbar = zeros(n, 1);
lift = zeros(n, 1);
drag = zeros(n, 1);
forces = zeros(n, 3);
moments = zeros(n, 3);

for k = 1:n
    aero = computeAeroForcesMoments_stage10(t(k), state(k,:).', vehicle, constants);
    V(k) = aero.V;
    Mach(k) = aero.Mach;
    alpha_deg(k) = rad2deg(aero.alpha_rad);
    beta_deg(k) = rad2deg(aero.beta_rad);
    qbar(k) = aero.qbar;
    lift(k) = aero.lift_N;
    drag(k) = aero.drag_N;
    forces(k,:) = aero.forceBody_N.';
    moments(k,:) = aero.momentBody_Nm.';
end

phi_deg = rad2deg(state(:,7));
theta_deg = rad2deg(state(:,8));
psi_deg = rad2deg(state(:,9));
p_deg_s = rad2deg(state(:,10));
q_deg_s = rad2deg(state(:,11));
r_deg_s = rad2deg(state(:,12));

attitudeBound_deg = 85;
rateBound_deg_s = 720;
attitudeBounded = max(abs(theta_deg)) < attitudeBound_deg && ...
    max(abs(phi_deg)) < attitudeBound_deg && ...
    max(abs(beta_deg)) < 45;
ratesBounded = max(abs([p_deg_s; q_deg_s; r_deg_s])) < rateBound_deg_s;

results.t = t;
results.state = state;
results.x = state(:,1);
results.y = state(:,2);
results.z = state(:,3);
results.V = V;
results.Mach = Mach;
results.qbar_Pa = qbar;
results.alpha_deg = alpha_deg;
results.beta_deg = beta_deg;
results.phi_deg = phi_deg;
results.theta_deg = theta_deg;
results.psi_deg = psi_deg;
results.p_deg_s = p_deg_s;
results.q_deg_s = q_deg_s;
results.r_deg_s = r_deg_s;
results.aeroForces = forces;
results.aeroMoments = moments;
results.lift_N = lift;
results.drag_N = drag;
results.maxAltitude_m = max(state(:,3));
results.downrange_m = sqrt(state(end,1).^2 + state(end,2).^2);
results.finalSpeed_mps = V(end);
results.maxMach = max(Mach);
results.maxAlpha_deg = max(abs(alpha_deg));
results.maxPitchRate_deg_s = max(abs(q_deg_s));
results.maxYawRate_deg_s = max(abs(r_deg_s));
results.maxRollRate_deg_s = max(abs(p_deg_s));
results.attitudeRemainedBounded = attitudeBounded && ratesBounded;
results.attitudeWithinPresetBounds = results.attitudeRemainedBounded;
results.impactDetected = impactDetected;
results.finalTime_s = t(end);
results.finalAltitude_m = state(end,3);
results.maxAllowedSimulationTime_s = tFinal_s;

if impactDetected
    impactState = ye(end,:).';
    impactAero = computeAeroForcesMoments_stage10(te(end), impactState, vehicle, constants);

    results.impactTime_s = te(end);
    results.impactRange_m = sqrt(impactState(1).^2 + impactState(2).^2);
    results.impactLateral_m = impactState(2);
    results.impactSpeed_mps = impactAero.V;
    results.impactMach = impactAero.Mach;
else
    results.impactTime_s = NaN;
    results.impactRange_m = NaN;
    results.impactLateral_m = NaN;
    results.impactSpeed_mps = NaN;
    results.impactMach = NaN;
end

results.constants = constants;
end

function printStage10Summary(results, vehicle, verbose)
if ~verbose
    return;
end

fprintf('Stage 10 Simplified 6-DOF Prototype Summary:\n');
fprintf('This is an approximate engineering prototype, not a validated flight dynamics simulation.\n\n');

fprintf('Initial conditions:\n');
fprintf('  Initial speed: %.2f m/s\n', results.V(1));
fprintf('  Initial pitch angle: %.2f deg\n', results.theta_deg(1));
fprintf('  Initial yaw angle: %.2f deg\n', results.psi_deg(1));
fprintf('  Initial angular rates p/q/r: %.2f / %.2f / %.2f deg/s\n\n', ...
    results.p_deg_s(1), results.q_deg_s(1), results.r_deg_s(1));

fprintf('Vehicle properties:\n');
fprintf('  Mass: %.3f kg\n', vehicle.mass);
fprintf('  Length: %.4f m\n', vehicle.length);
fprintf('  Diameter: %.4f m\n', vehicle.diameter);
fprintf('  Inertia Ix/Iy/Iz: %.5f / %.5f / %.5f kg-m^2\n', ...
    vehicle.Ix, vehicle.Iy, vehicle.Iz);
fprintf('  CG location: %.4f m\n', vehicle.cgLocation_m);
fprintf('  CP location: %.4f m\n', vehicle.cpLocation_m);
fprintf('  Static margin: %.2f %% body length\n\n', ...
    100 * vehicle.staticMargin);

fprintf('6-DOF results:\n');
fprintf('  Maximum altitude: %.2f m\n', results.maxAltitude_m);
if results.impactDetected
    fprintf('  Impact detected: yes\n');
    fprintf('  Impact time: %.2f s\n', results.impactTime_s);
    fprintf('  Impact downrange distance: %.2f m\n', results.impactRange_m);
    fprintf('  Impact lateral displacement: %.2f m\n', results.impactLateral_m);
    fprintf('  Impact speed: %.2f m/s\n', results.impactSpeed_mps);
    fprintf('  Impact Mach number: %.2f\n', results.impactMach);
else
    fprintf('  Impact detected: no\n');
    fprintf('  Final simulation time: %.2f s\n', results.finalTime_s);
    fprintf('  Final altitude: %.2f m\n', results.finalAltitude_m);
    fprintf('  Final speed: %.2f m/s\n', results.finalSpeed_mps);
    fprintf('  Note: ground impact was not reached before the %.2f s maximum simulation time.\n', ...
        results.maxAllowedSimulationTime_s);
end
fprintf('  Maximum Mach: %.2f\n', results.maxMach);
fprintf('  Maximum angle of attack: %.2f deg\n', results.maxAlpha_deg);
fprintf('  Maximum pitch rate: %.2f deg/s\n', results.maxPitchRate_deg_s);
fprintf('  Maximum yaw rate: %.2f deg/s\n', results.maxYawRate_deg_s);
fprintf('  Maximum roll rate: %.2f deg/s\n', results.maxRollRate_deg_s);
fprintf('  Attitude remained within preset bounds during the simplified simulation: %s\n\n', ...
    yesNo(results.attitudeWithinPresetBounds));

fprintf('Assumptions: flat Earth, no propulsion, no active guidance/control, approximate aero moments,\n');
fprintf('and simple damping derivatives. Future work: control surfaces, full derivative tables,\n');
fprintf('sensor/actuator dynamics, guidance laws, and CFD/wind-tunnel/flight validation.\n\n');
end

function [value, isterminal, direction] = groundEvent_stage10(t, state)
if t < 1e-6
    value = 1.0;
else
    value = state(3);
end
isterminal = 1;
direction = -1;
end

function text = yesNo(value)
if value
    text = 'yes';
else
    text = 'no';
end
end

function value = getVehicleField(vehicle, fieldName, defaultValue)
if isfield(vehicle, fieldName) && ~isempty(vehicle.(fieldName))
    value = vehicle.(fieldName);
else
    value = defaultValue;
end
end

function value = getConstantField(constants, fieldName, defaultValue)
if isfield(constants, fieldName) && ~isempty(constants.(fieldName))
    value = constants.(fieldName);
else
    value = defaultValue;
end
end
