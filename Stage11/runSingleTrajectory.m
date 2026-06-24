function results = runSingleTrajectory(vehicle, constants, config)
% runSingleTrajectory
% Runs one Stage 11 trajectory until ground impact or the time limit.
%
% 3-DOF state: [x; y; h; vx; vy; vh]
% 6-DOF state: [x; y; h; u; v; w; phi; theta; psi; p; q; r]
%
% All Stage 11 post-processing is performed here so Stage 12 and Stage 13
% can reuse one stable interface.

if nargin < 3
    config = buildStage11Config(vehicle, constants, struct('showPlots', false));
end

vehicle = validateVehicleInputs(buildVehicleFromGeometry_stage11(vehicle, ...
    getVehicleField(vehicle, 'bodyType', 'Custom baseline')));

try
    if strcmpi(config.dofMode, '6DOF')
        [t, state, te, ye, ie] = propagate6DOF(vehicle, constants, config);
    else
        [t, state, te, ye, ie] = propagate3DOF(vehicle, constants, config);
    end

    impactDetected = ~isempty(te) && any(ie == 1);
    results = postProcessStage11(t, state, vehicle, constants, config, impactDetected, te, ye);
    results.failed = false;
    results.failureMessage = '';
catch ME
    warning('Stage11:TrajectoryFailed', 'Stage 11 trajectory failed: %s', ME.message);
    results = failedResult(vehicle, config, ME.message);
end

end

function [t, state, te, ye, ie] = propagate3DOF(vehicle, constants, config)
gamma0 = deg2rad(config.launchAngle_deg);
yaw0 = deg2rad(config.launchYaw_deg);
V0 = max(config.launchSpeed_mps, 1);

x0 = 0;
y0 = 0;
h0 = max(config.initialAltitude_m, 0) + 1e-3;
vx0 = V0 * cos(gamma0) * cos(yaw0);
vy0 = V0 * cos(gamma0) * sin(yaw0);
vh0 = V0 * sin(gamma0);
state0 = [x0; y0; h0; vx0; vy0; vh0];

options = odeset('Events', @impactEvent, ...
    'RelTol', config.relTol, ...
    'AbsTol', config.absTol, ...
    'MaxStep', config.maxStep_s);

[t, state, te, ye, ie] = ode45(@(t, s) trajectoryODE_3DOF_stage11(t, s, vehicle, constants, config), ...
    [0, config.tFinal_s], state0, options);
end

function [t, state, te, ye, ie] = propagate6DOF(vehicle, constants, config)
gamma0 = deg2rad(config.launchAngle_deg);
yaw0 = deg2rad(config.launchYaw_deg);
V0 = max(config.launchSpeed_mps, 1);

x0 = 0;
y0 = 0;
h0 = max(config.initialAltitude_m, 0) + 1e-3;
u0 = V0;
v0 = 0;
w0 = 0;
phi0 = 0;
theta0 = gamma0;
psi0 = yaw0;
p0 = deg2rad(getConfigField(config, 'initialP_deg_s', 0));
q0 = deg2rad(getConfigField(config, 'initialQ_deg_s', 0));
r0 = deg2rad(getConfigField(config, 'initialR_deg_s', 0));
state0 = [x0; y0; h0; u0; v0; w0; phi0; theta0; psi0; p0; q0; r0];

if getConfigField(config, 'debug6DOFInitialPrint', false) || getConfigField(config, 'verbose', false)
    inertial0 = eulerBodyToInertial_stage11(phi0, theta0, psi0) * [u0; v0; w0];
    fprintf('Stage 11 6-DOF initial condition check:\n');
    fprintf('  V0 = %.6g m/s, launch angle = %.6g deg, theta0 = %.6g deg\n', ...
        V0, config.launchAngle_deg, rad2deg(theta0));
    fprintf('  body velocity [u v w] = [%.6g %.6g %.6g] m/s\n', u0, v0, w0);
    fprintf('  inertial velocity [vx vy vh] = [%.6g %.6g %.6g] m/s\n', ...
        inertial0(1), inertial0(2), inertial0(3));
end

