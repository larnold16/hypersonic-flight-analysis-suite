function fileName = exportPlotPNG(app)
% exportPlotPNG
% Exports the main Stage 14 single-run plot to PNG.

fileName = fullfile(app.State.figureDir, ['Stage14Plot_', datestr(now, 'yyyymmdd_HHMMSS'), '.png']);
if isfield(app, 'SingleAxes') && ~isempty(app.SingleAxes) && isvalid(app.SingleAxes(1))
    exportgraphics(app.SingleAxes(1), fileName, 'Resolution', 160);
else
    error('Stage14:NoPlot', 'No main plot is available to export.');
end
end
