function [value, isterminal, direction] = impactEvent(t, state)
% impactEvent
% Generic Stage 11+ ground-impact event.
%
% Stage 11/12/13 states store altitude in element 3. The small time guard
% prevents ode45 from stopping immediately at t = 0 when launch altitude is
% initialized very close to the ground.

if t < 1e-6
    value = 1.0;
else
    value = state(3);
end

isterminal = 1;
direction = -1;
end
