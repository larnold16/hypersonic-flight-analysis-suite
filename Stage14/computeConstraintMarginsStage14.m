function constraint = computeConstraintMarginsStage14(results, constraints)
% computeConstraintMarginsStage14
% Computes margins and violation intervals for the Stage 14 constraint
% envelope controls.

if nargin < 2 || isempty(constraints)
    constraints = defaultConstraints();
end

rows = {};
rows = addMaxConstraint(rows, results, 'Dynamic pressure', 'q', 1000, ...
    getField(constraints, 'maxQ_kPa', 2000), 'kPa');
rows = addMaxConstraint(rows, results, 'Stagnation temperature', {'stagTemp','Tstag'}, 1, ...
    getField(constraints, 'maxStagTemp_K', 2500), 'K');
rows = addMaxConstraint(rows, results, 'Mach number', 'Mach', 1, ...
    getField(constraints, 'maxMach', 8), 'Mach');
rows = addMaxConstraint(rows, results, 'Load factor', {'gLoad','gLoad_g','normalLoad_g'}, 1, ...
    getField(constraints, 'maxGLoad', 75), 'g');
rows = addMinStaticMargin(rows, results, getField(constraints, 'minStaticMargin_percent', 5));
rows = addMaxConstraint(rows, results, 'Angle of attack', 'alpha_deg', 1, ...
    getField(constraints, 'maxAlpha_deg', 10), 'deg', true);
rows = addMaxConstraint(rows, results, 'Drag force', 'drag', 1, ...
    getField(constraints, 'maxDrag_N', 6000), 'N');
rows = addMaxConstraint(rows, results, 'Lift force', 'lift', 1, ...
    getField(constraints, 'maxLift_N', 2500), 'N', true);

T = cell2table(rows, 'VariableNames', {'Constraint','LimitValue','WorstValue', ...
    'Margin','PassFail','ViolationInterval_s','WorstTime_s','Message'});

constraint = struct();
constraint.table = T;
constraint.allPassed = ~any(strcmpi(string(T.PassFail), "FAIL"));
constraint.violatedConstraints = string(T.Constraint(strcmpi(string(T.PassFail), "FAIL")));
if isempty(constraint.violatedConstraints)
    constraint.violationSummary = "None";
else
    constraint.violationSummary = strjoin(constraint.violatedConstraints, ", ");
end
end

function constraints = defaultConstraints()
constraints.maxQ_kPa = 2000;
constraints.maxStagTemp_K = 2500;
constraints.maxMach = 8;
constraints.maxGLoad = 75;
constraints.minStaticMargin_percent = 5;
constraints.maxAlpha_deg = 10;
constraints.maxDrag_N = 6000;
constraints.maxLift_N = 2500;
end

function rows = addMaxConstraint(rows, results, label, fieldNames, scale, limitValue, units, useAbs)
if nargin < 8
    useAbs = false;
end
[values, available] = seriesField(results, fieldNames);
times = timeSeries(results, numel(values));
if ~available
    rows(end+1, :) = unavailableRow(label, limitValue, units);
    return;
end
values = values(:) ./ scale;
if useAbs
    checkValues = abs(values);
else
    checkValues = values;
end
[worstValue, idx] = max(checkValues, [], 'omitnan');
worstTime = valueAt(times, idx);
margin = limitValue - worstValue;
violation = checkValues > limitValue;
[intervalText, message] = violationMessage(times, checkValues, violation, label, worstValue, units, 'exceeds');
rows(end+1, :) = {string(label), limitValue, worstValue, margin, passFail(~any(violation)), ...
    intervalText, worstTime, message};
end

function rows = addMinStaticMargin(rows, results, limitValue)
[values, available] = seriesField(results, {'staticMargin','staticMarginHistory','minStaticMargin'});
times = timeSeries(results, numel(values));
if ~available
    rows(end+1, :) = unavailableRow('Static margin', limitValue, '%');
    return;
end
values = values(:);
finiteValues = values(isfinite(values));
if ~isempty(finiteValues) && all(abs(finiteValues) < 2)
    values = 100 .* values;
end
[worstValue, idx] = min(values, [], 'omitnan');
worstTime = valueAt(times, idx);
margin = worstValue - limitValue;
violation = values < limitValue;
[intervalText, message] = violationMessage(times, values, violation, 'Static margin', worstValue, '%', 'falls below');
rows(end+1, :) = {"Static margin", limitValue, worstValue, margin, passFail(~any(violation)), ...
    intervalText, worstTime, message};
end

function row = unavailableRow(label, limitValue, units)
row = {string(label), limitValue, NaN, NaN, "UNAVAILABLE", "N/A", NaN, ...
    sprintf('%s requires a higher-fidelity model or an output not present in this run (%s).', label, units)};
end

function [text, message] = violationMessage(times, values, violation, label, worstValue, units, verb)
if any(violation)
    idx = find(violation);
    t0 = valueAt(times, idx(1));
    t1 = valueAt(times, idx(end));
    text = sprintf('%.3f to %.3f', t0, t1);
    message = sprintf('%s %s the selected limit between %.3f s and %.3f s. Worst case %.3f %s.', ...
        label, verb, t0, t1, worstValue, units);
else
    text = "None";
    message = sprintf('%s stays within the selected limit. Worst case %.3f %s.', label, worstValue, units);
end
end

function [values, available] = seriesField(s, names)
if ischar(names) || isstring(names)
    names = cellstr(string(names));
end
values = [];
available = false;
for k = 1:numel(names)
    name = names{k};
    if isstruct(s) && isfield(s, name) && isnumeric(s.(name)) && ~isempty(s.(name))
        values = s.(name)(:);
        available = true;
        return;
    end
end
end

function t = timeSeries(results, n)
if isstruct(results) && isfield(results, 't') && isnumeric(results.t) && numel(results.t) == n
    t = results.t(:);
elseif isstruct(results) && isfield(results, 't') && isnumeric(results.t) && ~isempty(results.t)
    raw = results.t(:);
    t = linspace(raw(1), raw(end), max(n, 1)).';
else
    t = (0:max(n, 1)-1).';
end
end

function value = valueAt(x, idx)
if isempty(x) || idx < 1 || idx > numel(x)
    value = NaN;
else
    value = x(idx);
end
end

function text = passFail(ok)
if ok
    text = "PASS";
else
    text = "FAIL";
end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
