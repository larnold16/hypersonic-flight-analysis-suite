function validation = runValidationCases(vehicle, constants, config)
% runValidationCases
% Runs the Stage 12 analytical and sanity-check validation cases.

caseNames = {'Vacuum projectile', 'Constant drag projectile', ...
    'Atmosphere sanity check', 'Aero continuity check', 'Energy check'};
caseResults = cell(numel(caseNames), 1);

caseResults{1} = validationVacuumProjectile(vehicle, constants, config);
caseResults{2} = validationConstantDragProjectile(vehicle, constants, config);
caseResults{3} = validationAtmosphereCheck(vehicle, constants, config);
caseResults{4} = validationAeroContinuityCheck(vehicle, constants, config);
caseResults{5} = validationEnergyCheck(vehicle, constants, config);

passed = false(numel(caseNames), 1);
messages = strings(numel(caseNames), 1);
for k = 1:numel(caseNames)
    passed(k) = caseResults{k}.passed;
    messages(k) = string(caseResults{k}.message);
end

summaryTable = table(string(caseNames(:)), passed, messages, ...
    'VariableNames', {'ValidationCase','Passed','Message'});

validation.caseNames = caseNames;
validation.caseResults = caseResults;
validation.summaryTable = summaryTable;
validation.passRate = mean(passed);

if ~exist(config.tableDir, 'dir')
    mkdir(config.tableDir);
end
writetable(summaryTable, fullfile(config.tableDir, 'Stage12ValidationSummary.csv'));
save(fullfile(config.matDir, 'Stage12ValidationResults.mat'), 'validation');

if config.showPlots
    plotValidationResults(validation, config);
end

if config.verbose
    fprintf('\nStage 12 Validation Summary:\n');
    disp(summaryTable);
end
end