options = odeset('Events', @impactEvent, ...
    'RelTol', max(config.relTol, 1e-6), ...
    'AbsTol', max(config.absTol, 1e-8), ...
    'MaxStep', min(config.maxStep_s, 0.05));

[t, state, te, ye, ie] = ode45(@(t, s) trajectoryODE_6DOF_stage11(t, s, vehicle, constants, config), ...
    [0, min(config.tFinal_s, 300)], state0, options);
end

function results = postProcessStage11(t, state, vehicle, constants, config, impactDetected, te, ye)
n = numel(t);
is6 = size(state, 2) >= 12;

x = state(:,1);
y = state(:,2);
h = max(state(:,3), 0);

if is6
    bodyVelocity = state(:,4:6);
    V = sqrt(sum(bodyVelocity.^2, 2));
    vx = zeros(n, 1);
    vy = zeros(n, 1);
    vh = zeros(n, 1);
    alpha = zeros(n, 1);
    beta = zeros(n, 1);
    for k = 1:n
        phi = state(k,7);
        theta = state(k,8);
        psi = state(k,9);
        Cbi = eulerBodyToInertial_stage11(phi, theta, psi);
        inertialV = Cbi * bodyVelocity(k,:).';
        vx(k) = inertialV(1);
        vy(k) = inertialV(2);
        vh(k) = inertialV(3);
        if V(k) > 1e-8
            alpha(k) = atan2(bodyVelocity(k,3), max(abs(bodyVelocity(k,1)), 1e-8));
            beta(k) = asin(max(-1, min(1, bodyVelocity(k,2) / V(k))));
        end
    end
else
    vx = state(:,4);
    vy = state(:,5);
    vh = state(:,6);
    inertialVelocity = [vx, vy, vh];
    V = sqrt(sum(inertialVelocity.^2, 2));
    alpha = deg2rad(getVehicleField(vehicle, 'alpha_deg', 2.0)) * ones(n, 1);
    beta = zeros(n, 1);
end

Mach = zeros(n, 1);
qbar = zeros(n, 1);
drag = zeros(n, 1);
lift = zeros(n, 1);
sideForce = zeros(n, 1);
CD = zeros(n, 1);
CL = zeros(n, 1);
CY = zeros(n, 1);
LD = zeros(n, 1);
rho = zeros(n, 1);
temperature = zeros(n, 1);
pressure = zeros(n, 1);
speedSound = zeros(n, 1);
mu = zeros(n, 1);
gravity = zeros(n, 1);
stagTemp = zeros(n, 1);
heatRate = zeros(n, 1);
reynolds = zeros(n, 1);
ballisticCoefficient = zeros(n, 1);
staticMargin = zeros(n, 1);
gLoad = zeros(n, 1);
axialAccel = zeros(n, 1);
normalAccel = zeros(n, 1);
kineticEnergy = zeros(n, 1);
potentialEnergy = zeros(n, 1);

for k = 1:n
    hk = max(h(k), 0);
    [T, P, r, a, muk] = atmosphere1976_simple(hk);
    T = T * config.environment.temperatureMultiplier;
    r = r * config.environment.densityMultiplier;
    a = sqrt(1.4 * 287.05 * max(T, 1));

    temperature(k) = T;
    pressure(k) = P;
    rho(k) = r;
    speedSound(k) = a;
    mu(k) = muk;

    gravity(k) = getGravity(hk, constants);
    Mach(k) = V(k) / max(a, 1e-8);
    qbar(k) = 0.5 * r * V(k)^2;

    atmosphere.T = T;
    atmosphere.P = P;
    atmosphere.rho = r;
    atmosphere.a = a;
    atmosphere.mu = muk;
    aero = aeroModel_stage11(Mach(k), alpha(k), beta(k), vehicle, atmosphere);
    heat = heatingModel_stage11(r, V(k), vehicle, constants, Mach(k), T);
    stability = stabilityModel_stage11(vehicle);

    CD(k) = aero.CD;
    CL(k) = aero.CL;
    CY(k) = aero.CY;
    LD(k) = aero.LD;
    drag(k) = qbar(k) * vehicle.referenceArea * aero.CD;
    lift(k) = qbar(k) * vehicle.referenceArea * aero.CL;
    sideForce(k) = qbar(k) * vehicle.referenceArea * aero.CY;
    stagTemp(k) = heat.stagnationTemperature_K;
    heatRate(k) = heat.heatRate_W_m2;
    reynolds(k) = r * V(k) * vehicle.length / max(muk, 1e-12);
    ballisticCoefficient(k) = vehicle.mass / max(aero.CD * vehicle.referenceArea, eps);
    staticMargin(k) = stability.staticMargin;
    axialAccel(k) = drag(k) / max(vehicle.mass, eps);
    normalAccel(k) = sqrt(lift(k)^2 + sideForce(k)^2) / max(vehicle.mass, eps);
    gLoad(k) = sqrt(axialAccel(k)^2 + normalAccel(k)^2) / 9.80665;
    kineticEnergy(k) = 0.5 * vehicle.mass * V(k)^2;
    potentialEnergy(k) = vehicle.mass * gravity(k) * h(k);
