function value = safeGetFieldStage14(s, fieldNames, defaultValue)
% safeGetFieldStage14
% Safe struct/object field access for Stage 14.
%
% fieldNames may be a char/string scalar or a cell/string array of aliases.
% The first non-empty matching field is returned. Missing optional backend
% fields return defaultValue instead of crashing the GUI.

value = defaultValue;
if nargin < 3
    defaultValue = [];
    value = [];
end
if isempty(s)
    return;
end
if ischar(fieldNames) || isstring(fieldNames)
    fieldNames = cellstr(string(fieldNames));
end

for k = 1:numel(fieldNames)
    name = char(fieldNames{k});
    try
        if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
            value = s.(name);
            return;
        elseif isobject(s) && isprop(s, name) && ~isempty(s.(name))
            value = s.(name);
            return;
        end
    catch
        value = defaultValue;
    end
end
end
