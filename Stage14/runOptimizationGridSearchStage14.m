function optimization = runOptimizationGridSearchStage14(vehicle, constants, baseConfig, options, constraints, progressCallback)
% runOptimizationGridSearchStage14
% Simple baseline-safe grid search for Stage 14 Optimization Mode.

if nargin < 4 || isempty(options)
    options = struct();
end
if nargin < 5 || isempty(constraints)
    constraints = struct();
end
if nargin < 6
    progressCallback = [];
end

[names, grids] = buildGrids(vehicle, baseConfig, options);
numCases = prod(cellfun(@numel, grids));
maxCases = max(1, round(getField(options, 'maxCases', 180)));
caseCount = min(numCases, maxCases);

rows = cell(caseCount, 1);
caseResults = cell(caseCount, 1);
caseSpecs = cell(caseCount, 1);
failedRows = strings(0, 1);
sizes = cellfun(@numel, grids);

for c = 1:caseCount
    callProgress(progressCallback, 0.05 + 0.85 * (c - 1) / max(caseCount, 1), ...
        sprintf('Optimization case %d of %d', c, caseCount));
    idx = cell(1, numel(grids));
    if numel(grids) == 1
        idx{1} = c;
    else
        [idx{:}] = ind2sub(sizes, c);
    end
    spec = caseSpecFromGrid(names, grids, idx, c);
    try
        result = runSingleScenarioStage14(vehicle, constants, baseConfig, spec, getField(options, 'objective', "Best balanced design"));
        margins = computeConstraintMarginsStage14(result, constraints);
        row = rowFromResult(result, spec, getField(options, 'objective', "Best balanced design"), margins);
        if result.failed || ~result.impactDetected
            row.Feasible = false;
            row.ViolatedConstraints = "Solver/impact";
        end
        rows{c} = row;
        caseResults{c} = result;
        caseSpecs{c} = spec;
    catch ME
        failedRows(end+1, 1) = string(ME.message); %#ok<AGROW>
        rows{c} = failedRow(spec, getField(options, 'objective', "Best balanced design"), ME.message);
        caseResults{c} = struct();
        caseSpecs{c} = spec;
    end
end

summaryTable = vertcatRows(rows);
if ~isempty(summaryTable)
    summaryTable = sortrows(summaryTable, {'Feasible','ObjectiveValue'}, {'descend','descend'});
end
feasibleCount = sum(summaryTable.Feasible);
if feasibleCount > 0
    bestCase = summaryTable(1, :);
    bestId = bestCase.CaseNumber(1);
    bestSpec = caseSpecs{bestId};
    bestResult = caseResults{bestId};
    status = sprintf('Optimization complete. Evaluated %d of %d requested cases. Feasible cases: %d. Best case: %s.', ...
        caseCount, numCases, feasibleCount, bestCase.CaseName(1));
else
    bestCase = table();
    bestSpec = struct();
    bestResult = struct();
    status = sprintf('No feasible case found. Evaluated %d of %d requested cases.', caseCount, numCases);
end
if numCases > caseCount
    status = sprintf('%s Case count was capped at %d for app responsiveness.', status, maxCases);
end

optimization = struct();
optimization.summaryTable = summaryTable;
optimization.rankedTable = summaryTable;
optimization.topFiveTable = summaryTable(1:min(5, height(summaryTable)), :);
optimization.failedMessages = failedRows;
optimization.caseResults = caseResults;
optimization.caseSpecs = caseSpecs;
optimization.bestCase = bestCase;
optimization.bestCaseSpec = bestSpec;
optimization.bestResult = bestResult;
optimization.statusMessage = status;
optimization.objective = string(getField(options, 'objective', "Best balanced design"));
optimization.numRequestedCases = numCases;
optimization.numEvaluatedCases = caseCount;
optimization.numFeasibleCases = feasibleCount;
callProgress(progressCallback, 1.0, status);
end

