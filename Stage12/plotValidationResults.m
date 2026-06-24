function fig = plotValidationResults(validation, config)
% plotValidationResults
% Creates concise validation overview figures.

fig = figure('Name', 'Stage 12 Validation Results', 'Visible', config.figureVisible);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile;
bar(categorical(validation.summaryTable.ValidationCase), validation.summaryTable.Passed);
ylim([0 1.2]); grid on; ylabel('Pass = 1'); title('Validation Pass/Fail');

vac = validation.caseResults{1};
nexttile;
if isfield(vac, 'metrics') && ~isempty(vac.metrics)
    bar(categorical(vac.metrics.Metric), vac.metrics.PercentError);
    ylabel('Percent error'); title('Vacuum Projectile Error'); grid on;
else
    text(0.1, 0.5, 'Vacuum metrics unavailable'); axis off;
end

atm = validation.caseResults{3};
nexttile;
if isfield(atm, 'h')
    semilogx(atm.rho, atm.h / 1000, 'LineWidth', 1.5); grid on;
    xlabel('Density (kg/m^3)'); ylabel('Altitude (km)'); title('Atmosphere Density');
else
    text(0.1, 0.5, 'Atmosphere metrics unavailable'); axis off;
end

aero = validation.caseResults{4};
nexttile;
if isfield(aero, 'Mach')
    plot(aero.Mach, aero.CD, 'LineWidth', 1.5); grid on;
    xlabel('Mach'); ylabel('C_D'); title('Aero Continuity');
else
    text(0.1, 0.5, 'Aero metrics unavailable'); axis off;
end

saveas(fig, fullfile(config.figureDir, 'Stage12_ValidationDashboard.png'));
end
