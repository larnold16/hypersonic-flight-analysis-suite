function results = runStage5(vehicle, constants, stage5Config)
% runStage5
% Runs a Stage 5 mission-design sweep using the existing Stage 4 model.

if nargin < 3
    stage5Config = struct();
end

if ~isfield(stage5Config, 'launchAngles_deg')
    stage5Config.launchAngles_deg = 1:1:60;
end

if ~isfield(stage5Config, 'maxAllowableAngle_deg')
    stage5Config.maxAllowableAngle_deg = 60;
end

if ~isfield(stage5Config, 'maxQ_limit')
    stage5Config.maxQ_limit = 2000e3;    % [Pa]
end

if ~isfield(stage5Config, 'minRangeForAltitude_m')
    stage5Config.minRangeForAltitude_m = 30000;    % [m]
end

if ~isfield(stage5Config, 'targetRange')
    stage5Config.targetRange = [];       % [m], optional
end

if ~isfield(stage5Config, 'verbose')
    stage5Config.verbose = true;
end

if ~isfield(stage5Config, 'showProgress')
    stage5Config.showProgress = stage5Config.verbose;
end

verbose = stage5Config.verbose;

if verbose
    fprintf('Stage 5 Sweep Settings:\n');
    fprintf('Launch angle sweep: %.2f deg to %.2f deg (%d cases)\n', ...
        min(stage5Config.launchAngles_deg), ...
        max(stage5Config.launchAngles_deg), ...
        numel(stage5Config.launchAngles_deg));
    fprintf('Maximum allowable launch angle: %.2f deg\n', ...
        stage5Config.maxAllowableAngle_deg);
    fprintf('Max-Q limit: %.2f kPa\n', stage5Config.maxQ_limit / 1000);

    if ~isempty(stage5Config.minRangeForAltitude_m)
        fprintf('Minimum range for altitude case: %.2f km\n', ...
            stage5Config.minRangeForAltitude_m / 1000);
    else
        fprintf('Minimum range for altitude case: disabled\n');
    end

    if ~isempty(stage5Config.targetRange)
        fprintf('Target range: %.2f km\n', stage5Config.targetRange / 1000);
    else
        fprintf('Target range: not specified\n');
    end

    fprintf('\nRunning Stage 4 cases...\n');
end

results = parameterSweep_stage5(vehicle, constants, stage5Config);

minAngle = min(results.launchAngles_deg);
maxAngle = max(results.launchAngles_deg);
nAngles = numel(results.launchAngles_deg);
maxAllowableAngle = stage5Config.maxAllowableAngle_deg;
angleTol = 1e-9;

if verbose
    fprintf('\nStage 5 Optimization Summary:\n');
    fprintf('Maximum range angle: %.2f deg\n', results.bestRangeAngle_deg);
    fprintf('  Range: %.2f km\n', results.bestRange / 1000);
    fprintf('  Max altitude: %.2f km\n', results.maxAltitude(results.idxBestRange) / 1000);
    fprintf('  Impact speed: %.2f m/s\n', results.impactSpeed(results.idxBestRange));
    fprintf('  Initial ballistic coefficient: %.2f kg/m^2\n', ...
        results.bestRange_beta_initial);
    fprintf('  Average ballistic coefficient: %.2f kg/m^2\n', ...
        results.bestRange_beta_average);
    fprintf('  Minimum ballistic coefficient: %.2f kg/m^2\n', ...
        results.bestRange_beta_min);
end

if verbose && results.idxBestRange == 1
    warning('Stage5:RangeBoundary', ...
        ['Maximum range occurs at the sweep boundary %.2f deg. ', ...
        'Consider extending the launch angle sweep beyond %.2f-%.2f deg.'], ...
        results.bestRangeAngle_deg, minAngle, maxAngle);
elseif verbose && results.idxBestRange == nAngles
    if abs(maxAngle - maxAllowableAngle) <= angleTol
        fprintf(['\nNote: Maximum range occurs at the maximum allowed launch angle of %.2f deg. ', ...
            'This is expected because %.2f deg is the selected upper limit for the Stage 5 sweep.\n'], ...
            results.bestRangeAngle_deg, maxAllowableAngle);
    elseif maxAngle < maxAllowableAngle
        warning('Stage5:RangeBoundary', ...
            ['Maximum range occurs at the upper sweep boundary %.2f deg. ', ...
            'Consider extending the launch angle sweep up to the maximum allowable angle of %.2f deg.'], ...
            results.bestRangeAngle_deg, maxAllowableAngle);
    else
        warning('Stage5:RangeBoundary', ...
            ['Maximum range occurs at the upper sweep boundary %.2f deg. ', ...
            'Review the Stage 5 launch-angle sweep limits.'], ...
            results.bestRangeAngle_deg);
    end
end

