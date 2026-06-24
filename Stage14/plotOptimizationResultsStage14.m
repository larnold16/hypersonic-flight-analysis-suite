function app = plotOptimizationResultsStage14(app, optimization)
% plotOptimizationResultsStage14
% Updates the Optimization Mode tradeoff plots.

if ~isfield(app, 'OptimizationAxes') || isempty(app.OptimizationAxes)
    return;
end
T = optimization.summaryTable;
if isempty(T)
    return;
end

ax = app.OptimizationAxes(1);
cla(ax); hold(ax, 'on'); grid(ax, 'on');
scatter(ax, T.MaxQ_kPa, T.Range_km, 42, double(T.Feasible), 'filled');
xlabel(ax, 'Max dynamic pressure (kPa)');
ylabel(ax, 'Range (km)');
title(ax, 'Feasible Trade Space');
colormap(ax, [0.75 0.15 0.15; 0.10 0.45 0.75]);
styleStage14Axes(ax);

if numel(app.OptimizationAxes) >= 2
    ax = app.OptimizationAxes(2);
    cla(ax); grid(ax, 'on');
    top = T(1:min(5, height(T)), :);
    bar(ax, categorical(top.CaseName), top.ObjectiveValue);
    ylabel(ax, 'Objective value');
    title(ax, 'Top Ranked Cases');
    styleStage14Axes(ax);
end
end
