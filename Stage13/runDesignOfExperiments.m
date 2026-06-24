function doe = runDesignOfExperiments(config)
% runDesignOfExperiments
% Structured reduced-factorial design study.

angles = [10 25 40];
masses = [4 6];
diameters = [0.045 0.065];
lengths = [0.45 0.70];
noseTypes = {'sharp cone','ogive','blunt'};
cdMultipliers = [0.9 1.1];

designs = {};
for a = angles
    for m = masses
        for d = diameters
            for L = lengths
                for n = 1:numel(noseTypes)
                    for cd = cdMultipliers
                        dv = config.baselineDesign;
                        dv.launchAngle_deg = a;
                        dv.mass_kg = m;
                        dv.diameter_m = d;
                        dv.length_m = L;
                        dv.noseType = string(noseTypes{n});
                        dv.bodyType = string(bodyFromNose(noseTypes{n}));
                        dv.CdMultiplier = cd;
                        dv.referenceArea_m2 = pi * dv.diameter_m^2 / 4;
                        dv.finenessRatio = dv.length_m / dv.diameter_m;
                        dv.cpLocation_m = dv.cgLocation_m + dv.staticMargin * dv.length_m;
                        designs{end+1, 1} = dv; %#ok<AGROW>
                    end
                end
            end
        end
    end
end

if numel(designs) > config.doe.maxCases
    stride = ceil(numel(designs) / config.doe.maxCases);
    designs = designs(1:stride:end);
end

results = repmat(evaluateDesignCase(config, config.baselineDesign, 0), 0, 1);
for k = 1:numel(designs)
    results(end+1, 1) = evaluateDesignCase(config, designs{k}, k); %#ok<AGROW>
end

summaryTable = struct2table(results);
doe.summaryTable = summaryTable;
doe.bestCase = selectRow(summaryTable, 'score', 'max');
doe.worstCase = selectRow(summaryTable, 'score', 'min');
doe.mainEffects = mainEffects(summaryTable);

writetable(summaryTable, fullfile(config.tableDir, 'Stage13DOEResults.csv'));
save(fullfile(config.matDir, 'Stage13DOEResults.mat'), 'doe');

if config.showPlots
    plotOptimizationResults(doe, config);
end
end

function body = bodyFromNose(nose)
switch lower(nose)
    case 'blunt'
        body = 'Blunt nose';
    case 'ogive'
        body = 'Ogive nose';
    otherwise
        body = 'Slender cone';
end
end

function effects = mainEffects(T)
vars = {'launchAngle_deg','mass_kg','diameter_m','length_m','CdMultiplier'};
rows = {};
for v = 1:numel(vars)
    levels = unique(T.(vars{v}));
    for k = 1:numel(levels)
        idx = T.(vars{v}) == levels(k);
        rows(end+1, :) = {string(vars{v}), levels(k), mean(T.range_m(idx), 'omitnan'), ...
            mean(T.maxHeating_W_m2(idx), 'omitnan'), mean(T.score(idx), 'omitnan')}; %#ok<AGROW>
    end
end
effects = cell2table(rows, 'VariableNames', {'Variable','Level','MeanRange_m','MeanHeating_W_m2','MeanScore'});
end

function row = selectRow(T, field, mode)
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
