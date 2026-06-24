function results = runStage7(vehicle, constants, stage7Config)
% runStage7
% Runs a simplified Stage 7 thermal loading estimate using Stage 4 outputs.
%
% This is an approximate engineering trade-study model. It is intended for
% relative comparisons and early sizing only; it is not a CFD analysis,
% material response model, or flight-qualified thermal prediction.

if nargin < 3
    stage7Config = struct();
end

if ~isfield(stage7Config, 'verbose')
    stage7Config.verbose = true;
end

if ~isfield(stage7Config, 'showPlots')
    stage7Config.showPlots = true;
end

if isfield(stage7Config, 'trajectoryResults')
    trajectoryResults = stage7Config.trajectoryResults;
else
    trajectoryResults = runStage4Case(vehicle, constants);
end

results = trajectoryResults;
results.thermal = computeThermalLoads_stage7(trajectoryResults, vehicle, constants, stage7Config);

printStage7Summary(results, vehicle, stage7Config.verbose);

if stage7Config.showPlots
    plotStage7ThermalResults(results);
end

end

function trajectoryResults = runStage4Case(vehicle, constants)
% Reuse the Stage 4 trajectory model as the flight-environment source.

if isfield(vehicle, 'launchAngle') && abs(vehicle.launchAngle) > pi
    vehicle.launchAngle = deg2rad(vehicle.launchAngle);
end

if ~isfield(vehicle, 'launchAzimuth') && isfield(vehicle, 'launchAzimuth_deg')
    vehicle.launchAzimuth = deg2rad(vehicle.launchAzimuth_deg);
elseif isfield(vehicle, 'launchAzimuth') && abs(vehicle.launchAzimuth) > 2*pi
    vehicle.launchAzimuth = deg2rad(vehicle.launchAzimuth);
end

if isfield(vehicle, 'M_table_stage3')
    vehicle.M_table = vehicle.M_table_stage3;
end

if isfield(vehicle, 'Cd0_table_stage3')
    vehicle.Cd_table = vehicle.Cd0_table_stage3;
end

[t, state] = runStage4(vehicle, constants);
trajectoryResults = postProcess_stage4(t, state, vehicle, constants);

end

function printStage7Summary(results, vehicle, verbose)
if ~verbose
    return;
end

thermal = results.thermal;

fprintf('Stage 7 Simplified Thermal Loading Summary:\n');
fprintf('Approximate stagnation-point heating estimate for trade studies only.\n');
fprintf('Nose radius used: %.4f m\n', thermal.noseRadius_m);
fprintf('Peak heat flux: %.2f kW/m^2\n', thermal.peakHeatFlux_W_m2 / 1000);
fprintf('Time of peak heat flux: %.2f s\n', thermal.peakHeatFluxTime_s);
fprintf('Total heat load: %.4f MJ/m^2\n', thermal.totalHeatLoad_J_m2 / 1e6);
fprintf('Peak stagnation temperature: %.2f K\n', thermal.peakStagnationTemp_K);
fprintf('Time of peak stagnation temperature: %.2f s\n', thermal.peakStagnationTempTime_s);

if isfield(thermal, 'maxWallTemp_K')
    fprintf('Maximum estimated wall temperature: %.2f K\n', thermal.maxWallTemp_K);
end

if isfield(vehicle, 'maxAllowableWallTemp_K') && isfield(thermal, 'maxWallTemp_K')
    thermalMargin_K = vehicle.maxAllowableWallTemp_K - thermal.maxWallTemp_K;
    fprintf('Thermal margin to allowable wall temperature: %.2f K\n', thermalMargin_K);
end

fprintf('\n');

end
