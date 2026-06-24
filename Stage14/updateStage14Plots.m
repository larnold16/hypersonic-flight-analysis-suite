function app = updateStage14Plots(app, plotType, results)
% updateStage14Plots
% Central plotting dispatcher for Stage 14.

switch lower(plotType)
    case 'single'
        app = plotSingleTrajectory(app, results);
    case 'angle'
        app = plotAngleSweep(app, results);
    case 'validation'
        app = plotValidation(app, results);
    case 'montecarlo'
        app = plotMonteCarlo(app, results);
    case 'pareto'
        app = plotPareto(app, results);
    otherwise
        warning('Stage14:UnknownPlotType', 'Unknown Stage 14 plot type: %s', plotType);
end
styleStage14Axes(axesForPlotType(app, plotType));
end

function app = plotSingleTrajectory(app, r)
axesList = app.SingleAxes;
clearAxes(axesList);
if isempty(r) || ~isfield(r, 't')
    return;
end
h = plot(axesList(1), r.x ./ 1000, r.h ./ 1000, 'LineWidth', 1.5); attachTrajectoryDataTipStage14(h, r); attachTrajectoryPointSelectionStage14(h, app.Figure, r, "Trajectory"); grid(axesList(1), 'on');
xlabel(axesList(1), 'Downrange (km)'); ylabel(axesList(1), 'Altitude (km)'); title(axesList(1), 'Trajectory');
h = plot(axesList(2), r.t, r.V, 'LineWidth', 1.5); attachTrajectoryDataTipStage14(h, r); attachTrajectoryPointSelectionStage14(h, app.Figure, r, "Velocity"); grid(axesList(2), 'on');
xlabel(axesList(2), 'Time (s)'); ylabel(axesList(2), 'Velocity (m/s)'); title(axesList(2), 'Velocity');
h = plot(axesList(3), r.t, r.Mach, 'LineWidth', 1.5); attachTrajectoryDataTipStage14(h, r); attachTrajectoryPointSelectionStage14(h, app.Figure, r, "Mach"); grid(axesList(3), 'on');
xlabel(axesList(3), 'Time (s)'); ylabel(axesList(3), 'Mach'); title(axesList(3), 'Mach');
h = plot(axesList(4), r.t, r.q ./ 1000, 'LineWidth', 1.5); attachTrajectoryDataTipStage14(h, r); attachTrajectoryPointSelectionStage14(h, app.Figure, r, "Dynamic pressure"); grid(axesList(4), 'on');
xlabel(axesList(4), 'Time (s)'); ylabel(axesList(4), 'q (kPa)'); title(axesList(4), 'Dynamic Pressure');
h = plot(axesList(5), r.t, safeSeries(r, {'drag'}), 'LineWidth', 1.5); attachTrajectoryDataTipStage14(h, r); attachTrajectoryPointSelectionStage14(h, app.Figure, r, "Drag"); grid(axesList(5), 'on');
xlabel(axesList(5), 'Time (s)'); ylabel(axesList(5), 'Drag (N)'); title(axesList(5), 'Drag');
h = plot(axesList(6), r.t, safeSeries(r, {'stagTemp','Tstag'}), 'LineWidth', 1.5); attachTrajectoryDataTipStage14(h, r); attachTrajectoryPointSelectionStage14(h, app.Figure, r, "Stagnation temperature"); grid(axesList(6), 'on');
xlabel(axesList(6), 'Time (s)'); ylabel(axesList(6), 'Tstag (K)'); title(axesList(6), 'Stagnation Temperature');
end

function app = plotAngleSweep(app, results)
axesList = app.AngleAxes;
clearAxes(axesList);
if isfield(results, 'summaryTable')
    T = standardizeCaseTableStage14(results.summaryTable, "AngleSweep");
else
    return;
