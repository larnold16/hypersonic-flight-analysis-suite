function app = plotSensitivityStage14(app, sensitivity)
% plotSensitivityStage14
% Draws ranked one-at-a-time sensitivity results.

if ~isfield(app, 'SensitivityAxes') || isempty(app.SensitivityAxes) || ~isvalid(app.SensitivityAxes)
    return;
end
ax = app.SensitivityAxes;
cla(ax);
if ~isstruct(sensitivity) || ~isfield(sensitivity, 'rankedTable') || isempty(sensitivity.rankedTable)
    title(ax, 'Sensitivity results unavailable');
    styleStage14Axes(ax);
    return;
end

T = sensitivity.rankedTable;
theme = stage14Theme();
y = categorical(T.Variable);
y = reordercats(y, flip(string(T.Variable)));
scores = flip(T.SensitivityScore);
b = barh(ax, y, scores, 'FaceColor', theme.accent, 'EdgeColor', theme.surface);
if isprop(b, 'FaceAlpha')
    b.FaceAlpha = 0.88;
end
xlabel(ax, 'Average absolute output change (%)');
title(ax, 'Ranked Sensitivity');
grid(ax, 'on');
styleStage14Axes(ax);
end
