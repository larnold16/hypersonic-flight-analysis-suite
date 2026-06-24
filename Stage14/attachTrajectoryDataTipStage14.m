function attachTrajectoryDataTipStage14(plotHandle, results)
% attachTrajectoryDataTipStage14
% Adds common trajectory fields to MATLAB data tips for line plots.

try
    if isempty(plotHandle) || ~isvalid(plotHandle) || ~isprop(plotHandle, 'DataTipTemplate')
        return;
    end
    n = numel(plotHandle.XData);
    dt = plotHandle.DataTipTemplate;
    rows = dataTipTextRow('Time s', vectorForTip(results, 't', n));
    rows(end+1) = dataTipTextRow('Downrange km', vectorForTip(results, 'x', n) ./ 1000);
    rows(end+1) = dataTipTextRow('Altitude km', vectorForTip(results, 'h', n) ./ 1000);
    rows(end+1) = dataTipTextRow('Velocity m/s', vectorForTip(results, 'V', n));
    rows(end+1) = dataTipTextRow('Mach', vectorForTip(results, 'Mach', n));
    rows(end+1) = dataTipTextRow('q kPa', vectorForTip(results, 'q', n) ./ 1000);
    rows(end+1) = dataTipTextRow('Drag N', vectorForTip(results, 'drag', n));
    rows(end+1) = dataTipTextRow('Lift N', vectorForTip(results, 'lift', n));
    rows(end+1) = dataTipTextRow('Tstag K', vectorForTipAny(results, {'stagTemp','Tstag'}, n));
    rows(end+1) = dataTipTextRow('FPA deg', vectorForTipAny(results, {'flightPathAngle_deg','gamma_deg'}, n));
    rows(end+1) = dataTipTextRow('AoA deg', vectorForTip(results, 'alpha_deg', n));
    rows(end+1) = dataTipTextRow('L/D', vectorForTip(results, 'LD', n));
    dt.DataTipRows = rows;
catch
end
end

function values = vectorForTip(results, fieldName, n)
values = nan(n, 1);
if isstruct(results) && isfield(results, fieldName) && isnumeric(results.(fieldName))
    raw = results.(fieldName)(:);
    m = min(n, numel(raw));
    values(1:m) = raw(1:m);
end
end

function values = vectorForTipAny(results, names, n)
values = nan(n, 1);
for k = 1:numel(names)
    values = vectorForTip(results, names{k}, n);
    if any(isfinite(values))
        return;
    end
end
end
