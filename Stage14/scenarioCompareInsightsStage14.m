function insights = scenarioCompareInsightsStage14(compare)
% scenarioCompareInsightsStage14
% Plain-English, careful interpretation for Scenario Compare mode.

lines = strings(0, 1);
lines(end+1, 1) = "Scenario Compare uses the same simplified Stage 11 backend for each case, so differences should be read as trend indicators rather than validated flight predictions.";

if ~isstruct(compare) || ~isfield(compare, 'summaryTable') || isempty(compare.summaryTable)
    insights = cellstr(lines);
    return;
end
T = compare.summaryTable;
if height(T) < 1
    insights = cellstr(lines);
    return;
end

if isfield(compare, 'bestCaseIndex') && compare.bestCaseIndex >= 1 && compare.bestCaseIndex <= height(T)
    best = T(compare.bestCaseIndex, :);
    lines(end+1, 1) = sprintf('For the current mission goal (%s), the best highlighted case is %s with a heuristic score of %.0f/100.', ...
        char(compare.missionGoal), char(best.CaseName), best.OverallDesignScore);
end

if width(T) >= 1 && any(isfinite(T.LaunchAngle_deg)) && numel(unique(T.LaunchAngle_deg(isfinite(T.LaunchAngle_deg)))) > 1
    [~, iRange] = max(T.Range_km);
    [~, iAlt] = max(T.MaxAltitude_km);
    lines(end+1, 1) = sprintf(['Launch angle appears to trade range against altitude in this set. ', ...
        'The longest range occurred near %.1f deg, while the highest altitude occurred near %.1f deg.'], ...
        T.LaunchAngle_deg(iRange), T.LaunchAngle_deg(iAlt));
end

dominant = dominantCompareVariable(T);
if strlength(dominant) > 0
    lines(end+1, 1) = "The input that appears to dominate range variation in this comparison is " + dominant + ". This is based only on the cases currently in the table.";
end

if any(strcmp(T.HeatingRisk, "High risk"))
    lines(end+1, 1) = "At least one case shows high heating risk; based on this simplified model, thermal protection or material assumptions would likely become a design driver.";
end
if any(strcmp(T.StructuralLoadRisk, "High risk"))
    lines(end+1, 1) = "At least one case shows high structural load risk, usually associated with high dynamic pressure during fast lower-atmosphere flight.";
end

rangeSpread = spreadPercent(T.Range_km);
altSpread = spreadPercent(T.MaxAltitude_km);
if isfinite(rangeSpread) && isfinite(altSpread)
    if rangeSpread > altSpread
        lines(end+1, 1) = "The compared cases appear more range-sensitive than altitude-sensitive for this setup.";
    elseif altSpread > rangeSpread
        lines(end+1, 1) = "The compared cases appear more altitude-sensitive than range-sensitive for this setup.";
    end
end

insights = cellstr(lines);
end

function name = dominantCompareVariable(T)
name = "";
candidates = {'LaunchAngle_deg','InitialVelocity_mps'};
labels = ["launch angle", "initial velocity"];
bestScore = -Inf;
for k = 1:numel(candidates)
    if any(strcmp(T.Properties.VariableNames, candidates{k}))
        x = T.(candidates{k});
        y = T.Range_km;
        valid = isfinite(x) & isfinite(y);
        if sum(valid) >= 3 && numel(unique(x(valid))) > 1
            c = corrcoef(x(valid), y(valid));
            if numel(c) >= 4 && abs(c(1,2)) > bestScore
                bestScore = abs(c(1,2));
                name = labels(k);
            end
        end
    end
end
end

function pct = spreadPercent(x)
x = x(isfinite(x));
if isempty(x) || mean(abs(x)) <= eps
    pct = NaN;
else
    pct = 100 * (max(x) - min(x)) / mean(abs(x));
end
end
