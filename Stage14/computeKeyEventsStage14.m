function [events, eventTable] = computeKeyEventsStage14(results)
% computeKeyEventsStage14
% Builds key flight-event data for educational trajectory review.

events = findPeakEvents(results);
eventList = ["launch"; "max altitude"; "max Mach"; "max dynamic pressure"; ...
    "max drag"; "max lift"; "max stagnation temperature"; "max L/D"; "impact"];
eventStructs = {events.launch, events.maxAltitude, events.maxMach, events.maxQ, ...
    events.maxDrag, events.maxLift, events.maxStagnationTemperature, events.maxLD, events.impact};

n = numel(eventStructs);
eventName = strings(n, 1);
time_s = nan(n, 1);
range_km = nan(n, 1);
altitude_km = nan(n, 1);
velocity_mps = nan(n, 1);
mach = nan(n, 1);
q_kPa = nan(n, 1);
drag_N = nan(n, 1);
lift_N = nan(n, 1);
stagTemp_K = nan(n, 1);
flightPathAngle_deg = nan(n, 1);
alpha_deg = nan(n, 1);
LD = nan(n, 1);

for k = 1:n
    eventName(k) = eventList(k);
    ev = eventStructs{k};
    if ~isstruct(ev) || ~isfield(ev, 'valid') || ~ev.valid || ~isfinite(ev.index)
        continue;
    end
    idx = max(1, min(round(ev.index), vectorLength(results)));
    time_s(k) = valueAt(results, 't', idx);
    range_km(k) = valueAt(results, 'x', idx) / 1000;
    altitude_km(k) = valueAt(results, 'h', idx) / 1000;
    velocity_mps(k) = valueAt(results, 'V', idx);
    mach(k) = valueAt(results, 'Mach', idx);
    q_kPa(k) = valueAtAny(results, {'q','qbar'}, idx) / 1000;
    drag_N(k) = valueAt(results, 'drag', idx);
    lift_N(k) = valueAt(results, 'lift', idx);
    stagTemp_K(k) = valueAtAny(results, {'stagTemp','Tstag'}, idx);
    flightPathAngle_deg(k) = valueAtAny(results, {'flightPathAngle_deg','gamma_deg'}, idx);
    alpha_deg(k) = valueAt(results, 'alpha_deg', idx);
    LD(k) = valueAt(results, 'LD', idx);
end

eventTable = table(eventName, time_s, range_km, altitude_km, velocity_mps, mach, ...
    q_kPa, drag_N, lift_N, stagTemp_K, flightPathAngle_deg, alpha_deg, LD, ...
    'VariableNames', {'Event','Time_s','Range_km','Altitude_km','Velocity_mps', ...
    'Mach','DynamicPressure_kPa','Drag_N','Lift_N','StagTemp_K', ...
    'FlightPathAngle_deg','Alpha_deg','LD'});
end

function n = vectorLength(results)
n = 0;
if isstruct(results) && isfield(results, 't') && isnumeric(results.t)
    n = numel(results.t);
end
if n < 1
    n = 1;
end
end

function value = valueAt(results, fieldName, idx)
value = NaN;
if isstruct(results) && isfield(results, fieldName) && isnumeric(results.(fieldName)) && ...
        ~isempty(results.(fieldName)) && idx >= 1 && idx <= numel(results.(fieldName))
    data = results.(fieldName);
    value = data(idx);
end
end

function value = valueAtAny(results, names, idx)
value = NaN;
for k = 1:numel(names)
    value = valueAt(results, names{k}, idx);
    if isfinite(value)
        return;
    end
end
end
