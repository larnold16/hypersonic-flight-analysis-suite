function summaryFile = createStage14PortfolioSummary(state)
% createStage14PortfolioSummary
% Writes the Stage 14 portfolio summary text file.

if nargin < 1 || ~isfield(state, 'reportDir')
    state.reportDir = fullfile(pwd, 'Outputs', 'Stage14', 'Reports');
end
if ~exist(state.reportDir, 'dir')
    mkdir(state.reportDir);
end

summaryFile = fullfile(state.reportDir, 'Stage14PortfolioSummary.txt');
fid = fopen(summaryFile, 'w');
if fid < 0
    warning('Stage14:SummaryOpenFailed', 'Could not write Stage 14 portfolio summary.');
    return;
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'Stage 14 Portfolio Summary\n\n');
fprintf(fid, 'Project Title\n');
fprintf(fid, '  Hypersonic Trajectory Calculator Interactive Engineering App\n\n');
fprintf(fid, 'Purpose\n');
fprintf(fid, '  Programmatic MATLAB GUI for educational trajectory simulation, validation,\n');
fprintf(fid, '  optimization, uncertainty analysis, Pareto trade studies, and reporting.\n\n');
fprintf(fid, 'App Capabilities\n');
fprintf(fid, '  - Vehicle, launch, and physics setup panels.\n');
fprintf(fid, '  - Stage 11 single-trajectory and angle-sweep execution.\n');
fprintf(fid, '  - Stage 12 validation, regression, comparison, and physics diagnostics.\n');
fprintf(fid, '  - Stage 13 optimization, Monte Carlo, Pareto, and DOE studies.\n');
fprintf(fid, '  - Interactive scatter-point selection with CaseID lookup and selected-case export.\n');
fprintf(fid, '  - Scenario save/load and current-session export.\n\n');
fprintf(fid, 'Backend Stages Used\n');
fprintf(fid, '  Stage 11: runStage11, runSingleTrajectory, runAngleSweep, generateStage11Report.\n');
fprintf(fid, '  Stage 12: runStage12, compareStages, runValidationCases, runRegressionTests, runPhysicsDiagnostics.\n');
fprintf(fid, '  Stage 13: runDesignOptimization, runMonteCarloStudy, runParetoStudy, runDesignOfExperiments.\n\n');
fprintf(fid, 'Assumptions and Limitations\n');
fprintf(fid, '  Educational trade-study app only. The app does not add targeting, lethality,\n');
fprintf(fid, '  weapon-effectiveness, or guidance-to-target features. Physics fidelity remains\n');
fprintf(fid, '  limited by the Stage 11-13 backend assumptions.\n\n');
fprintf(fid, 'Resume Bullets\n');
fprintf(fid, '  - Built a programmatic MATLAB engineering app for hypersonic trajectory simulation, validation, Monte Carlo uncertainty analysis, and Pareto trade studies.\n');
fprintf(fid, '  - Added interactive CaseID-based scatter plot inspection and selected-case export for engineering design traceability.\n');
fprintf(fid, '  - Integrated modular MATLAB backends into a portfolio-ready GUI with scenario management, reports, plots, and CSV/MAT exports.\n');
end
