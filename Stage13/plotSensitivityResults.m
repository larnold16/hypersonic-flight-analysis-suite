function fig = plotSensitivityResults(sensitivity, config)
% plotSensitivityResults
% Creates tornado-style sensitivity charts.

fig = figure('Name', 'Stage 13 Sensitivity Results', 'Visible', config.figureVisible);
tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
plotTornado(sensitivity.rangeRanking, 'Range Sensitivity');
plotTornado(sensitivity.heatingRanking, 'Heating Sensitivity');
plotTornado(sensitivity.maxQRanking, 'Max-q Sensitivity');
saveas(fig, fullfile(config.figureDir, 'Stage13_SensitivityResults.png'));
end

function plotTornado(T, titleText)
nexttile;
if isempty(T)
    text(0.1, 0.5, 'No data'); axis off; return;
end
barh(categorical(T.Variable), T.NormalizedSensitivity);
grid on; xlabel('Normalized sensitivity'); title(titleText);
end
