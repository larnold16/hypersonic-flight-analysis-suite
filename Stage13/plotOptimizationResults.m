function fig = plotOptimizationResults(study, config)
% plotOptimizationResults
% Plots optimization, launch, geometry, or DOE result tables.

T = study.summaryTable;
fig = figure('Name', 'Stage 13 Optimization Results', 'Visible', config.figureVisible);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile; scatter(T.launchAngle_deg, T.range_m / 1000, 36, T.score, 'filled'); grid on; colorbar;
xlabel('Launch angle (deg)'); ylabel('Range (km)'); title('Range by Angle');

nexttile; scatter(T.maxQ_Pa / 1000, T.range_m / 1000, 36, T.feasible, 'filled'); grid on;
xlabel('Max q (kPa)'); ylabel('Range (km)'); title('Constraint Trade');

nexttile; scatter(T.maxHeating_W_m2 / 1000, T.range_m / 1000, 36, T.score, 'filled'); grid on; colorbar;
xlabel('Heating (kW/m^2)'); ylabel('Range (km)'); title('Range vs Heating');

nexttile; [bodyLabels, bodyRange] = groupedMean(string(T.bodyType), T.range_m / 1000);
bar(categorical(bodyLabels), bodyRange); grid on;
ylabel('Range (km)'); title('Range by Body');

nexttile; scatter(T.staticMargin * 100, T.score, 36, T.feasible, 'filled'); grid on;
xlabel('Static margin (%)'); ylabel('Score'); title('Stability Score');

nexttile; histogram(T.score(isfinite(T.score))); grid on;
xlabel('Score'); ylabel('Count'); title('Balanced Score');

saveas(fig, fullfile(config.figureDir, 'Stage13_OptimizationResults.png'));
end

function [labels, means] = groupedMean(groups, values)
labels = unique(groups, 'stable');
means = nan(numel(labels), 1);
for k = 1:numel(labels)
    idx = groups == labels(k) & isfinite(values);
    if any(idx)
        means(k) = mean(values(idx));
    end
end
end
