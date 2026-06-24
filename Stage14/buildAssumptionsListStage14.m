function assumptions = buildAssumptionsListStage14(fidelityLabel, state)
% buildAssumptionsListStage14
% Builds dynamic included/not-included physics tables for the selected
% educational model fidelity.

if nargin < 1 || strlength(string(fidelityLabel)) == 0
    fidelityLabel = "Stage 14: MATLAB App / interactive interface";
end
if nargin < 2
    state = struct();
end

stageNumber = parseStageNumber(fidelityLabel);
physics = getStateField(state, 'physics', struct());

included = strings(0, 3);
notIncluded = strings(0, 3);

included(end+1, :) = ["Gravity", "Included", "Uses constant-g or backend gravity approximations depending on selected stage."];
if stageNumber >= 2
    included(end+1, :) = ["Atmospheric density variation", "Included", "Standard-atmosphere trend model used for density, temperature, Mach, and q."];
    included(end+1, :) = ["Dynamic pressure", "Included", "Computed from density and velocity squared."];
    included(end+1, :) = ["Stagnation temperature", "Included", "Simplified perfect-gas estimate for trend analysis."];
else
    notIncluded(end+1, :) = ["Atmospheric density variation", "Not included", "Requires Stage 2 or higher."];
    notIncluded(end+1, :) = ["Mach/q/heating outputs", "Not included", "Requires Stage 2 or higher."];
end

if stageNumber >= 3
    included(end+1, :) = ["Vehicle geometry", "Included", "Length, diameter, reference area, body type, CG, and CP affect simplified aero."];
    included(end+1, :) = ["Mach-dependent drag", "Included", "Simplified coefficient model with transonic and hypersonic trends."];
    if getPhysicsFlag(physics, 'liftEnabled', true)
        included(end+1, :) = ["Lift model", "Included", "Educational alpha-based lift model is active."];
    else
        notIncluded(end+1, :) = ["Lift model", "Disabled", "Lift is available but currently disabled by the Physics tab."];
    end
else
    notIncluded(end+1, :) = ["Vehicle geometry and lift", "Not included", "Requires Stage 3 or higher."];
end

if stageNumber >= 4 && getPhysicsFlag(physics, 'earthRotation', false)
    included(end+1, :) = ["Earth rotation / Coriolis", "Selected", "Rotation effects are requested in the Stage 11/14 configuration."];
elseif stageNumber >= 4
    notIncluded(end+1, :) = ["Earth rotation / Coriolis", "Available but off", "Enable Earth rotation in Physics Options to include this simplified effect."];
else
    notIncluded(end+1, :) = ["Spherical Earth / rotation", "Not included", "Requires Stage 4 or higher."];
end

if stageNumber >= 10 && strcmpi(string(getStateText(physics, 'dofMode', '3DOF')), "6DOF")
    included(end+1, :) = ["6-DOF dynamics", "Experimental", "6-DOF setup is available but should be checked with the debug validation tool."];
elseif stageNumber >= 10
    notIncluded(end+1, :) = ["6-DOF dynamics", "Available but off", "Current app mode is 3-DOF."];
else
    notIncluded(end+1, :) = ["6-DOF dynamics", "Not included", "Requires Stage 10 or higher."];
end

if stageNumber >= 13
    included(end+1, :) = ["Monte Carlo and Pareto studies", "Included", "Stage 13 studies are available from the Monte Carlo and Pareto tabs."];
else
    notIncluded(end+1, :) = ["Monte Carlo and Pareto studies", "Not included", "Requires Stage 13 or higher."];
end

if stageNumber >= 14
    included(end+1, :) = ["Interactive app workflow", "Included", "Stage 14 combines setup, plots, trade studies, reports, and diagnostics."];
end

notIncluded = [notIncluded; commonLimitations()];

assumptions = struct();
assumptions.stageNumber = stageNumber;
assumptions.fidelityLabel = string(fidelityLabel);
assumptions.includedTable = array2table(included, 'VariableNames', {'PhysicsItem','Status','Notes'});
assumptions.notIncludedTable = array2table(notIncluded, 'VariableNames', {'PhysicsItem','Status','Notes'});
assumptions.limitationsText = {
    'This simplified model is useful for early trade studies and educational trajectory analysis.'
    'It should not be treated as a validated flight design, targeting, flight-safety, or certification tool.'
    'Verification checks prove selected numerical behavior; they do not replace validation against real flight data.'
    'Higher-fidelity effects such as ablation, shock-layer chemistry, structural deformation, and control-system dynamics are outside the current model.'};
end

function rows = commonLimitations()
rows = [
    "Ablation", "Not included", "Thermal protection material loss is not modeled."
    "Real gas chemistry", "Not included", "High-temperature dissociation/ionization effects are outside this model."
    "Shock-layer radiation", "Not included", "Radiative heating is not modeled."
    "Structural deformation", "Not included", "Vehicle bending, flutter, and material failure are not modeled."
    "Active guidance", "Not included", "No closed-loop guidance or autopilot is modeled."
    "Propulsion after launch", "Not included", "The default simulation is an initial-velocity trajectory."
    "Wind turbulence", "Not included", "Only simplified wind placeholders are available."
    "Control actuator dynamics", "Not included", "No actuator bandwidth, limits, or control-surface dynamics."
    "High-fidelity CFD/TPS", "Not included", "Aero and heating are simplified engineering trend models."];
end

function n = parseStageNumber(label)
token = regexp(char(string(label)), 'Stage\s+(\d+)', 'tokens', 'once');
if isempty(token)
    n = 14;
else
    n = str2double(token{1});
end
end

function value = getStateField(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end

function value = getStateText(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    value = s.(name);
else
    value = defaultValue;
end
end

function tf = getPhysicsFlag(s, name, defaultValue)
if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
    tf = logical(s.(name));
else
    tf = logical(defaultValue);
end
end
