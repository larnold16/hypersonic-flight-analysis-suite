function app = saveCurrentRun(app)
% saveCurrentRun
% Stores the current single trajectory for comparison.

if ~isfield(app.State, 'Results') || ~isfield(app.State.Results, 'single')
    error('Stage14:NoSingleRun', 'Run a single trajectory before saving a comparison run.');
end
if ~isfield(app.State, 'savedRuns') || isempty(app.State.savedRuns)
    app.State.savedRuns = struct([]);
end
if ~isfield(app.State, 'savedRunCounter') || isempty(app.State.savedRunCounter)
    app.State.savedRunCounter = 0;
end
app.State.savedRunCounter = app.State.savedRunCounter + 1;
runName = sprintf('Run %d', app.State.savedRunCounter);
entry = struct();
entry.Name = string(runName);
entry.Timestamp = string(datestr(now));
entry.Results = app.State.Results.single;
entry.Vehicle = app.State.vehicle;
entry.Launch = app.State.launch;
app.State.savedRuns(end+1) = entry;
app = updateComparisonTable(app);
end
