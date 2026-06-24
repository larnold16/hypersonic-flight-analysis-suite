function packageDir = exportPortfolioPackage(vehicle, constants, config)
% exportPortfolioPackage
% Builds a self-contained Stage 12 portfolio package folder.

packageDir = config.packageDir;
if ~exist(packageDir, 'dir')
    mkdir(packageDir);
end

validation = runValidationCases(vehicle, constants, config);
regression = runRegressionTests(vehicle, constants, config);
createPortfolioFigures(vehicle, constants, config);
summaryFile = createPortfolioSummary(vehicle, constants, config);
reportFile = generateFinalEngineeringReport(vehicle, constants, validation, regression, config);

copyIfExists(summaryFile, packageDir);
copyIfExists(reportFile, packageDir);

copyFolderFiles(config.figureDir, packageDir, '*.png');
copyFolderFiles(config.tableDir, packageDir, '*.csv');
copyFolderFiles(config.matDir, packageDir, '*.mat');

manifest = fullfile(packageDir, 'PackageManifest.txt');
fid = fopen(manifest, 'w');
if fid > 0
    fprintf(fid, 'Stage 12 Portfolio Package\nGenerated: %s\n\n', datestr(now));
    listing = dir(packageDir);
    for k = 1:numel(listing)
        if ~listing(k).isdir
            fprintf(fid, '%s\n', listing(k).name);
        end
    end
    fclose(fid);
end
end

function copyIfExists(file, dest)
if exist(file, 'file') == 2
    copyfile(file, dest);
end
end

function copyFolderFiles(src, dest, pattern)
if exist(src, 'dir') ~= 7
    return;
end
files = dir(fullfile(src, pattern));
for k = 1:numel(files)
    copyfile(fullfile(src, files(k).name), dest);
end
end
