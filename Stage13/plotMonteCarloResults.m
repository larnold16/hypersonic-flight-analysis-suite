function fig = plotMonteCarloResults(monteCarlo, config)
% plotMonteCarloResults
% Creates Monte Carlo uncertainty plots.

T = monteCarlo.summaryTable;
fig = figure('Name', 'Stage 13 Monte Carlo Results', 'Visible', config.figureVisible);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; histogram(T.range_m / 1000); grid on; xlabel('Range (km)'); ylabel('Count'); title('Range');
nexttile; histogram(T.maxQ_Pa / 1000); grid on; xlabel('Max q (kPa)'); ylabel('Count'); title('Max q');
nexttile; histogram(T.maxHeating_W_m2 / 1000); grid on; xlabel('Heating (kW/m^2)'); ylabel('Count'); title('Heating');
nexttile; scatter(T.range_m / 1000, T.maxHeating_W_m2 / 1000, 20, T.feasible, 'filled'); grid on;
xlabel('Range (km)'); ylabel('Heating (kW/m^2)'); title('Range vs Heating');
nexttile; scatter(T.range_m / 1000, T.maxQ_Pa / 1000, 20, T.feasible, 'filled'); grid on;
xlabel('Range (km)'); ylabel('Max q (kPa)'); title('Range vs Max q');
nexttile; bar(categorical({'Feasible','Stable','Successful'}), ...
    [monteCarlo.probabilityMeetingConstraints, monteCarlo.probabilityStable, monteCarlo.probabilitySuccessful]);
ylim([0 1]); grid on; ylabel('Probability'); title('Pass Rates');
saveas(fig, fullfile(config.figureDir, 'Stage13_MonteCarloResults.png'));
end
