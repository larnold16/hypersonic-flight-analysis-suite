function sensitivity = runSensitivityStudy(config)
% runSensitivityStudy
% One-at-a-time normalized sensitivity around the baseline.

variables = {'initialSpeed_mps','launchAngle_deg','mass_kg','diameter_m','length_m', ...
    'CdMultiplier','CLalphaMultiplier','cgLocation_m','cpLocation_m','windSpeed_mps','densityMultiplier'};
outputs = {'range_m','maxAltitude_m','maxQ_Pa','maxHeating_W_m2','maxGLoad_g'};

baseline = evaluateDesignCase(config, config.baselineDesign, 1);
rows = {};

for v = 1:numel(variables)
    name = variables{v};
    baseDesign = config.baselineDesign;
    delta = perturbation(baseDesign, name);
    dPlus = baseDesign;
    dMinus = baseDesign;
    dPlus.(name) = dPlus.(name) + delta;
    dMinus.(name) = dMinus.(name) - delta;
    dPlus = repairDesign(dPlus);
    dMinus = repairDesign(dMinus);

    plus = evaluateDesignCase(config, dPlus, 100 + v);
    minus = evaluateDesignCase(config, dMinus, 200 + v);

    inputDenom = max(abs(2 * delta / max(abs(baseDesign.(name)), 1e-8)), 1e-8);
    for o = 1:numel(outputs)
        out = outputs{o};
        baseOut = baseline.(out);
        sens = ((plus.(out) - minus.(out)) / max(abs(baseOut), 1e-8)) / inputDenom;
        rows(end+1, :) = {string(name), string(out), sens, plus.(out), minus.(out)}; %#ok<AGROW>
    end
end

summaryTable = cell2table(rows, 'VariableNames', ...
    {'Variable','OutputMetric','NormalizedSensitivity','PlusValue','MinusValue'});
sensitivity.baseline = baseline;
sensitivity.summaryTable = summaryTable;
sensitivity.rangeRanking = rankFor(summaryTable, 'range_m');
sensitivity.heatingRanking = rankFor(summaryTable, 'maxHeating_W_m2');
sensitivity.maxQRanking = rankFor(summaryTable, 'maxQ_Pa');
sensitivity.stabilityRanking = table(string({'cgLocation_m';'cpLocation_m';'staticMargin'}), ...
    [1; 1; 1], 'VariableNames', {'Variable','RelativeImportance'});

writetable(summaryTable, fullfile(config.tableDir, 'Stage13SensitivityResults.csv'));
save(fullfile(config.matDir, 'Stage13SensitivityResults.mat'), 'sensitivity');

if config.showPlots
    plotSensitivityResults(sensitivity, config);
end
end

function delta = perturbation(d, name)
value = d.(name);
if strcmp(name, 'launchAngle_deg')
    delta = 1;
elseif strcmp(name, 'windSpeed_mps')
    delta = 5;
elseif abs(value) < 1e-8
    delta = 0.05;
else
    delta = 0.05 * abs(value);
end
end

function d = repairDesign(d)
d.referenceArea_m2 = pi * d.diameter_m^2 / 4;
d.finenessRatio = d.length_m / max(d.diameter_m, eps);
d.staticMargin = (d.cpLocation_m - d.cgLocation_m) / max(d.length_m, eps);
end

function ranking = rankFor(T, outputName)
S = T(T.OutputMetric == string(outputName), :);
[~, idx] = sort(abs(S.NormalizedSensitivity), 'descend');
ranking = S(idx, {'Variable','NormalizedSensitivity'});
end
