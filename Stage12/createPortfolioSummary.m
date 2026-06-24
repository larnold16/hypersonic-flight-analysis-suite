function summaryFile = createPortfolioSummary(vehicle, constants, config)
% createPortfolioSummary
% Writes a concise portfolio-language summary for the full project.

if nargin < 3
    config = struct('outputRoot', fullfile(pwd, 'Outputs', 'Stage12'));
    config.reportDir = fullfile(config.outputRoot, 'Reports');
end
if ~exist(config.outputRoot, 'dir')
    mkdir(config.outputRoot);
end

summaryFile = fullfile(config.outputRoot, 'PortfolioSummary.txt');
fid = fopen(summaryFile, 'w');
if fid < 0
    warning('Stage12:PortfolioSummaryOpenFailed', 'Could not write portfolio summary.');
    return;
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'Hypersonic Trajectory Calculator Portfolio Summary\n\n');
fprintf(fid, 'Purpose\n');
fprintf(fid, '  Educational MATLAB trajectory, aerodynamics, heating, stability, validation, and trade-study tool.\n\n');
fprintf(fid, 'Stages Completed\n');
fprintf(fid, '  Stages 1-4: projectile motion, atmosphere, Mach-dependent aero, vehicle geometry, and higher-fidelity trajectory modeling.\n');
fprintf(fid, '  Stages 5-10: mission sweeps, body comparisons, thermal estimates, stability checks, weather sensitivity, and simplified 6-DOF dynamics.\n');
fprintf(fid, '  Stage 11: advanced 3-DOF/6-DOF trajectory analysis suite with heating, stability, warnings, plots, and exports.\n');
fprintf(fid, '  Stage 12: validation cases, regression tests, portfolio figures, and engineering documentation.\n\n');
fprintf(fid, 'Validation Methods\n');
fprintf(fid, '  Vacuum projectile closed-form comparison, constant-drag sanity case, atmosphere monotonicity, aero continuity, and energy conservation/loss checks.\n\n');
fprintf(fid, 'Key Assumptions\n');
fprintf(fid, '  Plain MATLAB implementation, empirical aero, simplified heating, and educational rigid-body dynamics.\n\n');
fprintf(fid, 'Limitations\n');
fprintf(fid, '  Not CFD, not flight test validated, not TPS qualification, and not suitable for targeting or weapon-effectiveness analysis.\n\n');
fprintf(fid, 'Future Work Ideas\n');
fprintf(fid, '  Add measured aero tables, higher-fidelity atmosphere, uncertainty calibration, control-system models, and richer validation datasets.\n\n');
fprintf(fid, 'Resume Bullet Examples\n');
fprintf(fid, '  - Built a MATLAB hypersonic trajectory analysis suite with 3-DOF/6-DOF dynamics, aerodynamic heating, stability tracking, and engineering dashboards.\n');
fprintf(fid, '  - Added analytical validation, regression tests, automated plots, CSV/MAT exports, and engineering reports for a portfolio-ready aerospace simulation.\n');
fprintf(fid, '  - Designed modular simulation stages that preserve earlier models while progressively adding physics fidelity and trade-study capability.\n');
end
