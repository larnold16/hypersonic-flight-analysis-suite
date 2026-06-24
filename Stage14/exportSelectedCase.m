function exportFiles = exportSelectedCase(appOrState, baseFileName)
% exportSelectedCase
% Exports the currently selected case to CSV and MAT.

exportFiles = struct('csvFile', "", 'matFile', "");
try
    if isfield(appOrState, 'State')
        state = appOrState.State;
    else
        state = appOrState;
    end

    if ~isfield(state, 'selectedCase') || isempty(state.selectedCase) || height(state.selectedCase) == 0
        warning('Stage14:NoSelectedCase', 'No selected case is available to export.');
        return;
    end

    if nargin < 2 || isempty(baseFileName)
        baseFileName = fullfile(state.tableDir, ...
            ['Stage14SelectedCase_', datestr(now, 'yyyymmdd_HHMMSS')]);
    end

    selectedCase = standardizeCaseTableStage14(state.selectedCase, "SelectedCase");
    csvFile = [baseFileName, '.csv'];
    matFile = [baseFileName, '.mat'];
    writetable(selectedCase, csvFile);
    save(matFile, 'selectedCase');

    exportFiles.csvFile = string(csvFile);
    exportFiles.matFile = string(matFile);
catch ME
    warning('Stage14:SelectedCaseExportFailed', '%s', ME.message);
end
end