function [names, grids] = buildGrids(vehicle, cfg, options)
names = {};
grids = {};
addIfEnabled('LaunchAngle_deg', getField(options, 'useAngle', true), ...
    getRange(options, 'angle', getField(cfg, 'launchAngle_deg', getField(vehicle, 'launchAngle', 25)), 10));
addIfEnabled('InitialVelocity_mps', getField(options, 'useSpeed', false), ...
    getRange(options, 'speed', getField(cfg, 'launchSpeed_mps', getField(vehicle, 'V0', 1800)), 200));
addIfEnabled('Mass_kg', getField(options, 'useMass', false), ...
    getRange(options, 'mass', getField(vehicle, 'mass', 5), 1));
addIfEnabled('Diameter_m', getField(options, 'useDiameter', false), ...
    getRange(options, 'diameter', getField(vehicle, 'diameter', 0.0564), 0.01));
addIfEnabled('Length_m', getField(options, 'useLength', false), ...
    getRange(options, 'length', getField(vehicle, 'length', 0.45), 0.05));
addIfEnabled('CdScale', getField(options, 'useCd', false), ...
    getRange(options, 'cd', getField(vehicle, 'Cd_scale', 1), 0.1));
addIfEnabled('Alpha_deg', getField(options, 'useAlpha', false), ...
    getRange(options, 'alpha', getField(vehicle, 'alpha_deg', 2), 1));
staticMargin = 100 * (getField(vehicle, 'cpLocation_m', NaN) - getField(vehicle, 'cgLocation_m', NaN)) / max(getField(vehicle, 'length', NaN), eps);
addIfEnabled('StaticMargin_percent', getField(options, 'useStaticMargin', false), ...
    getRange(options, 'staticMargin', staticMargin, 2));

if isempty(names)
    names = {'LaunchAngle_deg'};
    grids = {getRange(options, 'angle', getField(cfg, 'launchAngle_deg', 25), 10)};
end

    function addIfEnabled(name, enabled, values)
        if enabled
            names{end+1} = name; %#ok<AGROW>
            grids{end+1} = values; %#ok<AGROW>
        end
    end
end

function values = getRange(options, prefix, center, defaultStep)
lo = getField(options, [prefix, 'Min'], center - defaultStep);
hi = getField(options, [prefix, 'Max'], center + defaultStep);
step = abs(getField(options, [prefix, 'Step'], defaultStep));
if ~isfinite(lo) || ~isfinite(hi) || ~isfinite(step) || step <= 0
    values = center;
else
    if hi < lo
        tmp = hi; hi = lo; lo = tmp;
    end
    values = lo:step:hi;
    if isempty(values)
        values = center;
    end
end
values = values(:).';
end

function spec = caseSpecFromGrid(names, grids, idx, caseNumber)
spec = struct();
spec.CaseName = sprintf('OPT-%03d', caseNumber);
spec.OutputSuffix = sprintf('OPT_%03d', caseNumber);
for k = 1:numel(names)
    spec.(names{k}) = grids{k}(idx{k});
end
end

