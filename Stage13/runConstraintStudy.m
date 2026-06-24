function study = runConstraintStudy(config, studyType)
% runConstraintStudy
% Runs focused launch-angle or geometry optimization studies.

if nargin < 2
    studyType = 'launch';
end

switch lower(studyType)
    case 'launch'
        angles = config.ranges.launchAngle_deg(1):5:config.ranges.launchAngle_deg(2);
        designs = cell(numel(angles), 1);
        for k = 1:numel(angles)
            d = config.baselineDesign;
            d.launchAngle_deg = angles(k);
            designs{k} = d;
        end
        titleText = 'Launch angle optimization';
    case 'geometry'
        bodyTypes = config.ranges.bodyTypes;
        designs = {};
        for b = 1:numel(bodyTypes)
            for m = [config.ranges.mass_kg(1), mean(config.ranges.mass_kg), config.ranges.mass_kg(2)]
                d = config.baselineDesign;
                d.bodyType = string(bodyTypes{b});
                d.mass_kg = m;
                d.length_m = mean(config.ranges.length_m);
                d.diameter_m = mean(config.ranges.diameter_m);
                d.staticMargin = mean(config.ranges.staticMargin);
                d.referenceArea_m2 = pi * d.diameter_m^2 / 4;
                d.finenessRatio = d.length_m / d.diameter_m;
                d.cpLocation_m = d.cgLocation_m + d.staticMargin * d.length_m;
                designs{end+1, 1} = d; %#ok<AGROW>
            end
        end
        titleText = 'Vehicle geometry optimization';
    otherwise
        error('Unknown constraint study type: %s', studyType);
end

results = repmat(evaluateDesignCase(config, config.baselineDesign, 0), 0, 1);
for k = 1:numel(designs)
    results(end+1, 1) = evaluateDesignCase(config, designs{k}, k); %#ok<AGROW>
end

summaryTable = struct2table(results);
study.studyType = studyType;
study.title = titleText;
study.summaryTable = summaryTable;
study.bestRange = selectRow(summaryTable, 'range_m', 'max');
study.lowestQ = selectRow(summaryTable, 'maxQ_Pa', 'min');
study.lowestHeating = selectRow(summaryTable, 'maxHeating_W_m2', 'min');
study.bestScore = selectRow(summaryTable(summaryTable.feasible, :), 'score', 'max');

writetable(summaryTable, fullfile(config.tableDir, ['Stage13_', studyType, '_Study.csv']));
if config.showPlots
    plotOptimizationResults(study, config);
end
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
