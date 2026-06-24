function showEventExplanationStage14(markerHandle, event)
% showEventExplanationStage14
% Shows a short explanation when an event marker is clicked.

try
    ax = ancestor(markerHandle, 'axes');
    fig = ancestor(ax, 'figure');
    app = fig.UserData;
    msg = eventMessage(event);
    if isfield(app, 'StatusLabel') && isvalid(app.StatusLabel)
        app.StatusLabel.Text = char(msg);
    end
    if isfield(app, 'EngineeringInsightsArea') && isvalid(app.EngineeringInsightsArea)
        current = string(app.EngineeringInsightsArea.Value);
        app.EngineeringInsightsArea.Value = cellstr([msg; current(:)]);
    end
    fig.UserData = app;
    drawnow;
catch
end
end

function msg = eventMessage(event)
label = lower(char(event.label));
if contains(label, 'dynamic')
    msg = sprintf('Max Q at t = %.2f s is a structural loading indicator.', event.time_s);
elseif contains(label, 'mach')
    msg = sprintf('Peak Mach at t = %.2f s marks the maximum speed relative to local sound speed.', event.time_s);
elseif contains(label, 'stagnation')
    msg = sprintf('Peak stagnation temperature at t = %.2f s is a thermal environment indicator.', event.time_s);
elseif contains(label, 'altitude')
    msg = sprintf('Apogee occurred at t = %.2f s and altitude %.1f m.', event.time_s, event.h_m);
elseif contains(label, 'drag')
    msg = sprintf('Peak drag at t = %.2f s indicates the strongest aerodynamic drag force in this run.', event.time_s);
elseif contains(label, 'impact')
    msg = sprintf('Impact occurred at t = %.2f s near range %.1f m.', event.time_s, event.x_m);
else
    msg = sprintf('%s occurred at t = %.2f s.', event.label, event.time_s);
end
msg = string(msg);
end
