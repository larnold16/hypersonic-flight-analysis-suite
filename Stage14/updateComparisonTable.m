function app = updateComparisonTable(app)
% updateComparisonTable
% Updates the saved-run comparison table.

T = comparisonTable(app);
app.State.Tables.SavedRunComparison = T;
if isfield(app, 'ComparisonTable') && isvalid(app.ComparisonTable)
    app.ComparisonTable.Data = T;
end
if isfield(app, 'ResultsComparisonTable') && isvalid(app.ResultsComparisonTable)
    app.ResultsComparisonTable.Data = T;
end
if isfield(app, 'ResultsTable') && isvalid(app.ResultsTable)
    app.ResultsTable.Data = T;
end
if isfield(app, 'CurrentTableDropDown') && isvalid(app.CurrentTableDropDown)
    names = fieldnames(app.State.Tables);
    app.CurrentTableDropDown.Items = names;
    app.CurrentTableDropDown.Value = 'SavedRunComparison';
end
end

function T = comparisonTable(app)
runs = struct([]);
if isfield(app.State, 'savedRuns')
    runs = app.State.savedRuns;
end
n = numel(runs);
runName = strings(n, 1);
launchAngle = nan(n, 1);
initialSpeed = nan(n, 1);
mass = nan(n, 1);
diameter = nan(n, 1);
range = nan(n, 1);
maxAltitude = nan(n, 1);
maxMach = nan(n, 1);
maxQ = nan(n, 1);
impactSpeed = nan(n, 1);
for k = 1:n
    runName(k) = runs(k).Name;
    launchAngle(k) = getNested(runs(k), {'Launch','launchAngle_deg'}, NaN);
    initialSpeed(k) = getNested(runs(k), {'Launch','initialSpeed_mps'}, NaN);
    mass(k) = getNested(runs(k), {'Vehicle','mass'}, NaN);
    diameter(k) = getNested(runs(k), {'Vehicle','diameter'}, NaN);
    r = runs(k).Results;
    range(k) = getField(r, 'range') / 1000;
    maxAltitude(k) = getField(r, 'maxAltitude') / 1000;
    maxMach(k) = getField(r, 'maxMach');
    maxQ(k) = getField(r, 'maxQ') / 1000;
    impactSpeed(k) = getField(r, 'impactSpeed');
end
T = table(runName, launchAngle, initialSpeed, mass, diameter, range, maxAltitude, ...
    maxMach, maxQ, impactSpeed, 'VariableNames', {'RunName','LaunchAngle_deg', ...
    'InitialSpeed_mps','Mass_kg','Diameter_m','Range_km','MaxAltitude_km', ...
    'MaxMach','MaxQ_kPa','ImpactSpeed_mps'});
end

function value = getField(s, fieldName)
value = NaN;
if isstruct(s) && isfield(s, fieldName) && ~isempty(s.(fieldName)) && isnumeric(s.(fieldName))
    value = s.(fieldName)(1);
end
end

function value = getNested(s, path, defaultValue)
value = defaultValue;
cursor = s;
for k = 1:numel(path)
    if isstruct(cursor) && isfield(cursor, path{k}) && ~isempty(cursor.(path{k}))
        cursor = cursor.(path{k});
    else
        return;
    end
end
if isnumeric(cursor)
    value = cursor(1);
end
end
