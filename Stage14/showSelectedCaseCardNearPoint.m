function app = showSelectedCaseCardNearPoint(app, ax, x, y, selectedCase)
% showSelectedCaseCardNearPoint
% Draws a compact case card near the selected scatter point.

if isempty(ax) || ~isvalid(ax)
    return;
end
try
    lines = buildCardLines(selectedCase);
    xl = xlim(ax);
    yl = ylim(ax);
    dx = 0.025 * max(diff(xl), eps);
    dy = 0.035 * max(diff(yl), eps);
    tx = min(max(x + dx, xl(1)), xl(2));
    ty = min(max(y + dy, yl(1)), yl(2));
    app.SelectedCaseCard = text(ax, tx, ty, lines, ...
        'BackgroundColor', [1 1 1], ...
        'EdgeColor', [0.1 0.1 0.1], ...
        'Color', [0.05 0.05 0.05], ...
        'Margin', 6, ...
        'FontSize', 9, ...
        'VerticalAlignment', 'bottom', ...
        'HorizontalAlignment', 'left', ...
        'Interpreter', 'none', ...
        'HitTest', 'off');
catch
    app.SelectedCaseCard = gobjects(0);
end
end

function lines = buildCardLines(T)
caseID = getValue(T, 'CaseID');
range = getValue(T, 'Range_km');
altitude = getValue(T, 'MaxAltitude_km');
maxQ = getValue(T, 'MaxQ_kPa');
heating = getValue(T, 'MaxHeating_kW_m2');
score = getValue(T, 'Score');
feasible = getValue(T, 'Feasible');
lines = sprintf(['CaseID: %s\nRange: %s km\nMax altitude: %s km\n', ...
    'Max q: %s kPa\nHeating: %s kW/m^2\nScore: %s\nFeasible: %s'], ...
    caseID, range, altitude, maxQ, heating, score, feasible);
end

function textValue = getValue(T, fieldName)
textValue = "N/A";
try
    if istable(T) && height(T) > 0
        names = string(T.Properties.VariableNames);
        idx = find(strcmpi(names, fieldName), 1);
        if ~isempty(idx)
            value = T.(T.Properties.VariableNames{idx});
            if iscell(value)
                textValue = string(value{1});
            elseif isnumeric(value)
                if isfinite(value(1))
                    textValue = string(sprintf('%.4g', value(1)));
                end
            elseif islogical(value)
                textValue = string(value(1));
            else
                textValue = string(value(1));
            end
        end
    end
catch
    textValue = "N/A";
end
if ismissing(textValue) || strlength(strtrim(textValue)) == 0
    textValue = "N/A";
end
textValue = char(textValue);
end
