%% Local sensitivity test for nine outer strategy parameters.
% This script keeps the original Cell-Free evaluation path intact and adds
% an experiment layer for one-at-a-time local perturbations.

clear; clc; close all;

rootFolder = fileparts(mfilename('fullpath'));
addpath(rootFolder);

resultsDir = fullfile(rootFolder,'results','local_sensitivity');
if ~exist(resultsDir,'dir')
    mkdir(resultsDir);
end

profile = 'quick';
seedList = 1:5;

baseCfg = cf_default_config(profile);
baseCfg.search.verbose = false;
baseCandidate = cf_decode_candidate(baseCfg.defaultX,baseCfg);

[specs,parameterSettings] = cf_local_sensitivity_config(baseCfg,baseCandidate);

fprintf('Local sensitivity profile: %s\n',profile);
fprintf('Seeds: %s\n',mat2str(seedList));
fprintf('Result directory: %s\n',resultsDir);

baselineMetrics = cell(numel(seedList),1);
baselineScenarios = cell(numel(seedList),1);

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
                if spec.AffectsScenario
                    scenarioRun = cf_generate_scenario(cfgRun);
                else
                    scenarioRun = baselineScenarios{si};
                end
                [metrics,~] = cf_evaluate_three_objectives(cfgRun,scenarioRun,candidateRun);
            end

            rowIndex = rowIndex + 1;
            rawRows{rowIndex,1} = makeRawRow(spec,value,label,vi,seed,cfgRun,candidateRun,metrics); %#ok<SAGROW>
        end
    end
end

rawStruct = vertcat(rawRows{:});
rawTable = struct2table(rawStruct);
runInfo = struct();
runInfo.profile = profile;
runInfo.seedList = seedList;
runInfo.createdAt = datestr(now,31);
runInfo.objectiveNotes = [ ...
    "J_inner is the final recorded inner WPS/sparse-beam objective."; ...
    "J_outer is the existing result.Score used by outer search fitness."; ...
    "J_true is recomputed only from b and SLINR as scheduled sum log2(1+SINR)." ...
    ];

summary = cf_export_sensitivity_results(rawTable,parameterSettings,specs,resultsDir,runInfo);
cf_plot_local_sensitivity(summary,resultsDir);

fprintf('\nFinished local sensitivity test.\n');
fprintf('Main workbook: %s\n',fullfile(resultsDir,'local_sensitivity_all_results.xlsx'));
fprintf('Text report:   %s\n',fullfile(resultsDir,'local_sensitivity_report.txt'));

function cfg = prepareSeed(cfg,seed)
cfg.seedPosition = 1000 + seed;
cfg.seedChannel = 2000 + seed;
cfg.seedSearch = 3000 + seed;
cfg.search.verbose = false;
end

function [cfg,candidate] = applySensitivityValue(cfg,candidate,spec,value)
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
