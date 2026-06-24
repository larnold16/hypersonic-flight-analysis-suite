function ids = normalizeCaseIDStage14(values)
% normalizeCaseIDStage14
% Converts numeric/string/cell/categorical CaseID values into comparable text.

if nargin < 1 || isempty(values)
    ids = strings(0, 1);
    return;
end

try
    if iscell(values)
        ids = strings(numel(values), 1);
        for k = 1:numel(values)
            ids(k) = scalarToString(values{k});
        end
    elseif ischar(values)
        ids = string(values);
    else
        ids = string(values);
    end
catch
    ids = strings(0, 1);
    return;
end

ids = ids(:);
ids = upper(strtrim(ids));
ids(ismissing(ids)) = "";
ids = regexprep(ids, '\.0+$', '');
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
