function options = updateModelFidelityOptionsStage14()
% updateModelFidelityOptionsStage14
% Returns only model-fidelity stages that are available on the MATLAB path
% or present as sibling Stage folders in the current Hypersonics project.

descriptions = {
    1,  'Basic 2D projectile with drag'
    2,  'Atmosphere, Mach, dynamic pressure, stagnation temperature'
    3,  'Vehicle geometry and lift/drag model'
    4,  'Spherical Earth and Earth rotation'
    5,  'Mission sweep'
    6,  'Vehicle comparison / ballistic coefficient'
    7,  'Thermal/stability placeholder'
    8,  'Stability and trim'
    9,  'Environmental sensitivity'
    10, '6-DOF baseline'
    11, 'Physics diagnostics'
    12, 'Angle and model comparison'
    13, 'Pareto and Monte Carlo'
    14, 'MATLAB App / interactive interface'};

candidateRoots = candidateProjectRoots();
items = {};
for k = 1:size(descriptions, 1)
    stageNumber = descriptions{k, 1};
    if stageExists(stageNumber, candidateRoots)
        items{end+1} = sprintf('Stage %d: %s', stageNumber, descriptions{k, 2}); %#ok<AGROW>
    end
end

if isempty(items)
    items = {'Stage 14: MATLAB App / interactive interface'};
end
options = items;
end

function roots = candidateProjectRoots()
roots = {};
thisFile = mfilename('fullpath');
if ~isempty(thisFile)
    roots{end+1} = fileparts(fileparts(thisFile)); %#ok<AGROW>
end
for n = [14 13 12 11 10 1]
    f = which(sprintf('runStage%d', n));
    if ~isempty(f)
        roots{end+1} = fileparts(fileparts(f)); %#ok<AGROW>
    end
end
roots = unique(roots, 'stable');
end

function tf = stageExists(stageNumber, roots)
tf = false;
folderName = sprintf('Stage%d', stageNumber);
for r = 1:numel(roots)
    if exist(fullfile(roots{r}, folderName), 'dir') == 7
        tf = true;
        return;
    end
end
if stageNumber == 14
    tf = exist('HypersonicTrajectoryApp', 'file') == 2 || exist('runStage14', 'file') == 2;
else
    tf = exist(sprintf('runStage%d', stageNumber), 'file') == 2;
end
end
