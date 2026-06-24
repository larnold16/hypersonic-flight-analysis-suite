function text = formatDataTip(results, index)
% formatDataTip
% Returns a compact tooltip string for a trajectory sample.

text = sprintf(['Time: %.3g s\nDownrange: %.3g km\nAltitude: %.3g km\n', ...
    'Velocity: %.3g m/s\nMach: %.3g\nq: %.3g kPa\nDrag: %.3g N\nLift: %.3g N\nTstag: %.3g K'], ...
    valueAt(results, 't', index), valueAt(results, 'x', index) / 1000, ...
    valueAt(results, 'h', index) / 1000, valueAt(results, 'V', index), ...
    valueAt(results, 'Mach', index), valueAt(results, 'q', index) / 1000, ...
    valueAt(results, 'drag', index), valueAt(results, 'lift', index), ...
    valueAtAny(results, {'stagTemp','Tstag'}, index));
end

function value = valueAt(results, fieldName, index)
value = NaN;
if isstruct(results) && isfield(results, fieldName) && isnumeric(results.(fieldName)) && ...
        index >= 1 && index <= numel(results.(fieldName))
    values = results.(fieldName);
    value = values(index);
end
end

function value = valueAtAny(results, names, index)
value = NaN;
for k = 1:numel(names)
    value = valueAt(results, names{k}, index);
    if isfinite(value)
        return;
    end
end
end