end
plot(axesList(1), T.LaunchAngle_deg, T.Range_km, '-o', 'LineWidth', 1.5); hold(axesList(1), 'on');
s = scatter(axesList(1), T.LaunchAngle_deg, T.Range_km, 28, 'filled');
attachInteractiveScatterData(s, T, app.Figure, 'LaunchAngle_deg', 'Range_km', 'AngleSweep');
grid(axesList(1), 'on');
xlabel(axesList(1), 'Launch angle (deg)'); ylabel(axesList(1), 'Range (km)'); title(axesList(1), 'Range');
plot(axesList(2), T.LaunchAngle_deg, T.MaxAltitude_km, '-o', 'LineWidth', 1.5); hold(axesList(2), 'on');
s = scatter(axesList(2), T.LaunchAngle_deg, T.MaxAltitude_km, 28, 'filled');
attachInteractiveScatterData(s, T, app.Figure, 'LaunchAngle_deg', 'MaxAltitude_km', 'AngleSweep');
grid(axesList(2), 'on');
xlabel(axesList(2), 'Launch angle (deg)'); ylabel(axesList(2), 'Altitude (km)'); title(axesList(2), 'Max Altitude');
plot(axesList(3), T.LaunchAngle_deg, T.TimeOfFlight_s, '-o', 'LineWidth', 1.5); grid(axesList(3), 'on');
xlabel(axesList(3), 'Launch angle (deg)'); ylabel(axesList(3), 'Time (s)'); title(axesList(3), 'Time of Flight');
plot(axesList(4), T.LaunchAngle_deg, T.MaxQ_kPa, '-o', 'LineWidth', 1.5); hold(axesList(4), 'on');
s = scatter(axesList(4), T.LaunchAngle_deg, T.MaxQ_kPa, 28, 'filled');
attachInteractiveScatterData(s, T, app.Figure, 'LaunchAngle_deg', 'MaxQ_kPa', 'AngleSweep');
grid(axesList(4), 'on');
xlabel(axesList(4), 'Launch angle (deg)'); ylabel(axesList(4), 'Max q (kPa)'); title(axesList(4), 'Max q');
plot(axesList(5), T.LaunchAngle_deg, T.MaxHeating_kW_m2, '-o', 'LineWidth', 1.5); hold(axesList(5), 'on');
s = scatter(axesList(5), T.LaunchAngle_deg, T.MaxHeating_kW_m2, 28, 'filled');
attachInteractiveScatterData(s, T, app.Figure, 'LaunchAngle_deg', 'MaxHeating_kW_m2', 'AngleSweep');
grid(axesList(5), 'on');
xlabel(axesList(5), 'Launch angle (deg)'); ylabel(axesList(5), 'Heating (kW/m^2)'); title(axesList(5), 'Heating');
y = T.Score;
if all(~isfinite(y))
    y = normalizeMetric(T.Range_km);
end
plot(axesList(6), T.LaunchAngle_deg, y, '-o', 'LineWidth', 1.5); hold(axesList(6), 'on');
s = scatter(axesList(6), T.LaunchAngle_deg, y, 28, 'filled');
T.Score = y;
attachInteractiveScatterData(s, T, app.Figure, 'LaunchAngle_deg', 'Score', 'AngleSweep');
grid(axesList(6), 'on');
xlabel(axesList(6), 'Launch angle (deg)'); ylabel(axesList(6), 'Score'); title(axesList(6), 'Score');
end

function app = plotValidation(app, results)
axesList = app.ValidationAxes;
clearAxes(axesList);
if isfield(results, 'stageComparison') && isfield(results.stageComparison, 'trajectories')
    axes(axesList(1)); %#ok<LAXES>
    hold(axesList(1), 'on'); grid(axesList(1), 'on');
    for k = 1:numel(results.stageComparison.trajectories)
        tr = results.stageComparison.trajectories{k};
        plot(axesList(1), tr.x ./ 1000, tr.h ./ 1000, 'LineWidth', 1.3);
    end
    title(axesList(1), 'Stage Trajectories'); xlabel(axesList(1), 'Range (km)'); ylabel(axesList(1), 'Altitude (km)');
    if isfield(results.stageComparison, 'trajectoryLabels')
        legend(axesList(1), results.stageComparison.trajectoryLabels, 'Location', 'best');
    end
