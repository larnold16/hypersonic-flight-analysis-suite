function results = runStage8(vehicle, constants, stage8Config)
% runStage8
% Runs a simplified Stage 8 stability, trim, and maneuverability estimate.
%
% Stage 8 is a first-order engineering trade-study model based on simplified
% CG/CP assumptions, aerodynamic coefficient trends, and point-mass Stage 4
% trajectory data. It is not a CFD model, wind-tunnel correlation, control
% law, or 6-DOF simulation.

if nargin < 3
    stage8Config = struct();
end

if ~isfield(stage8Config, 'verbose')
    stage8Config.verbose = true;
end

if ~isfield(stage8Config, 'showPlots')
    stage8Config.showPlots = true;
end

if isfield(stage8Config, 'trajectoryResults')
    trajectoryResults = stage8Config.trajectoryResults;
else
    trajectoryResults = runStage4Case(vehicle, constants);
end

stability = computeStability_stage8(trajectoryResults, vehicle, constants, stage8Config);
stability.trim = computeTrim_stage8(stability, vehicle, stage8Config);
stability.maneuverability = computeManeuverability_stage8(trajectoryResults, vehicle, constants, stage8Config);

stability.trimAlpha_deg = stability.trim.trimAlpha_deg;
stability.trimFeasible = stability.trim.trimFeasible;
stability.normalAcceleration_g = stability.maneuverability.normalAcceleration_g;
stability.maxNormalAcceleration_g = stability.maneuverability.maxNormalAcceleration_g;
stability.targetNormalLoad_g = stability.maneuverability.targetNormalLoad_g;
stability.meetsTargetNormalLoad = stability.maneuverability.meetsTargetNormalLoad;

results = trajectoryResults;
results.stability = stability;

printStage8Summary(results, vehicle, stage8Config.verbose);

if stage8Config.showPlots
    plotStage8StabilityResults(results);
end

end

function trajectoryResults = runStage4Case(vehicle, constants)
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

function printStage8Summary(results, vehicle, verbose)
if ~verbose
    return;
end

stability = results.stability;
trim = stability.trim;
maneuver = stability.maneuverability;

fprintf('Stage 8 Simplified Stability / Trim / Maneuverability Summary:\n');
fprintf('Approximate engineering trade-study estimate only; not CFD or 6-DOF validated.\n\n');

fprintf('Static Stability Assumptions:\n');
fprintf('  x-axis is measured aft from the nose.\n');
fprintf('  Positive static margin means CP is behind CG and is treated as statically stable in pitch.\n');
fprintf('  CG location: %.4f m (%.1f %% body length)\n', ...
    stability.cgLocation_m, 100 * stability.cgLocation_m / vehicle.length);
fprintf('  CP location: %.4f m (%.1f %% body length)\n', ...
    stability.cpLocation_m, 100 * stability.cpLocation_m / vehicle.length);
fprintf('  Static margin: %.2f %% body length\n', ...
    stability.staticMargin_percentLength);
fprintf('  Stability classification: %s\n\n', stability.classification);

fprintf('Trim Estimate:\n');
if isnan(trim.nominalTrimAlpha_deg)
    fprintf('  Estimated trim angle of attack: unavailable\n');
else
    fprintf('  Estimated trim angle of attack near Mach %.1f: %.2f deg\n', ...
        trim.nominalTrimMach, trim.nominalTrimAlpha_deg);
end
fprintf('  Trim feasible within +/- %.2f deg AoA: %s\n', ...
    trim.maxAllowableAlpha_deg, yesNo(trim.trimFeasible));
fprintf('  Trim model: Cm = Cm0 + Cm_alpha * alpha, with simplified Cm_alpha from static margin and CL_alpha unless provided.\n\n');

fprintf('Maneuverability Estimate:\n');
fprintf('  Maximum estimated normal acceleration: %.2f g\n', ...
    maneuver.maxNormalAcceleration_g);
fprintf('  Time of max normal acceleration: %.2f s\n', ...
    maneuver.maxNormalAccelerationTime_s);
fprintf('  Target maneuver load: %.2f g\n', maneuver.targetNormalLoad_g);
fprintf('  Target maneuver load met: %s\n', yesNo(maneuver.meetsTargetNormalLoad));
fprintf('  At max-Q: %.2f g normal acceleration, CL required for target = %.3f\n\n', ...
    maneuver.normalAccelerationAtMaxQ_g, maneuver.CLRequiredAtMaxQ);

fprintf('Future work: replace this estimate with full 6-DOF dynamics, control-surface modeling,\n');
fprintf('aerodynamic moment derivatives, and CFD/wind-tunnel validation when those data are available.\n\n');
end

function text = yesNo(value)
if value
    text = 'yes';
else
    text = 'no';
end
end
