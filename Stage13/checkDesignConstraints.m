function constraint = checkDesignConstraints(result, config)
% checkDesignConstraints
% Applies hard Stage 13 design constraints to one evaluated case.

violations = {};
warnings = {};

if ~result.solverSuccess
    violations{end+1} = 'solver failed';
end
if ~result.impactDetected
    violations{end+1} = 'impact not reached';
end
if any(~isfinite([result.range_m, result.maxAltitude_m, result.maxQ_Pa, ...
        result.maxHeating_W_m2, result.totalHeatLoad_J_m2, result.maxGLoad_g]))
    violations{end+1} = 'NaN or Inf metric';
end
if result.maxQ_Pa > config.constraints.maxQ_Pa
    violations{end+1} = 'max q limit';
end
if result.maxGLoad_g > config.constraints.maxGLoad
    violations{end+1} = 'g-load limit';
end
if result.stabilityMargin < config.constraints.minStaticMargin || ...
        result.stabilityMargin > config.constraints.maxStaticMargin
    violations{end+1} = 'static margin bounds';
end
if result.maxHeating_W_m2 > config.constraints.maxHeating_W_m2
    violations{end+1} = 'heating rate limit';
end
if result.totalHeatLoad_J_m2 > config.constraints.maxHeatLoad_J_m2
    violations{end+1} = 'total heat load limit';
end
if result.mass_kg < config.ranges.mass_kg(1) || result.mass_kg > config.ranges.mass_kg(2)
    violations{end+1} = 'mass bounds';
end
if result.diameter_m < config.ranges.diameter_m(1) || result.diameter_m > config.ranges.diameter_m(2)
    violations{end+1} = 'diameter bounds';
end
if result.length_m < config.ranges.length_m(1) || result.length_m > config.ranges.length_m(2)
    violations{end+1} = 'length bounds';
end

if result.maxQ_Pa > 0.8 * config.constraints.maxQ_Pa
    warnings{end+1} = 'near max-q limit';
end
if result.maxHeating_W_m2 > 0.8 * config.constraints.maxHeating_W_m2
    warnings{end+1} = 'near heating limit';
end
if result.maxGLoad_g > 0.8 * config.constraints.maxGLoad
    warnings{end+1} = 'near g-load limit';
end

constraint.feasible = isempty(violations);
constraint.violatedConstraints = violations;
constraint.warningFlags = warnings;
end