end
if isfield(results, 'physicsDiagnostics') && isfield(results.physicsDiagnostics, 'sweep')
    sweep = results.physicsDiagnostics.sweep;
    hold(axesList(2), 'on'); grid(axesList(2), 'on');
    for k = 1:numel(sweep.modeNames)
        plot(axesList(2), sweep.angles_deg, sweep.rangeMatrix_km(:, k), '-o', 'LineWidth', 1.3);
    end
    title(axesList(2), 'Vacuum / Drag / Full Aero Sweep');
    xlabel(axesList(2), 'Launch angle (deg)'); ylabel(axesList(2), 'Range (km)');
    legend(axesList(2), sweep.modeNames, 'Location', 'best');
end
end

function app = plotMonteCarlo(app, mc)
axesList = app.MonteCarloAxes;
clearAxes(axesList);
if ~isfield(mc, 'summaryTable')
    return;
end
theme = stage14Theme();
T = standardizeCaseTableStage14(mc.summaryTable, "MonteCarlo");
h = histogram(axesList(1), T.Range_km); h.FaceColor = theme.plotColors(1,:); h.EdgeColor = theme.surface; grid(axesList(1), 'on'); title(axesList(1), 'Range'); xlabel(axesList(1), 'km');
h = histogram(axesList(2), T.MaxQ_kPa); h.FaceColor = theme.plotColors(3,:); h.EdgeColor = theme.surface; grid(axesList(2), 'on'); title(axesList(2), 'Max q'); xlabel(axesList(2), 'kPa');
h = histogram(axesList(3), T.MaxHeating_kW_m2); h.FaceColor = theme.plotColors(5,:); h.EdgeColor = theme.surface; grid(axesList(3), 'on'); title(axesList(3), 'Heating'); xlabel(axesList(3), 'kW/m^2');
s1 = scatter(axesList(4), T.Range_km, T.MaxHeating_kW_m2, 28, T.Feasible, 'filled');
grid(axesList(4), 'on'); xlabel(axesList(4), 'Range (km)'); ylabel(axesList(4), 'Heating (kW/m^2)'); title(axesList(4), 'Range vs Heating');
attachInteractiveScatterData(s1, T, app.Figure, 'Range_km', 'MaxHeating_kW_m2', 'MonteCarlo');
s2 = scatter(axesList(5), T.Range_km, T.MaxQ_kPa, 28, T.Feasible, 'filled');
grid(axesList(5), 'on'); xlabel(axesList(5), 'Range (km)'); ylabel(axesList(5), 'Max q (kPa)'); title(axesList(5), 'Range vs Max q');
attachInteractiveScatterData(s2, T, app.Figure, 'Range_km', 'MaxQ_kPa', 'MonteCarlo');
b = bar(axesList(6), categorical({'Feasible','Stable','Successful'}), ...
    [mean(T.Feasible), mean(T.Feasible), mean(T.Feasible)]);
b.FaceColor = theme.accent;
ylim(axesList(6), [0 1]); grid(axesList(6), 'on'); title(axesList(6), 'Pass Rates');
end

function app = plotPareto(app, pareto)
axesList = app.ParetoAxes;
clearAxes(axesList);
if ~isfield(pareto, 'summaryTable')
    return;
end
T = standardizeCaseTableStage14(pareto.summaryTable, "Pareto");
T.ParetoFlag = computeRangeHeatingPareto(T);
writetable(T, fullfile(app.State.tableDir, 'Stage14ParetoDesigns.csv'));
app = updateStage14Tables(app, 'ParetoDesigns', T);

plotParetoAxes(axesList(1), T, 'Range_km', 'MaxHeating_kW_m2', 'Range (km)', 'Heating (kW/m^2)', app.Figure);
plotParetoAxes(axesList(2), T, 'Range_km', 'MaxQ_kPa', 'Range (km)', 'Max q (kPa)', app.Figure);
plotParetoAxes(axesList(3), T, 'MaxAltitude_km', 'MaxHeating_kW_m2', 'Altitude (km)', 'Heating (kW/m^2)', app.Figure);
plotParetoAxes(axesList(4), T, 'Score', 'MaxHeating_kW_m2', 'Score', 'Heating (kW/m^2)', app.Figure);
end

