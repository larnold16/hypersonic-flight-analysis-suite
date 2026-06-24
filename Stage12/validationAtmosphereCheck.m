function result = validationAtmosphereCheck(~, ~, config)
% validationAtmosphereCheck
% Sanity-checks the shared atmosphere from 0 to 50 km.

try
    h = (0:500:50000).';
    [T, P, rho, a, mu] = atmosphere1976_simple(h);
    densityDecreases = all(diff(rho) <= 1e-10);
    pressureDecreases = all(diff(P) <= 1e-6);
    finiteValues = all(isfinite([T; P; rho; a; mu]));
    temperatureReasonable = all(T > 150 & T < 330);

    result.name = 'Atmosphere sanity check';
    result.h = h;
    result.T = T;
    result.P = P;
    result.rho = rho;
    result.a = a;
    result.mu = mu;
    result.metrics = table(densityDecreases, pressureDecreases, finiteValues, temperatureReasonable);
    result.passed = densityDecreases && pressureDecreases && finiteValues && temperatureReasonable;
    result.message = sprintf('Density monotonic: %d, pressure monotonic: %d.', ...
        densityDecreases, pressureDecreases);

    if config.showPlots
        fig = figure('Name', 'Stage 12 Atmosphere Check', 'Visible', config.figureVisible);
        tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
        nexttile; plot(T, h / 1000, 'LineWidth', 1.5); grid on; xlabel('T (K)'); ylabel('Altitude (km)');
        nexttile; semilogx(rho, h / 1000, 'LineWidth', 1.5); grid on; xlabel('Density (kg/m^3)'); ylabel('Altitude (km)');
        nexttile; semilogx(P, h / 1000, 'LineWidth', 1.5); grid on; xlabel('Pressure (Pa)'); ylabel('Altitude (km)');
        nexttile; plot(a, h / 1000, 'LineWidth', 1.5); grid on; xlabel('Speed of sound (m/s)'); ylabel('Altitude (km)');
        saveas(fig, fullfile(config.figureDir, 'Stage12_AtmosphereCheck.png'));
    end
catch ME
    result = failedResult('Atmosphere sanity check', ME.message);
end
end

function result = failedResult(name, message)
result.name = name;
result.metrics = table();
result.passed = false;
result.message = message;
end
