function pareto = runParetoStudy(config)
% runParetoStudy
% Generates feasible designs and identifies Pareto-efficient tradeoffs.

reportProgress(config, 0.03, "Generating Pareto design set...");
designs = generateRandomDesigns(config, config.pareto.numCases);
results = repmat(evaluateDesignCase(config, config.baselineDesign, 0), 0, 1);
for k = 1:numel(designs)
    results(end+1, 1) = evaluateDesignCase(config, designs{k}, k); %#ok<AGROW>
    if shouldReportProgress(k, numel(designs))
        reportProgress(config, 0.05 + 0.80 * k / max(numel(designs), 1), ...
            sprintf('Pareto design %d of %d', k, numel(designs)));
    end
end

reportProgress(config, 0.87, "Computing Pareto fronts...");
T = struct2table(results);
F = T(T.feasible, :);
if isempty(F)
    F = T;
end

pareto.summaryTable = T;
pareto.rangeHeatingFront = F(isPareto([F.range_m, -F.maxHeating_W_m2]), :);
pareto.rangeQFront = F(isPareto([F.range_m, -F.maxQ_Pa]), :);
pareto.altitudeHeatingFront = F(isPareto([F.maxAltitude_m, -F.maxHeating_W_m2]), :);
pareto.rangeGFront = F(isPareto([F.range_m, -F.maxGLoad_g]), :);
pareto.scoreHeatingFront = F(isPareto([F.score, -F.maxHeating_W_m2]), :);
pareto.topFiveRangeHeating = topN(pareto.rangeHeatingFront, 'range_m', 5);

reportProgress(config, 0.89, "Saving Pareto outputs...");
writetable(T, fullfile(config.tableDir, 'Stage13ParetoResults.csv'));
save(fullfile(config.matDir, 'Stage13ParetoResults.mat'), 'pareto');

if config.showPlots
    plotParetoResults(pareto, config);
end
reportProgress(config, 0.90, "Pareto study finished.");
end

function flag = isPareto(objectives)
n = size(objectives, 1);
flag = true(n, 1);
for i = 1:n
    for j = 1:n
        if all(objectives(j,:) >= objectives(i,:)) && any(objectives(j,:) > objectives(i,:))
            flag(i) = false;
            break;
        end
    end
end
end

function Tn = topN(T, field, N)
if isempty(T)
    Tn = T;
    return;
end
[~, idx] = sort(T.(field), 'descend');
idx = idx(1:min(N, numel(idx)));
Tn = T(idx,:);
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
