function result = validationEnergyCheck(vehicle, constants, config)
% validationEnergyCheck
% Checks that mechanical energy is conserved in vacuum and decreases when
% drag is applied.

try
    g = getField(constants, 'g', 9.80665);
    m = getField(vehicle, 'mass', 5);
    V0 = getField(vehicle, 'V0', 1800);
    theta = deg2rad(getField(vehicle, 'launchAngle', 25));
    state0 = [0; 0; 1e-6; V0 * cos(theta); 0; V0 * sin(theta)];
    options = odeset('Events', @impactEvent, 'RelTol', 1e-9, 'AbsTol', 1e-11);

    [tv, sv] = ode45(@(~, s) [s(4); s(5); s(6); 0; 0; -g], [0 500], state0, options);
    Ev = energyHistory(sv, m, g);
    vacuumError = max(abs(Ev.total - Ev.total(1))) / max(abs(Ev.total(1)), eps);

    rho = getField(constants, 'rho0', 1.225);
    Cd = getField(vehicle, 'Cd', 0.35);
    S = getField(vehicle, 'area', pi * getField(vehicle, 'diameter', 0.0564)^2 / 4);
    [td, sd] = ode45(@(~, s) dragODE(s, m, Cd, S, rho, g), [0 500], state0, options);
    Ed = energyHistory(sd, m, g);
    dragEnergyLost = Ed.total(1) - Ed.total(end);

    metrics = table(["VacuumMaxRelativeEnergyError";"DragEnergyLost_J"], ...
        [vacuumError; dragEnergyLost], 'VariableNames', {'Metric','Value'});

    result.name = 'Energy check';
    result.metrics = metrics;
    result.vacuum.t = tv;
    result.vacuum.energy = Ev;
    result.drag.t = td;
    result.drag.energy = Ed;
    result.passed = vacuumError < 1e-6 && dragEnergyLost > 0;
    result.message = sprintf('Vacuum relative energy error %.3e, drag energy lost %.3e J.', ...
        vacuumError, dragEnergyLost);
catch ME
    result = failedResult('Energy check', ME.message);
end
end

function E = energyHistory(state, m, g)
V = sqrt(sum(state(:,4:6).^2, 2));
h = max(state(:,3), 0);
E.kinetic = 0.5 * m * V.^2;
E.potential = m * g * h;
E.total = E.kinetic + E.potential;
end

function ds = dragODE(s, m, Cd, S, rho, g)
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
