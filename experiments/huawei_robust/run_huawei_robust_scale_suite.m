%% Huawei robust scale suite: probe, medium, and full-lite.
% Runs staged validation for logic check, robust-parameter tuning, and a
% closer-to-Huawei low-budget confirmation.
clear; clc; close all;

scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptFolder));
run(fullfile(projectRoot,'setup_project_paths.m'));

runId = getenvOrDefault('HUAWEI_ROBUST_SUITE_RUN_ID', ...
    ['suite_' char(datetime('now','Format','yyyyMMdd_HHmmss'))]);
resultRoot = fullfile(projectRoot,'results','huawei_robust',runId);
if ~exist(resultRoot,'dir'), mkdir(resultRoot); end

scales = buildScaleSpecs();
allRows = {};
bestMediumProfile = 'default';
for si = 1:numel(scales)
    spec = scales(si);
    if strcmp(spec.Name,'full_lite')
        spec.RobustProfiles = {'nonrobust',bestMediumProfile};
    end
    scaleDir = fullfile(resultRoot,spec.Name);
    if ~exist(scaleDir,'dir'), mkdir(scaleDir); end

    cfgBase = makeScaleConfig(spec);
    scenario = cf_generate_scenario(cfgBase);
    save(fullfile(scaleDir,'scenario.mat'),'cfgBase','scenario','spec','-v7.3');

    rows = runScale(spec,cfgBase,scenario,scaleDir);
    scaleTable = struct2table(vertcat(rows{:}));
    writetable(scaleTable,fullfile(scaleDir,'robust_comparison.csv'));
    writetable(scaleTable,fullfile(scaleDir,'robust_comparison.xlsx'));
    plotResults(scaleTable,fullfile(scaleDir,'fig_robust_comparison.png'),spec.Name);
    writeScaleExplanation(scaleTable,spec,fullfile(scaleDir,'scale_explanation.md'));
    allRows = [allRows; rows]; %#ok<AGROW>

    if strcmp(spec.Name,'medium')
        bestMediumProfile = selectBestRobustProfile(scaleTable);
    end
end

summaryTable = struct2table(vertcat(allRows{:}));
writetable(summaryTable,fullfile(resultRoot,'suite_robust_comparison.csv'));
writetable(summaryTable,fullfile(resultRoot,'suite_robust_comparison.xlsx'));
save(fullfile(resultRoot,'suite_robust_comparison.mat'),'summaryTable','scales','bestMediumProfile','-v7.3');
plotResults(summaryTable,fullfile(resultRoot,'fig_suite_robust_comparison.png'),'suite');
writeSuiteExplanation(summaryTable,scales,bestMediumProfile, ...
    fullfile(resultRoot,'Huawei_robust_scale_suite_explanation.md'));

fprintf('\nFinished Huawei robust scale suite.\n');
fprintf('Result folder: %s\n',resultRoot);
fprintf('Medium-selected robust profile for full-lite: %s\n',bestMediumProfile);

function scales = buildScaleSpecs()
scales = struct([]);
scales(1).Name = 'probe';
scales(1).NumUEs = 21; scales(1).NumRBGs = 4;
scales(1).NumTxAntennas = 8; scales(1).NumRxAntennas = 2;
scales(1).InnerIter = []; scales(1).MaxEval = 2; scales(1).Population = 2;
scales(1).Methods = {'basic','inner','PSO+GA'};
scales(1).RobustProfiles = {'nonrobust','default'};
scales(1).Purpose = 'logic validation';

scales(2).Name = 'medium';
scales(2).NumUEs = 42; scales(2).NumRBGs = 8;
scales(2).NumTxAntennas = 8; scales(2).NumRxAntennas = 2;
scales(2).InnerIter = []; scales(2).MaxEval = 2; scales(2).Population = 2;
scales(2).Methods = {'basic','inner','PSO+GA','PGSAO'};
scales(2).RobustProfiles = {'nonrobust','soft','default','aggressive'};
scales(2).Purpose = 'robust parameter tuning and algorithm screening';

