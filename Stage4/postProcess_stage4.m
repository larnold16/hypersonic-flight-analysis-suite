function results = postProcess_stage4(t, state, vehicle, constants)
% postProcess_stage4
% Computes useful Stage 4 flight quantities.

rECI = state(:,1:3);
vECI = state(:,4:6);

rMag = sqrt(sum(rECI.^2, 2));
h = rMag - constants.Re;

% Launch-site reference vector in ECEF.
rLaunchECEF = llaToECEF_stage4(constants.launchLat, ...
                               constants.launchLon, ...
                               constants.launchAlt, ...
                               constants.Re);
rLaunchHat = rLaunchECEF / norm(rLaunchECEF);

% Convert all ECI positions to ECEF for the ground track.
theta = constants.omegaEarth .* t;
cosTheta = cos(theta);
sinTheta = sin(theta);

rECEF = [cosTheta.*rECI(:,1) + sinTheta.*rECI(:,2), ...
        -sinTheta.*rECI(:,1) + cosTheta.*rECI(:,2), ...
         rECI(:,3)];

rECEFMag = sqrt(sum(rECEF.^2, 2));
lat = asin(rECEF(:,3) ./ rECEFMag);
lon = atan2(rECEF(:,2), rECEF(:,1));

rHat = bsxfun(@rdivide, rECEF, rECEFMag);
cosSigma = rHat * rLaunchHat;
cosSigma = max(-1, min(1, cosSigma));
x = constants.Re .* acos(cosSigma);

% Atmosphere-relative velocity. The atmosphere is assumed to rotate with Earth.
omega = constants.omegaEarth;
vAtm = [-omega.*rECI(:,2), omega.*rECI(:,1), zeros(size(t))];

for k = 1:numel(t)
    vAtm(k,:) = vAtm(k,:) + environmentWind_stage4(t(k), constants).';
end

vRel = vECI - vAtm;
V = sqrt(sum(vRel.^2, 2));

[T, rho, ~, a] = standardAtmosphere_stage4(max(h, 0), constants);

Mach = zeros(size(t));
validSoundSpeed = a > 0;
Mach(validSoundSpeed) = V(validSoundSpeed) ./ a(validSoundSpeed);

[Cd, CL] = aeroCoefficients_stage4(Mach, vehicle);

q = 0.5 .* rho .* V.^2;
drag = q .* Cd .* vehicle.referenceArea;
lift = q .* CL .* vehicle.referenceArea;
beta = vehicle.mass ./ (Cd .* vehicle.referenceArea);
stagTemp = T .* (1 + ((constants.gamma - 1)/2).*Mach.^2);

results.t = t;
results.state = state;

results.x = x;
results.h = h;
results.V = V;
results.T = T;
results.rho = rho;
results.a = a;
results.Mach = Mach;
results.q = q;
results.drag = drag;
results.lift = lift;
results.Cd = Cd;
results.CL = CL;
results.beta = beta;
results.LD = lift ./ max(drag, eps);
results.stagTemp = stagTemp;
results.Tstag = stagTemp;
results.lat = lat;
results.lon = lon;

results.range = x(end);
results.maxAltitude = max(h);
results.impactSpeed = V(end);
results.maxMach = max(Mach);
results.maxQ = max(q);
results.maxDrag = max(drag);
results.maxLift = max(lift);
results.maxStagTemp = max(stagTemp);
results.maxLD = max(results.LD);

Cd_average = trapz(t, Cd) / max(t(end) - t(1), eps);

results.beta_initial = beta(1);
results.beta_average = vehicle.mass / (Cd_average * vehicle.referenceArea);
results.beta_min = min(beta);

[~, results.idxMaxQ] = max(q);
[~, results.idxMaxMach] = max(Mach);
[~, results.idxMaxAlt] = max(h);
[~, results.idxMaxDrag] = max(drag);

end
