function designs = generateDesignGrid(config)
% generateDesignGrid
% Creates a conservative coarse grid for the no-toolbox optimizer.

angles = config.optimization.gridAngles_deg;
speeds = config.optimization.gridSpeeds_mps;
masses = config.optimization.gridMasses_kg;
bodyTypes = config.ranges.bodyTypes;

designs = {};
idx = 0;
for a = 1:numel(angles)
    for s = 1:numel(speeds)
        for m = 1:numel(masses)
            for b = 1:numel(bodyTypes)
                idx = idx + 1;
                d = config.baselineDesign;
                d.launchAngle_deg = angles(a);
                d.initialSpeed_mps = speeds(s);
                d.mass_kg = masses(m);
                d.bodyType = string(bodyTypes{b});
                d.noseType = noseFromBody(d.bodyType);
                d = enforceGeometry(d, config);
                designs{idx, 1} = d; %#ok<AGROW>
            end
        end
    end
end
end

function d = enforceGeometry(d, config)
d.length_m = clamp(d.length_m, config.ranges.length_m(1), config.ranges.length_m(2));
d.diameter_m = clamp(d.diameter_m, config.ranges.diameter_m(1), config.ranges.diameter_m(2));
d.referenceArea_m2 = pi * d.diameter_m^2 / 4;
d.finenessRatio = d.length_m / max(d.diameter_m, eps);
d.staticMargin = clamp(d.staticMargin, config.ranges.staticMargin(1), config.ranges.staticMargin(2));
d.cpLocation_m = d.cgLocation_m + d.staticMargin * d.length_m;
end

function nose = noseFromBody(bodyType)
name = lower(char(bodyType));
if contains(name, 'blunt')
    nose = "blunt";
elseif contains(name, 'ogive') || contains(name, 'finned')
    nose = "ogive";
elseif contains(name, 'cone')
    nose = "sharp cone";
else
    nose = "custom";
end
end

function y = clamp(x, lo, hi)
y = min(max(x, lo), hi);
end
