function state = loadStage14Scenario(state, fileName)
% loadStage14Scenario
% Loads a Stage 14 scenario MAT file into an existing app state.

if nargin < 2 || isempty(fileName)
    error('Stage14:MissingScenarioFile', 'A scenario MAT file path is required.');
end

loaded = load(fileName, 'scenario');
if ~isfield(loaded, 'scenario')
    error('Stage14:InvalidScenarioFile', 'The selected MAT file does not contain a scenario struct.');
end

scenario = loaded.scenario;
fields = {'vehicle','constants','launch','physics','monteCarlo','optimization', ...
    'builder','compare','sensitivity','fidelity','constraints','optimizationMode', ...
    'uncertainty','outputRoot'};
for k = 1:numel(fields)
    if isfield(scenario, fields{k})
        state.(fields{k}) = scenario.(fields{k});
    end
end

state.figureDir = fullfile(state.outputRoot, 'Figures');
state.tableDir = fullfile(state.outputRoot, 'Tables');
state.reportDir = fullfile(state.outputRoot, 'Reports');
state.matDir = fullfile(state.outputRoot, 'MAT');
state.sessionDir = fullfile(state.outputRoot, 'Sessions');

folders = {state.outputRoot, state.figureDir, state.tableDir, state.reportDir, state.matDir, state.sessionDir};
for k = 1:numel(folders)
    if ~exist(folders{k}, 'dir')
        mkdir(folders{k});
    end
end
end
