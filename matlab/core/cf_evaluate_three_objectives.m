function [metrics,nativeResult] = cf_evaluate_three_objectives(cfg,scenario,candidate)
%CF_EVALUATE_THREE_OBJECTIVES Run one simulation and separate objectives.
%
% J_inner: final inner-loop objective recorded by cf_evaluate_candidate.
%          It is WPS minus link and power penalties inside the beam loop.
% J_outer: existing outer-search fitness, result.Score.
% J_true : scheduled sum log2(1+SINR), recomputed from b and SLINR only.

if nargin < 2 || isempty(scenario)
    scenario = cf_generate_scenario(cfg);
end

tic;
nativeResult = cf_evaluate_candidate(cfg,scenario,candidate,true);
runtime = toc;

% J_true is deliberately recomputed from the final schedule and SLINR. This
% prevents the sensitivity analysis from conflating it with the weighted
% search score used by the optimizer.
[Jtrue,trueDetails] = cf_compute_true_objective(nativeResult);

if ~isempty(nativeResult.history.objective)
    Jinner = nativeResult.history.objective(end);
else
    Jinner = sum(nativeResult.WPS(:)) - candidate.rhoLink*nativeResult.ActiveLinks - ...
        candidate.rhoPower*nativeResult.TotalPower;
end

Jouter = nativeResult.Score;
innerIterations = numel(nativeResult.history.objective);
if innerIterations > 0
    lastRelativeChange = nativeResult.history.relativeChange(end);
    converged = lastRelativeChange < cfg.inner.tolerance;
else
    lastRelativeChange = NaN;
    converged = false;
end

rankValues = nativeResult.r(:);
rank1Count = sum(rankValues == 1);
rank2Count = sum(rankValues == 2);
rankMean = mean(rankValues);

fronthaul = 0;
% Fronthaul proxy: each active DU-UE-RBG link consumes rankUG(u,g) streams.
for r = 1:cfg.numDUs
    for u = 1:cfg.numUEs
        for g = 1:cfg.numRBGs
            if nativeResult.b(r,u,g) > 0
                fronthaul = fronthaul + nativeResult.r(u,g);
            end
        end
    end
end

wDims = size(nativeResult.W);
if numel(wDims) < 5
    wDims(end+1:5) = 1;
end

h = scenario.H(:);
idxH = (1:numel(h)).';
% Lightweight deterministic hashes support diagnostics that verify whether
% candidate-only perturbations reused the same channel/geometry.
scenarioHash = sum(abs(h).^2 .* idxH) / max(1,numel(h));
d = scenario.distance(:);
idxD = (1:numel(d)).';
distanceHash = sum(d .* idxD) / max(1,numel(d));

metrics = struct();
metrics.J_inner = Jinner;
metrics.J_outer = Jouter;
metrics.J_true = Jtrue;
metrics.sumRate = nativeResult.SumRate;
metrics.jain = nativeResult.Jain;
metrics.rate5 = nativeResult.Rate5;
metrics.rate10 = nativeResult.Rate10;
metrics.activeLinks = nativeResult.ActiveLinks;
metrics.fronthaul = fronthaul;
metrics.totalPower = nativeResult.TotalPower;
metrics.rankMean = rankMean;
metrics.rank1Count = rank1Count;
metrics.rank2Count = rank2Count;
metrics.rankDistributionText = sprintf('rank1=%d, rank2=%d',rank1Count,rank2Count);
metrics.numScheduledUE = trueDetails.numScheduledUE;
metrics.innerIterations = innerIterations;
metrics.converged = converged;
metrics.lastRelativeChange = lastRelativeChange;
metrics.runtime = runtime;
metrics.initialActiveLinks = sum(nativeResult.bInit(:));
metrics.wDim1 = wDims(1);
metrics.wDim2 = wDims(2);
metrics.wDim3 = wDims(3);
metrics.wDim4 = wDims(4);
metrics.wDim5 = wDims(5);
metrics.scenarioHash = scenarioHash;
metrics.distanceHash = distanceHash;
metrics.trueFromBAndSINR = true;
metrics.trueMatchesSumRate = trueDetails.valueMatchesSumRate;
metrics.repairFunctionCalled = candidate.maxRepairLinks > 0;
end
