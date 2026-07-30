function summary = run_local_sensitivity_profile(profile,seedList,resultsDir)
%RUN_LOCAL_SENSITIVITY_PROFILE Run nine-parameter local sensitivity.

if nargin < 1 || isempty(profile)
    profile = 'quick';
end
if nargin < 2 || isempty(seedList)
    seedList = 1:5;
end
if nargin < 3 || isempty(resultsDir)
    projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    resultsDir = fullfile(projectRoot,'results','local_sensitivity',char(profile));
end

if ~exist(resultsDir,'dir')
    mkdir(resultsDir);
end

% The profile changes only system scale and default configuration
% dimensions. The sensitivity workflow below is identical for quick,
% standard, and paper so their rankings are directly comparable.
baseCfg = cf_default_config(profile);
baseCfg.search.verbose = false;
innerIterCap = numericEnvOrEmpty('M3_SENSITIVITY_INNER_ITER_CAP');
if ~isempty(innerIterCap)
    baseCfg.inner.maxIter = max(0,round(min(baseCfg.inner.maxIter,innerIterCap)));
end
baseCandidate = cf_decode_candidate(baseCfg.defaultX,baseCfg);

[specs,parameterSettings] = cf_local_sensitivity_config(baseCfg,baseCandidate);

fprintf('Local sensitivity profile: %s\n',profile);
fprintf('Seeds: %s\n',mat2str(seedList));
fprintf('Result directory: %s\n',resultsDir);

baselineMetrics = cell(numel(seedList),1);
baselineScenarios = cell(numel(seedList),1);

% Baselines are computed once per seed and reused for every parameter's
% "base" point. This avoids measuring the same baseline repeatedly and also
% lets diagnostics confirm that base rows are identical across parameters.
for si = 1:numel(seedList)
    cfgSeed = prepareSeed(baseCfg,seedList(si));
    scenario = cf_generate_scenario(cfgSeed);
    baselineScenarios{si} = scenario;
    [metrics,~] = cf_evaluate_three_objectives(cfgSeed,scenario,baseCandidate);
    baselineMetrics{si} = metrics;
    fprintf('Baseline seed %d: J_inner=%.6g, J_outer=%.6g, J_true=%.6g\n', ...
        seedList(si),metrics.J_inner,metrics.J_outer,metrics.J_true);
end

rawRows = cell(0,1);
rowIndex = 0;

for pi = 1:numel(specs)
    spec = specs(pi);
    fprintf('\nParameter %d/%d: %s -> %s\n', ...
        pi,numel(specs),spec.TheoreticalName,spec.ActualField);

    for vi = 1:numel(spec.Values)
        value = spec.Values(vi);
        label = spec.PointLabels{vi};
        fprintf('  point %-5s value %.8g\n',label,value);

        for si = 1:numel(seedList)
            seed = seedList(si);
            cfgRun = prepareSeed(baseCfg,seed);
            candidateRun = baseCandidate;

            if strcmp(label,'base')
                metrics = baselineMetrics{si};
            else
                [cfgRun,candidateRun] = applySensitivityValue(cfgRun,candidateRun,spec,value);
                % Candidate-only perturbations reuse the same scenario for
                % that seed, so changes are attributed to the tested
                % parameter rather than to a regenerated channel. Scenario
                % parameters such as duHeight and numTransmitAntennas must
                % regenerate H and related geometry-dependent quantities.
                if spec.AffectsScenario
                    scenarioRun = cf_generate_scenario(cfgRun);
                else
                    scenarioRun = baselineScenarios{si};
                end
                [metrics,~] = cf_evaluate_three_objectives(cfgRun,scenarioRun,candidateRun);
            end

            rowIndex = rowIndex + 1;
            rawRows{rowIndex,1} = makeRawRow(spec,value,label,vi,seed,cfgRun,candidateRun,metrics); %#ok<AGROW>
        end
    end
end

rawStruct = vertcat(rawRows{:});
rawTable = struct2table(rawStruct);
runInfo = struct();
runInfo.profile = profile;
runInfo.seedList = seedList;
runInfo.innerIterCap = innerIterCap;
runInfo.createdAt = datestr(now,31);
runInfo.objectiveNotes = [ ...
    "J_inner is the final recorded inner WPS/sparse-beam objective."; ...
    "J_outer is the existing result.Score used by outer search fitness."; ...
    "J_true is recomputed only from b and SLINR as scheduled sum log2(1+SINR)." ...
    ];

