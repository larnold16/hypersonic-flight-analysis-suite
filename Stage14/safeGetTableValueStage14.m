function values = safeGetTableValueStage14(T, columnNames, defaultValue)
% safeGetTableValueStage14
% Safe table column access for Stage 14 with alias support.

if nargin < 3
    defaultValue = [];
end
if istable(T)
    n = height(T);
else
    n = 1;
end

if isscalar(defaultValue)
    values = repmat(defaultValue, n, 1);
elseif isstring(defaultValue) && isscalar(defaultValue)
    values = repmat(defaultValue, n, 1);
else
    values = defaultValue;
end

if ~istable(T) || isempty(T)
    return;
end
if ischar(columnNames) || isstring(columnNames)
    columnNames = cellstr(string(columnNames));
end

names = T.Properties.VariableNames;
for k = 1:numel(columnNames)
    idx = find(strcmp(names, char(columnNames{k})), 1);
    if isempty(idx)
        idx = find(strcmpi(names, char(columnNames{k})), 1);
    end
    if ~isempty(idx)
        values = T.(names{idx});
        return;
    end
end
end
