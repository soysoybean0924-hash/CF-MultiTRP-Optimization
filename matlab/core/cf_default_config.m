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
    case 'huawei'
        % Huawei typical validation scene from the challenge material:
        % 7 sites, 3 cells/sectors per site, 64TRX, 2T4R UE, 100 MHz
        % bandwidth with 273 RB at 30 kHz SCS.
        cfg.numSites = 7; cfg.cellsPerSite = 3; cfg.numDUs = 21;
        cfg.usersPerCellRange = [10 20];
        cfg.numUEs = round(mean(cfg.usersPerCellRange) * cfg.numDUs);
        cfg.numRBGs = 273;
        cfg.numTxAntennas = 64; cfg.numRxAntennas = 4; cfg.maxRank = 4;
        cfg.inner.maxIter = 35;
        cfg.search.populationSize = 12; cfg.search.maxEvaluations = 48;
    otherwise
        error('Unknown profile "%s". Use quick, standard, paper, M3, or huawei.', profile);
end

cfg.areaX = 400; cfg.areaY = 400;
cfg.duHeight = 20; cfg.ueHeight = 1.5;
cfg.pathlossExponent = 3.4;
cfg.referenceDistance = 10; cfg.minimumDistance = 10;
cfg.normalizeChannel = true;
cfg.maxDUPower = 1.0; cfg.noisePower = 1e-2;

if strcmp(cfg.profile,'huawei')
    cfg.areaX = 900; cfg.areaY = 900;
    cfg.interSiteDistance = 300;
    cfg.frequencyGHz = [2.6 3.5];
    cfg.channelModel = 'TR 38.901 UMi/UMa';
    cfg.bandwidthMHz = 100;
    cfg.subcarrierSpacingKHz = 30;
    cfg.numRB = 273;
    cfg.loadRatio = 0.30;
    cfg.prbUtilizationRange = [0.30 0.50];
    cfg.mobilityKmh = 3;
    cfg.traffic.model = 'burst';
    cfg.traffic.tailDataFraction = 0.30;
    cfg.traffic.tailTtiFraction = 0.60;
    cfg.antenna.baseStationTrx = 64;
    cfg.antenna.arrayHorizontal = 8;
    cfg.antenna.arrayVertical = 4;
    cfg.antenna.polarization = 2;
    cfg.antenna.elementSpacingWavelength = 0.5;
    cfg.antenna.ueTx = 2;
    cfg.antenna.ueRx = 4;
    cfg.measurement.srsChannelEstimation = {'ideal','nonideal'};
    cfg.measurement.srsPeriodTti = 340;
    cfg.measurement.srsHoppingFactor = 17;
    cfg.measurement.srsHoppingPeriodMs = 20;
    cfg.measurement.srsRbPerHop = 16;
    cfg.measurement.srsLastHopRb = 17;
    cfg.measurement.csiRsPeriodTti = 40;
    cfg.measurement.rankMode = 'adaptive';
    cfg.measurement.mode = 'nonideal';
    cfg.measurement.seed = 53;
    cfg.measurement.presinrReferenceDb = 8;
    cfg.measurement.presinrDistancePenaltyDb = 18;
    cfg.measurement.presinrShadowStdDb = 3;
    cfg.measurement.unmeasuredErrorMultiplier = 3;
    cfg.measurement.minimumErrorVariance = 1e-4;
    cfg.measurement.maximumErrorVariance = 0.45;
    cfg.receiver.type = 'IRC';
    cfg.experience.protocol = '3GPP TS 28.554 6.3.6.2';
    cfg.robust.enabled = true;
    cfg.robust.uncertaintyPenalty = 2.5;
    cfg.robust.channelShrinkage = 0.75;
    cfg.robust.unmeasuredPenalty = 1.0;
    cfg.robust.minimumChannelScale = 0.35;
end

% Inner-loop controls for the WPS/SCA-like beam update.
cfg.inner.tolerance = 1e-4;
cfg.inner.alphaEpsilon = 1e-3;
cfg.inner.regularization = 1e-8;
cfg.inner.lambdaStep = 0.05; cfg.inner.muStep = 0.10;
cfg.inner.rateAveragingFactor = 0.85; cfg.inner.pfEpsilon = 1e-6;
cfg.inner.minimumServicePower = 0.04;
cfg.inner.fairnessRepairRatio = 0.85;

if ~isfield(cfg,'robust'), cfg.robust = struct(); end
if ~isfield(cfg.robust,'enabled'), cfg.robust.enabled = false; end
if ~isfield(cfg.robust,'uncertaintyPenalty'), cfg.robust.uncertaintyPenalty = 0; end
if ~isfield(cfg.robust,'channelShrinkage'), cfg.robust.channelShrinkage = 0; end
if ~isfield(cfg.robust,'unmeasuredPenalty'), cfg.robust.unmeasuredPenalty = 0; end
if ~isfield(cfg.robust,'minimumChannelScale'), cfg.robust.minimumChannelScale = 0.0; end

% Experience-rate controls follow the 3GPP TS 28.554 Sec. 6.3.6.2 idea:
% measure throughput as ThpVolDl / ThpTimeDl while excluding idle or
% buffer-empty intervals and the last sample of each DL burst.
if ~isfield(cfg,'experience'), cfg.experience = struct(); end
cfg.experience.bottomPercentile = 5;
cfg.experience.excludeLastBurstSample = true;
cfg.experience.keepSingleSampleBursts = true;
cfg.experience.sampleAxis = 'RBG';
cfg.traffic.seed = 41;
cfg.traffic.numSamples = cfg.numRBGs;
cfg.traffic.meanBurstTti = max(3,round(0.08*cfg.numRBGs));
cfg.traffic.minBurstTti = 2;
cfg.traffic.maxBurstTti = max(3,round(0.20*cfg.numRBGs));

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
