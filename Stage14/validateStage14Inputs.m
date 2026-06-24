function [ok, messages] = validateStage14Inputs(app)
% validateStage14Inputs
% Friendly UI validation before a Stage 14 simulation run.

messages = strings(0, 1);
messages = requirePositive(messages, app.MassField.Value, "Mass must be greater than zero.");
messages = requirePositive(messages, app.DiameterField.Value, "Diameter must be greater than zero.");
messages = requirePositive(messages, app.LengthField.Value, "Length must be greater than zero.");
messages = requirePositive(messages, app.ReferenceAreaField.Value, "Reference area must be greater than zero.");
messages = requirePositive(messages, app.SpeedField.Value, "Initial speed must be greater than zero.");
if app.AngleField.Value < 0 || app.AngleField.Value > 90
    messages(end+1, 1) = "Launch angle should be between 0 and 90 degrees.";
end
if app.SweepStepField.Value <= 0
    messages(end+1, 1) = "Angle sweep step must be greater than zero.";
end
if app.SweepMinField.Value > app.SweepMaxField.Value
    messages(end+1, 1) = "Angle sweep minimum must be less than or equal to the maximum.";
end
ok = isempty(messages);
end

function messages = requirePositive(messages, value, message)
if ~isnumeric(value) || ~isfinite(value) || value <= 0
    messages(end+1, 1) = string(message);
end
end
