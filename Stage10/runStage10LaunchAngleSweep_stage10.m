function sweepResults = runStage10LaunchAngleSweep_stage10(vehicle, constants, stage10Config)
% runStage10LaunchAngleSweep_stage10
% Runs a small launch-angle trade study using the simplified Stage 10 6-DOF
% prototype. This is not a validated flight-dynamics optimization.

if ~isfield(stage10Config, 'launchAngles_deg')
    stage10Config.launchAngles_deg = [5 15 25 35 45];
end

launchAngles_deg = stage10Config.launchAngles_deg(:);
nCases = numel(launchAngles_deg);

caseResults = cell(nCases, 1);
impactDetected = false(nCases, 1);
impactTime_s = nan(nCases, 1);
impactRange_m = nan(nCases, 1);
impactLateral_m = nan(nCases, 1);
impactSpeed_mps = nan(nCases, 1);
impactMach = nan(nCases, 1);
maxAltitude_m = nan(nCases, 1);
maxMach = nan(nCases, 1);
maxQ_Pa = nan(nCases, 1);
maxAlpha_deg = nan(nCases, 1);
maxPitchRate_deg_s = nan(nCases, 1);
maxYawRate_deg_s = nan(nCases, 1);
attitudeBounded = false(nCases, 1);

fprintf('Stage 10 Simplified 6-DOF Launch-Angle Sweep\n');
fprintf('Approximate trade study only; not CFD, wind-tunnel, or flight validated.\n\n');

for k = 1:nCases
    vehicleCase = vehicle;
    vehicleCase.launchAngle = launchAngles_deg(k);

    caseConfig = stage10Config;
    caseConfig.mode = 1;
    caseConfig.showPlots = false;
    caseConfig.verbose = false;

    fprintf('  Running launch angle %.2f deg (%d/%d)...\n', ...
        launchAngles_deg(k), k, nCases);

    caseResult = runStage10(vehicleCase, constants, caseConfig);
    caseResults{k} = caseResult;

    impactDetected(k) = caseResult.impactDetected;
    impactTime_s(k) = caseResult.impactTime_s;
    impactRange_m(k) = caseResult.impactRange_m;
    impactLateral_m(k) = caseResult.impactLateral_m;
    impactSpeed_mps(k) = caseResult.impactSpeed_mps;
    impactMach(k) = caseResult.impactMach;
    maxAltitude_m(k) = caseResult.maxAltitude_m;
    maxMach(k) = caseResult.maxMach;
    maxQ_Pa(k) = max(caseResult.qbar_Pa);
    maxAlpha_deg(k) = caseResult.maxAlpha_deg;
    maxPitchRate_deg_s(k) = caseResult.maxPitchRate_deg_s;
    maxYawRate_deg_s(k) = caseResult.maxYawRate_deg_s;
    attitudeBounded(k) = caseResult.attitudeWithinPresetBounds;
end

sweepResults.mode = 2;
sweepResults.modelNote = ['Simplified Stage 10 6-DOF launch-angle sweep ', ...
    'using approximate aerodynamics and damping; not validated.'];
sweepResults.caseResults = caseResults;
sweepResults.launchAngles_deg = launchAngles_deg;
sweepResults.impactDetected = impactDetected;
sweepResults.impactTime_s = impactTime_s;
sweepResults.impactRange_m = impactRange_m;
sweepResults.impactLateral_m = impactLateral_m;
sweepResults.impactSpeed_mps = impactSpeed_mps;
sweepResults.impactMach = impactMach;
sweepResults.maxAltitude_m = maxAltitude_m;
sweepResults.maxMach = maxMach;
sweepResults.maxQ_Pa = maxQ_Pa;
sweepResults.maxAlpha_deg = maxAlpha_deg;
sweepResults.maxPitchRate_deg_s = maxPitchRate_deg_s;
sweepResults.maxYawRate_deg_s = maxYawRate_deg_s;
sweepResults.attitudeBounded = attitudeBounded;
sweepResults.attitudeWithinPresetBounds = attitudeBounded;

printStage10SweepSummary(sweepResults, stage10Config.tFinal_s);

if stage10Config.showPlots
    plotStage10SweepResults_stage10(sweepResults);
end

end

function printStage10SweepSummary(sweepResults, maxTime_s)
fprintf('\nStage 10 Launch-Angle Sweep Summary:\n');
fprintf(' Angle  Impact  Time[s]  Range[km]  Lateral[m]  Vimp[m/s]  MachImp  MaxAlt[km]  MaxAoA[deg]  MaxPitchRate[deg/s]  Bounded\n');
fprintf(' -----  ------  -------  ---------  ----------  ---------  -------  ----------  -----------  -------------------  -------\n');

for k = 1:numel(sweepResults.launchAngles_deg)
    fprintf('%6.1f  %6s  %7.2f  %9.2f  %10.2f  %9.2f  %7.2f  %10.2f  %11.2f  %19.2f  %7s\n', ...
        sweepResults.launchAngles_deg(k), ...
        yesNo(sweepResults.impactDetected(k)), ...
        sweepResults.impactTime_s(k), ...
        sweepResults.impactRange_m(k) / 1000, ...
        sweepResults.impactLateral_m(k), ...
        sweepResults.impactSpeed_mps(k), ...
        sweepResults.impactMach(k), ...
        sweepResults.maxAltitude_m(k) / 1000, ...
        sweepResults.maxAlpha_deg(k), ...
        sweepResults.maxPitchRate_deg_s(k), ...
        yesNo(sweepResults.attitudeBounded(k)));
end

validImpact = sweepResults.impactDetected & ~isnan(sweepResults.impactRange_m);
if any(validImpact)
    rangeForBest = sweepResults.impactRange_m;
    rangeForBest(~validImpact) = -Inf;
    [~, idxBestRange] = max(rangeForBest);
    fprintf('\nBest angle for maximum impact range: %.1f deg (%.2f km)\n', ...
        sweepResults.launchAngles_deg(idxBestRange), ...
        sweepResults.impactRange_m(idxBestRange) / 1000);
else
    fprintf('\nNo sweep angle reached ground impact before %.1f s.\n', maxTime_s);
end

[~, idxBestAltitude] = max(sweepResults.maxAltitude_m);
fprintf('Best angle for maximum altitude: %.1f deg (%.2f km)\n', ...
    sweepResults.launchAngles_deg(idxBestAltitude), ...
    sweepResults.maxAltitude_m(idxBestAltitude) / 1000);

idxUnbounded = find(~sweepResults.attitudeBounded);
if isempty(idxUnbounded)
    fprintf('All sweep cases stayed within the preset attitude/rate bounds.\n');
else
    fprintf('Angles exceeding preset attitude/rate bounds: ');
    fprintf('%.1f ', sweepResults.launchAngles_deg(idxUnbounded));
    fprintf('deg\n');
end

idxNoImpact = find(~sweepResults.impactDetected);
if ~isempty(idxNoImpact)
    fprintf('Angles without ground impact before %.1f s: ', maxTime_s);
    fprintf('%.1f ', sweepResults.launchAngles_deg(idxNoImpact));
    fprintf('deg\n');
end

fprintf('\nAssumptions: simplified 6-DOF prototype, flat Earth, no propulsion,\n');
fprintf('no active guidance/control, approximate aerodynamic moments, and simple damping derivatives.\n\n');
end

function text = yesNo(value)
if value
    text = 'yes';
else
    text = 'no';
end
end
