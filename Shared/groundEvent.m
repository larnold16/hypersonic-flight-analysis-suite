function [value, isterminal, direction] = groundEvent(t, state)
% groundEvent
% Stops the simulation when altitude returns to ground level.
%
% Works for Stage 1, Stage 2, and Stage 3.

h = state(2);

% Prevent event from triggering immediately at launch
if t < 1e-6
    value = 1;
else
    value = h;
end

isterminal = 1;     % stop integration
direction = -1;     % only detect when falling downward

end