function insights = generateEngineeringInsights(results, vehicle, constants)
% generateEngineeringInsights
% Builds careful engineering interpretation text from trajectory results.

if nargin < 2
    vehicle = struct(); %#ok<NASGU>
end
if nargin < 3
    constants = struct(); %#ok<NASGU>
end

events = findPeakEvents(results);
score = computeDesignScoreStage14(results, "Balanced");
lines = strings(0, 1);

if events.maxQ.valid
    lines(end+1, 1) = sprintf(['Max Q occurred at t = %.2f s (%.1f kPa). ', ...
        'This usually occurs when the vehicle is still in relatively dense air while moving quickly, so it is likely one of the most severe structural loading regions in this simplified model.'], ...
        events.maxQ.time_s, events.maxQ.value / 1000);
end
if events.maxMach.valid
    lines(end+1, 1) = sprintf(['Peak Mach occurred at t = %.2f s (Mach %.2f). ', ...
        'Based on this model, peak Mach often appears early if drag steadily removes kinetic energy after launch.'], ...
        events.maxMach.time_s, events.maxMach.value);
end
if events.maxStagnationTemperature.valid
    lines(end+1, 1) = sprintf(['Peak stagnation temperature was %.0f K at t = %.2f s. ', ...
        'This is a useful indicator of the most severe thermal environment in this model.'], ...
        events.maxStagnationTemperature.value, events.maxStagnationTemperature.time_s);
end
if events.maxAltitude.valid
    lines(end+1, 1) = sprintf('The vehicle reached maximum altitude at t = %.2f s and altitude = %.1f m.', ...
        events.maxAltitude.time_s, events.maxAltitude.h_m);
end
if events.impact.valid
    lines(end+1, 1) = sprintf('Impact occurred at range = %.1f m with speed = %.1f m/s.', ...
        events.impact.x_m, events.impact.value);
end
if events.maxDrag.valid
    lines(end+1, 1) = sprintf(['Peak drag occurred at t = %.2f s. ', ...
        'Early flight can be drag-dominated when speed and dynamic pressure are high.'], ...
        events.maxDrag.time_s);
end
if isfield(events, 'maxLift') && events.maxLift.valid
    lines(end+1, 1) = sprintf('Peak lift occurred at t = %.2f s. In this simplified model, lift follows dynamic pressure and angle-of-attack assumptions.', ...
        events.maxLift.time_s);
end
if isfield(events, 'maxLD') && events.maxLD.valid
    lines(end+1, 1) = sprintf('The maximum L/D value was %.2f. This is a trend metric from the simplified aero model, not a measured aerodynamic polar.', ...
        events.maxLD.value);
end

maxQ = safeScalar(results, 'maxQ');
if isfinite(maxQ) && maxQ > 1000e3
    lines(end+1, 1) = "Max Q is high in this run; structural load limits may become an important design constraint.";
end
maxStag = safeScalar(results, 'maxStagTemp');
if isfinite(maxStag) && maxStag > 1200
    lines(end+1, 1) = "Stagnation temperature is elevated; material limits or thermal protection assumptions should be checked.";
end
lines(end+1, 1) = "Heating risk is classified as " + string(score.HeatingRisk) + ", and structural load risk is classified as " + string(score.StructuralLoadRisk) + " by the simplified dashboard heuristic.";
if safeScalar(results, 'range') > 1.4 * safeScalar(results, 'maxAltitude')
    lines(end+1, 1) = "The trajectory appears more range-oriented than altitude-oriented because downrange distance is large relative to apogee height.";
elseif safeScalar(results, 'maxAltitude') > 0.8 * safeScalar(results, 'range')
    lines(end+1, 1) = "The trajectory appears relatively altitude-oriented; this may indicate a more lofted flight path.";
else
    lines(end+1, 1) = "The trajectory appears balanced between range and altitude for this simplified setup.";
end
if isstruct(vehicle)
    if safeScalar(vehicle, 'mass') <= 0 || safeScalar(vehicle, 'diameter') <= 0 || safeScalar(vehicle, 'length') <= 0
        lines(end+1, 1) = "One or more vehicle inputs appear nonphysical; check mass, diameter, and length before trusting trends.";
    end
end
lines(end+1, 1) = "These statements are analysis aids for the current model, not final design validation.";

insights = cellstr(lines);
end

function value = safeScalar(s, fieldName)
value = NaN;
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName)) && isnumeric(s.(fieldName))
    value = s.(fieldName)(1);
end
end