if verbose && ~isnan(results.idxBestMaxQConstrained)
    fprintf('\nBest range angle satisfying max-Q limit: %.2f deg\n', ...
        results.bestMaxQConstrainedAngle_deg);
    fprintf('  Range: %.2f km\n', results.bestMaxQConstrainedRange / 1000);
    fprintf('  Max altitude: %.2f km\n', ...
        results.bestMaxQConstrainedAltitude / 1000);
    fprintf('  Max-Q: %.2f kPa\n', ...
        results.maxQ(results.idxBestMaxQConstrained) / 1000);
    fprintf('  Initial ballistic coefficient: %.2f kg/m^2\n', ...
        results.bestMaxQConstrained_beta_initial);
    fprintf('  Average ballistic coefficient: %.2f kg/m^2\n', ...
        results.bestMaxQConstrained_beta_average);
    fprintf('  Minimum ballistic coefficient: %.2f kg/m^2\n', ...
        results.bestMaxQConstrained_beta_min);
elseif verbose
    fprintf('\nNo launch angle satisfies the max-Q limit of %.2f kPa.\n', ...
        results.maxQ_limit / 1000);
end

if verbose && ~isempty(results.minRangeForAltitude_m)
    if ~isnan(results.idxBestMinRangeAltitude)
        fprintf('\nHighest altitude while reaching at least %.2f km:\n', ...
            results.minRangeForAltitude_m / 1000);
        fprintf('  Launch angle: %.2f deg\n', ...
            results.bestMinRangeAltitudeAngle_deg);
        fprintf('  Max altitude: %.2f km\n', ...
            results.bestMinRangeAltitude / 1000);
        fprintf('  Range: %.2f km\n', ...
            results.range(results.idxBestMinRangeAltitude) / 1000);
        fprintf('  Initial ballistic coefficient: %.2f kg/m^2\n', ...
            results.bestMinRangeAltitude_beta_initial);
        fprintf('  Average ballistic coefficient: %.2f kg/m^2\n', ...
            results.bestMinRangeAltitude_beta_average);
        fprintf('  Minimum ballistic coefficient: %.2f kg/m^2\n', ...
            results.bestMinRangeAltitude_beta_min);

        if results.idxBestMinRangeAltitude == 1
            warning('Stage5:ConstrainedAltitudeBoundary', ...
                ['Minimum-range-constrained altitude result occurs at the sweep boundary %.2f deg. ', ...
                'Consider extending the launch angle sweep beyond %.2f-%.2f deg.'], ...
                results.bestMinRangeAltitudeAngle_deg, minAngle, maxAngle);
        elseif results.idxBestMinRangeAltitude == nAngles
            if abs(maxAngle - maxAllowableAngle) <= angleTol
                fprintf(['\nNote: Minimum-range-constrained altitude result occurs at the maximum allowed ', ...
                    'launch angle of %.2f deg. This is expected because %.2f deg is the selected ', ...
                    'upper limit for the Stage 5 sweep.\n'], ...
                    results.bestMinRangeAltitudeAngle_deg, maxAllowableAngle);
            elseif maxAngle < maxAllowableAngle
                warning('Stage5:ConstrainedAltitudeBoundary', ...
                    ['Minimum-range-constrained altitude result occurs at the upper sweep boundary %.2f deg. ', ...
                    'Consider extending the launch angle sweep up to the maximum allowable angle of %.2f deg.'], ...
                    results.bestMinRangeAltitudeAngle_deg, maxAllowableAngle);
            else
                warning('Stage5:ConstrainedAltitudeBoundary', ...
                    ['Minimum-range-constrained altitude result occurs at the upper sweep boundary %.2f deg. ', ...
                    'Review the Stage 5 launch-angle sweep limits.'], ...
                    results.bestMinRangeAltitudeAngle_deg);
            end
        end
    else
        fprintf('\nNo launch angle reaches the minimum range requirement of %.2f km.\n', ...
            results.minRangeForAltitude_m / 1000);
    end
end

if verbose && ~isempty(results.targetRange)
    fprintf('\nClosest angle to target range: %.2f deg\n', ...
        results.closestTargetAngle_deg);
    fprintf('  Target range: %.2f km\n', results.targetRange / 1000);
    fprintf('  Achieved range: %.2f km\n', results.closestTargetRange / 1000);
    fprintf('  Range error: %.2f km\n', results.closestTargetError / 1000);
    fprintf('  Initial ballistic coefficient: %.2f kg/m^2\n', ...
        results.closestTarget_beta_initial);
    fprintf('  Average ballistic coefficient: %.2f kg/m^2\n', ...
        results.closestTarget_beta_average);
    fprintf('  Minimum ballistic coefficient: %.2f kg/m^2\n', ...
        results.closestTarget_beta_min);
end

if verbose
    fprintf('\nStage 5 sweep complete.\n\n');
end

end
