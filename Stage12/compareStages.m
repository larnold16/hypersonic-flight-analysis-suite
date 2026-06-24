function comparison = compareStages(vehicle, constants, config)
% compareStages
% Runs available Stage 1, Stage 2, Stage 3, and Stage 11 cases for a common
% baseline and produces a summary table.

stageNumber = [];
modelDescription = strings(0, 1);
range = [];
maxAltitude = [];
impactSpeed = [];
maxMach = [];
maxQ = [];
maxStagTemp = [];
notes = strings(0, 1);
trajectories = {};
trajectoryLabels = {};

runIfAvailable(1, 'Baseline 2D projectile with drag', 'runStage1', 'postProcess_stage1');
runIfAvailable(2, 'Variable atmosphere and Mach-dependent drag', 'runStage2', 'postProcess_stage2');
runIfAvailable(3, 'Vehicle geometry with lift/drag aero', 'runStage3', 'postProcess_stage3');

try
    stage11Cfg = buildStage11Config(vehicle, constants, struct( ...
        'showPlots', false, 'exportResults', false, 'generateReport', false, ...
        'verbose', false, 'interactive', false, 'figureVisible', 'off', ...
        'outputRoot', fullfile(config.outputRoot, 'StageComparisonStage11')));
    r11 = runSingleTrajectory(vehicle, constants, stage11Cfg);
    appendRow(11, 'Stage 11 3-DOF suite with heating/stability', r11, 'Stage 11 available');
catch ME
    appendMissing(11, 'Stage 11 3-DOF suite with heating/stability', ME.message);
end

summaryTable = table(stageNumber(:), modelDescription(:), range(:), maxAltitude(:), ...
    impactSpeed(:), maxMach(:), maxQ(:), maxStagTemp(:), notes(:), ...
    'VariableNames', {'Stage','ModelDescription','Range_m','MaxAltitude_m', ...
    'ImpactSpeed_mps','MaxMach','MaxQ_Pa','MaxStagnationTemp_K','Notes'});

comparison.summaryTable = summaryTable;
comparison.trajectories = trajectories;
comparison.trajectoryLabels = trajectoryLabels;

writetable(summaryTable, fullfile(config.tableDir, 'Stage12StageComparison.csv'));

if config.showPlots && ~isempty(trajectories)
    fig = figure('Name', 'Stage 12 Stage Comparison', 'Visible', config.figureVisible);
    tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
    nexttile; hold on; grid on; title('Trajectory'); xlabel('Range (km)'); ylabel('Altitude (km)');
    for k = 1:numel(trajectories), plot(trajectories{k}.x / 1000, trajectories{k}.h / 1000, 'LineWidth', 1.5); end
    legend(trajectoryLabels, 'Location', 'best');
    nexttile; hold on; grid on; title('Velocity'); xlabel('Time (s)'); ylabel('V (m/s)');
    for k = 1:numel(trajectories), plot(trajectories{k}.t, trajectories{k}.V, 'LineWidth', 1.5); end
    nexttile; hold on; grid on; title('Mach'); xlabel('Time (s)'); ylabel('Mach');
    for k = 1:numel(trajectories), if isfield(trajectories{k}, 'Mach'), plot(trajectories{k}.t, trajectories{k}.Mach, 'LineWidth', 1.5); end, end
    nexttile; hold on; grid on; title('Dynamic Pressure'); xlabel('Time (s)'); ylabel('q (kPa)');
    for k = 1:numel(trajectories), if isfield(trajectories{k}, 'q'), plot(trajectories{k}.t, trajectories{k}.q / 1000, 'LineWidth', 1.5); end, end
    saveas(fig, fullfile(config.figureDir, 'Stage12_StageComparison.png'));
end

    function runIfAvailable(stage, description, runName, postName)
        if exist(runName, 'file') == 2 && exist(postName, 'file') == 2
            try
                [t, state] = feval(runName, vehicle, constants);
                r = feval(postName, t, state, vehicle, constants);
                appendRow(stage, description, r, 'Available');
            catch ME
                appendMissing(stage, description, ME.message);
            end
        else
            appendMissing(stage, description, 'Stage functions not on path.');
        end
    end

    function appendRow(stage, description, r, note)
        stageNumber(end+1) = stage; %#ok<AGROW>
        modelDescription(end+1) = string(description); %#ok<AGROW>
        range(end+1) = getField(r, 'range', NaN); %#ok<AGROW>
        maxAltitude(end+1) = getField(r, 'maxAltitude', NaN); %#ok<AGROW>
        impactSpeed(end+1) = getField(r, 'impactSpeed', NaN); %#ok<AGROW>
        maxMach(end+1) = getField(r, 'maxMach', NaN); %#ok<AGROW>
        maxQ(end+1) = getField(r, 'maxQ', NaN); %#ok<AGROW>
        maxStagTemp(end+1) = getField(r, 'maxStagTemp', NaN); %#ok<AGROW>
        notes(end+1) = string(note); %#ok<AGROW>
        if isfield(r, 'x') && isfield(r, 'h') && isfield(r, 't') && isfield(r, 'V')
            trajectories{end+1} = r; %#ok<AGROW>
            trajectoryLabels{end+1} = sprintf('Stage %d', stage); %#ok<AGROW>
        end
    end

    function appendMissing(stage, description, note)
        stageNumber(end+1) = stage; %#ok<AGROW>
        modelDescription(end+1) = string(description); %#ok<AGROW>
        range(end+1) = NaN; maxAltitude(end+1) = NaN; impactSpeed(end+1) = NaN; %#ok<AGROW>
        maxMach(end+1) = NaN; maxQ(end+1) = NaN; maxStagTemp(end+1) = NaN; %#ok<AGROW>
        notes(end+1) = string(note); %#ok<AGROW>
    end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
