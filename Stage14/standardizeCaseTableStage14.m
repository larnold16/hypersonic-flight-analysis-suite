function T = standardizeCaseTableStage14(inputData, studyType)
% standardizeCaseTableStage14
% Converts Stage 11/13 structs or tables into one robust Stage 14 case table.
%
% Every required Stage 14 column is always present. Missing optional backend
% diagnostics are filled with NaN, false, "N/A", or "None" as appropriate.

if nargin < 2 || isempty(studyType)
    studyType = "Stage14";
end

raw = normalizeToTable(inputData);
n = height(raw);

T = table();
T.CaseID = caseIDColumn(raw, {'CaseID','caseId','CaseId','ID','Id','id', ...
    'RunID','runID','DesignID','designID'}, studyType);
T.StudyType = stringColumn(raw, {'StudyType','studyType'}, repmat(string(studyType), n, 1));
T.ParetoFlag = logicalColumn(raw, {'ParetoFlag','paretoFlag'}, false(n, 1));
T.MonteCarloRunNumber = numericColumn(raw, {'MonteCarloRunNumber','monteCarloRunNumber'}, nan(n, 1));
T.Feasible = logicalColumn(raw, {'Feasible','feasible'}, true(n, 1));
if any(strcmpi(raw.Properties.VariableNames, 'Failed'))
    T.Feasible = ~logicalColumn(raw, {'Failed'}, false(n, 1));
elseif any(strcmpi(raw.Properties.VariableNames, 'failed'))
    T.Feasible = ~logicalColumn(raw, {'failed'}, false(n, 1));
end
T.ViolatedConstraints = stringColumn(raw, {'ViolatedConstraints','violatedConstraints'}, repmat("None", n, 1));
T.BodyType = stringColumn(raw, {'BodyType','bodyType'}, repmat("N/A", n, 1));
T.NoseType = stringColumn(raw, {'NoseType','noseType'}, repmat("N/A", n, 1));
T.LaunchAngle_deg = numericColumn(raw, {'LaunchAngle_deg','launchAngle_deg'}, nan(n, 1));
T.InitialSpeed_mps = numericColumn(raw, {'InitialSpeed_mps','initialSpeed_mps'}, nan(n, 1));
T.InitialYaw_deg = numericColumn(raw, {'InitialYaw_deg','initialYaw_deg','launchYaw_deg'}, nan(n, 1));
T.InitialAltitude_m = numericColumn(raw, {'InitialAltitude_m','initialAltitude_m'}, nan(n, 1));
T.Mass_kg = numericColumn(raw, {'Mass_kg','mass_kg'}, nan(n, 1));
T.Length_m = numericColumn(raw, {'Length_m','length_m'}, nan(n, 1));
T.Diameter_m = numericColumn(raw, {'Diameter_m','diameter_m'}, nan(n, 1));
T.ReferenceArea_m2 = numericColumn(raw, {'ReferenceArea_m2','referenceArea_m2'}, nan(n, 1));
T.CG_m = numericColumn(raw, {'CG_m','cg_m','cgLocation_m'}, nan(n, 1));
T.CP_m = numericColumn(raw, {'CP_m','cp_m','cpLocation_m'}, nan(n, 1));
T.StaticMargin_percent = 100 .* numericColumn(raw, {'StaticMargin','staticMargin','stabilityMargin'}, nan(n, 1));
if any(strcmpi(raw.Properties.VariableNames, 'StaticMargin_percent'))
    T.StaticMargin_percent = numericColumn(raw, {'StaticMargin_percent'}, T.StaticMargin_percent);
end
T.CdMultiplier = numericColumn(raw, {'CdMultiplier','cdMultiplier','Cd_scale','CdScale'}, nan(n, 1));
T.CLalphaMultiplier = numericColumn(raw, {'CLalphaMultiplier','CLMultiplier','CL_scale','CLScale'}, nan(n, 1));
T.WindSpeed_mps = numericColumn(raw, {'WindSpeed_mps','windSpeed_mps'}, nan(n, 1));
T.DensityMultiplier = numericColumn(raw, {'DensityMultiplier','densityMultiplier'}, nan(n, 1));

T.Range_km = kmColumn(raw, {'Range_km'}, {'Range_m','range_m','range'});
T.MaxAltitude_km = kmColumn(raw, {'MaxAltitude_km'}, {'MaxAltitude_m','maxAltitude_m','maxAltitude'});
T.TimeOfFlight_s = numericColumn(raw, {'TimeOfFlight_s','timeOfFlight_s'}, nan(n, 1));
T.ImpactSpeed_mps = numericColumn(raw, {'ImpactSpeed_mps','impactSpeed_mps','impactSpeed'}, nan(n, 1));
T.ImpactMach = numericColumn(raw, {'ImpactMach','impactMach'}, nan(n, 1));
T.MaxMach = numericColumn(raw, {'MaxMach','maxMach'}, nan(n, 1));
T.MaxQ_kPa = kpaColumn(raw, {'MaxQ_kPa'}, {'MaxQ_Pa','maxQ_Pa','maxQ'});
T.MaxHeating_kW_m2 = heatingColumn(raw);
T.MaxStagTemp_K = numericColumn(raw, {'MaxStagTemp_K','maxStagTemp_K', ...
    'MaxStagTemp','maxStagTemp','Tstag','stagTemp'}, nan(n, 1));
T.TotalHeatLoad = numericColumn(raw, {'TotalHeatLoad','totalHeatLoad_J_m2','TotalHeatLoad_J_m2'}, nan(n, 1));
T.MaxGLoad = numericColumn(raw, {'MaxGLoad','MaxGLoad_g','maxGLoad_g','maxGLoad'}, nan(n, 1));

