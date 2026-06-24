function result = validationVacuumProjectile(vehicle, constants, config)
% validationVacuumProjectile
% Validates the integrator and impact event against closed-form projectile
% motion with no drag and constant gravity.

try
    g = getField(constants, 'g', getField(constants, 'g0', 9.80665));
    V0 = getField(vehicle, 'V0', 1800);
    theta = deg2rad(getField(vehicle, 'launchAngle', 25));

    state0 = [0; 0; 1e-6; V0 * cos(theta); 0; V0 * sin(theta)];
    options = odeset('Events', @impactEvent, 'RelTol', 1e-10, 'AbsTol', 1e-12);
    [t, state] = ode45(@(~, s) [s(4); s(5); s(6); 0; 0; -g], [0 500], state0, options);

    x = state(:,1);
    h = max(state(:,3), 0);
    V = sqrt(sum(state(:,4:6).^2, 2));

    analyticalRange = V0^2 * sin(2 * theta) / g;
    analyticalMaxAltitude = (V0 * sin(theta))^2 / (2 * g);
    analyticalTime = 2 * V0 * sin(theta) / g;
    analyticalImpactSpeed = V0;

    numeric = [x(end), max(h), t(end), V(end)];
    analytical = [analyticalRange, analyticalMaxAltitude, analyticalTime, analyticalImpactSpeed];
    percentError = 100 * abs(numeric - analytical) ./ max(abs(analytical), eps);

    metrics = table(["Range";"MaxAltitude";"TimeOfFlight";"ImpactSpeed"], ...
        numeric(:), analytical(:), percentError(:), ...
        'VariableNames', {'Metric','Numerical','Analytical','PercentError'});

    result.name = 'Vacuum projectile';
    result.metrics = metrics;
    result.t = t;
    result.state = state;
    result.passed = all(percentError < [0.05 0.05 0.05 0.05]);
    result.message = sprintf('Max error %.4f%%.', max(percentError));
catch ME
    result = failedResult('Vacuum projectile', ME.message);
end
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