scales(3).Name = 'full_lite';
scales(3).NumUEs = 63; scales(3).NumRBGs = 12;
scales(3).NumTxAntennas = 12; scales(3).NumRxAntennas = 2;
scales(3).InnerIter = []; scales(3).MaxEval = 2; scales(3).Population = 2;
scales(3).Methods = {'basic','inner','PSO+GA','PGSAO'};
scales(3).RobustProfiles = {'nonrobust','default'};
scales(3).Purpose = 'closer-to-Huawei low-budget confirmation';
end

function cfg = makeScaleConfig(spec)
cfg = cf_default_config('huawei');
cfg.numUEs = numericEnvOrDefault(['HUAWEI_' upper(spec.Name) '_NUM_UES'],spec.NumUEs);
cfg.numRBGs = numericEnvOrDefault(['HUAWEI_' upper(spec.Name) '_NUM_RBGS'],spec.NumRBGs);
cfg.numTxAntennas = numericEnvOrDefault(['HUAWEI_' upper(spec.Name) '_NUM_TX'],spec.NumTxAntennas);
cfg.numRxAntennas = numericEnvOrDefault(['HUAWEI_' upper(spec.Name) '_NUM_RX'],spec.NumRxAntennas);
cfg.maxRank = min(cfg.maxRank,cfg.numRxAntennas);
cfg.inner.maxIter = numericEnvOrDefault(['HUAWEI_' upper(spec.Name) '_INNER_ITER'],cfg.inner.maxIter);
cfg.search.maxEvaluations = numericEnvOrDefault(['HUAWEI_' upper(spec.Name) '_MAX_EVAL'],spec.MaxEval);
cfg.search.populationSize = min(numericEnvOrDefault(['HUAWEI_' upper(spec.Name) '_POPULATION'],spec.Population), ...
    cfg.search.maxEvaluations);
cfg.search.eliteCount = min(cfg.search.eliteCount,max(0,cfg.search.populationSize-1));
cfg.search.verbose = false;
cfg.traffic.numSamples = cfg.numRBGs;
cfg.traffic.meanBurstTti = max(2,round(0.5*cfg.numRBGs));
cfg.traffic.maxBurstTti = max(cfg.traffic.minBurstTti,cfg.numRBGs);
cfg.search.numConnectionsRange = [1 min(4,cfg.numDUs)];
cfg.search.maxRepairLinksRange = [0 min(4,cfg.numDUs*cfg.numRBGs)];
end

function rows = runScale(spec,cfgBase,scenario,scaleDir)
rows = {};
for vi = 1:numel(spec.RobustProfiles)
    profile = spec.RobustProfiles{vi};
    cfgRun = applyRobustProfile(cfgBase,profile);
    for mi = 1:numel(spec.Methods)
        method = spec.Methods{mi};
        fprintf('[Huawei suite] scale=%s robust=%s method=%s\n',spec.Name,profile,method);
        tic;
        [searchResult,result] = runMethod(method,cfgRun,scenario);
        runtimeSeconds = toc;
        methodDir = fullfile(scaleDir,profile,methodToTag(method));
        if ~exist(methodDir,'dir'), mkdir(methodDir); end
        save(fullfile(methodDir,'result.mat'),'cfgRun','scenario','searchResult','result', ...
            'runtimeSeconds','spec','profile','-v7.3');
        writetable(searchResult.History,fullfile(methodDir,'search_history.csv'));
        rows{end+1,1} = makeRow(spec.Name,profile,method,cfgRun,searchResult,result,runtimeSeconds); %#ok<AGROW>
    end
end
end

function cfg = applyRobustProfile(cfg,profile)
switch lower(profile)
    case 'nonrobust'
        cfg.robust.enabled = false;
    case 'soft'
        cfg.robust.enabled = true;
        cfg.robust.uncertaintyPenalty = 1.25;
        cfg.robust.channelShrinkage = 0.45;
        cfg.robust.unmeasuredPenalty = 0.50;
        cfg.robust.minimumChannelScale = 0.50;
    case 'default'
        cfg.robust.enabled = true;
    case 'aggressive'
        cfg.robust.enabled = true;
        cfg.robust.uncertaintyPenalty = 4.00;
        cfg.robust.channelShrinkage = 0.90;
        cfg.robust.unmeasuredPenalty = 1.50;
        cfg.robust.minimumChannelScale = 0.25;
    otherwise
        error('Unknown robust profile: %s',profile);
end
end

