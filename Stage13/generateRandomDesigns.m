function designs = generateRandomDesigns(config, N)
% generateRandomDesigns
% Draws random designs inside editable Stage 13 ranges.

if nargin < 2
    N = config.optimization.randomCount;
end

designs = cell(N, 1);
for k = 1:N
    d = config.baselineDesign;
    d.launchAngle_deg = randRange(config.ranges.launchAngle_deg);
    d.initialSpeed_mps = randRange(config.ranges.initialSpeed_mps);
    d.initialYaw_deg = randRange(config.ranges.initialYaw_deg);
    d.initialAltitude_m = randRange(config.ranges.initialAltitude_m);
    d.mass_kg = randRange(config.ranges.mass_kg);
    d.length_m = randRange(config.ranges.length_m);
    d.diameter_m = randRange(config.ranges.diameter_m);
    d.noseRadius_m = max(0.002, 0.5 * d.diameter_m * randRange([0.35 1.0]));
    d.staticMargin = randRange(config.ranges.staticMargin);
    d.cgLocation_m = 0.45 * d.length_m;
    d.cpLocation_m = d.cgLocation_m + d.staticMargin * d.length_m;
    d.referenceArea_m2 = pi * d.diameter_m^2 / 4;
    d.finenessRatio = d.length_m / max(d.diameter_m, eps);
    d.CdMultiplier = randRange(config.ranges.CdMultiplier);
    d.CLalphaMultiplier = randRange(config.ranges.CLalphaMultiplier);
    d.dragUncertaintyFactor = d.CdMultiplier;
    d.liftUncertaintyFactor = d.CLalphaMultiplier;
    d.windSpeed_mps = randRange(config.ranges.windSpeed_mps);
    d.windDirection_deg = randRange([0 360]);
    d.densityMultiplier = randRange(config.ranges.densityMultiplier);
    d.temperatureMultiplier = randRange(config.ranges.temperatureMultiplier);
    bodyIdx = randi(numel(config.ranges.bodyTypes));
    d.bodyType = string(config.ranges.bodyTypes{bodyIdx});
    d.noseType = noseFromBody(d.bodyType);
    designs{k} = d;
end
end

function x = randRange(bounds)
x = bounds(1) + (bounds(2) - bounds(1)) * rand();
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
