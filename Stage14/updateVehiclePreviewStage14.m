function app = updateVehiclePreviewStage14(app)
% updateVehiclePreviewStage14
% Draws a simple side-profile schematic for the current vehicle.

if ~isfield(app, 'VehiclePreviewAxes') || isempty(app.VehiclePreviewAxes) || ~isvalid(app.VehiclePreviewAxes)
    return;
end
ax = app.VehiclePreviewAxes;
cla(ax);
v = app.State.vehicle;
L = getField(v, 'length', 0.45);
D = getField(v, 'diameter', 0.0564);
cg = getField(v, 'cgLocation_m', 0.50 * L);
cp = getField(v, 'cpLocation_m', 0.60 * L);
theme = stage14Theme();

hold(ax, 'on');
bodyX = [0.18*L, L, L, 0.18*L];
bodyY = [D/2, D/2, -D/2, -D/2];
patch(ax, bodyX, bodyY, theme.primarySoft, 'EdgeColor', theme.primary, 'LineWidth', 1.5);
patch(ax, [0, 0.18*L, 0.18*L], [0, D/2, -D/2], theme.accentSoft, 'EdgeColor', theme.accent, 'LineWidth', 1.5);
plot(ax, [cg cg], [-0.75*D 0.75*D], '-', 'LineWidth', 2.0, 'Color', theme.warning, 'DisplayName', 'CG');
plot(ax, [cp cp], [-0.75*D 0.75*D], '--', 'LineWidth', 2.0, 'Color', theme.danger, 'DisplayName', 'CP');
text(ax, cg, 0.85*D, 'CG', 'HorizontalAlignment', 'center', 'Color', theme.warning, 'FontWeight', 'bold');
text(ax, cp, -0.95*D, 'CP', 'HorizontalAlignment', 'center', 'Color', theme.danger, 'FontWeight', 'bold');
axis(ax, 'equal');
xlim(ax, [-0.05*L, 1.08*L]);
ylim(ax, [-1.4*D, 1.4*D]);
title(ax, 'Simplified Side Profile');
xlabel(ax, 'Length (m)');
ylabel(ax, 'Diameter scale (m)');
grid(ax, 'on');
styleStage14Axes(ax);
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
