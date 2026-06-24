function result = runSingleScenarioStage14(vehicle, constants, baseConfig, caseSpec, missionGoal)
% runSingleScenarioStage14
% Runs one labeled Stage 14 scenario using the existing Stage 11 backend.

if nargin < 4 || ~isstruct(caseSpec)
    caseSpec = struct();
end
if nargin < 5
    missionGoal = "Balanced";
end

[caseVehicle, runConfig] = applyScenarioCase(vehicle, baseConfig, caseSpec);
result = runSingleTrajectory(caseVehicle, constants, runConfig);
result.stage = 14;
result.config = runConfig;

caseName = getCaseString(caseSpec, 'CaseName', getCaseString(caseSpec, 'name', "Scenario"));
result.caseName = caseName;
result.inputParameters = scenarioInputTable(caseVehicle, runConfig, caseSpec);
[result.keyEvents, result.keyEventTable] = computeKeyEventsStage14(result);
result.designScore = computeDesignScoreStage14(result, missionGoal);
result.summaryMetrics = buildSummaryMetrics(result);
end

function [v, cfg] = applyScenarioCase(vehicle, baseConfig, caseSpec)
v = vehicle;
cfg = baseConfig;
cfg.mode = 1;
cfg.showPlots = false;
cfg.exportResults = false;
cfg.generateReport = false;
cfg.verbose = false;
cfg.interactive = false;
cfg.figureVisible = 'off';

if hasField(caseSpec, 'BodyType')
    v.bodyType = char(caseSpec.BodyType);
elseif hasField(caseSpec, 'bodyType')
    v.bodyType = char(caseSpec.bodyType);
end
if hasField(caseSpec, 'LaunchAngle_deg')
    cfg.launchAngle_deg = caseSpec.LaunchAngle_deg;
elseif hasField(caseSpec, 'launchAngle_deg')
    cfg.launchAngle_deg = caseSpec.launchAngle_deg;
end
if hasField(caseSpec, 'InitialVelocity_mps')
    cfg.launchSpeed_mps = caseSpec.InitialVelocity_mps;
elseif hasField(caseSpec, 'initialSpeed_mps')
    cfg.launchSpeed_mps = caseSpec.initialSpeed_mps;
end
if hasField(caseSpec, 'Mass_kg')
    v.mass = caseSpec.Mass_kg;
elseif hasField(caseSpec, 'mass_kg')
    v.mass = caseSpec.mass_kg;
end
if hasField(caseSpec, 'Diameter_m')
    v.diameter = caseSpec.Diameter_m;
elseif hasField(caseSpec, 'diameter_m')
    v.diameter = caseSpec.diameter_m;
end
if hasField(caseSpec, 'Length_m')
    v.length = caseSpec.Length_m;
elseif hasField(caseSpec, 'length_m')
    v.length = caseSpec.length_m;
end
if hasField(caseSpec, 'CdScale')
    v.Cd_scale = caseSpec.CdScale;
elseif hasField(caseSpec, 'cdScale')
    v.Cd_scale = caseSpec.cdScale;
end
if hasField(caseSpec, 'CLScale')
    v.CL_scale = caseSpec.CLScale;
elseif hasField(caseSpec, 'clScale')
    v.CL_scale = caseSpec.clScale;
end
if hasField(caseSpec, 'Alpha_deg')
    v.alpha_deg = caseSpec.Alpha_deg;
elseif hasField(caseSpec, 'alpha_deg')
    v.alpha_deg = caseSpec.alpha_deg;
end

v.referenceArea = pi * max(v.diameter, eps)^2 / 4;
v.area = v.referenceArea;
v.finenessRatio = max(v.length, eps) / max(v.diameter, eps);
v.fineness = v.finenessRatio;

staticMargin = NaN;
if hasField(caseSpec, 'StaticMargin_percent')
    staticMargin = caseSpec.StaticMargin_percent / 100;
elseif hasField(caseSpec, 'staticMargin')
    staticMargin = caseSpec.staticMargin;
end
if isfinite(staticMargin)
    v.cgLocation_m = getVehicleField(v, 'cgLocation_m', 0.50 * v.length);
    v.cpLocation_m = v.cgLocation_m + staticMargin * v.length;
end

if hasField(caseSpec, 'OutputSuffix')
    suffix = char(caseSpec.OutputSuffix);
else
    suffix = matlab.lang.makeValidName(char(getCaseString(caseSpec, 'CaseName', "Scenario")));
end
cfg.outputRoot = fullfile(getConfigField(cfg, 'outputRoot', fullfile(pwd, 'Outputs', 'Stage14')), 'ScenarioCompare', suffix);

v.V0 = getConfigField(cfg, 'launchSpeed_mps', getVehicleField(v, 'V0', 1800));
v.launchAngle = getConfigField(cfg, 'launchAngle_deg', getVehicleField(v, 'launchAngle', 25));
v = buildVehicleFromGeometry_stage11(v, getVehicleField(v, 'bodyType', 'Custom baseline'));
end

function T = scenarioInputTable(vehicle, cfg, caseSpec)
names = ["Case name"; "Body type"; "Launch angle deg"; "Initial velocity m/s"; ...
    "Mass kg"; "Length m"; "Diameter m"; "Reference area m^2"; ...
    "Cd scale"; "CL scale"; "Static margin %"; "Angle of attack deg"; "Assumption"];
staticMargin = (getVehicleField(vehicle, 'cpLocation_m', NaN) - getVehicleField(vehicle, 'cgLocation_m', NaN)) / ...
    max(getVehicleField(vehicle, 'length', NaN), eps);
values = [
    getCaseString(caseSpec, 'CaseName', getCaseString(caseSpec, 'name', "Scenario"))
    string(getVehicleField(vehicle, 'bodyType', 'Custom baseline'))
    string(getConfigField(cfg, 'launchAngle_deg', NaN))
    string(getConfigField(cfg, 'launchSpeed_mps', NaN))
    string(getVehicleField(vehicle, 'mass', NaN))
    string(getVehicleField(vehicle, 'length', NaN))
    string(getVehicleField(vehicle, 'diameter', NaN))
    string(getVehicleField(vehicle, 'referenceArea', NaN))
    string(getVehicleField(vehicle, 'Cd_scale', NaN))
    string(getVehicleField(vehicle, 'CL_scale', NaN))
    string(100 * staticMargin)
    string(getVehicleField(vehicle, 'alpha_deg', NaN))
    "Simplified educational Stage 11 physics backend"];
T = table(names, values, 'VariableNames', {'Parameter','Value'});
end

function tf = hasField(s, name)
tf = isstruct(s) && isfield(s, name) && ~isempty(s.(name));
end

function value = getCaseString(s, name, defaultValue)
if hasField(s, name)
    value = string(s.(name));
else
    value = string(defaultValue);
end
end

function value = getVehicleField(vehicle, name, defaultValue)
if isstruct(vehicle) && isfield(vehicle, name) && ~isempty(vehicle.(name))
    value = vehicle.(name);
else
    value = defaultValue;
end
end

function value = getConfigField(config, name, defaultValue)
if isstruct(config) && isfield(config, name) && ~isempty(config.(name))
    value = config.(name);
else
    value = defaultValue;
end
end
