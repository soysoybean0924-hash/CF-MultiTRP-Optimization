function cfg = cf_default_config(profile)
%CF_DEFAULT_CONFIG Cell-Free b/p/r/W joint-optimization configuration.

if nargin < 1 || isempty(profile)
    profile = 'quick';
end

cfg.profile = lower(char(profile));
cfg.seedPosition = 11;
cfg.seedChannel = 23;
cfg.seedSearch = 37;

% Profiles scale the network and evaluation budget. Keep default
% search-vector semantics shared so quick/standard/paper/M3 runs remain
% comparable.
switch cfg.profile
    case 'quick'
        cfg.numDUs = 4; cfg.numUEs = 6; cfg.numRBGs = 3;
        cfg.numTxAntennas = 4; cfg.numRxAntennas = 2; cfg.maxRank = 2;
        cfg.inner.maxIter = 12;
        cfg.search.populationSize = 8; cfg.search.maxEvaluations = 32;
    case 'standard'
        cfg.numDUs = 8; cfg.numUEs = 16; cfg.numRBGs = 4;
        cfg.numTxAntennas = 8; cfg.numRxAntennas = 2; cfg.maxRank = 2;
        cfg.inner.maxIter = 25;
        cfg.search.populationSize = 12; cfg.search.maxEvaluations = 72;
    case 'paper'
        cfg.numDUs = 16; cfg.numUEs = 30; cfg.numRBGs = 5;
        cfg.numTxAntennas = 8; cfg.numRxAntennas = 2; cfg.maxRank = 2;
        cfg.inner.maxIter = 35;
        cfg.search.populationSize = 20; cfg.search.maxEvaluations = 200;
    case 'm3'
        cfg.numDUs = 7; cfg.numUEs = 100; cfg.numRBGs = 100;
        cfg.numTxAntennas = 12; cfg.numRxAntennas = 2; cfg.maxRank = 2;
        cfg.inner.maxIter = 35;
        cfg.search.populationSize = 20; cfg.search.maxEvaluations = 200;
    otherwise
        error('Unknown profile "%s". Use quick, standard, paper, or M3.', profile);
end

cfg.areaX = 400; cfg.areaY = 400;
cfg.duHeight = 20; cfg.ueHeight = 1.5;
cfg.pathlossExponent = 3.4;
cfg.referenceDistance = 10; cfg.minimumDistance = 10;
cfg.normalizeChannel = true;
cfg.maxDUPower = 1.0; cfg.noisePower = 1e-2;

% Inner-loop controls for the WPS/SCA-like beam update.
cfg.inner.tolerance = 1e-4;
cfg.inner.alphaEpsilon = 1e-3;
cfg.inner.regularization = 1e-8;
cfg.inner.lambdaStep = 0.05; cfg.inner.muStep = 0.10;
cfg.inner.rateAveragingFactor = 0.85; cfg.inner.pfEpsilon = 1e-6;
cfg.inner.minimumServicePower = 0.04;
cfg.inner.fairnessRepairRatio = 0.85;

% Legacy diagnostic weights. The active outer-search objective is J_true:
% scheduled sum log2(1+SINR). These weights are retained only to report the
% previous weighted score in result.ScoreParts.LegacyWeightedScore.
cfg.score.wSumRate = 1.0; cfg.score.wJain = 35;
cfg.score.wMinRate = 15; cfg.score.wRate10 = 20;
cfg.score.wActiveLinks = 0.02; cfg.score.wPower = 0.01;
cfg.score.wStreams = 0.01; cfg.score.wMinRateLoss = 40;
cfg.score.wRate10Loss = 50; cfg.score.wJainTarget = 60;
cfg.score.jainTarget = 0.80;

% The outer search always operates in normalized [0,1]^9. cf_decode_candidate
% maps these normalized coordinates into physical/mixed parameter values.
cfg.search.dimension = 9;
cfg.search.lowerBound = zeros(1,9); cfg.search.upperBound = ones(1,9);
cfg.search.parameterNames = {'betaPF','numConnections','scheduleThreshold', ...
    'rhoLink','rhoPower','maxRank','rankThreshold','repairPower','maxRepairLinks'};
cfg.search.betaPFRange = [0.6 2.4];
cfg.search.numConnectionsRange = [1 min(4,cfg.numDUs)];
cfg.search.scheduleThresholdRange = [1e-6 1e-2];
cfg.search.rhoLinkRange = [1e-3 1e-1];
cfg.search.rhoPowerRange = [1e-4 2e-2];
cfg.search.rankThresholdRange = [0.05 0.50];
cfg.search.repairPowerRange = [0.01 0.15] * cfg.maxDUPower;
cfg.search.maxRepairLinksRange = [0 min(4,cfg.numDUs*cfg.numRBGs)];

cfg.search.eliteCount = min(2,cfg.search.populationSize-1);
cfg.search.tournamentSize = 2; cfg.search.crossoverRate = 0.80;
cfg.search.mutationRate = 0.18; cfg.search.mutationSigma = 0.12;
cfg.search.psoInertiaStart = 0.85; cfg.search.psoInertiaEnd = 0.40;
cfg.search.psoCognitive = 1.7; cfg.search.psoSocial = 1.7;
cfg.search.psoVelocityLimit = 0.25; cfg.search.hybridFirstFraction = 0.50;
cfg.search.pgsaoCrossoverRate = 0.50; cfg.search.pgsaoMutationRate = 0.15;
cfg.search.verbose = true;
cfg.defaultX = [0.35 0.35 0.50 0.45 0.45 1.00 0.25 0.30 0.50];
end