end

heatLoad = cumtrapz(t, heatRate);
flightPathAngle = atan2(vh, sqrt(vx.^2 + vy.^2));

results.t = t;
results.state = state;
results.x = x;
results.y = y;
results.h = h;
results.vx = vx;
results.vy = vy;
results.vh = vh;
results.vx_inertial = vx;
results.vy_inertial = vy;
results.vh_inertial = vh;
results.V = V;
results.flightPathAngle_deg = rad2deg(flightPathAngle);
results.gamma_deg = results.flightPathAngle_deg;
results.Mach = Mach;
results.q = qbar;
results.qbar = qbar;
results.drag = drag;
results.lift = lift;
results.sideForce = sideForce;
results.CD = CD;
results.Cd = CD;
results.CL = CL;
results.CY = CY;
results.LD = LD;
results.alpha_deg = rad2deg(alpha);
results.beta_deg = rad2deg(beta);
results.temperature = temperature;
results.pressure = pressure;
results.rho = rho;
results.speedSound = speedSound;
results.dynamicViscosity = mu;
results.gravity = gravity;
results.stagTemp = stagTemp;
results.Tstag = stagTemp;
results.heatingRate = heatRate;
results.heatLoad = heatLoad;
results.reynolds = reynolds;
results.ballisticCoefficient = ballisticCoefficient;
results.staticMargin = staticMargin;
results.axialAccel_mps2 = axialAccel;
results.normalAccel_mps2 = normalAccel;
results.gLoad = gLoad;
results.kineticEnergy = kineticEnergy;
results.potentialEnergy = potentialEnergy;
results.totalEnergy = kineticEnergy + potentialEnergy;

results.range = sqrt(x(end)^2 + y(end)^2);
results.downrange = x(end);
results.crossrange = y(end);
results.maxAltitude = max(h);
results.timeOfFlight = t(end);
results.impactSpeed = V(end);
results.maxMach = max(Mach);
results.maxQ = max(qbar);
results.maxDrag = max(drag);
results.maxLift = max(lift);
results.maxCD = max(CD);
results.maxCL = max(CL);
results.maxLD = max(LD);
results.maxStagTemp = max(stagTemp);
results.maxHeatingRate = max(heatRate);
results.totalHeatLoad = heatLoad(end);
results.maxGLoad = max(gLoad);
results.maxAlpha_deg = max(abs(results.alpha_deg));
results.maxBeta_deg = max(abs(results.beta_deg));
results.minStaticMargin = min(staticMargin);
results.maxStaticMargin = max(staticMargin);
results.impactDetected = impactDetected;
results.impactEventTime = getImpactTime(te);
results.impactEventState = ye;
results.dofMode = config.dofMode;
results.vehicle = vehicle;
results.warnings = buildWarnings(results, config);

if is6
    results.u = state(:,4);
    results.v = state(:,5);
    results.w = state(:,6);
    results.phi = state(:,7);
    results.theta = state(:,8);
    results.psi = state(:,9);
    results.p = state(:,10);
    results.q_rate = state(:,11);
    results.r = state(:,12);
    results.phi_deg = rad2deg(state(:,7));
    results.theta_deg = rad2deg(state(:,8));
    results.psi_deg = rad2deg(state(:,9));
    results.p_deg_s = rad2deg(state(:,10));
    results.q_deg_s = rad2deg(state(:,11));
    results.r_deg_s = rad2deg(state(:,12));
