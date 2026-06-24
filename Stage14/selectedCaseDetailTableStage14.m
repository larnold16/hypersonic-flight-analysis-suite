function detailTable = selectedCaseDetailTableStage14(caseRow)
% selectedCaseDetailTableStage14
% Builds the Field/Value selected-case display table used by Stage 14.

fields = ["CaseID";"StudyType";"ParetoFlag";"MonteCarloRunNumber";"Feasible"; ...
    "ViolatedConstraints";"BodyType";"NoseType";"LaunchAngle_deg"; ...
    "InitialSpeed_mps";"InitialYaw_deg";"InitialAltitude_m";"Mass_kg"; ...
    "Length_m";"Diameter_m";"ReferenceArea_m2";"CG_m";"CP_m"; ...
    "StaticMargin_percent";"CdMultiplier";"CLalphaMultiplier";"WindSpeed_mps"; ...
    "DensityMultiplier";"Range_km";"MaxAltitude_km";"TimeOfFlight_s"; ...
    "ImpactSpeed_mps";"ImpactMach";"MaxMach";"MaxQ_kPa"; ...
    "MaxHeating_kW_m2";"MaxStagTemp_K";"TotalHeatLoad";"MaxGLoad";"MaxAlpha_deg"; ...
    "MaxBeta_deg";"MaxCL";"MaxCD";"MaxLD";"Score"];

values = repmat("N/A", numel(fields), 1);
if istable(caseRow) && height(caseRow) > 0
    try
        caseRow = standardizeCaseTableStage14(caseRow(1,:), "SelectedCase");
    catch
    end
    names = string(caseRow.Properties.VariableNames);
    for k = 1:numel(fields)
        idx = find(strcmpi(names, fields(k)), 1);
        if ~isempty(idx)
            values(k) = valueToString(caseRow.(caseRow.Properties.VariableNames{idx}));
        end
    end
end

detailTable = table(fields, values, 'VariableNames', {'Field','Value'});
end

function text = valueToString(value)
try
    if iscell(value)
        text = valueToString(value{1});
    elseif iscategorical(value)
        text = string(value(1));
    elseif isstring(value)
        text = value(1);
    elseif ischar(value)
        text = string(value);
    elseif isnumeric(value)
        if isempty(value) || isnan(value(1))
            text = "N/A";
        else
            text = string(value(1));
        end
    elseif islogical(value)
        text = string(value(1));
    else
        text = strtrim(string(evalc('disp(value(1))')));
    end
    if ismissing(text) || strlength(strtrim(text)) == 0
        text = "N/A";
    end
catch
    text = "N/A";
end
end