function [searchResult,result] = runMethod(method,cfg,scenario)
methodKey = upper(strrep(char(method),' ',''));
candidate = cf_decode_candidate(cfg.defaultX,cfg);
switch methodKey
    case 'BASIC'
        result = cf_evaluate_candidate(cfg,scenario,candidate,false);
        searchResult = singleEvaluationResult(methodKey,cfg.defaultX,candidate,result);
    case 'INNER'
        result = cf_evaluate_candidate(cfg,scenario,candidate,true);
        searchResult = singleEvaluationResult(methodKey,cfg.defaultX,candidate,result);
    otherwise
        searchResult = cf_search(method,cfg,scenario,cfg.search);
        result = searchResult.BestResult;
end
end

function searchResult = singleEvaluationResult(method,bestX,candidate,result)
searchResult = struct();
searchResult.Method = method;
searchResult.BestX = bestX;
searchResult.BestReducedX = bestX;
searchResult.ActiveDimensions = 1:numel(bestX);
searchResult.FixedX = bestX;
searchResult.BestCandidate = candidate;
searchResult.BestResult = result;
searchResult.BestScore = result.Score;
searchResult.BestObjective = result.Objective;
searchResult.ObjectiveName = 'J_true_estimated_channel';
searchResult.Evaluations = 1;
searchResult.History = table(1,result.Objective,result.Score,result.Objective,result.Score, ...
    'VariableNames',{'Evaluation','Objective','Score','BestObjective','BestScore'});
searchResult.EvaluationX = bestX;
searchResult.EvaluationScore = result.Score;
searchResult.EvaluationObjective = result.Objective;
searchResult.FinalPopulation = bestX;
searchResult.FinalObjectives = result.Objective;
searchResult.FinalScores = result.Score;
end

function row = makeRow(scaleName,profile,method,cfg,searchResult,result,runtimeSeconds)
row = struct();
row.Scale = {scaleName};
row.RobustProfile = {profile};
row.Method = {method};
row.NumDUs = cfg.numDUs;
row.NumUEs = cfg.numUEs;
row.NumRBGs = cfg.numRBGs;
row.NumTxAntennas = cfg.numTxAntennas;
row.NumRxAntennas = cfg.numRxAntennas;
row.InnerMaxIter = cfg.inner.maxIter;
row.InnerIterations = result.history.iterations;
row.InnerConverged = result.history.converged;
row.InnerStopReason = {result.history.stopReason};
row.Evaluations = searchResult.Evaluations;
row.RuntimeSeconds = runtimeSeconds;
row.EstimatedObjective = result.Objective;
row.EstimatedScore = result.Score;
row.TrueObjective = trueField(result,'SumRate');
row.TrueEdgeExperienceRate5 = trueExperienceField(result,'EdgeExperienceRate5');
row.TrueMeanExperienceRate = trueExperienceField(result,'MeanExperienceRate');
row.TotalPower = result.TotalPower;
row.ActiveLinks = result.ActiveLinks;
row.Jain = result.Jain;
row.NumEdgeUsers = result.Edge.NumEdgeUsers;
row.EdgeUserRatio = result.Edge.EdgeUserRatio;
row.MeanEdgeExperienceRate = result.Edge.MeanEdgeExperienceRate;
row.MeanNonEdgeExperienceRate = result.Edge.MeanNonEdgeExperienceRate;
row.ActiveEdgeLinks = result.Edge.ActiveEdgeLinks;
row.ActiveNonEdgeLinks = result.Edge.ActiveNonEdgeLinks;
row.RobustEnabled = result.Robust.Enabled;
row.UncertaintyPenalty = result.Robust.UncertaintyPenalty;
row.ChannelShrinkage = result.Robust.ChannelShrinkage;
row.UnmeasuredPenalty = result.Robust.UnmeasuredPenalty;
row.MeanErrorVariance = result.Robust.MeanErrorVariance;
row.MeasuredFraction = result.Robust.MeasuredFraction;
end

function value = trueField(result,name)
if isfield(result,'TrueChannel') && result.TrueChannel.Available
    value = result.TrueChannel.(name);
else
    value = NaN;
end
end

function value = trueExperienceField(result,name)
if isfield(result,'TrueChannel') && result.TrueChannel.Available
    value = result.TrueChannel.ExperienceRate.(name);
