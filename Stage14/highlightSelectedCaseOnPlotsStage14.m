function [app, highlighted] = highlightSelectedCaseOnPlotsStage14(app, selectedCase, sourceInfo)
% highlightSelectedCaseOnPlotsStage14
% Highlights the selected case on any visible Stage 14 scatter plot.

highlighted = false;
if nargin < 3
    sourceInfo = struct(); %#ok<NASGU>
end
if ~isfield(app, 'Figure') || isempty(app.Figure) || ~isvalid(app.Figure) || ...
        isempty(selectedCase) || ~istable(selectedCase) || height(selectedCase) == 0
    return;
end

caseID = normalizeCaseIDStage14(selectedCase.CaseID);
if isempty(caseID)
    return;
end
caseID = caseID(1);

objects = findall(app.Figure, '-property', 'UserData');
for k = 1:numel(objects)
    h = objects(k);
    try
        if ~isvalid(h) || ~isprop(h, 'XData') || ~isprop(h, 'YData')
            continue;
        end
        data = h.UserData;
        if ~isstruct(data) || ~isfield(data, 'caseTable') || ~istable(data.caseTable)
            continue;
        end
        ids = normalizeCaseIDStage14(data.caseTable.CaseID);
        idx = find(ids == caseID, 1);
        if isempty(idx)
            continue;
        end
        app = clearSelectedCaseCard(app);
        if isfield(app, 'SelectedPointMarker') && ~isempty(app.SelectedPointMarker) && ...
                isvalid(app.SelectedPointMarker)
            delete(app.SelectedPointMarker);
        end
        ax = ancestor(h, 'axes');
        x = h.XData(idx);
        y = h.YData(idx);
        app.SelectedPointMarker = line(ax, x, y, ...
            'Marker', 'o', 'MarkerSize', 12, 'LineWidth', 2, ...
            'Color', [0 0 0], 'LineStyle', 'none', 'HitTest', 'off');
        [app, ok] = showSelectedCaseDataTip(app, h, idx, selectedCase);
        if ~ok
            app = showSelectedCaseCardNearPoint(app, ax, x, y, selectedCase);
        end
        highlighted = true;
        return;
    catch
    end
end
end
