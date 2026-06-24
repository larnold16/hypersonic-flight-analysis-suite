function fileName = exportSummaryMetricsStage14(app, results)
% exportSummaryMetricsStage14
% Exports dashboard summary metrics to a CSV file.

if nargin < 2 || isempty(results)
    results = app.State.Results.single;
end
metrics = buildSummaryMetrics(results);
names = ["Range"; "Max altitude"; "Impact speed"; "Max Mach"; "Max q"; ...
    "Max stagnation temperature"; "Time to max altitude"; "Time to impact"; "Feasibility"];
values = [metrics.Range; metrics.MaxAltitude; metrics.ImpactSpeed; metrics.MaxMach; ...
    metrics.MaxQ; metrics.MaxStagnationTemp; metrics.TimeToMaxAltitude; ...
    metrics.TimeToImpact; metrics.Feasibility];
T = table(names, values, 'VariableNames', {'Metric','Value'});
fileName = fullfile(app.State.tableDir, ['Stage14Summary_', datestr(now, 'yyyymmdd_HHMMSS'), '.csv']);
writetable(T, fileName);
end