function plotParetoAxes(ax, T, xField, yField, xLabelText, yLabelText, appFigure)
hold(ax, 'on'); grid(ax, 'on');
infeasible = ~T.Feasible;
feasibleNonPareto = T.Feasible & ~T.ParetoFlag;
pareto = T.Feasible & T.ParetoFlag;
if any(infeasible)
    s = scatter(ax, T.(xField)(infeasible), T.(yField)(infeasible), 26, [0.75 0.2 0.15], 'x');
    attachInteractiveScatterData(s, T(infeasible, :), appFigure, xField, yField, 'Pareto');
end
if any(feasibleNonPareto)
    s = scatter(ax, T.(xField)(feasibleNonPareto), T.(yField)(feasibleNonPareto), 24, [0.35 0.55 0.8], 'filled');
    attachInteractiveScatterData(s, T(feasibleNonPareto, :), appFigure, xField, yField, 'Pareto');
end
if any(pareto)
    s = scatter(ax, T.(xField)(pareto), T.(yField)(pareto), 44, [0.05 0.55 0.25], 'filled');
    attachInteractiveScatterData(s, T(pareto, :), appFigure, xField, yField, 'Pareto');
end
xlabel(ax, xLabelText); ylabel(ax, yLabelText); title(ax, strrep([xField, ' vs ', yField], '_', ' '));
legend(ax, {'Infeasible','Feasible','Pareto'}, 'Location', 'best');
end

