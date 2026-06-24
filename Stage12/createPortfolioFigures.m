function figureFiles = createPortfolioFigures(vehicle, constants, config)
% createPortfolioFigures
% Generates clean Stage 12 portfolio figures in Outputs/Stage12/Figures.

figureFiles = strings(0, 1);

stage11Cfg = buildStage11Config(vehicle, constants, struct( ...
    'showPlots', false, 'exportResults', false, 'generateReport', false, ...
    'verbose', false, 'interactive', false, 'figureVisible', config.figureVisible, ...
    'outputRoot', config.outputRoot));

single = runSingleTrajectory(vehicle, constants, stage11Cfg);
figureFiles(end+1) = saveSingleFigure(single, config, 'Stage12_TrajectoryAltitudeRange.png', 1);
figureFiles(end+1) = saveTimeFigure(single.t, single.Mach, 'Time (s)', 'Mach', 'Mach vs Time', config, 'Stage12_MachTime.png');
figureFiles(end+1) = saveTimeFigure(single.t, single.q / 1000, 'Time (s)', 'q (kPa)', 'Dynamic Pressure vs Time', config, 'Stage12_DynamicPressureTime.png');
figureFiles(end+1) = saveTimeFigure(single.t, single.stagTemp, 'Time (s)', 'T_0 (K)', 'Stagnation Temperature vs Time', config, 'Stage12_StagnationTemperatureTime.png');
figureFiles(end+1) = saveTimeFigure(single.t, single.heatingRate / 1000, 'Time (s)', 'qdot (kW/m^2)', 'Heating Rate vs Time', config, 'Stage12_HeatingRateTime.png');

stage11Cfg.launchAngles_deg = 5:5:45;
sweep = runAngleSweep(vehicle, constants, stage11Cfg);
figureFiles(end+1) = saveSweepFigure(sweep.summaryTable.LaunchAngle_deg, sweep.summaryTable.Range_m / 1000, ...
    'Launch angle (deg)', 'Range (km)', 'Launch Angle Sweep: Range', config, 'Stage12_SweepRange.png');
figureFiles(end+1) = saveSweepFigure(sweep.summaryTable.LaunchAngle_deg, sweep.summaryTable.MaxAltitude_m / 1000, ...
    'Launch angle (deg)', 'Max altitude (km)', 'Launch Angle Sweep: Altitude', config, 'Stage12_SweepAltitude.png');

bodies = runBodyComparison(vehicle, constants, stage11Cfg);
figureFiles(end+1) = saveBarFigure(categorical(bodies.summaryTable.BodyType), bodies.summaryTable.Range_m / 1000, ...
    'Range (km)', 'Body Comparison: Range', config, 'Stage12_BodyRange.png');
figureFiles(end+1) = saveBarFigure(categorical(bodies.summaryTable.BodyType), bodies.summaryTable.MaxHeating_W_m2 / 1000, ...
    'Heating (kW/m^2)', 'Body Comparison: Heating', config, 'Stage12_BodyHeating.png');

comparison = compareStages(vehicle, constants, config);
if isfield(comparison, 'trajectories') && ~isempty(comparison.trajectories)
    fig = figure('Name', 'Stage Comparison Trajectories', 'Visible', config.figureVisible);
    hold on; grid on;
    for k = 1:numel(comparison.trajectories)
        tr = comparison.trajectories{k};
        plot(tr.x / 1000, tr.h / 1000, 'LineWidth', 1.5);
    end
    xlabel('Range (km)'); ylabel('Altitude (km)'); title('Stage Trajectory Comparison');
    legend(comparison.trajectoryLabels, 'Location', 'best');
    file = fullfile(config.figureDir, 'Stage12_StageTrajectoryComparison.png');
    saveas(fig, file);
    figureFiles(end+1) = string(file);
end

save(fullfile(config.matDir, 'Stage12PortfolioFigures.mat'), 'figureFiles');
end

function file = saveSingleFigure(r, config, fileName, ~)
fig = figure('Name', 'Trajectory Altitude vs Range', 'Visible', config.figureVisible);
plot(r.x / 1000, r.h / 1000, 'LineWidth', 1.8); grid on;
xlabel('Range (km)'); ylabel('Altitude (km)'); title('Trajectory Altitude vs Range');
file = fullfile(config.figureDir, fileName); saveas(fig, file); file = string(file);
end

function file = saveTimeFigure(x, y, xlab, ylab, ttl, config, fileName)
fig = figure('Name', ttl, 'Visible', config.figureVisible);
plot(x, y, 'LineWidth', 1.8); grid on; xlabel(xlab); ylabel(ylab); title(ttl);
if contains(ttl, 'Dynamic Pressure')
    [ym, idx] = max(y); hold on; plot(x(idx), ym, 'ro', 'MarkerFaceColor', 'r');
end
file = fullfile(config.figureDir, fileName); saveas(fig, file); file = string(file);
end

function file = saveSweepFigure(x, y, xlab, ylab, ttl, config, fileName)
fig = figure('Name', ttl, 'Visible', config.figureVisible);
plot(x, y, '-o', 'LineWidth', 1.8, 'MarkerFaceColor', [0.2 0.45 0.75]); grid on;
xlabel(xlab); ylabel(ylab); title(ttl);
file = fullfile(config.figureDir, fileName); saveas(fig, file); file = string(file);
end

function file = saveBarFigure(x, y, ylab, ttl, config, fileName)
fig = figure('Name', ttl, 'Visible', config.figureVisible);
bar(x, y); grid on; ylabel(ylab); title(ttl);
file = fullfile(config.figureDir, fileName); saveas(fig, file); file = string(file);
end
