function exportInfo = exportStage14Session(appOrState, fileName)
% exportStage14Session
% Exports current Stage 14 state, tables, and available figures.

if isfield(appOrState, 'State')
    state = appOrState.State;
    app = appOrState;
else
    state = appOrState;
    app = struct();
end

if nargin < 2 || isempty(fileName)
    fileName = fullfile(state.sessionDir, ...
        ['Stage14Session_', datestr(now, 'yyyymmdd_HHMMSS'), '.mat']);
end

save(fileName, 'state');

tableFiles = strings(0, 1);
if isfield(state, 'Tables')
    names = fieldnames(state.Tables);
    for k = 1:numel(names)
        T = state.Tables.(names{k});
        if istable(T)
            csv = fullfile(state.tableDir, [names{k}, '.csv']);
            writetable(T, csv);
            tableFiles(end+1, 1) = string(csv); %#ok<AGROW>
        end
    end
end

figureFiles = strings(0, 1);
if isfield(app, 'Figure') && isvalid(app.Figure)
    png = fullfile(state.figureDir, ['Stage14AppWindow_', datestr(now, 'yyyymmdd_HHMMSS'), '.png']);
    try
        exportapp(app.Figure, png);
        figureFiles(end+1, 1) = string(png);
    catch
        % exportapp can fail in some batch or headless contexts. The MAT/CSV
        % session export is still valid.
    end
end

reportFile = fullfile(state.reportDir, ['Stage14SessionReport_', datestr(now, 'yyyymmdd_HHMMSS'), '.txt']);
fid = fopen(reportFile, 'w');
if fid > 0
    fprintf(fid, 'Stage 14 App Session Report\n');
    fprintf(fid, 'Generated: %s\n\n', datestr(now));
    fprintf(fid, 'Last run: %s\n', state.lastRunType);
    fprintf(fid, 'Success: %d\n', state.lastSuccess);
    fprintf(fid, 'Warnings:\n%s\n\n', state.lastWarningText);
    fprintf(fid, 'Output folder: %s\n', state.outputRoot);
    fclose(fid);
end

exportInfo.sessionFile = fileName;
exportInfo.tableFiles = tableFiles;
exportInfo.figureFiles = figureFiles;
exportInfo.reportFile = reportFile;
end
