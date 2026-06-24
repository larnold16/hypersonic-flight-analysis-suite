function exportInfo = exportStage11Results(results, config)
% exportStage11Results
% Exports Stage 11 tables, MAT files, and available figures.

if nargin < 2
    config = results.config;
end

ensureFolder(config.tableDir);
ensureFolder(config.matDir);

timestamp = datestr(now, 'yyyymmdd_HHMMSS');
matFile = fullfile(config.matDir, ['Stage11Results_', timestamp, '.mat']);
save(matFile, 'results', 'config');

if isfield(results, 'summaryTable')
    csvFile = fullfile(config.tableDir, ['Stage11Summary_', timestamp, '.csv']);
    writetable(results.summaryTable, csvFile);
else
    csvFile = fullfile(config.tableDir, ['Stage11SingleSummary_', timestamp, '.csv']);
    T = singleSummaryTable(results);
    writetable(T, csvFile);
end

exportInfo.matFile = matFile;
exportInfo.csvFile = csvFile;

if isfield(results, 'config')
    results.config.stage11ExportInfo = exportInfo; %#ok<NASGU>
end
end

function T = singleSummaryTable(r)
T = table(r.range, r.maxAltitude, r.timeOfFlight, r.impactSpeed, r.maxMach, ...
    r.maxQ, r.maxStagTemp, r.maxHeatingRate, r.totalHeatLoad, r.maxGLoad, ...
    r.minStaticMargin, r.impactDetected, ...
    'VariableNames', {'Range_m','MaxAltitude_m','TimeOfFlight_s','ImpactSpeed_mps', ...
    'MaxMach','MaxQ_Pa','MaxStagnationTemp_K','MaxHeating_W_m2','TotalHeatLoad_J_m2', ...
    'MaxGLoad_g','MinStaticMargin','ImpactDetected'});
end

function ensureFolder(folder)
if ~exist(folder, 'dir')
    mkdir(folder);
end
end