% cf_export_sensitivity_results performs ranking, consistency checks, and
% report/table export. cf_plot_local_sensitivity then creates the per-profile
% figures from the exported summary.
summary = cf_export_sensitivity_results(rawTable,parameterSettings,specs,resultsDir,runInfo);
cf_plot_local_sensitivity(summary,resultsDir);

fprintf('\nFinished local sensitivity test.\n');
fprintf('Main workbook: %s\n',fullfile(resultsDir,'local_sensitivity_all_results.xlsx'));
fprintf('Text report:   %s\n',fullfile(resultsDir,'local_sensitivity_report.txt'));
end

function value = numericEnvOrEmpty(name)
raw = getenv(name);
if isempty(raw)
    value = [];
else
    value = str2double(raw);
    if ~isfinite(value)
        error('Environment variable %s must be numeric.',name);
    end
end
end

function cfg = prepareSeed(cfg,seed)
% Use separated seed offsets so user locations, channels, and any search
% randomness can vary together by seed without sharing the same RNG stream.
cfg.seedPosition = 1000 + seed;
cfg.seedChannel = 2000 + seed;
cfg.seedSearch = 3000 + seed;
cfg.search.verbose = false;
end

function [cfg,candidate] = applySensitivityValue(cfg,candidate,spec,value)
% A sensitivity spec points either to cfg or candidate. Integer parameters
% are rounded here because perturbation values are stored numerically even
% when they represent counts.
switch spec.Target
    case 'candidate'
        if strcmp(spec.DataType,'integer')
            value = round(value);
        end
        candidate.(spec.Field) = value;
    case 'cfg'
        if strcmp(spec.DataType,'integer')
            value = round(value);
        end
        cfg.(spec.Field) = value;
    otherwise
        error('Unknown sensitivity target: %s',spec.Target);
end
end

function row = makeRawRow(spec,value,label,pointIndex,seed,cfg,candidate,metrics)
% Store both input settings and output metrics in every raw row. This makes
% the CSV self-contained enough for later ranking, diagnostics, and plotting
% without rerunning the MATLAB evaluation.
row.ParameterIndex = spec.Index;
row.TheoreticalName = spec.TheoreticalName;
row.ActualField = spec.ActualField;
row.DataType = spec.DataType;
row.PointLabel = label;
row.PointIndex = pointIndex;
row.PointOrder = pointIndex - 2;
row.ParameterValue = value;
row.Seed = seed;
row.seedPosition = cfg.seedPosition;
row.seedChannel = cfg.seedChannel;
row.cfgDuHeight = cfg.duHeight;
row.cfgNumTxAntennas = cfg.numTxAntennas;
row.candidateBetaPF = candidate.betaPF;
row.candidateNumConnections = candidate.numConnections;
row.candidateScheduleThreshold = candidate.scheduleThreshold;
row.candidateRhoLink = candidate.rhoLink;
row.candidateRhoPower = candidate.rhoPower;
row.candidateRankThreshold = candidate.rankThreshold;
row.candidateRepairPower = candidate.repairPower;
row.candidateMaxRepairLinks = candidate.maxRepairLinks;
row.J_inner = metrics.J_inner;
row.J_outer = metrics.J_outer;
row.J_true = metrics.J_true;
row.sumRate = metrics.sumRate;
row.jain = metrics.jain;
row.rate5 = metrics.rate5;
row.rate10 = metrics.rate10;
row.activeLinks = metrics.activeLinks;
row.fronthaul = metrics.fronthaul;
row.totalPower = metrics.totalPower;
row.rankMean = metrics.rankMean;
row.rank1Count = metrics.rank1Count;
row.rank2Count = metrics.rank2Count;
row.numScheduledUE = metrics.numScheduledUE;
row.innerIterations = metrics.innerIterations;
row.converged = metrics.converged;
row.runtime = metrics.runtime;
row.initialActiveLinks = metrics.initialActiveLinks;
row.wDim1 = metrics.wDim1;
row.wDim2 = metrics.wDim2;
row.wDim3 = metrics.wDim3;
row.wDim4 = metrics.wDim4;
row.wDim5 = metrics.wDim5;
row.scenarioHash = metrics.scenarioHash;
row.distanceHash = metrics.distanceHash;
row.trueFromBAndSINR = metrics.trueFromBAndSINR;
row.trueMatchesSumRate = metrics.trueMatchesSumRate;
row.repairFunctionCalled = metrics.repairFunctionCalled;
row.rankDistributionText = metrics.rankDistributionText;
end