function row = rowFromResult(r, spec, objective, margins)
score = computeDesignScoreStage14(r, objective);
objectiveValue = objectiveMetric(r, objective, score);
row = table();
row.CaseNumber = str2double(erase(string(spec.CaseName), "OPT-"));
row.CaseName = string(spec.CaseName);
row.ObjectiveName = string(objective);
row.ObjectiveValue = objectiveValue;
row.Feasible = margins.allPassed && logical(getField(r, 'impactDetected', false)) && ~logical(getField(r, 'failed', false));
row.ViolatedConstraints = string(margins.violationSummary);
row.Range_km = getField(r, 'range', NaN) / 1000;
row.MaxAltitude_km = getField(r, 'maxAltitude', NaN) / 1000;
row.TimeOfFlight_s = getField(r, 'timeOfFlight', NaN);
row.ImpactSpeed_mps = getField(r, 'impactSpeed', NaN);
row.MaxMach = getField(r, 'maxMach', NaN);
row.MaxQ_kPa = getField(r, 'maxQ', NaN) / 1000;
row.MaxStagTemp_K = getField(r, 'maxStagTemp', NaN);
row.MaxGLoad = getField(r, 'maxGLoad', NaN);
row.LaunchAngle_deg = getSpecValue(spec, 'LaunchAngle_deg');
row.InitialSpeed_mps = getSpecValue(spec, 'InitialVelocity_mps');
row.Mass_kg = getSpecValue(spec, 'Mass_kg');
row.Diameter_m = getSpecValue(spec, 'Diameter_m');
row.Length_m = getSpecValue(spec, 'Length_m');
row.CdMultiplier = getSpecValue(spec, 'CdScale');
row.Alpha_deg = getSpecValue(spec, 'Alpha_deg');
row.StaticMargin_percent = getSpecValue(spec, 'StaticMargin_percent');
end

function row = failedRow(spec, objective, message)
row = table();
row.CaseNumber = str2double(erase(string(spec.CaseName), "OPT-"));
row.CaseName = string(spec.CaseName);
row.ObjectiveName = string(objective);
row.ObjectiveValue = -Inf;
row.Feasible = false;
row.ViolatedConstraints = "Failed: " + string(message);
row.Range_km = NaN;
row.MaxAltitude_km = NaN;
row.TimeOfFlight_s = NaN;
row.ImpactSpeed_mps = NaN;
row.MaxMach = NaN;
row.MaxQ_kPa = NaN;
row.MaxStagTemp_K = NaN;
row.MaxGLoad = NaN;
row.LaunchAngle_deg = getSpecValue(spec, 'LaunchAngle_deg');
row.InitialSpeed_mps = getSpecValue(spec, 'InitialVelocity_mps');
row.Mass_kg = getSpecValue(spec, 'Mass_kg');
row.Diameter_m = getSpecValue(spec, 'Diameter_m');
row.Length_m = getSpecValue(spec, 'Length_m');
row.CdMultiplier = getSpecValue(spec, 'CdScale');
row.Alpha_deg = getSpecValue(spec, 'Alpha_deg');
row.StaticMargin_percent = getSpecValue(spec, 'StaticMargin_percent');
end

function value = objectiveMetric(r, objective, score)
label = lower(char(string(objective)));
if contains(label, 'range')
    value = getField(r, 'range', NaN) / 1000;
elseif contains(label, 'altitude')
    value = getField(r, 'maxAltitude', NaN) / 1000;
elseif contains(label, 'heating')
    value = -getField(r, 'maxStagTemp', NaN);
elseif contains(label, 'dynamic') || contains(label, 'max q')
    value = -getField(r, 'maxQ', NaN) / 1000;
elseif contains(label, 'drag loss')
    value = energyChangePercent(r);
elseif contains(label, 'impact speed')
    value = getField(r, 'impactSpeed', NaN);
else
    value = getField(score, 'OverallDesignScore', NaN);
end
end

function pct = energyChangePercent(r)
if isstruct(r) && isfield(r, 'totalEnergy') && numel(r.totalEnergy) >= 2
    pct = 100 * (r.totalEnergy(end) - r.totalEnergy(1)) / max(abs(r.totalEnergy(1)), eps);
else
    pct = NaN;
end
end

function T = vertcatRows(rows)
valid = rows(~cellfun(@isempty, rows));
if isempty(valid)
    T = table();
else
    T = valid{1};
    for k = 2:numel(valid)
        T = [T; valid{k}]; %#ok<AGROW>
    end
end
end

function value = getSpecValue(spec, name)
if isstruct(spec) && isfield(spec, name)
    value = spec.(name);
else
    value = NaN;
end
end

function callProgress(callback, fraction, message)
if isa(callback, 'function_handle')
    callback(fraction, message);
end
end

function value = getField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end
