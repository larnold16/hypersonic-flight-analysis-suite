function fig = plotParetoResults(pareto, config)
% plotParetoResults
% Plots selected Pareto fronts.

T = pareto.summaryTable;
fig = figure('Name', 'Stage 13 Pareto Results', 'Visible', config.figureVisible);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
plotFront(T, pareto.rangeHeatingFront, 'range_m', 'maxHeating_W_m2', 'Range (km)', 'Heating (kW/m^2)', 1000, 1000, 'Range vs Heating');
plotFront(T, pareto.rangeQFront, 'range_m', 'maxQ_Pa', 'Range (km)', 'Max q (kPa)', 1000, 1000, 'Range vs Max q');
plotFront(T, pareto.altitudeHeatingFront, 'maxAltitude_m', 'maxHeating_W_m2', 'Altitude (km)', 'Heating (kW/m^2)', 1000, 1000, 'Altitude vs Heating');
plotFront(T, pareto.scoreHeatingFront, 'score', 'maxHeating_W_m2', 'Score', 'Heating (kW/m^2)', 1, 1000, 'Score vs Heating');
saveas(fig, fullfile(config.figureDir, 'Stage13_ParetoResults.png'));
end

function plotFront(T, F, xField, yField, xlab, ylab, xScale, yScale, titleText)
nexttile; hold on; grid on;
scatter(T.(xField) / xScale, T.(yField) / yScale, 20, [0.65 0.65 0.65], 'filled');
if ~isempty(F)
    scatter(F.(xField) / xScale, F.(yField) / yScale, 38, 'r', 'filled');
end
xlabel(xlab); ylabel(ylab); title(titleText); legend('All','Pareto','Location','best');
end
