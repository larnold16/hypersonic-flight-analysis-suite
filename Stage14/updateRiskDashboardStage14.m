function app = updateRiskDashboardStage14(app, results, missionGoal)
% updateRiskDashboardStage14
% Updates the simplified score/risk dashboard.

if nargin < 3
    missionGoal = "Balanced";
end
if isempty(results) || ~isstruct(results)
    return;
end
score = computeDesignScoreStage14(results, missionGoal);
metric = ["Range score"; "Altitude score"; "Heating risk"; "Structural load risk"; ...
    "Stability"; "Overall design score"; "Dashboard note"];
value = [
    string(score.RangeScore) + "/100"
    string(score.AltitudeScore) + "/100"
    string(score.HeatingRisk)
    string(score.StructuralLoadRisk)
    string(score.Stability)
    string(score.OverallDesignScore) + "/100"
    string(score.HeuristicNote)];
T = table(metric, value, 'VariableNames', {'Metric','Value'});

app.State.Results.riskDashboard = score;
if isfield(app, 'RiskTable') && isvalid(app.RiskTable)
    app.RiskTable.Data = T;
end
if isfield(app, 'RiskOverallGauge') && isvalid(app.RiskOverallGauge)
    app.RiskOverallGauge.Value = score.OverallDesignScore;
end
if isfield(app, 'RiskRangeGauge') && isvalid(app.RiskRangeGauge)
    app.RiskRangeGauge.Value = score.RangeScore;
end
if isfield(app, 'RiskAltitudeGauge') && isvalid(app.RiskAltitudeGauge)
    app.RiskAltitudeGauge.Value = score.AltitudeScore;
end
if isfield(app, 'RiskInsightsArea') && isvalid(app.RiskInsightsArea)
    app.RiskInsightsArea.Value = {
        sprintf('Overall score: %.0f/100 using the %s mission goal.', score.OverallDesignScore, char(string(missionGoal)))
        sprintf('Heating is classified as %s from stagnation temperature trends.', char(score.HeatingRisk))
        sprintf('Structural loading is classified as %s from dynamic pressure and g-load trends.', char(score.StructuralLoadRisk))
        sprintf('Stability indication: %s based on simplified static margin.', char(score.Stability))
        'These are simplified engineering heuristics, not validation or certification metrics.'};
end
end