end
end

function warningsOut = buildWarnings(results, config)
warningsOut = {};
limits = config.warningLimits;

if results.maxQ > limits.maxQ_Pa
    warningsOut{end+1} = sprintf('Max dynamic pressure %.1f kPa exceeds %.1f kPa.', ...
        results.maxQ / 1000, limits.maxQ_Pa / 1000);
end
if results.maxHeatingRate > limits.maxHeating_W_m2
    warningsOut{end+1} = sprintf('Max heating rate %.1f kW/m^2 exceeds %.1f kW/m^2.', ...
        results.maxHeatingRate / 1000, limits.maxHeating_W_m2 / 1000);
end
if results.totalHeatLoad > limits.maxHeatLoad_J_m2
    warningsOut{end+1} = sprintf('Total heat load %.1f MJ/m^2 exceeds %.1f MJ/m^2.', ...
        results.totalHeatLoad / 1e6, limits.maxHeatLoad_J_m2 / 1e6);
end
if results.minStaticMargin < limits.minStaticMargin
    warningsOut{end+1} = sprintf('Static margin %.1f%% is below the %.1f%% lower limit.', ...
        100 * results.minStaticMargin, 100 * limits.minStaticMargin);
end
if results.maxStaticMargin > limits.maxStaticMargin
    warningsOut{end+1} = sprintf('Static margin %.1f%% is above the %.1f%% stiffness guideline.', ...
        100 * results.maxStaticMargin, 100 * limits.maxStaticMargin);
end
if results.maxGLoad > limits.maxGLoad
    warningsOut{end+1} = sprintf('Peak g-load %.1f g exceeds %.1f g.', ...
        results.maxGLoad, limits.maxGLoad);
end
if ~results.impactDetected
    warningsOut{end+1} = 'Ground impact was not reached before the simulation time limit.';
end
numericFields = {'x','y','h','V','Mach','q','heatingRate','gLoad'};
for k = 1:numel(numericFields)
    values = results.(numericFields{k});
    if any(~isfinite(values))
        warningsOut{end+1} = ['NaN or Inf detected in ', numericFields{k}, '.'];
        break;
    end
end
if isempty(warningsOut)
    warningsOut = {};
end
end

function results = failedResult(vehicle, config, message)
results.t = 0;
results.state = [];
results.x = 0;
results.y = 0;
results.h = 0;
results.V = 0;
results.range = NaN;
results.maxAltitude = NaN;
results.timeOfFlight = NaN;
results.impactSpeed = NaN;
results.maxMach = NaN;
results.maxQ = NaN;
results.maxStagTemp = NaN;
results.maxHeatingRate = NaN;
results.totalHeatLoad = NaN;
results.maxGLoad = NaN;
results.maxAlpha_deg = NaN;
results.maxBeta_deg = NaN;
results.maxCL = NaN;
results.maxCD = NaN;
results.maxLD = NaN;
results.minStaticMargin = NaN;
results.impactDetected = false;
results.failed = true;
results.failureMessage = message;
results.vehicle = vehicle;
results.dofMode = config.dofMode;
results.warnings = {['Solver failure: ', message]};
end

function g = getGravity(h, constants)
if isfield(constants, 'g0') && isfield(constants, 'Re')
    g = constants.g0 * (constants.Re / (constants.Re + max(h, 0)))^2;
elseif isfield(constants, 'g')
    g = constants.g;
else
    g = 9.80665;
end
end

function value = getImpactTime(te)
if isempty(te)
    value = NaN;
else
    value = te(end);
end
end

function value = getVehicleField(vehicle, fieldName, defaultValue)
if isfield(vehicle, fieldName) && ~isempty(vehicle.(fieldName))
    value = vehicle.(fieldName);
else
    value = defaultValue;
end
end

function value = getConfigField(config, fieldName, defaultValue)
if isstruct(config) && isfield(config, fieldName) && ~isempty(config.(fieldName))
    value = config.(fieldName);
else
    value = defaultValue;
end
end