else
    value = NaN;
end
end

function bestProfile = selectBestRobustProfile(t)
robustRows = t(t.RobustEnabled,:);
if isempty(robustRows)
    bestProfile = 'default';
    return;
end
methodScore = robustRows.TrueObjective + 0.1*robustRows.TrueMeanExperienceRate;
[~,idx] = max(methodScore);
bestProfile = robustRows.RobustProfile{idx};
end

function plotResults(summaryTable,outFile,titleText)
fig = figure('Visible','off','Color','w','Position',[100 100 1280 760]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
plotGrouped(nexttile(layout),summaryTable,'TrueObjective','True objective');
plotGrouped(nexttile(layout),summaryTable,'TrueMeanExperienceRate','True mean experience');
plotGrouped(nexttile(layout),summaryTable,'TotalPower','Total power');
plotGrouped(nexttile(layout),summaryTable,'RuntimeSeconds','Runtime seconds');
title(layout,['Huawei robust scale: ' titleText],'Interpreter','none');
exportgraphics(fig,outFile,'Resolution',180);
close(fig);
end

function plotGrouped(ax,t,fieldName,yLabelText)
labels = categorical(strcat(t.Scale," / ",t.Method," / ",t.RobustProfile));
bar(ax,labels,t.(fieldName));
grid(ax,'on'); xtickangle(ax,35); ylabel(ax,yLabelText);
end

function writeScaleExplanation(t,spec,outFile)
fid = fopen(outFile,'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'# Huawei Robust Scale: %s\n\n',spec.Name);
fprintf(fid,'Purpose: %s.\n\n',spec.Purpose);
writeTable(fid,t);
fprintf(fid,'\nBest true objective in this scale: %s / %s / %.6g.\n', ...
    bestMethod(t),bestProfile(t),max(t.TrueObjective));
end

function writeSuiteExplanation(t,scales,bestMediumProfile,outFile)
fid = fopen(outFile,'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'# Huawei Robust Probe-Medium-Full-Lite Suite\n\n');
fprintf(fid,'This suite runs three staged scales before the final full Huawei validation.\n\n');
for i = 1:numel(scales)
    fprintf(fid,'- `%s`: %s.\n',scales(i).Name,scales(i).Purpose);
end
fprintf(fid,'\nMedium-selected robust profile for full-lite: `%s`.\n\n',bestMediumProfile);
writeTable(fid,t);
fprintf(fid,'\n## Judgment\n\n');
fprintf(fid,'- Probe checks logic and output fields.\n');
fprintf(fid,'- Medium compares robust parameters and feasible algorithms.\n');
fprintf(fid,'- Full-lite keeps 21 sectors and larger UE/RBG counts with a low search budget.\n');
fprintf(fid,'- These runs guide final Huawei full-scale settings but do not replace full-scale validation.\n');
end

function writeTable(fid,t)
fprintf(fid,'| Scale | Profile | Method | EstObj | Score | TrueObj | TrueMeanExp | TrueEdgeP5 | Power | Links | Runtime |\n');
fprintf(fid,'|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(t)
    fprintf(fid,'| %s | %s | %s | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %d | %.3f |\n', ...
        t.Scale{i},t.RobustProfile{i},t.Method{i},t.EstimatedObjective(i), ...
        t.EstimatedScore(i),t.TrueObjective(i),t.TrueMeanExperienceRate(i), ...
        t.TrueEdgeExperienceRate5(i), ...
        t.TotalPower(i),t.ActiveLinks(i),t.RuntimeSeconds(i));
end
end

function method = bestMethod(t)
[~,idx] = max(t.TrueObjective);
method = t.Method{idx};
end

function profile = bestProfile(t)
[~,idx] = max(t.TrueObjective);
profile = t.RobustProfile{idx};
end

function tag = methodToTag(method)
tag = lower(strrep(method,'+','_'));
end

function value = getenvOrDefault(name,defaultValue)
value = getenv(name);
if isempty(value), value = defaultValue; end
end

function value = numericEnvOrDefault(name,defaultValue)
raw = getenv(name);
if isempty(raw)
    value = defaultValue;
else
    value = str2double(raw);
    if ~isfinite(value), error('Environment variable %s must be numeric.',name); end
end
end
