function summaryFile = createStage13PortfolioSummary(config)
% createStage13PortfolioSummary
% Writes a portfolio-ready Stage 13 summary.

summaryFile = fullfile(config.reportDir, 'Stage13PortfolioSummary.txt');
fid = fopen(summaryFile, 'w');
if fid < 0
    warning('Stage13:SummaryOpenFailed', 'Could not write Stage 13 portfolio summary.');
    return;
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'Stage 13 Portfolio Summary\n\n');
fprintf(fid, 'Project Title\n');
fprintf(fid, '  MATLAB Hypersonic Trajectory Optimization and Trade Study Suite\n\n');
fprintf(fid, 'Stage 13 Purpose\n');
fprintf(fid, '  Extend the trajectory calculator into a design-analysis environment for constrained optimization,\n');
fprintf(fid, '  uncertainty propagation, sensitivity ranking, Pareto trade studies, and structured DOE.\n\n');
fprintf(fid, 'Capabilities\n');
fprintf(fid, '  - Coarse grid, random search, and local refinement without Optimization Toolbox.\n');
fprintf(fid, '  - Monte Carlo uncertainty analysis for mass, speed, angle, aero multipliers, density, wind, CG, and CP.\n');
fprintf(fid, '  - One-at-a-time normalized sensitivity ranking for range, heating, max q, altitude, and g-load.\n');
fprintf(fid, '  - Pareto front visualization for range/heating, range/max-q, altitude/heating, and score/heating.\n');
fprintf(fid, '  - CSV, MAT, PNG, and text report export for portfolio documentation.\n\n');
fprintf(fid, 'Engineering Concepts Demonstrated\n');
fprintf(fid, '  Trajectory propagation, constraints, scoring functions, uncertainty quantification,\n');
fprintf(fid, '  sensitivity analysis, Pareto efficiency, DOE, and robust failure handling.\n\n');
fprintf(fid, 'Resume Bullets\n');
fprintf(fid, '  - Developed a MATLAB hypersonic trajectory trade-study suite with constrained design optimization, Monte Carlo uncertainty analysis, sensitivity ranking, and Pareto front visualization.\n');
fprintf(fid, '  - Built modular simulation tools to compare vehicle geometry, launch conditions, aerodynamic uncertainty, aerothermal loading, and stability constraints across hundreds of trajectory cases.\n');
fprintf(fid, '  - Automated engineering reports, validation summaries, plots, and CSV exports for portfolio-ready aerospace analysis documentation.\n');
end