T.MaxAlpha_deg = numericColumn(raw, {'MaxAlpha_deg','maxAlpha_deg'}, nan(n, 1));
T.MaxBeta_deg = numericColumn(raw, {'MaxBeta_deg','maxBeta_deg'}, nan(n, 1));
T.MaxCL = numericColumn(raw, {'MaxCL','maxCL'}, nan(n, 1));
T.MaxCD = numericColumn(raw, {'MaxCD','maxCD','MaxCd','maxCd'}, nan(n, 1));
T.MaxLD = numericColumn(raw, {'MaxLD','maxLD'}, nan(n, 1));
T.Score = numericColumn(raw, {'Score','score'}, nan(n, 1));

emptyViolations = strlength(strtrim(T.ViolatedConstraints)) == 0;
T.ViolatedConstraints(emptyViolations) = "None";
end

function T = normalizeToTable(inputData)
if istable(inputData)
    T = inputData;
elseif isstruct(inputData)
    if isempty(inputData)
        T = table();
    else
        T = struct2table(inputData);
    end
else
    T = table();
end
end

function values = caseIDColumn(T, aliases, studyType)
n = height(T);
prefix = casePrefix(studyType);
rawValues = safeGetTableValueStage14(T, aliases, []);
if isempty(rawValues)
    rawValues = (1:n).';
end
values = stringifyCaseIDs(rawValues, n, prefix);
end

function values = stringifyCaseIDs(rawValues, n, prefix)
if iscell(rawValues)
    ids = strings(numel(rawValues), 1);
    for k = 1:numel(rawValues)
        ids(k) = scalarToString(rawValues{k});
    end
elseif ischar(rawValues)
    ids = string(rawValues);
else
    ids = string(rawValues);
end
ids = ids(:);
if n > 0 && numel(ids) == 1 && n > 1
    ids = repmat(ids, n, 1);
end
if n > 0 && numel(ids) ~= n
    ids = strings(n, 1);
end

values = strings(n, 1);
for k = 1:n
    if k <= numel(ids)
        token = upper(strtrim(ids(k)));
    else
        token = "";
    end
    if ismissing(token) || token == "" || token == "NAN" || token == "<UNDEFINED>"
        values(k) = sprintf('%s-%03d', prefix, k);
        continue;
    end
    numericToken = str2double(token);
    if isfinite(numericToken) && ~contains(token, "-") && ~contains(token, "_")
        values(k) = sprintf('%s-%03d', prefix, round(numericToken));
    else
        values(k) = token;
    end
end
end

function text = scalarToString(value)
try
    if isempty(value)
        text = "";
    elseif isnumeric(value) || islogical(value)
        text = string(value(1));
    elseif iscategorical(value)
        text = string(value(1));
    elseif isstring(value)
        text = value(1);
    elseif ischar(value)
        text = string(value);
    else
        text = string(value);
    end
catch
    text = "";
end
end

function prefix = casePrefix(studyType)
label = lower(char(string(studyType)));
if contains(label, 'angle')
    prefix = 'ANG';
elseif contains(label, 'monte')
    prefix = 'MC';
elseif contains(label, 'pareto')
    prefix = 'PAR';
elseif contains(label, 'optim')
    prefix = 'OPT';
elseif contains(label, 'doe') || contains(label, 'experiment')
    prefix = 'DOE';
elseif contains(label, 'selected')
    prefix = 'SEL';
else
    prefix = 'CASE';
end
end

function values = numericColumn(T, aliases, defaultValues)
values = safeGetTableValueStage14(T, aliases, defaultValues);
if iscell(values)
    values = str2double(string(values));
elseif isstring(values) || ischar(values)
    values = str2double(string(values));
elseif islogical(values)
    values = double(values);
end
values = values(:);
if height(T) > 0 && numel(values) == 1
    values = repmat(values, height(T), 1);
end
end

function values = logicalColumn(T, aliases, defaultValues)
values = safeGetTableValueStage14(T, aliases, defaultValues);
if iscell(values) || isstring(values) || ischar(values)
    values = strcmpi(string(values), "true") | strcmpi(string(values), "1") | strcmpi(string(values), "yes");
else
    values = logical(values);
end
values = values(:);
if height(T) > 0 && numel(values) == 1
    values = repmat(values, height(T), 1);
end
end

function values = stringColumn(T, aliases, defaultValues)
values = safeGetTableValueStage14(T, aliases, defaultValues);
if iscell(values)
    values = string(values);
elseif ischar(values)
    values = repmat(string(values), height(T), 1);
else
    values = string(values);
end
values = values(:);
if height(T) > 0 && numel(values) == 1
    values = repmat(values, height(T), 1);
end
end

function values = kmColumn(T, kmAliases, mAliases)
values = safeGetTableValueStage14(T, kmAliases, []);
if isempty(values)
    values = numericColumn(T, mAliases, nan(height(T), 1)) ./ 1000;
else
    values = numericColumn(table(values), {'values'}, values);
end
end

function values = kpaColumn(T, kpaAliases, paAliases)
values = safeGetTableValueStage14(T, kpaAliases, []);
if isempty(values)
    values = numericColumn(T, paAliases, nan(height(T), 1)) ./ 1000;
else
    values = numericColumn(table(values), {'values'}, values);
end
end

function values = heatingColumn(T)
values = safeGetTableValueStage14(T, {'MaxHeating_kW_m2'}, []);
if isempty(values)
    values = numericColumn(T, {'MaxHeating_W_m2','maxHeating_W_m2','maxHeatingRate'}, nan(height(T), 1)) ./ 1000;
else
    values = numericColumn(table(values), {'values'}, values);
end
end
