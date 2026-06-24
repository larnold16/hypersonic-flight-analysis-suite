function fig = openFullCaseTable(caseTable, titleText)
% openFullCaseTable
% Opens a table in a separate Stage 14 popup figure.

try
    if nargin < 2 || isempty(titleText)
        titleText = 'Stage 14 Case Table';
    end
    if nargin < 1 || isempty(caseTable)
        caseTable = table();
    end
    if ~istable(caseTable)
        caseTable = standardizeCaseTableStage14(caseTable, "Popup");
    end

    fig = uifigure('Name', titleText, 'Position', [150 150 1100 600]);
    layout = uigridlayout(fig, [1 1]);
    layout.Padding = [8 8 8 8];
    uitable(layout, 'Data', caseTable);
catch ME
    fig = uifigure('Name', 'Stage 14 Table Error', 'Position', [250 250 700 160]);
    uilabel(fig, 'Text', ['Could not open table: ', ME.message], ...
        'Position', [20 60 660 40]);
end
end
