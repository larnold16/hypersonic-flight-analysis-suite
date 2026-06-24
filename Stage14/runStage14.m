function app = runStage14(vehicle, constants)
% runStage14
% Launches the Stage 14 programmatic MATLAB app.
%
% Stage 14 is a front end. It calls the validated Stage 11, Stage 12, and
% Stage 13 backend functions rather than duplicating trajectory physics.

if nargin < 1
    vehicle = struct();
end
if nargin < 2
    constants = struct();
end

app = HypersonicTrajectoryApp(vehicle, constants);
end
