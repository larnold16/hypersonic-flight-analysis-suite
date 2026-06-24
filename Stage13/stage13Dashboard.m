function mode = stage13Dashboard()
% stage13Dashboard
% Command-line dashboard for Stage 13 trade studies.

fprintf('\nStage 13: Optimization, Monte Carlo, Sensitivity, and Design Trade Studies\n');
fprintf('  1 = Run constrained design optimization\n');
fprintf('  2 = Run launch angle optimization\n');
fprintf('  3 = Run vehicle geometry optimization\n');
fprintf('  4 = Run Monte Carlo uncertainty study\n');
fprintf('  5 = Run sensitivity study\n');
fprintf('  6 = Run Pareto trade study\n');
fprintf('  7 = Run design of experiments\n');
fprintf('  8 = Generate Stage 13 report\n');
fprintf('  9 = Export Stage 13 portfolio package\n\n');

if exist('promptWithDefault', 'file') == 2
    mode = promptWithDefault('Select Stage 13 option', 1);
else
    try
        raw = input('Select Stage 13 option [1]: ', 's');
    catch
        raw = '';
    end
    if isempty(strtrim(raw))
        mode = 1;
    else
        mode = str2double(raw);
    end
end

if isempty(mode) || isnan(mode) || mode < 1 || mode > 9
    warning('Stage13:InvalidMenuSelection', ...
        'Invalid Stage 13 selection. Running constrained optimization.');
    mode = 1;
end
end
