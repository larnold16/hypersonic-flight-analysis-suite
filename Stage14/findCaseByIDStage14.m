function [selectedCase, sourceTableName, found, info] = findCaseByIDStage14(app, userCaseID)
% findCaseByIDStage14
% Searches all currently loaded Stage 14 case tables for a CaseID.

selectedCase = table();
sourceTableName = "";
found = false;
info = struct();
info.messages = strings(0, 1);
info.query = normalizeCaseIDStage14(userCaseID);

if isempty(info.query) || strlength(info.query(1)) == 0
    info.messages(end+1, 1) = "CaseID search failed: empty CaseID";
    return;
end
query = info.query(1);
info.messages(end+1, 1) = "Searching CaseID: " + query;
fprintf('%s\n', info.messages(end));

candidates = collectCandidateTables(app);
for k = 1:numel(candidates)
    rawTable = candidates(k).Table;
    if ~istable(rawTable) || height(rawTable) == 0 || isDetailTable(rawTable)
        continue;
    end
    try
        studyType = inferStudyType(candidates(k).Name, rawTable);
        T = standardizeCaseTableStage14(rawTable, studyType);
        match = matchCaseID(T.CaseID, query);
        if any(match)
            selectedCase = T(find(match, 1), :);
            sourceTableName = candidates(k).Name;
            found = true;
            info.messages(end+1, 1) = "Found CaseID in table: " + sourceTableName;
            fprintf('%s\n', info.messages(end));
            return;
        end
    catch ME
        info.messages(end+1, 1) = "CaseID search failed in " + candidates(k).Name + ": " + string(ME.message);
    end
end

info.messages(end+1, 1) = "CaseID not found";
fprintf('%s\n', info.messages(end));
end

function candidates = collectCandidateTables(app)
candidates = struct('Name', {}, 'Table', {});
candidates = addFieldCandidate(candidates, app, 'CurrentCaseTable');
candidates = addFieldCandidate(candidates, app, 'AngleSweepTable');
candidates = addFieldCandidate(candidates, app, 'MonteCarloTable');
candidates = addFieldCandidate(candidates, app, 'ParetoTable');
candidates = addFieldCandidate(candidates, app, 'OptimizationTable');
candidates = addFieldCandidate(candidates, app, 'DOETable');
candidates = addFieldCandidate(candidates, app, 'AllCaseTables');

uiFields = {'AngleTable','MonteCarloTable','ParetoTable','ResultsTable','SingleTable'};
for k = 1:numel(uiFields)
    if isfield(app, uiFields{k}) && isvalid(app.(uiFields{k})) && istable(app.(uiFields{k}).Data)
        candidates = addCandidate(candidates, uiFields{k}, app.(uiFields{k}).Data);
    end
end

if isfield(app, 'State')
    if isfield(app.State, 'selectedCase') && istable(app.State.selectedCase)
        candidates = addCandidate(candidates, "SelectedCaseHistory", app.State.selectedCase);
    end
    if isfield(app.State, 'Tables')
        names = fieldnames(app.State.Tables);
        for k = 1:numel(names)
            T = app.State.Tables.(names{k});
            if istable(T)
                candidates = addCandidate(candidates, names{k}, T);
            end
        end
    end
end
end

function candidates = addFieldCandidate(candidates, app, fieldName)
if isfield(app, fieldName) && istable(app.(fieldName))
    candidates = addCandidate(candidates, fieldName, app.(fieldName));
end
end

function candidates = addCandidate(candidates, name, T)
entry.Name = string(name);
entry.Table = T;
candidates(end+1) = entry; %#ok<AGROW>
end

function tf = isDetailTable(T)
names = string(T.Properties.VariableNames);
tf = height(T) > 1 && all(ismember(["Field","Value"], names));
end

function studyType = inferStudyType(name, T)
label = lower(char(string(name)));
if contains(label, 'angle')
    studyType = "AngleSweep";
elseif contains(label, 'monte')
    studyType = "MonteCarlo";
elseif contains(label, 'pareto')
    studyType = "Pareto";
elseif contains(label, 'optim')
    studyType = "Optimization";
elseif contains(label, 'doe')
    studyType = "DOE";
elseif any(strcmpi(T.Properties.VariableNames, 'StudyType'))
    values = string(T.StudyType);
    if ~isempty(values) && strlength(values(1)) > 0
        studyType = values(1);
    else
        studyType = "Stage14";
    end
else
    studyType = "Stage14";
end
end

function match = matchCaseID(caseIDs, query)
ids = normalizeCaseIDStage14(caseIDs);
query = normalizeCaseIDStage14(query);
query = query(1);
match = ids == query;
if any(match)
    return;
end

querySuffix = numericSuffix(query);
if strlength(querySuffix) > 0
    suffixes = strings(numel(ids), 1);
    for k = 1:numel(ids)
        suffixes(k) = numericSuffix(ids(k));
    end
    match = suffixes == querySuffix;
end
end

function suffix = numericSuffix(id)
id = normalizeCaseIDStage14(id);
if isempty(id)
    suffix = "";
    return;
end
token = char(id(1));
parts = regexp(token, '(\d+)$', 'tokens', 'once');
if isempty(parts)
    suffix = "";
else
    numericValue = str2double(parts{1});
    if isfinite(numericValue)
        suffix = string(numericValue);
    else
        suffix = "";
    end
end
end
