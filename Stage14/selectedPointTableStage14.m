function T = selectedPointTableStage14(results, idx, eventName)
% selectedPointTableStage14
% Exact point/event values shown in the Selected Point Data panel.

if nargin < 3
    eventName = "trajectory point";
end
idx = max(1, min(round(idx), vectorLength(results)));
fields = ["Event"; "Index"; "Time s"; "Range km"; "Altitude km"; ...
    "Velocity m/s"; "Mach"; "Dynamic pressure kPa"; "Drag N"; "Lift N"; ...
    "Stagnation temperature K"; "Flight path angle deg"; "Angle of attack deg"; "L/D"];
values = [
    string(eventName)
    string(idx)
    string(valueAt(results, 't', idx))
    string(valueAt(results, 'x', idx) / 1000)
    string(valueAt(results, 'h', idx) / 1000)
    string(valueAt(results, 'V', idx))
    string(valueAt(results, 'Mach', idx))
    string(valueAtAny(results, {'q','qbar'}, idx) / 1000)
    string(valueAt(results, 'drag', idx))
    string(valueAt(results, 'lift', idx))
    string(valueAtAny(results, {'stagTemp','Tstag'}, idx))
    string(valueAtAny(results, {'flightPathAngle_deg','gamma_deg'}, idx))
    string(valueAt(results, 'alpha_deg', idx))
    string(valueAt(results, 'LD', idx))];
T = table(fields, values, 'VariableNames', {'Quantity','Value'});
end

function n = vectorLength(results)
n = 1;
if isstruct(results) && isfield(results, 't') && isnumeric(results.t) && ~isempty(results.t)
    n = numel(results.t);
end
end

function value = valueAt(results, fieldName, idx)
value = NaN;
if isstruct(results) && isfield(results, fieldName) && isnumeric(results.(fieldName)) && ...
        idx >= 1 && idx <= numel(results.(fieldName))
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
