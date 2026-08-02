%% Huawei robust vs nonrobust comparison.
% Probe-scale validation for SRS nonideal measurement and robust weights.
clear; clc; close all;

scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptFolder));
run(fullfile(projectRoot,'setup_project_paths.m'));

runId = getenvOrDefault('HUAWEI_ROBUST_RUN_ID', ...
    ['run_' char(datetime('now','Format','yyyyMMdd_HHmmss'))]);
resultRoot = fullfile(projectRoot,'results','huawei_robust',runId);
if ~exist(resultRoot,'dir'), mkdir(resultRoot); end

methods = parseList(getenvOrDefault('HUAWEI_ROBUST_METHODS','basic,inner,PSO+GA'));
cfgBase = makeProbeConfig();
scenario = cf_generate_scenario(cfgBase);
save(fullfile(resultRoot,'scenario.mat'),'cfgBase','scenario','-v7.3');

rows = {};
for robustFlag = [false true]
    cfgRun = cfgBase;
    cfgRun.robust.enabled = robustFlag;
    variant = variantName(robustFlag);
    for mi = 1:numel(methods)
        method = methods{mi};
        fprintf('[Huawei robust] variant=%s method=%s\n',variant,method);
        tic;
        [searchResult,result] = runMethod(method,cfgRun,scenario);
        runtimeSeconds = toc;
        methodDir = fullfile(resultRoot,variant,methodToTag(method));
        if ~exist(methodDir,'dir'), mkdir(methodDir); end
        save(fullfile(methodDir,'result.mat'),'cfgRun','scenario','searchResult','result', ...
            'runtimeSeconds','-v7.3');
        writetable(searchResult.History,fullfile(methodDir,'search_history.csv'));
        rows{end+1,1} = makeRow(variant,method,cfgRun,searchResult,result,runtimeSeconds); %#ok<SAGROW>
    end
end

summaryTable = struct2table(vertcat(rows{:}));
writetable(summaryTable,fullfile(resultRoot,'robust_comparison.csv'));
writetable(summaryTable,fullfile(resultRoot,'robust_comparison.xlsx'));
save(fullfile(resultRoot,'robust_comparison.mat'),'summaryTable','cfgBase','methods','-v7.3');
plotResults(summaryTable,fullfile(resultRoot,'fig_huawei_robust_comparison.png'));
writeExplanation(summaryTable,cfgBase,fullfile(resultRoot,'Huawei_robust_explanation.md'));

fprintf('\nFinished Huawei robust comparison.\n');
fprintf('Result folder: %s\n',resultRoot);

function cfg = makeProbeConfig()
cfg = cf_default_config('huawei');
cfg.numUEs = numericEnvOrDefault('HUAWEI_ROBUST_NUM_UES',21);
cfg.numRBGs = numericEnvOrDefault('HUAWEI_ROBUST_NUM_RBGS',4);
cfg.numTxAntennas = numericEnvOrDefault('HUAWEI_ROBUST_NUM_TX',8);
cfg.numRxAntennas = numericEnvOrDefault('HUAWEI_ROBUST_NUM_RX',2);
cfg.maxRank = min(cfg.maxRank,cfg.numRxAntennas);
cfg.inner.maxIter = numericEnvOrDefault('HUAWEI_ROBUST_INNER_ITER',1);
cfg.search.maxEvaluations = numericEnvOrDefault('HUAWEI_ROBUST_MAX_EVAL',2);
cfg.search.populationSize = min(numericEnvOrDefault('HUAWEI_ROBUST_POPULATION',2), ...
    cfg.search.maxEvaluations);
cfg.search.eliteCount = min(cfg.search.eliteCount,max(0,cfg.search.populationSize-1));
cfg.search.verbose = false;
cfg.traffic.numSamples = cfg.numRBGs;
cfg.traffic.meanBurstTti = max(2,round(0.5*cfg.numRBGs));
cfg.traffic.maxBurstTti = max(cfg.traffic.minBurstTti,cfg.numRBGs);
cfg.search.numConnectionsRange = [1 min(4,cfg.numDUs)];
cfg.search.maxRepairLinksRange = [0 min(4,cfg.numDUs*cfg.numRBGs)];
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
searchResult.BestObjective = result.Score;
searchResult.ObjectiveName = 'J_true_estimated_channel';
searchResult.Evaluations = 1;
searchResult.History = table(1,result.Score,result.Score, ...
    'VariableNames',{'Evaluation','Objective','BestObjective'});
