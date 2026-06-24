function [caseRow, idx, distance] = findNearestScatterCase(scatterHandle, point)
% findNearestScatterCase
% Finds the nearest plotted case to a clicked point in data units.

caseRow = table();
idx = [];
distance = Inf;

try
    if isempty(scatterHandle) || ~isvalid(scatterHandle) || ~isprop(scatterHandle, 'XData')
        return;
    end

    data = scatterHandle.UserData;
    if isstruct(data) && isfield(data, 'xData') && isfield(data, 'yData')
        x = data.xData(:);
        y = data.yData(:);
    else
        x = scatterHandle.XData(:);
        y = scatterHandle.YData(:);
    end
    if isempty(x) || isempty(y)
        return;
    end

    if nargin < 2 || isempty(point)
        ax = ancestor(scatterHandle, 'axes');
        cp = ax.CurrentPoint;
        point = cp(1, 1:2);
    end

    xRange = max(max(x) - min(x), eps);
    yRange = max(max(y) - min(y), eps);
    normalizedDistance = sqrt(((x - point(1)) ./ xRange).^2 + ((y - point(2)) ./ yRange).^2);
    [distance, idx] = min(normalizedDistance);

    caseTable = table();
    if isstruct(data) && isfield(data, 'caseTable') && istable(data.caseTable)
        caseTable = data.caseTable;
    elseif isstruct(data) && isfield(data, 'CaseTable') && istable(data.CaseTable)
        caseTable = data.CaseTable;
    end
    if ~isempty(caseTable) && idx <= height(caseTable)
        caseRow = caseTable(idx, :);
    end
catch
    caseRow = table();
    idx = [];
    distance = Inf;
end
end
