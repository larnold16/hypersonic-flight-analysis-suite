function mode = stage11Menu()
% stage11Menu
% Small command-line menu for the Stage 11 analysis suite.

fprintf('\nStage 11: Hypersonic Trajectory Analysis Suite\n');
fprintf('  1 = Single trajectory demo\n');
fprintf('  2 = Launch angle sweep\n');
fprintf('  3 = Vehicle body comparison\n');
fprintf('  4 = Full body/angle comparison\n');
fprintf('  5 = Export single demo results and report\n\n');

if exist('promptWithDefault', 'file') == 2
    mode = promptWithDefault('Select Stage 11 option', 1);
else
    try
        raw = input('Select Stage 11 option [1]: ', 's');
    catch
        raw = '';
    end
    if isempty(strtrim(raw))
        mode = 1;
    else
        mode = str2double(raw);
    end
end

if isempty(mode) || isnan(mode) || mode < 1 || mode > 5
    warning('Stage11:InvalidMenuSelection', ...
        'Invalid Stage 11 selection. Using single trajectory demo.');
    mode = 1;
end
end