searchResult.EvaluationX = bestX;
searchResult.EvaluationScore = result.Score;
searchResult.EvaluationObjective = result.Score;
searchResult.FinalPopulation = bestX;
searchResult.FinalScores = result.Score;
end

function row = makeRow(variant,method,cfg,searchResult,result,runtimeSeconds)
row = struct();
row.Variant = {variant};
row.Method = {method};
row.NumDUs = cfg.numDUs;
row.NumUEs = cfg.numUEs;
row.NumRBGs = cfg.numRBGs;
row.NumTxAntennas = cfg.numTxAntennas;
row.NumRxAntennas = cfg.numRxAntennas;
row.InnerMaxIter = cfg.inner.maxIter;
row.Evaluations = searchResult.Evaluations;
row.RuntimeSeconds = runtimeSeconds;
row.EstimatedObjective = result.Score;
row.EstimatedEdgeExperienceRate5 = result.ExperienceRate.EdgeExperienceRate5;
row.EstimatedMeanExperienceRate = result.ExperienceRate.MeanExperienceRate;
row.TrueObjective = trueField(result,'SumRate');
row.TrueEdgeExperienceRate5 = trueExperienceField(result,'EdgeExperienceRate5');
row.TrueMeanExperienceRate = trueExperienceField(result,'MeanExperienceRate');
row.Jain = result.Jain;
row.ActiveLinks = result.ActiveLinks;
row.TotalPower = result.TotalPower;
row.RobustEnabled = result.Robust.Enabled;
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

function plotResults(summaryTable,outFile)
fig = figure('Visible','off','Color','w','Position',[100 100 1250 760]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
plotGrouped(nexttile(layout),summaryTable,'TrueObjective','True-channel objective');
plotGrouped(nexttile(layout),summaryTable,'TrueEdgeExperienceRate5','True edge experience p5');
plotGrouped(nexttile(layout),summaryTable,'TotalPower','Total power');
plotGrouped(nexttile(layout),summaryTable,'ActiveLinks','Active links');
title(layout,'Huawei probe robust vs nonrobust comparison','Interpreter','none');
exportgraphics(fig,outFile,'Resolution',180);
close(fig);
end

function plotGrouped(ax,t,fieldName,yLabelText)
labels = categorical(strcat(t.Method," / ",t.Variant));
bar(ax,labels,t.(fieldName));
grid(ax,'on'); xtickangle(ax,35); ylabel(ax,yLabelText);
end

function writeExplanation(t,cfg,outFile)
fid = fopen(outFile,'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'# Huawei Robust SRS Comparison\n\n');
fprintf(fid,'Probe scale: DUs=%d, UEs=%d, RBGs=%d, MIMO=%dx%d.\n\n', ...
    cfg.numDUs,cfg.numUEs,cfg.numRBGs,cfg.numTxAntennas,cfg.numRxAntennas);
fprintf(fid,'The scheduler uses `H_est`; robust validation is judged on `H_true` columns.\n\n');
fprintf(fid,'| Variant | Method | EstObj | TrueObj | TrueEdgeP5 | TotalPower | ActiveLinks | Runtime |\n');
fprintf(fid,'|---|---|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(t)
    fprintf(fid,'| %s | %s | %.6g | %.6g | %.6g | %.6g | %d | %.3f |\n', ...
        t.Variant{i},t.Method{i},t.EstimatedObjective(i),t.TrueObjective(i), ...
        t.TrueEdgeExperienceRate5(i),t.TotalPower(i),t.ActiveLinks(i),t.RuntimeSeconds(i));
end
fprintf(fid,'\n## Interpretation\n\n');
fprintf(fid,'- `nonrobust` uses the same SRS-estimated channel without uncertainty-aware penalties.\n');
fprintf(fid,'- `robust` applies uncertainty shrinkage and extra penalty on high-error or unmeasured SRS links.\n');
fprintf(fid,'- This is a Huawei probe, not the final full-scale validation run.\n');
end

function tag = methodToTag(method)
tag = lower(strrep(method,'+','_'));
end

function variant = variantName(flag)
if flag, variant = 'robust'; else, variant = 'nonrobust'; end
end

function list = parseList(raw)
parts = strsplit(char(raw),',');
list = {};
for i = 1:numel(parts)
    item = strtrim(parts{i});
    if ~isempty(item), list{end+1} = item; end %#ok<AGROW>
end
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
