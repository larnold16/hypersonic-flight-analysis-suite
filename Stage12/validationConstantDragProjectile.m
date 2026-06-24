function result = validationConstantDragProjectile(vehicle, constants, config)
% validationConstantDragProjectile
% Runs a simple constant-density/constant-Cd drag case and compares it with
% Stage 1 when Stage 1 is available on the MATLAB path.

try
    g = getField(constants, 'g', 9.80665);
    rho = getField(constants, 'rho0', 1.225);
    V0 = getField(vehicle, 'V0', 1800);
    theta = deg2rad(getField(vehicle, 'launchAngle', 25));
    Cd = getField(vehicle, 'Cd', 0.35);
    S = getField(vehicle, 'area', pi * getField(vehicle, 'diameter', 0.0564)^2 / 4);
    m = getField(vehicle, 'mass', 5);

    state0 = [0; 0; 1e-6; V0 * cos(theta); 0; V0 * sin(theta)];
    options = odeset('Events', @impactEvent, 'RelTol', 1e-8, 'AbsTol', 1e-10);
    [t, state] = ode45(@(~, s) constantDragODE(s, m, Cd, S, rho, g), [0 500], state0, options);
    simple.range = state(end,1);
    simple.maxAltitude = max(state(:,3));
    simple.impactSpeed = norm(state(end,4:6));
    simple.timeOfFlight = t(end);

    if exist('runStage1', 'file') == 2 && exist('postProcess_stage1', 'file') == 2
        [t1, state1] = runStage1(vehicle, constants);
        r1 = postProcess_stage1(t1, state1, vehicle, constants);
        reference = [r1.range, r1.maxAltitude, r1.impactSpeed, t1(end)];
        note = 'Compared against available Stage 1 exponential-density drag model.';
    else
        reference = [NaN NaN NaN NaN];
        note = 'Stage 1 was not on the path; constant-drag case ran without Stage 1 comparison.';
    end

    simpleValues = [simple.range, simple.maxAltitude, simple.impactSpeed, simple.timeOfFlight];
    difference = simpleValues - reference;
    metrics = table(["Range";"MaxAltitude";"ImpactSpeed";"TimeOfFlight"], ...
        simpleValues(:), reference(:), difference(:), ...
        'VariableNames', {'Metric','ConstantDrag','Stage1Reference','Difference'});

    result.name = 'Constant drag projectile';
    result.metrics = metrics;
    result.t = t;
    result.state = state;
    result.passed = all(isfinite(simpleValues)) && simple.range > 0 && simple.maxAltitude > 0;
    result.message = note;
catch ME
    result = failedResult('Constant drag projectile', ME.message);
end
end

function ds = constantDragODE(s, m, Cd, S, rho, g)
v = s(4:6);
V = norm(v);
D = 0.5 * rho * V^2 * Cd * S;
if V > 1e-8
    accelDrag = -D / m * v / V;
else
    accelDrag = [0; 0; 0];
end
ds = [v; accelDrag + [0; 0; -g]];
end

function result = failedResult(name, message)
result.name = name;
result.metrics = table();
result.passed = false;
result.message = message;
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
