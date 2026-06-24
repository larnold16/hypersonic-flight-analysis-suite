function fileName = exportResultsCSV(app, results)
% exportResultsCSV
% Exports current trajectory time history to CSV.

if nargin < 2 || isempty(results)
    results = app.State.Results.single;
end
fileName = fullfile(app.State.tableDir, ['Stage14Results_', datestr(now, 'yyyymmdd_HHMMSS'), '.csv']);
T = table();
fields = {'t','x','y','h','V','Mach','q','drag','lift','alpha_deg','LD','stagTemp','Tstag'};
for k = 1:numel(fields)
    if isfield(results, fields{k}) && isnumeric(results.(fields{k}))
        name = matlab.lang.makeValidName(fields{k});
        values = results.(fields{k})(:);
        if height(T) == 0
            T.(name) = values;
        elseif numel(values) == height(T)
            T.(name) = values;
        end
    end
end
writetable(T, fileName);
end
