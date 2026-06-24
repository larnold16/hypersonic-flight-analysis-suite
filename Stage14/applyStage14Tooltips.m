function app = applyStage14Tooltips(app)
% applyStage14Tooltips
% Short engineering term help for key Stage 14 controls.

tips = {
    'MainPlotDropDown', 'Choose which trajectory time history or path to show in the main plot.'
    'EventMarkersCheckbox', 'Marks launch, apogee, peak Mach, max q, max drag/lift, max stagnation temperature, max L/D, and impact.'
    'CompareMissionDropDown', 'Selects the objective used to highlight the best scenario case. Balanced uses a simplified heuristic score.'
    'CompareSweepDropDown', 'Runs preset or custom side-by-side scenarios without changing the baseline inputs.'
    'SensitivityPerturbField', 'Percent perturbation for one-at-a-time sensitivity analysis. Some variables use small absolute changes.'
    'DofDropDown', '3DOF is the primary educational trajectory mode; 6DOF is experimental and should be validated.'
    'LiftCheckbox', 'Enables lift from the simplified aerodynamic model.'
    'DragCheckbox', 'Enables aerodynamic drag. Turning it off is useful for diagnostics, not realism.'
    'HeatingCheckbox', 'Uses a simplified stagnation heating estimate for trend analysis.'
    'StabilityCheckbox', 'Uses simplified static-margin and moment assumptions.'
    'StaticMarginField', 'Static margin estimates CG/CP separation as a stability indicator.'
    'CdMultiplierField', 'Scales the simplified drag model; useful for trade studies.'
    'CLMultiplierField', 'Scales the simplified lift model; useful for trade studies.'
    'ModelFidelityDropDown', 'Changes the assumptions list and explains which physics are available at the selected project stage.'
    'RunVerificationButton', 'Runs vacuum, drag-only, and full-aero diagnostics with energy and analytic projectile checks.'
    'MaxQConstraintField', 'Maximum allowed dynamic pressure for the constraint-envelope and optimization feasibility checks.'
    'RunConstraintEnvelopeButton', 'Checks the current baseline trajectory against selected q, heating, Mach, g-load, stability, alpha, drag, and lift limits.'
    'OptObjectiveDropDown', 'Selects the scalar objective used to rank feasible grid-search cases.'
    'RunOptimizationGridButton', 'Runs a simple grid search over selected design variables without changing baseline inputs.'
    'ApplyBestDesignButton', 'Applies the current best feasible optimization case to the baseline inputs.'
    'RunUncertaintyButton', 'Runs deterministic low/high perturbation cases and draws shaded uncertainty bands.'};

for k = 1:size(tips, 1)
    fieldName = tips{k, 1};
    if isfield(app, fieldName) && isvalid(app.(fieldName)) && isprop(app.(fieldName), 'Tooltip')
        try
            app.(fieldName).Tooltip = tips{k, 2};
        catch
        end
    end
end
end
