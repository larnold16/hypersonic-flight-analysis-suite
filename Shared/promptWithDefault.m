function value = promptWithDefault(promptText, defaultValue, parser)
% promptWithDefault
% Prompts for a value and returns the default when Enter is pressed.

if nargin < 3
    parser = [];
end

defaultText = valueToText(defaultValue);
prompt = sprintf('%s [%s]: ', promptText, defaultText);

try
    rawValue = strtrim(input(prompt, 's'));
catch
    rawValue = '';
end

if isempty(rawValue)
    value = defaultValue;
    return;
end

if ~isempty(parser)
    value = parser(rawValue);
elseif isnumeric(defaultValue)
    value = str2double(rawValue);
elseif isstring(defaultValue)
    value = string(rawValue);
else
    value = rawValue;
end

if isnumeric(value) && any(isnan(value))
    warning('promptWithDefault:InvalidNumericInput', ...
        'Invalid numeric input. Using default value.');
    value = defaultValue;
end

end

function textValue = valueToText(value)
if isempty(value)
    textValue = 'disabled';
elseif isnumeric(value)
    textValue = num2str(value);
elseif isstring(value)
    textValue = char(value);
else
    textValue = value;
end
end
