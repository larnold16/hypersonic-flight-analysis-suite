function tutorial = generateTutorialContentStage14()
% generateTutorialContentStage14
% Student-friendly technical explanations for Stage 14 app concepts.

topic = [
    "Trajectory plot"
    "Mach number"
    "Dynamic pressure"
    "Max-Q"
    "Stagnation temperature"
    "Drag force"
    "Lift force"
    "L/D ratio"
    "Ballistic coefficient"
    "Static margin"
    "Angle of attack"
    "Launch angle"
    "High ballistic coefficient"
    "Hypersonic drag and heating"
    "Verification and validation"
    "Uncertainty bands"];

explanation = [
    "The trajectory plot shows altitude versus downrange distance, so it is the quickest view of path shape, range, and apogee."
    "Mach number is vehicle speed divided by local speed of sound. Hypersonic flight is usually Mach 5 and above."
    "Dynamic pressure is one of the most important structural loading indicators. It scales with air density and velocity squared."
    "Max-Q is the peak dynamic pressure point. It often occurs early because the vehicle is still low in dense air while moving very fast."
    "Stagnation temperature is a simplified estimate of the temperature air would reach if brought to rest at the vehicle nose."
    "Drag force opposes motion and removes mechanical energy from the trajectory."
    "Lift force acts roughly normal to the velocity direction in this simplified model and can reshape the flight path."
    "L/D ratio compares lift to drag. Higher L/D can help path shaping, but it does not remove the cost of drag."
    "Ballistic coefficient is mass divided by drag area. Higher values often decelerate less for the same atmosphere and speed."
    "Static margin estimates CG/CP separation. Too little margin can be unstable; too much can make the vehicle overly stiff."
    "Angle of attack is the angle between the vehicle axis and velocity direction. The simple aero model is most credible at modest values."
    "Launch angle trades range and altitude. In vacuum, 45 degrees maximizes range; drag and lift can shift the practical optimum."
    "Heavier high-ballistic-coefficient vehicles can sometimes travel farther because they lose speed more slowly to drag."
    "At hypersonic speed, drag and heating dominate because aerodynamic loads scale strongly with velocity."
    "Verification checks whether the math and code behave as expected; validation would require comparison with real data."
    "Uncertainty bands show how sensitive plots are to assumed input variation without overwriting the baseline case."];

tutorial = struct();
tutorial.table = table(topic, explanation, 'VariableNames', {'Topic','Explanation'});
tutorial.text = cellstr(topic + ": " + explanation);
end
