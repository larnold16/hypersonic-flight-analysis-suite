function monteCarlo = runMonteCarloStudy(config)
% runMonteCarloStudy
% Monte Carlo uncertainty propagation around the baseline design.

N = config.monteCarlo.N;
if config.verbose
    fprintf('Stage 13: Monte Carlo uncertainty study, N = %d...\n', N);
end
reportProgress(config, 0.03, "Preparing Monte Carlo cases...");

results = repmat(evaluateDesignCase(config, config.baselineDesign, 0), 0, 1);
for k = 1:N
    d = perturbBaseline(config.baselineDesign);
    results(end+1, 1) = evaluateDesignCase(config, d, k); %#ok<AGROW>
    if shouldReportProgress(k, N)
        reportProgress(config, 0.05 + 0.80 * k / max(N, 1), ...
            sprintf('Monte Carlo case %d of %d', k, N));
    end
end

reportProgress(config, 0.87, "Summarizing Monte Carlo statistics...");
summaryTable = struct2table(results);
monteCarlo.summaryTable = summaryTable;
monteCarlo.statistics = metricStats(summaryTable);
monteCarlo.probabilityMeetingConstraints = mean(summaryTable.feasible);
monteCarlo.probabilityStable = mean(summaryTable.stable);
monteCarlo.probabilitySuccessful = mean(summaryTable.solverSuccess & summaryTable.impactDetected);

reportProgress(config, 0.89, "Saving Monte Carlo outputs...");
writetable(summaryTable, fullfile(config.tableDir, 'Stage13MonteCarloResults.csv'));
save(fullfile(config.matDir, 'Stage13MonteCarloResults.mat'), 'monteCarlo');

if config.showPlots
    plotMonteCarloResults(monteCarlo, config);
end
reportProgress(config, 0.90, "Monte Carlo study finished.");
end

function d = perturbBaseline(base)
d = base;
d.mass_kg = base.mass_kg * (1 + 0.05 * randn());
d.initialSpeed_mps = base.initialSpeed_mps * (1 + 0.02 * randn());
d.launchAngle_deg = base.launchAngle_deg + 1.0 * randn();
d.CdMultiplier = base.CdMultiplier * (1 + 0.10 * randn());
d.CLalphaMultiplier = base.CLalphaMultiplier * (1 + 0.10 * randn());
d.dragUncertaintyFactor = d.CdMultiplier;
d.liftUncertaintyFactor = d.CLalphaMultiplier;
d.densityMultiplier = 1 + 0.05 * randn();
d.windSpeed_mps = 15 * randn();
d.cgLocation_m = base.cgLocation_m + 0.02 * base.length_m * randn();
d.cpLocation_m = base.cpLocation_m + 0.02 * base.length_m * randn();
d.staticMargin = (d.cpLocation_m - d.cgLocation_m) / max(d.length_m, eps);
end

function stats = metricStats(T)
metrics = {'range_m','maxAltitude_m','impactSpeed_mps','maxMach','maxQ_Pa', ...
    'maxHeating_W_m2','totalHeatLoad_J_m2','maxGLoad_g'};
names = strings(numel(metrics), 1);
meanValue = nan(numel(metrics), 1);
stdValue = nan(numel(metrics), 1);
minValue = nan(numel(metrics), 1);
maxValue = nan(numel(metrics), 1);
p05 = nan(numel(metrics), 1);
p95 = nan(numel(metrics), 1);
for k = 1:numel(metrics)
    x = T.(metrics{k});
    x = x(isfinite(x));
    names(k) = string(metrics{k});
    if ~isempty(x)
        meanValue(k) = mean(x);
        stdValue(k) = std(x);
        minValue(k) = min(x);
        maxValue(k) = max(x);
        p05(k) = percentileLocal(x, 5);
        p95(k) = percentileLocal(x, 95);
    end
end
stats = table(names, meanValue, stdValue, minValue, maxValue, p05, p95, ...
    'VariableNames', {'Metric','Mean','Std','Min','Max','P05','P95'});
end

function p = percentileLocal(x, pct)
x = sort(x(:));
if isempty(x)
    p = NaN;
    return;
end
idx = 1 + (numel(x) - 1) * pct / 100;
lo = floor(idx);
hi = ceil(idx);
if lo == hi
    p = x(lo);
else
    p = x(lo) + (idx - lo) * (x(hi) - x(lo));
end
end

function tf = shouldReportProgress(k, totalCount)
step = max(1, floor(max(totalCount, 1) / 50));
tf = k == 1 || k == totalCount || mod(k, step) == 0;
end

function reportProgress(config, fraction, message)
if isstruct(config) && isfield(config, 'progressCallback') && ~isempty(config.progressCallback)
    try
        config.progressCallback(fraction, message);
    catch ME
        if isfield(config, 'verbose') && config.verbose
            warning('Stage13:ProgressCallbackFailed', '%s', ME.message);
        end
    end
end
end
