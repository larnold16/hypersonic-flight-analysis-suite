function metrics = buildSummaryMetrics(results)
% buildSummaryMetrics
% Converts result fields into dashboard-ready values with units.

events = findPeakEvents(results);
metrics = struct();
metrics.Range = textMetric(safeScalar(results, 'range') / 1000, '%.2f km');
metrics.MaxAltitude = textMetric(safeScalar(results, 'maxAltitude') / 1000, '%.2f km');
metrics.ImpactSpeed = textMetric(safeScalar(results, 'impactSpeed'), '%.1f m/s');
metrics.MaxMach = textMetric(safeScalar(results, 'maxMach'), '%.2f');
metrics.MaxQ = textMetric(safeScalar(results, 'maxQ') / 1000, '%.1f kPa');
metrics.MaxStagnationTemp = textMetric(safeScalar(results, 'maxStagTemp'), '%.0f K');
if ~isfinite(safeScalar(results, 'maxStagTemp')) && isfield(events, 'maxStagnationTemperature')
    metrics.MaxStagnationTemp = textMetric(events.maxStagnationTemperature.value, '%.0f K');
end
metrics.TimeToMaxAltitude = textMetric(events.maxAltitude.time_s, '%.2f s');
metrics.TimeToImpact = textMetric(safeScalar(results, 'timeOfFlight'), '%.2f s');
if isfield(results, 'impactDetected') && results.impactDetected
    metrics.Feasibility = "impact reached";
elseif isfield(results, 'failed') && results.failed
    metrics.Feasibility = "failed";
else
    metrics.Feasibility = "check warnings";
end
metrics.Events = events;
end

function text = textMetric(value, formatSpec)
if isnumeric(value) && isfinite(value)
    text = string(sprintf(formatSpec, value));
else
    text = "N/A";
end
end

function value = safeScalar(s, fieldName)
value = NaN;
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName)) && isnumeric(s.(fieldName))
    value = s.(fieldName)(1);
end
end
