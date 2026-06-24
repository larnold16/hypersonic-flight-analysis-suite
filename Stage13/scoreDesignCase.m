function score = scoreDesignCase(result, config)
% scoreDesignCase
% Weighted normalized balanced-design score.
%
% Hard-constraint-violating designs receive -Inf so they cannot win the
% balanced design category. Individual objective rankings still report their
% raw metrics separately.

if ~result.feasible
    score = -Inf;
    return;
end

w = config.score.weights;
rangeScore = clamp(result.range_m / max(config.score.referenceRange_m, eps), 0, 1.5);
heatingScore = 1 - clamp(result.maxHeating_W_m2 / max(config.constraints.maxHeating_W_m2, eps), 0, 1);
qScore = 1 - clamp(result.maxQ_Pa / max(config.constraints.maxQ_Pa, eps), 0, 1);
gScore = 1 - clamp(result.maxGLoad_g / max(config.constraints.maxGLoad, eps), 0, 1);

targetMargin = 0.15;
halfWidth = max(config.constraints.maxStaticMargin - targetMargin, 0.01);
stabilityScore = 1 - clamp(abs(result.stabilityMargin - targetMargin) / halfWidth, 0, 1);
successScore = double(result.solverSuccess && result.impactDetected);

score = w.range * rangeScore + ...
    w.lowHeating * heatingScore + ...
    w.lowQ * qScore + ...
    w.stability * stabilityScore + ...
    w.lowG * gScore + ...
    w.success * successScore;
end

function y = clamp(x, lo, hi)
y = min(max(x, lo), hi);
end
