function app = plotConstraintEnvelopeStage14(app, results, constraints)
% plotConstraintEnvelopeStage14
% Draws Stage 14 constraint envelope time histories with limit lines and
% highlighted violations.

if ~isfield(app, 'ConstraintAxes') || isempty(app.ConstraintAxes)
    return;
end

specs = {
    'q',          1000, 'Dynamic pressure',      'q (kPa)',   getField(constraints, 'maxQ_kPa', 2000),          false
    {'stagTemp','Tstag'}, 1, 'Stagnation temperature', 'T_0 (K)', getField(constraints, 'maxStagTemp_K', 2500), false
    'Mach',      1,    'Mach number',           'Mach',      getField(constraints, 'maxMach', 8),              false
    {'gLoad','gLoad_g','normalLoad_g'}, 1, 'Load factor', 'g', getField(constraints, 'maxGLoad', 75),          false
    'alpha_deg', 1,    'Angle of attack',       'alpha (deg)', getField(constraints, 'maxAlpha_deg', 10),      true};

for k = 1:min(numel(app.ConstraintAxes), size(specs, 1))
    ax = app.ConstraintAxes(k);
    cla(ax); hold(ax, 'on'); grid(ax, 'on');
    [y, available] = getSeries(results, specs{k, 1});
    if available
        y = y(:) ./ specs{k, 2};
        t = getTime(results, numel(y));
        yCheck = y;
        if specs{k, 6}
            yCheck = abs(yCheck);
        end
        plot(ax, t, y, 'LineWidth', 1.5);
        yline(ax, specs{k, 5}, '--', 'Limit', 'LineWidth', 1.2);
        violation = yCheck > specs{k, 5};
        if any(violation)
            scatter(ax, t(violation), y(violation), 22, [0.80 0.12 0.12], 'filled');
        end
        xlabel(ax, 'Time (s)');
        ylabel(ax, specs{k, 4});
        title(ax, specs{k, 3});
    else
        text(ax, 0.5, 0.5, 'Requires a higher-fidelity output', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center');
        title(ax, specs{k, 3});
    end
    styleStage14Axes(ax);
end
end

function [values, available] = getSeries(s, names)
if ischar(names) || isstring(names)
    names = cellstr(string(names));
end
values = [];
available = false;
for k = 1:numel(names)
    if isstruct(s) && isfield(s, names{k}) && isnumeric(s.(names{k})) && ~isempty(s.(names{k}))
        values = s.(names{k})(:);
        available = true;
        return;
    end
end
end

function t = getTime(results, n)
if isstruct(results) && isfield(results, 't') && isnumeric(results.t) && ~isempty(results.t)
    raw = results.t(:);
    if numel(raw) == n
        t = raw;
    else
        t = linspace(raw(1), raw(end), n).';
    end
else
    t = (0:n-1).';
end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