function T = stage13ToStage14Table(Tin, studyType)
n = height(Tin);
T = table();
T.CaseID = localCaseIDs(getColumn(Tin, {'CaseID','caseId'}, (1:n).'), studyType, n);
T.StudyType = repmat(string(studyType), n, 1);
T.ParetoFlag = false(n, 1);
T.Feasible = logical(getColumn(Tin, {'Feasible','feasible'}, false(n,1)));
T.ViolatedConstraints = string(getColumn(Tin, {'ViolatedConstraints','violatedConstraints'}, strings(n,1)));
T.BodyType = string(getColumn(Tin, {'BodyType','bodyType'}, strings(n,1)));
T.NoseType = strings(n, 1);
T.LaunchAngle_deg = getColumn(Tin, {'LaunchAngle_deg','launchAngle_deg'}, nan(n,1));
T.InitialSpeed_mps = getColumn(Tin, {'InitialSpeed_mps','initialSpeed_mps'}, nan(n,1));
T.Mass_kg = getColumn(Tin, {'Mass_kg','mass_kg'}, nan(n,1));
T.Length_m = getColumn(Tin, {'Length_m','length_m'}, nan(n,1));
T.Diameter_m = getColumn(Tin, {'Diameter_m','diameter_m'}, nan(n,1));
T.StaticMargin_percent = 100 .* getColumn(Tin, {'StaticMargin','staticMargin','stabilityMargin'}, nan(n,1));
T.CdMultiplier = getColumn(Tin, {'CdMultiplier'}, nan(n,1));
T.CLalphaMultiplier = nan(n,1);
T.Range_km = getColumn(Tin, {'Range_km'}, getColumn(Tin, {'range_m'}, nan(n,1)) ./ 1000);
T.MaxAltitude_km = getColumn(Tin, {'MaxAltitude_km'}, getColumn(Tin, {'maxAltitude_m'}, nan(n,1)) ./ 1000);
T.TimeOfFlight_s = getColumn(Tin, {'TimeOfFlight_s','timeOfFlight_s'}, nan(n,1));
T.ImpactSpeed_mps = getColumn(Tin, {'ImpactSpeed_mps','impactSpeed_mps'}, nan(n,1));
T.ImpactMach = nan(n,1);
T.MaxMach = getColumn(Tin, {'MaxMach','maxMach'}, nan(n,1));
T.MaxQ_kPa = getColumn(Tin, {'MaxQ_kPa'}, getColumn(Tin, {'maxQ_Pa'}, nan(n,1)) ./ 1000);
T.MaxHeating_kW_m2 = getColumn(Tin, {'MaxHeating_kW_m2'}, getColumn(Tin, {'maxHeating_W_m2'}, nan(n,1)) ./ 1000);
T.TotalHeatLoad = getColumn(Tin, {'TotalHeatLoad','totalHeatLoad_J_m2'}, nan(n,1));
T.MaxGLoad = getColumn(Tin, {'MaxGLoad','maxGLoad_g'}, nan(n,1));
T.Score = getColumn(Tin, {'Score','score'}, nan(n,1));
end

function flag = computeRangeHeatingPareto(T)
flag = false(height(T), 1);
idx = find(T.Feasible);
if isempty(idx)
    return;
end
obj = [T.Range_km(idx), -T.MaxHeating_kW_m2(idx)];
front = true(numel(idx), 1);
for i = 1:numel(idx)
    for j = 1:numel(idx)
        if all(obj(j,:) >= obj(i,:)) && any(obj(j,:) > obj(i,:))
            front(i) = false;
            break;
        end
    end
end
flag(idx) = front;
end

function values = getColumn(T, names, defaultValue)
values = defaultValue;
for k = 1:numel(names)
    if any(strcmp(T.Properties.VariableNames, names{k}))
        values = T.(names{k});
        return;
    end
end
end

function T = addCaseIdIfMissing(T)
if ~any(strcmp(T.Properties.VariableNames, 'CaseID')) && ~any(strcmp(T.Properties.VariableNames, 'caseId'))
    T.CaseID = localCaseIDs((1:height(T)).', "Stage14", height(T));
end
end

function ids = localCaseIDs(rawIds, studyType, n)
prefix = "CASE";
label = lower(char(string(studyType)));
if contains(label, 'angle')
    prefix = "ANG";
elseif contains(label, 'monte')
    prefix = "MC";
elseif contains(label, 'pareto')
    prefix = "PAR";
elseif contains(label, 'optim')
    prefix = "OPT";
elseif contains(label, 'doe')
    prefix = "DOE";
end
ids = normalizeCaseIDStage14(rawIds);
if n > 0 && numel(ids) == 1 && n > 1
    ids = repmat(ids, n, 1);
end
if numel(ids) ~= n
    ids = strings(n, 1);
end
for k = 1:n
    numericValue = str2double(ids(k));
    if strlength(ids(k)) == 0 || (isfinite(numericValue) && ~contains(ids(k), "-"))
        if ~isfinite(numericValue)
            numericValue = k;
        end
        ids(k) = sprintf('%s-%03d', prefix, round(numericValue));
    end
end
end

function y = normalizeMetric(x)
x = x(:);
y = zeros(size(x));
finite = isfinite(x);
if any(finite)
    y(finite) = (x(finite) - min(x(finite))) ./ max(max(x(finite)) - min(x(finite)), eps);
end
end

function clearAxes(axesList)
for k = 1:numel(axesList)
    if isvalid(axesList(k))
        cla(axesList(k));
    end
end
end

function values = safeSeries(r, names)
values = nan(size(r.t));
for k = 1:numel(names)
    if isfield(r, names{k}) && isnumeric(r.(names{k})) && numel(r.(names{k})) == numel(r.t)
        values = r.(names{k});
        return;
    end
end
end

function axesList = axesForPlotType(app, plotType)
axesList = gobjects(0);
switch lower(plotType)
    case 'single'
        axesList = getAxes(app, 'SingleAxes');
    case 'angle'
        axesList = getAxes(app, 'AngleAxes');
    case 'validation'
        axesList = getAxes(app, 'ValidationAxes');
    case 'montecarlo'
        axesList = getAxes(app, 'MonteCarloAxes');
    case 'pareto'
        axesList = getAxes(app, 'ParetoAxes');
end
end

function axesList = getAxes(app, fieldName)
axesList = gobjects(0);
if isfield(app, fieldName)
    axesList = app.(fieldName);
end
end
