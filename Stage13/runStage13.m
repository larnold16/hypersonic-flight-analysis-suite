function results = runStage13(vehicle, constants, stage13Config)
% runStage13
% Entry point for Stage 13 optimization, uncertainty, sensitivity, Pareto,
% and design-of-experiments trade studies.

if nargin < 3
    stage13Config = struct();
end

config = buildStage13Config(vehicle, constants, stage13Config);

if isempty(config.mode)
    if config.interactive
        config.mode = stage13Dashboard();
    else
        config.mode = 1;
    end
end

switch round(config.mode)
    case 1
        results.optimization = runDesignOptimization(config);
    case 2
        results.launchAngleOptimization = runConstraintStudy(config, 'launch');
    case 3
        results.geometryOptimization = runConstraintStudy(config, 'geometry');
    case 4
        results.monteCarlo = runMonteCarloStudy(config);
    case 5
        results.sensitivity = runSensitivityStudy(config);
    case 6
        results.pareto = runParetoStudy(config);
    case 7
        results.doe = runDesignOfExperiments(config);
    case 8
        quick = runDesignOptimization(config);
        results.reportFile = generateStage13Report(quick, config);
    case 9
        quick.optimization = runDesignOptimization(config);
        quick.portfolioSummary = createStage13PortfolioSummary(config);
        results.export = exportStage13Results(quick, config);
    otherwise
        warning('Stage13:InvalidMode', ...
            'Invalid Stage 13 mode. Running constrained design optimization.');
        results.optimization = runDesignOptimization(config);
end

results.stage = 13;
results.config = config;

if config.verbose
    fprintf('\nStage 13 complete. Outputs root: %s\n', config.outputRoot);
end
end
