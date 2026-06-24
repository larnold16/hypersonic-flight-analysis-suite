function result = validationAeroContinuityCheck(vehicle, ~, config)
% validationAeroContinuityCheck
% Sweeps Mach number to confirm Stage 11 aerodynamic coefficients are finite
% and reasonably continuous.

try
    vehicle = buildVehicleFromGeometry_stage11(vehicle, 'Custom baseline');
    M = linspace(0.1, 8, 200).';
    CD = zeros(size(M));
    CL = zeros(size(M));
    LD = zeros(size(M));
    atmosphere = struct('T', 288.15, 'P', 101325, 'rho', 1.225, 'a', 340.3, 'mu', 1.8e-5);
    alpha = deg2rad(getField(vehicle, 'alpha_deg', 2));

    for k = 1:numel(M)
        aero = aeroModel_stage11(M(k), alpha, 0, vehicle, atmosphere);
        CD(k) = aero.CD;
        CL(k) = aero.CL;
        LD(k) = aero.LD;
    end

    finiteValues = all(isfinite([CD; CL; LD]));
    maxCdJump = max(abs(diff(CD)));
    transonicRise = max(CD(M > 0.9 & M < 1.3)) > mean(CD(M > 2 & M < 4));
    hypersonicReasonable = all(CD(M > 5) > 0.05 & CD(M > 5) < 1.5);

    result.name = 'Aero continuity check';
    result.Mach = M;
    result.CD = CD;
    result.CL = CL;
    result.LD = LD;
    result.metrics = table(finiteValues, maxCdJump, transonicRise, hypersonicReasonable);
    % A smooth transonic drag rise is expected, so the adjacent-point
    % threshold allows a steep but continuous rise across Mach 1.
    result.passed = finiteValues && maxCdJump < 0.12 && transonicRise && hypersonicReasonable;
    result.message = sprintf('Max adjacent Cd jump %.4f.', maxCdJump);

    if config.showPlots
        fig = figure('Name', 'Stage 12 Aero Continuity Check', 'Visible', config.figureVisible);
        tiledlayout(1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');
        nexttile; plot(M, CD, 'LineWidth', 1.5); grid on; xlabel('Mach'); ylabel('C_D'); title('Drag');
        nexttile; plot(M, CL, 'LineWidth', 1.5); grid on; xlabel('Mach'); ylabel('C_L'); title('Lift');
        nexttile; plot(M, LD, 'LineWidth', 1.5); grid on; xlabel('Mach'); ylabel('L/D'); title('L/D');
        saveas(fig, fullfile(config.figureDir, 'Stage12_AeroContinuityCheck.png'));
    end
catch ME
    result = failedResult('Aero continuity check', ME.message);
end
end

function result = failedResult(name, message)
result.name = name;
result.metrics = table();
result.passed = false;
result.message = message;
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
