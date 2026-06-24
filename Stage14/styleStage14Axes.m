function styleStage14Axes(axesList)
% styleStage14Axes
% Applies consistent plot styling without changing plotted data.

theme = stage14Theme();
for k = 1:numel(axesList)
    ax = axesList(k);
    if isempty(ax) || ~isvalid(ax)
        continue;
    end
    setIfProperty(ax, 'FontName', theme.fontName);
    setIfProperty(ax, 'FontSize', 10);
    setIfProperty(ax, 'Color', theme.surface);
    setIfProperty(ax, 'XColor', theme.mutedText);
    setIfProperty(ax, 'YColor', theme.mutedText);
    setIfProperty(ax, 'GridColor', theme.grid);
    setIfProperty(ax, 'MinorGridColor', theme.gridMinor);
    setIfProperty(ax, 'GridAlpha', 0.45);
    setIfProperty(ax, 'MinorGridAlpha', 0.25);
    setIfProperty(ax, 'LineWidth', 0.9);
    setIfProperty(ax, 'Box', 'on');
    setIfProperty(ax, 'ColorOrder', theme.plotColors);
    grid(ax, 'on');

    if ~isempty(ax.Title)
        setIfProperty(ax.Title, 'FontName', theme.fontName);
        setIfProperty(ax.Title, 'FontWeight', 'bold');
        setIfProperty(ax.Title, 'FontSize', 11);
        setIfProperty(ax.Title, 'Color', theme.text);
    end
    if ~isempty(ax.XLabel)
        setIfProperty(ax.XLabel, 'FontName', theme.fontName);
        setIfProperty(ax.XLabel, 'Color', theme.mutedText);
    end
    if ~isempty(ax.YLabel)
        setIfProperty(ax.YLabel, 'FontName', theme.fontName);
        setIfProperty(ax.YLabel, 'Color', theme.mutedText);
    end

    try
        legendHandle = ax.Legend;
    catch
        legendHandle = [];
    end
    if ~isempty(legendHandle) && isvalid(legendHandle)
        setIfProperty(legendHandle, 'FontName', theme.fontName);
        setIfProperty(legendHandle, 'Color', theme.surface);
        setIfProperty(legendHandle, 'TextColor', theme.text);
        setIfProperty(legendHandle, 'EdgeColor', theme.border);
    end
end
end

function setIfProperty(obj, propName, propValue)
if isprop(obj, propName)
    try
        obj.(propName) = propValue;
    catch
    end
end
end
