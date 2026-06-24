function exportInfo = exportStage13Results(results, config)
% exportStage13Results
% Exports Stage 13 study tables, MAT file, report, and portfolio summary.

if ~exist(config.packageDir, 'dir')
    mkdir(config.packageDir);
end

exportInfo = struct();
save(fullfile(config.matDir, 'Stage13ExportBundle.mat'), 'results', 'config');

fields = fieldnames(results);
for k = 1:numel(fields)
    item = results.(fields{k});
    if isstruct(item) && isfield(item, 'summaryTable')
        file = fullfile(config.tableDir, ['Stage13_', fields{k}, '.csv']);
        writetable(item.summaryTable, file);
        copyfile(file, config.packageDir);
    end
end

reportFile = generateStage13Report(results, config);
summaryFile = createStage13PortfolioSummary(config);
copyIfExists(reportFile, config.packageDir);
copyIfExists(summaryFile, config.packageDir);
copyFolder(config.figureDir, config.packageDir, '*.png');
copyFolder(config.matDir, config.packageDir, '*.mat');

exportInfo.packageDir = config.packageDir;
exportInfo.reportFile = reportFile;
exportInfo.summaryFile = summaryFile;
end

function copyIfExists(file, dest)
if exist(file, 'file') == 2
    copyfile(file, dest);
end
end

function copyFolder(src, dest, pattern)
if exist(src, 'dir') ~= 7
    return;
end
files = dir(fullfile(src, pattern));
for k = 1:numel(files)
    copyfile(fullfile(src, files(k).name), dest);
end
end
