function fileName = saveStage14Scenario(state, fileName)
% saveStage14Scenario
% Saves vehicle, launch, physics, uncertainty, optimization, and constraint
% settings as a Stage 14 scenario MAT file.

if nargin < 2 || isempty(fileName)
    if ~isfield(state, 'sessionDir') || isempty(state.sessionDir)
        state.sessionDir = fullfile(pwd, 'Outputs', 'Stage14', 'Sessions');
    end
    if ~exist(state.sessionDir, 'dir')
        mkdir(state.sessionDir);
    end
    fileName = fullfile(state.sessionDir, ...
        ['Stage14Scenario_', datestr(now, 'yyyymmdd_HHMMSS'), '.mat']);
end

scenario = struct();
scenario.vehicle = state.vehicle;
scenario.constants = state.constants;
scenario.launch = state.launch;
scenario.physics = state.physics;
scenario.monteCarlo = state.monteCarlo;
scenario.optimization = state.optimization;
if isfield(state, 'builder')
    scenario.builder = state.builder;
end
if isfield(state, 'compare')
    scenario.compare = state.compare;
end
if isfield(state, 'sensitivity')
    scenario.sensitivity = state.sensitivity;
end
if isfield(state, 'fidelity')
    scenario.fidelity = state.fidelity;
end
if isfield(state, 'constraints')
    scenario.constraints = state.constraints;
end
if isfield(state, 'optimizationMode')
    scenario.optimizationMode = state.optimizationMode;
end
if isfield(state, 'uncertainty')
    scenario.uncertainty = state.uncertainty;
end
scenario.outputRoot = state.outputRoot;

save(fileName, 'scenario');
end
