function app = clearSelectedCaseCard(app)
% clearSelectedCaseCard
% Removes old near-point card/data tip handles without touching the marker.

if isfield(app, 'SelectedCaseCard') && ~isempty(app.SelectedCaseCard)
    try
        if isvalid(app.SelectedCaseCard)
            delete(app.SelectedCaseCard);
        end
    catch
    end
end
app.SelectedCaseCard = gobjects(0);

if isfield(app, 'SelectedCaseDataTip') && ~isempty(app.SelectedCaseDataTip)
    try
        if isvalid(app.SelectedCaseDataTip)
            delete(app.SelectedCaseDataTip);
        end
    catch
    end
end
app.SelectedCaseDataTip = gobjects(0);
end
