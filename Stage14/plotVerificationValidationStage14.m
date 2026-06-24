function app = plotVerificationValidationStage14(app, verification)
% plotVerificationValidationStage14
% Updates the Stage 14 V&V energy and range-sweep plots.

if ~isfield(app, 'VerificationAxes') || numel(app.VerificationAxes) < 2
    return;
end

ax = app.VerificationAxes(1);
cla(ax); hold(ax, 'on'); grid(ax, 'on');
cases = verification.cases;
for k = 1:numel(cases)
    r = cases{k};
    if isfield(r, 't') && isfield(r, 'totalEnergy')
        plot(ax, r.t, r.totalEnergy / 1e6, 'LineWidth', 1.5, 'DisplayName', char(r.stageName));
    end
end
xlabel(ax, 'Time (s)');
ylabel(ax, 'Total mechanical energy (MJ)');
title(ax, 'Energy Behavior Check');
legend(ax, 'Location', 'best');
styleStage14Axes(ax);

ax = app.VerificationAxes(2);
cla(ax); hold(ax, 'on'); grid(ax, 'on');
sweep = verification.sweep;
styles = {'-o','-s','-^'};
for k = 1:numel(sweep.modeNames)
    plot(ax, sweep.angles_deg, sweep.rangeMatrix_km(:, k), styles{min(k, numel(styles))}, ...
        'LineWidth', 1.5, 'MarkerFaceColor', 'auto', 'DisplayName', char(sweep.modeNames(k)));
end
xlabel(ax, 'Launch angle (deg)');
ylabel(ax, 'Range (km)');
title(ax, 'Range vs Angle by Physics Mode');
legend(ax, 'Location', 'best');
styleStage14Axes(ax);
end
