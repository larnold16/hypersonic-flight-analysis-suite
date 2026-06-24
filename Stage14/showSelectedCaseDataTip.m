function [app, ok] = showSelectedCaseDataTip(app, scatterHandle, pointIndex, selectedCase)
% showSelectedCaseDataTip
% Attempts to show a MATLAB data tip on the selected scatter point.

ok = false;
if nargin < 4 %#ok<NASGU>
    selectedCase = table();
end
try
    if isempty(scatterHandle) || ~isvalid(scatterHandle) || isempty(pointIndex)
        return;
    end
    x = scatterHandle.XData(pointIndex);
    y = scatterHandle.YData(pointIndex);
    tip = datatip(scatterHandle, x, y);
    app.SelectedCaseDataTip = tip;
    ok = true;
catch
    ok = false;
end
end
