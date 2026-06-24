function attachTrajectoryPointSelectionStage14(plotHandle, fig, results, label)
% attachTrajectoryPointSelectionStage14
% Lets the user click a plotted trajectory/time-history point.

if nargin < 4
    label = "trajectory point";
end
try
    if isempty(plotHandle) || ~isvalid(plotHandle) || isempty(fig) || ~isvalid(fig)
        return;
    end
    plotHandle.ButtonDownFcn = @(src,~) selectNearestPoint(src, fig, results, label);
    plotHandle.PickableParts = 'visible';
    plotHandle.HitTest = 'on';
catch
end
end

function selectNearestPoint(src, fig, results, label)
try
    ax = ancestor(src, 'axes');
    cp = ax.CurrentPoint;
    clickX = cp(1,1);
    clickY = cp(1,2);
    x = src.XData(:);
    y = src.YData(:);
    valid = isfinite(x) & isfinite(y);
    if ~any(valid)
        return;
    end
    xr = max(x(valid)) - min(x(valid));
    yr = max(y(valid)) - min(y(valid));
    if xr <= eps, xr = 1; end
    if yr <= eps, yr = 1; end
    d = ((x - clickX) ./ xr).^2 + ((y - clickY) ./ yr).^2;
    d(~valid) = Inf;
    [~, idx] = min(d);
    showSelectedTrajectoryPointStage14(fig, ax, x(idx), y(idx), results, idx, label);
catch
end
end
