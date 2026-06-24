function [value, isterminal, direction] = groundEvent_stage4(t, state, constants)
% groundEvent_stage4
% Stops integration when vehicle returns to Earth's surface.

r = state(1:3);
h = norm(r) - constants.Re;

value = h;

% Avoid stopping immediately at launch.
if t < 1e-3
    value = 1;
end

isterminal = 1;
direction = -1;

end