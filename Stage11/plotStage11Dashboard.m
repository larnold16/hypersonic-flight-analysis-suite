function figureHandles = plotStage11Dashboard(results, config)
% plotStage11Dashboard
% Creates Stage 11 trajectory and comparison dashboard plots.

if nargin < 2
    config = buildStage11Config(results.vehicle, struct(), struct());
end

figureHandles = [];

if isfield(results, 'summaryTable')
    if strcmpi(getField(results, 'mode', ''), 'AngleSweep')
        figureHandles = plotAngleSweep(results, config);
    elseif strcmpi(getField(results, 'mode', ''), 'BodyComparison')
        figureHandles = plotBodyComparison(results, config);
    else
        figureHandles = plotFullComparison(results, config);
    end
else
    figureHandles = plotSingle(results, config);
end
end

function handles = plotSingle(r, config)
handles = gobjects(1, 1);
handles(1) = figure('Name', 'Stage 11 Engineering Dashboard', 'Visible', config.figureVisible);
tiledlayout(4, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile; plot(r.x / 1000, r.h / 1000, 'LineWidth', 1.5); grid on;
xlabel('Downrange (km)'); ylabel('Altitude (km)'); title('Trajectory');

nexttile; plot(r.t, r.h / 1000, 'LineWidth', 1.5); grid on;
xlabel('Time (s)'); ylabel('Altitude (km)'); title('Altitude');

nexttile; plot(r.t, r.V, 'LineWidth', 1.5); grid on;
xlabel('Time (s)'); ylabel('Velocity (m/s)'); title('Velocity');

nexttile; plot(r.t, r.Mach, 'LineWidth', 1.5); grid on;
xlabel('Time (s)'); ylabel('Mach'); title('Mach Number');

nexttile; plot(r.t, r.q / 1000, 'LineWidth', 1.5); hold on; grid on;
[maxQ, idxQ] = max(r.q);
plot(r.t(idxQ), maxQ / 1000, 'ro', 'MarkerFaceColor', 'r');
xlabel('Time (s)'); ylabel('q (kPa)'); title('Dynamic Pressure');

nexttile; plot(r.t, r.stagTemp, 'LineWidth', 1.5); grid on;
xlabel('Time (s)'); ylabel('T_0 (K)'); title('Stagnation Temperature');

nexttile; plot(r.t, r.heatingRate / 1000, 'LineWidth', 1.5); grid on;
xlabel('Time (s)'); ylabel('qdot (kW/m^2)'); title('Heating Rate');

nexttile; plot(r.t, r.drag, 'LineWidth', 1.5); hold on; plot(r.t, r.lift, 'LineWidth', 1.5); grid on;
xlabel('Time (s)'); ylabel('Force (N)'); title('Aero Forces'); legend('Drag','Lift','Location','best');

nexttile; plot(r.t, r.gLoad, 'LineWidth', 1.5); grid on;
xlabel('Time (s)'); ylabel('g'); title('Total g-load');

nexttile; plot(r.t, r.alpha_deg, 'LineWidth', 1.5); hold on; plot(r.t, r.beta_deg, 'LineWidth', 1.5); grid on;
xlabel('Time (s)'); ylabel('Angle (deg)'); title('Alpha / Beta'); legend('Alpha','Beta','Location','best');

nexttile; plot(r.t, r.kineticEnergy / 1e6, 'LineWidth', 1.5); hold on;
plot(r.t, r.potentialEnergy / 1e6, 'LineWidth', 1.5);
plot(r.t, r.totalEnergy / 1e6, 'LineWidth', 1.5); grid on;
xlabel('Time (s)'); ylabel('Energy (MJ)'); title('Energy'); legend('KE','PE','Total','Location','best');

nexttile; plot3(r.x / 1000, r.y / 1000, r.h / 1000, 'LineWidth', 1.5); grid on;
xlabel('Downrange (km)'); ylabel('Crossrange (km)'); zlabel('Altitude (km)'); title('3D Path');

saveFigure(handles(1), config.figureDir, 'Stage11_SingleTrajectoryDashboard.png');
end

function handles = plotAngleSweep(r, config)
handles = gobjects(1, 1);
T = r.summaryTable;
handles(1) = figure('Name', 'Stage 11 Launch Angle Sweep', 'Visible', config.figureVisible);
tiledlayout(2, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
plotTile(T.LaunchAngle_deg, T.Range_m / 1000, 'Range (km)', 'Range vs Angle');
plotTile(T.LaunchAngle_deg, T.MaxAltitude_m / 1000, 'Max altitude (km)', 'Altitude vs Angle');
plotTile(T.LaunchAngle_deg, T.ImpactSpeed_mps, 'Impact speed (m/s)', 'Impact Speed');
plotTile(T.LaunchAngle_deg, T.MaxQ_Pa / 1000, 'Max q (kPa)', 'Max q');
plotTile(T.LaunchAngle_deg, T.MaxHeating_W_m2 / 1000, 'Max heating (kW/m^2)', 'Heating');
plotTile(T.LaunchAngle_deg, T.TimeOfFlight_s, 'Time (s)', 'Time of Flight');
saveFigure(handles(1), config.figureDir, 'Stage11_AngleSweep.png');
end

function handles = plotBodyComparison(r, config)
handles = gobjects(1, 1);
T = r.summaryTable;
labels = categorical(T.BodyType);
handles(1) = figure('Name', 'Stage 11 Body Comparison', 'Visible', config.figureVisible);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; bar(labels, T.Range_m / 1000); grid on; ylabel('Range (km)'); title('Range');
nexttile; bar(labels, T.MaxQ_Pa / 1000); grid on; ylabel('Max q (kPa)'); title('Dynamic Pressure');
nexttile; bar(labels, T.MaxHeating_W_m2 / 1000); grid on; ylabel('Heating (kW/m^2)'); title('Heating');
nexttile; bar(labels, 100 * T.StaticMargin); grid on; ylabel('Static margin (%)'); title('Stability');
saveFigure(handles(1), config.figureDir, 'Stage11_BodyComparison.png');
end

function handles = plotFullComparison(r, config)
handles = gobjects(1, 1);
T = r.summaryTable;
handles(1) = figure('Name', 'Stage 11 Full Comparison', 'Visible', config.figureVisible);
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
nexttile; scatter(T.LaunchAngle_deg, T.Range_m / 1000, 45, T.MaxHeating_W_m2 / 1000, 'filled'); grid on; colorbar;
xlabel('Launch angle (deg)'); ylabel('Range (km)'); title('Range / Heating');
nexttile; scatter(T.MaxQ_Pa / 1000, T.Range_m / 1000, 45, T.StaticMargin, 'filled'); grid on; colorbar;
xlabel('Max q (kPa)'); ylabel('Range (km)'); title('Range / Max q');
nexttile; scatter(T.MaxHeating_W_m2 / 1000, T.MaxAltitude_m / 1000, 45, T.LaunchAngle_deg, 'filled'); grid on; colorbar;
xlabel('Heating (kW/m^2)'); ylabel('Altitude (km)'); title('Altitude / Heating');
nexttile; bar(T.Score); grid on; ylabel('Score'); title('Weighted Recommendation Score');
saveFigure(handles(1), config.figureDir, 'Stage11_FullComparison.png');
end

function plotTile(x, y, yLabel, ttl)
nexttile;
plot(x, y, '-o', 'LineWidth', 1.5, 'MarkerFaceColor', [0.1 0.4 0.8]);
grid on;
xlabel('Launch angle (deg)');
ylabel(yLabel);
title(ttl);
end

function saveFigure(fig, folder, fileName)
if ~exist(folder, 'dir')
    mkdir(folder);
end
try
    saveas(fig, fullfile(folder, fileName));
catch ME
    warning('Stage11:FigureSaveFailed', 'Could not save %s: %s', fileName, ME.message);
end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
