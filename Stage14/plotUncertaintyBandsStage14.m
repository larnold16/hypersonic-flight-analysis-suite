function app = plotUncertaintyBandsStage14(app, uncertainty)
% plotUncertaintyBandsStage14
% Draws shaded low/high uncertainty envelopes around the baseline.

if ~isfield(app, 'UncertaintyAxes') || isempty(app.UncertaintyAxes)
    return;
end

plotBand(app.UncertaintyAxes(1), uncertainty.bands.range_km, uncertainty.bands.altitude_km, ...
    'Range (km)', 'Altitude (km)', 'Altitude vs Range');
if numel(app.UncertaintyAxes) >= 2
    plotBand(app.UncertaintyAxes(2), uncertainty.bands.time_s, uncertainty.bands.mach, ...
        'Time (s)', 'Mach', 'Mach vs Time');
end
if numel(app.UncertaintyAxes) >= 3
    plotBand(app.UncertaintyAxes(3), uncertainty.bands.time_s, uncertainty.bands.q_kPa, ...
        'Time (s)', 'q (kPa)', 'Dynamic Pressure');
end
if numel(app.UncertaintyAxes) >= 4
    plotBand(app.UncertaintyAxes(4), uncertainty.bands.time_s, uncertainty.bands.stagTemp_K, ...
        'Time (s)', 'T_0 (K)', 'Stagnation Temperature');
end
if numel(app.UncertaintyAxes) >= 5
    plotBand(app.UncertaintyAxes(5), uncertainty.bands.time_s, uncertainty.bands.velocity_mps, ...
        'Time (s)', 'Velocity (m/s)', 'Velocity');
end
end

function plotBand(ax, x, envelope, xLabelText, yLabelText, titleText)
cla(ax); hold(ax, 'on'); grid(ax, 'on');
valid = isfinite(x(:)) & isfinite(envelope.min(:)) & isfinite(envelope.max(:));
if any(valid)
    xv = x(valid);
    lo = envelope.min(valid);
    hi = envelope.max(valid);
    fill(ax, [xv; flipud(xv)], [lo; flipud(hi)], [0.45 0.68 0.85], ...
        'FaceAlpha', 0.28, 'EdgeColor', 'none');
    plot(ax, xv, envelope.baseline(valid), 'LineWidth', 1.8, 'Color', [0.05 0.23 0.38]);
else
    text(ax, 0.5, 0.5, 'No uncertainty envelope available', ...
        'Units', 'normalized', 'HorizontalAlignment', 'center');
end
xlabel(ax, xLabelText);
ylabel(ax, yLabelText);
title(ax, titleText);
styleStage14Axes(ax);
end
