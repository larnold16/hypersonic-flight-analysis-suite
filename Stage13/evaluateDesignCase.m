function result = evaluateDesignCase(config, design, caseId)
% evaluateDesignCase
% Core Stage 13 evaluation function. It builds the vehicle, calls the Stage
% 11 trajectory solver, extracts metrics, checks constraints, and scores the
% design. Failures are stored in the returned result instead of thrown.

if nargin < 3
    caseId = 1;
end

result = emptyResult(caseId, design);

try
    [vehicle, stage11Config] = applyDesignVector(config, design);
    traj = runSingleTrajectory(vehicle, config.constants, stage11Config);

    result.bodyType = string(vehicle.bodyType);
    result.launchAngle_deg = design.launchAngle_deg;
    result.initialSpeed_mps = design.initialSpeed_mps;
    result.mass_kg = vehicle.mass;
    result.length_m = vehicle.length;
    result.diameter_m = vehicle.diameter;
    result.staticMargin = vehicle.staticMargin;
    result.CdMultiplier = design.CdMultiplier;
    result.windSpeed_mps = design.windSpeed_mps;

    result.range_m = traj.range;
    result.maxAltitude_m = traj.maxAltitude;
    result.timeOfFlight_s = traj.timeOfFlight;
    result.impactSpeed_mps = traj.impactSpeed;
    result.maxMach = traj.maxMach;
    result.maxQ_Pa = traj.maxQ;
    result.maxHeating_W_m2 = traj.maxHeatingRate;
    result.totalHeatLoad_J_m2 = traj.totalHeatLoad;
    result.maxGLoad_g = traj.maxGLoad;
    result.stabilityMargin = traj.minStaticMargin;
    result.stable = traj.minStaticMargin >= config.constraints.minStaticMargin && ...
        traj.minStaticMargin <= config.constraints.maxStaticMargin;
    result.impactDetected = traj.impactDetected;
    result.solverSuccess = ~traj.failed;
    result.failureMessage = string(traj.failureMessage);

    constraint = checkDesignConstraints(result, config);
    result.feasible = constraint.feasible;
    result.violatedConstraints = string(strjoin(constraint.violatedConstraints, '; '));
    result.warningFlags = string(strjoin(constraint.warningFlags, '; '));
    result.score = scoreDesignCase(result, config);
catch ME
    result.solverSuccess = false;
    result.feasible = false;
    result.score = -Inf;
    result.failureMessage = string(ME.message);
    result.violatedConstraints = "solver failure";
    result.warningFlags = "evaluation exception";
end
end

function result = emptyResult(caseId, design)
result = struct();
result.caseId = caseId;
result.bodyType = string(getDesignField(design, 'bodyType', "Custom baseline"));
result.launchAngle_deg = getDesignField(design, 'launchAngle_deg', NaN);
result.initialSpeed_mps = getDesignField(design, 'initialSpeed_mps', NaN);
result.mass_kg = getDesignField(design, 'mass_kg', NaN);
result.length_m = getDesignField(design, 'length_m', NaN);
result.diameter_m = getDesignField(design, 'diameter_m', NaN);
result.staticMargin = getDesignField(design, 'staticMargin', NaN);
result.CdMultiplier = getDesignField(design, 'CdMultiplier', NaN);
result.windSpeed_mps = getDesignField(design, 'windSpeed_mps', NaN);
result.range_m = NaN;
result.maxAltitude_m = NaN;
result.timeOfFlight_s = NaN;
result.impactSpeed_mps = NaN;
result.maxMach = NaN;
result.maxQ_Pa = NaN;
result.maxHeating_W_m2 = NaN;
result.totalHeatLoad_J_m2 = NaN;
result.maxGLoad_g = NaN;
result.stabilityMargin = NaN;
result.stable = false;
result.impactDetected = false;
result.solverSuccess = false;
result.feasible = false;
result.score = -Inf;
result.violatedConstraints = "";
result.warningFlags = "";
result.failureMessage = "";
end

function value = getDesignField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
