function score = computeDesignScoreStage14(results, missionGoal)
% computeDesignScoreStage14
% Simplified educational scoring and risk dashboard metrics.

if nargin < 2 || strlength(string(missionGoal)) == 0
    missionGoal = "Balanced";
end
missionGoal = lower(string(missionGoal));

range_km = safeScalar(results, 'range') / 1000;
altitude_km = safeScalar(results, 'maxAltitude') / 1000;
maxQ_kPa = safeScalar(results, 'maxQ') / 1000;
maxStag_K = safeScalar(results, 'maxStagTemp');
maxG = safeScalar(results, 'maxGLoad');
staticMargin = safeScalar(results, 'minStaticMargin');
if ~isfinite(maxStag_K)
    maxStag_K = maxVector(firstAvailable(results, {'stagTemp','Tstag'}));
end

rangeScore = boundedScore(range_km, 10, 80);
altitudeScore = boundedScore(altitude_km, 5, 60);
heatingPenalty = riskPenalty(maxStag_K, [900 1400 2000]);
qPenalty = riskPenalty(maxQ_kPa, [500 1500 3000]);
gPenalty = riskPenalty(maxG, [20 50 90]);
stabilityScore = stabilityHeuristic(staticMargin);

thermalScore = 100 - heatingPenalty;
structuralScore = 100 - max(qPenalty, gPenalty);
balanced = 0.28 * rangeScore + 0.22 * altitudeScore + ...
    0.20 * thermalScore + 0.20 * structuralScore + 0.10 * stabilityScore;

if contains(missionGoal, "range")
    overall = 0.55 * rangeScore + 0.15 * altitudeScore + 0.15 * thermalScore + 0.15 * structuralScore;
elseif contains(missionGoal, "altitude")
    overall = 0.50 * altitudeScore + 0.20 * rangeScore + 0.15 * thermalScore + 0.15 * structuralScore;
elseif contains(missionGoal, "heating")
    overall = 0.55 * thermalScore + 0.20 * rangeScore + 0.15 * altitudeScore + 0.10 * structuralScore;
elseif contains(missionGoal, "structural")
    overall = 0.55 * structuralScore + 0.20 * rangeScore + 0.15 * altitudeScore + 0.10 * thermalScore;
else
    overall = balanced;
end

score = struct();
score.RangeScore = round(clamp(rangeScore, 0, 100));
score.AltitudeScore = round(clamp(altitudeScore, 0, 100));
score.HeatingRisk = riskLabel(maxStag_K, [900 1400]);
score.StructuralLoadRisk = riskLabel(max(maxQ_kPa / 10, maxG), [50 90]);
score.Stability = stabilityLabel(staticMargin);
score.OverallDesignScore = round(clamp(overall, 0, 100));
score.HeuristicNote = "Simplified educational heuristic, not a validated design or certification score.";
score.Range_km = range_km;
score.MaxAltitude_km = altitude_km;
score.MaxQ_kPa = maxQ_kPa;
score.MaxStagTemp_K = maxStag_K;
score.MaxGLoad = maxG;
score.StaticMargin_percent = 100 * staticMargin;
end

function score = boundedScore(value, lowRef, highRef)
if ~isfinite(value)
    score = 0;
else
    score = 100 * (value - lowRef) / max(highRef - lowRef, eps);
end
score = clamp(score, 0, 100);
end

function penalty = riskPenalty(value, refs)
if ~isfinite(value)
    penalty = 50;
elseif value <= refs(1)
    penalty = 10;
elseif value <= refs(2)
    penalty = 10 + 35 * (value - refs(1)) / max(refs(2) - refs(1), eps);
elseif value <= refs(3)
    penalty = 45 + 45 * (value - refs(2)) / max(refs(3) - refs(2), eps);
else
    penalty = 95;
end
penalty = clamp(penalty, 0, 100);
end

function text = riskLabel(value, refs)
if ~isfinite(value)
    text = "Unknown";
elseif value < refs(1)
    text = "Low risk";
elseif value < refs(2)
    text = "Medium risk";
else
    text = "High risk";
end
end

function score = stabilityHeuristic(staticMargin)
if ~isfinite(staticMargin)
    score = 50;
elseif staticMargin < 0.03
    score = 20;
elseif staticMargin <= 0.25
    score = 100 - 80 * abs(staticMargin - 0.12) / 0.12;
else
    score = 55;
end
score = clamp(score, 0, 100);
end

function text = stabilityLabel(staticMargin)
if ~isfinite(staticMargin)
    text = "Unknown";
elseif staticMargin < 0.05
    text = "Low/unstable";
elseif staticMargin <= 0.25
    text = "Acceptable";
else
    text = "High/stiff";
end
end

function value = maxVector(values)
value = NaN;
if isnumeric(values) && ~isempty(values) && any(isfinite(values))
    value = max(values(:), [], 'omitnan');
end
end

function value = firstAvailable(results, names)
value = [];
if ~isstruct(results)
    return;
end
for k = 1:numel(names)
    if isfield(results, names{k}) && ~isempty(results.(names{k}))
        value = results.(names{k});
        return;
    end
end
end

function value = safeScalar(s, fieldName)
value = NaN;
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName)) && isnumeric(s.(fieldName))
    value = s.(fieldName)(1);
end
end

function y = clamp(x, lo, hi)
y = min(max(x, lo), hi);
end
