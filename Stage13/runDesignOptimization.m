function optimization = runDesignOptimization(config)
% runDesignOptimization
% No-toolbox optimization: coarse grid, random search, and local refinement.

if config.verbose
    fprintf('Stage 13: constrained design optimization...\n');
end

gridDesigns = generateDesignGrid(config);
randomDesigns = generateRandomDesigns(config, config.optimization.randomCount);
initialDesigns = [gridDesigns; randomDesigns];
initialResults = evaluateDesignList(config, initialDesigns, 1);

best = bestByScore(initialResults);
localDesigns = {};
if ~isempty(best)
    localDesigns = generateLocalDesigns(config, best);
end
localResults = evaluateDesignList(config, localDesigns, numel(initialResults) + 1);

allResults = [initialResults; localResults];
summaryTable = struct2table(allResults);

optimization.method = 'Coarse grid + random search + local refinement, no Optimization Toolbox';
optimization.summaryTable = summaryTable;
optimization.bestFeasibleDesign = bestRow(summaryTable, 'score', 'max', true);
optimization.bestRangeDesign = bestRow(summaryTable, 'range_m', 'max', false);
optimization.lowestHeatingDesign = bestRow(summaryTable, 'maxHeating_W_m2', 'min', false);
optimization.lowestMaxQDesign = bestRow(summaryTable, 'maxQ_Pa', 'min', false);
optimization.mostStableDesign = mostStable(summaryTable);
optimization.bestBalancedDesign = optimization.bestFeasibleDesign;
optimization.failedCases = summaryTable(~summaryTable.solverSuccess | ~summaryTable.impactDetected, :);
optimization.constraintViolationSummary = constraintSummary(summaryTable);

writetable(summaryTable, fullfile(config.tableDir, 'Stage13OptimizationResults.csv'));
save(fullfile(config.matDir, 'Stage13OptimizationResults.mat'), 'optimization');

if config.showPlots
    plotOptimizationResults(optimization, config);
end

if config.verbose
    fprintf('  Cases evaluated: %d\n', height(summaryTable));
    fprintf('  Feasible cases: %d\n', sum(summaryTable.feasible));
    if ~isempty(optimization.bestBalancedDesign)
        fprintf('  Best balanced range: %.2f km, score %.3f\n', ...
            optimization.bestBalancedDesign.range_m / 1000, optimization.bestBalancedDesign.score);
    end
end
end

function results = evaluateDesignList(config, designs, startId)
results = repmat(evaluateDesignCase(config, config.baselineDesign, 0), 0, 1);
for k = 1:numel(designs)
    results(end+1, 1) = evaluateDesignCase(config, designs{k}, startId + k - 1); %#ok<AGROW>
end
end

function bestDesign = bestByScore(results)
bestDesign = [];
if isempty(results)
    return;
end
scores = [results.score].';
[bestScore, idx] = max(scores);
if isfinite(bestScore)
    bestDesign = resultToDesign(results(idx));
end
end

function designs = generateLocalDesigns(config, center)
vars = {'launchAngle_deg','initialSpeed_mps','mass_kg','diameter_m','staticMargin','CdMultiplier'};
designs = {};
for k = 1:numel(vars)
    bounds = boundsFor(config, vars{k});
    step = config.optimization.localStepFraction * (bounds(2) - bounds(1));
    for signValue = [-1 1]
        d = center;
        d.(vars{k}) = clamp(d.(vars{k}) + signValue * step, bounds(1), bounds(2));
        d.referenceArea_m2 = pi * d.diameter_m^2 / 4;
        d.finenessRatio = d.length_m / max(d.diameter_m, eps);
        d.cpLocation_m = d.cgLocation_m + d.staticMargin * d.length_m;
        designs{end+1, 1} = d; %#ok<AGROW>
    end
end
end

function d = resultToDesign(r)
d = createDesignVector(struct('mass', r.mass_kg, 'length', r.length_m, ...
    'diameter', r.diameter_m, 'V0', r.initialSpeed_mps, ...
    'launchAngle', r.launchAngle_deg, 'bodyType', char(r.bodyType)), struct());
d.bodyType = r.bodyType;
d.mass_kg = r.mass_kg;
d.length_m = r.length_m;
d.diameter_m = r.diameter_m;
d.staticMargin = r.staticMargin;
d.CdMultiplier = r.CdMultiplier;
d.windSpeed_mps = r.windSpeed_mps;
d.referenceArea_m2 = pi * d.diameter_m^2 / 4;
d.finenessRatio = d.length_m / max(d.diameter_m, eps);
d.cpLocation_m = d.cgLocation_m + d.staticMargin * d.length_m;
end

function bounds = boundsFor(config, name)
switch name
    case 'launchAngle_deg', bounds = config.ranges.launchAngle_deg;
    case 'initialSpeed_mps', bounds = config.ranges.initialSpeed_mps;
    case 'mass_kg', bounds = config.ranges.mass_kg;
    case 'diameter_m', bounds = config.ranges.diameter_m;
    case 'staticMargin', bounds = config.ranges.staticMargin;
    case 'CdMultiplier', bounds = config.ranges.CdMultiplier;
    otherwise, bounds = [0 1];
end
end

function row = bestRow(T, field, mode, feasibleOnly)
if feasibleOnly
    T = T(T.feasible, :);
end
if isempty(T)
    row = table();
    return;
end
values = T.(field);
if strcmpi(mode, 'min')
    values(~isfinite(values)) = Inf;
    [~, idx] = min(values);
else
    values(~isfinite(values)) = -Inf;
    [~, idx] = max(values);
end
row = T(idx,:);
end

function row = mostStable(T)
if isempty(T)
    row = table();
    return;
end
target = 0.15;
[~, idx] = min(abs(T.stabilityMargin - target));
row = T(idx,:);
end

function summary = constraintSummary(T)
labels = string(T.violatedConstraints);
summary = table();
allText = strjoin(labels(labels ~= ""), '; ');
parts = split(string(allText), ';');
parts = strtrim(parts);
parts(parts == "") = [];
if isempty(parts)
    summary.Constraint = strings(0,1);
    summary.Count = zeros(0,1);
    return;
end
u = unique(parts);
counts = zeros(numel(u), 1);
for k = 1:numel(u)
    counts(k) = sum(parts == u(k));
end
summary = table(u, counts, 'VariableNames', {'Constraint','Count'});
end

function y = clamp(x, lo, hi)
y = min(max(x, lo), hi);
end
