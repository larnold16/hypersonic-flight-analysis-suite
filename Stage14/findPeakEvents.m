function events = findPeakEvents(results)
% findPeakEvents
% Finds key trajectory events from an existing Stage 11/14 result struct.

events = struct();
events.launch = launchEvent(results);
events.maxAltitude = peakEvent(results, 'h', 'max altitude');
events.maxMach = peakEvent(results, 'Mach', 'max Mach');
events.maxQ = peakEvent(results, 'q', 'max dynamic pressure');
events.maxDrag = peakEvent(results, 'drag', 'max drag');
events.maxLift = peakEvent(results, 'lift', 'max lift');
events.maxStagnationTemperature = peakEventFromValues(firstAvailable(results, {'stagTemp','Tstag','stagnationTemperature_K'}), ...
    results, 'max stagnation temperature');
events.maxLD = peakEvent(results, 'LD', 'max L/D');
events.impact = impactEvent(results);
end

function event = launchEvent(results)
event = makeEmptyEvent('launch');
if ~isstruct(results) || ~isfield(results, 't') || isempty(results.t)
    return;
end
event.index = 1;
event.time_s = safeVectorValue(results, 't', 1);
event.x_m = safeVectorValue(results, 'x', 1);
event.h_m = safeVectorValue(results, 'h', 1);
event.value = safeVectorValue(results, 'V', 1);
event.valid = true;
end

function event = peakEvent(results, fieldName, label)
values = [];
if isstruct(results) && isfield(results, fieldName)
    values = results.(fieldName);
end
event = makeEmptyEvent(label);
if isempty(values) || ~isnumeric(values) || all(~isfinite(values))
    return;
end
[event.value, event.index] = max(values(:), [], 'omitnan');
event.time_s = safeVectorValue(results, 't', event.index);
event.x_m = safeVectorValue(results, 'x', event.index);
event.h_m = safeVectorValue(results, 'h', event.index);
event.valid = true;
end

function event = impactEvent(results)
event = makeEmptyEvent('impact');
if ~isstruct(results) || ~isfield(results, 't') || isempty(results.t)
    return;
end
event.index = numel(results.t);
event.time_s = results.t(end);
event.x_m = safeVectorValue(results, 'x', event.index);
event.h_m = safeVectorValue(results, 'h', event.index);
event.value = safeScalar(results, 'impactSpeed', safeVectorValue(results, 'V', event.index));
event.valid = true;
end

function event = peakEventFromValues(values, results, label)
event = makeEmptyEvent(label);
if isempty(values) || ~isnumeric(values) || all(~isfinite(values))
    return;
end
[event.value, event.index] = max(values(:), [], 'omitnan');
event.time_s = safeVectorValue(results, 't', event.index);
event.x_m = safeVectorValue(results, 'x', event.index);
event.h_m = safeVectorValue(results, 'h', event.index);
event.valid = true;
end

function value = firstAvailable(results, names)
value = [];
if ~isstruct(results)
    return;
end
for k = 1:numel(names)
    if isfield(results, names{k}) && ~isempty(results.(names{k}))
        value = results.(names{k});
        return;
    end
end
end

function event = makeEmptyEvent(label)
event = struct('label', string(label), 'valid', false, 'index', NaN, ...
    'time_s', NaN, 'x_m', NaN, 'h_m', NaN, 'value', NaN);
end

function value = safeVectorValue(s, fieldName, idx)
value = NaN;
if isstruct(s) && isfield(s, fieldName) && isnumeric(s.(fieldName)) && ...
        ~isempty(s.(fieldName)) && isfinite(idx) && idx >= 1 && idx <= numel(s.(fieldName))
    data = s.(fieldName);
    value = data(idx);
end
end

function value = safeScalar(s, fieldName, defaultValue)
value = defaultValue;
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName))
    raw = s.(fieldName);
    if isnumeric(raw)
        value = raw(1);
    end
end
end
