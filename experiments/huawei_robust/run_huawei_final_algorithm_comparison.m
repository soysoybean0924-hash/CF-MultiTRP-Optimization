%% Huawei final algorithm comparison.
% Formal Huawei-style validation entry with full algorithm, robust, and
% edge-aware switches. The default scale is the full Huawei profile; use
% HUAWEI_FINAL_SCALE=probe|medium|full_lite for fast validation.
clear; clc; close all;

scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptFolder));
run(fullfile(projectRoot,'setup_project_paths.m'));

runId = getenvOrDefault('HUAWEI_FINAL_RUN_ID', ...
    ['final_' char(datetime('now','Format','yyyyMMdd_HHmmss'))]);
resultRoot = fullfile(projectRoot,'results','huawei_robust',runId);
if ~exist(resultRoot,'dir'), mkdir(resultRoot); end

scaleName = lower(getenvOrDefault('HUAWEI_FINAL_SCALE','final'));
methods = parseList(getenvOrDefault('HUAWEI_FINAL_METHODS', ...
    'basic,inner,GA,PSO,GA+PSO,PSO+GA,PGSAO'));
robustProfiles = parseList(getenvOrDefault('HUAWEI_FINAL_ROBUST_PROFILES', ...
    'nonrobust,robust'));
edgeProfiles = parseList(getenvOrDefault('HUAWEI_FINAL_EDGE_PROFILES', ...
    'edge_aware,non_edge_aware'));

cfgBase = makeFinalConfig(scaleName);
saveHeavyMat = logical(numericEnvOrDefault('HUAWEI_FINAL_SAVE_MAT', ...
    double(~strcmp(scaleName,'final'))));
scenarioCache = containers.Map('KeyType','char','ValueType','any');

runInfo = struct();
runInfo.CreatedAt = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
runInfo.RunId = runId;
runInfo.Scale = scaleName;
runInfo.Methods = methods;
runInfo.RobustProfiles = robustProfiles;
runInfo.EdgeProfiles = edgeProfiles;
runInfo.ResultRoot = resultRoot;
runInfo.Objective = 'scheduler optimizes H_est; acceptance metrics use H_true when available';
runInfo.Config = cfgBase;
runInfo.SaveHeavyMat = saveHeavyMat;

rows = {};
for ei = 1:numel(edgeProfiles)
    edgeProfile = edgeProfiles{ei};
    cfgEdge = applyEdgeProfile(cfgBase,edgeProfile);
    scenarioKey = 'shared_channel';
    if isKey(scenarioCache,scenarioKey)
        scenario = scenarioCache(scenarioKey);
    else
        scenario = cf_generate_scenario(cfgEdge);
        scenarioCache(scenarioKey) = scenario;
        if saveHeavyMat
            save(fullfile(resultRoot,['scenario_' edgeProfile '.mat']), ...
                'cfgEdge','scenario','edgeProfile','-v7.3');
        end
    end

    for ri = 1:numel(robustProfiles)
        robustProfile = robustProfiles{ri};
        cfgRun = applyRobustProfile(cfgEdge,robustProfile);
        for mi = 1:numel(methods)
            method = methods{mi};
            fprintf('[Huawei final] scale=%s edge=%s robust=%s method=%s\n', ...
                scaleName,edgeProfile,robustProfile,method);
            tic;
            [searchResult,result] = runMethod(method,cfgRun,scenario);
            runtimeSeconds = toc;

            methodDir = fullfile(resultRoot,edgeProfile,robustProfile,methodToTag(method));
            if ~exist(methodDir,'dir'), mkdir(methodDir); end
            if saveHeavyMat
                save(fullfile(methodDir,'result.mat'),'cfgRun','scenario','searchResult', ...
                    'result','runtimeSeconds','edgeProfile','robustProfile','runInfo','-v7.3');
            else
                lightResult = makeLightResult(result); %#ok<NASGU>
                lightSearchResult = makeLightSearchResult(searchResult); %#ok<NASGU>
                save(fullfile(methodDir,'result_light.mat'),'cfgRun','lightSearchResult', ...
                    'lightResult','runtimeSeconds','edgeProfile','robustProfile','runInfo','-v7.3');
            end
            writetable(searchResult.History,fullfile(methodDir,'search_history.csv'));
            writeCandidateTable(searchResult.BestCandidate,fullfile(methodDir,'best_candidate.csv'));
            writeMetricsTable(result,fullfile(methodDir,'best_result_metrics.csv'));
            writeExperienceCdf(result,fullfile(methodDir,'experience_cdf.csv'));

            rows{end+1,1} = makeRow(scaleName,edgeProfile,robustProfile,method, ...
                cfgRun,searchResult,result,runtimeSeconds); %#ok<SAGROW>
        end
    end
end

summaryTable = struct2table(vertcat(rows{:}));
summaryTable = addAcceptanceDeltas(summaryTable);
complexityTable = makeComplexityTable(summaryTable);

writetable(summaryTable,fullfile(resultRoot,'huawei_final_algorithm_comparison.csv'));
writetable(summaryTable,fullfile(resultRoot,'huawei_final_algorithm_comparison.xlsx'));
writetable(complexityTable,fullfile(resultRoot,'huawei_final_complexity_trend.csv'));
save(fullfile(resultRoot,'huawei_final_algorithm_comparison.mat'), ...
    'summaryTable','complexityTable','runInfo','-v7.3');
plotFinalResults(summaryTable,fullfile(resultRoot,'fig_huawei_final_algorithm_comparison.png'));
plotComplexity(complexityTable,fullfile(resultRoot,'fig_huawei_final_complexity_trend.png'));
writeFinalReport(summaryTable,complexityTable,runInfo, ...
    fullfile(resultRoot,'Huawei_final_algorithm_comparison.md'));

fprintf('\nFinished Huawei final algorithm comparison.\n');
fprintf('Result folder: %s\n',resultRoot);
fprintf('Summary CSV:   %s\n',fullfile(resultRoot,'huawei_final_algorithm_comparison.csv'));
fprintf('Report:        %s\n',fullfile(resultRoot,'Huawei_final_algorithm_comparison.md'));

function cfg = makeFinalConfig(scaleName)
cfg = cf_default_config('huawei');
switch lower(scaleName)
    case 'probe'
        cfg.numUEs = 21; cfg.numRBGs = 4; cfg.numTxAntennas = 8; cfg.numRxAntennas = 2;
        cfg.search.maxEvaluations = 2; cfg.search.populationSize = 2;
    case 'medium'
        cfg.numUEs = 42; cfg.numRBGs = 8; cfg.numTxAntennas = 8; cfg.numRxAntennas = 2;
        cfg.search.maxEvaluations = 2; cfg.search.populationSize = 2;
    case 'full_lite'
        cfg.numUEs = 63; cfg.numRBGs = 12; cfg.numTxAntennas = 12; cfg.numRxAntennas = 2;
        cfg.search.maxEvaluations = 2; cfg.search.populationSize = 2;
    case 'final'
        % Keep cf_default_config('huawei') as the full acceptance scale.
    otherwise
        error('Unknown HUAWEI_FINAL_SCALE: %s',scaleName);
end
cfg = applyEnvOverrides(cfg);
cfg.maxRank = min(cfg.maxRank,cfg.numRxAntennas);
cfg.search.populationSize = min(cfg.search.populationSize,cfg.search.maxEvaluations);
cfg.search.eliteCount = min(cfg.search.eliteCount,max(0,cfg.search.populationSize-1));
cfg.search.numConnectionsRange = [1 min(4,cfg.numDUs)];
cfg.search.maxRepairLinksRange = [0 min(4,cfg.numDUs*cfg.numRBGs)];
cfg.traffic.numSamples = cfg.numRBGs;
cfg.traffic.meanBurstTti = max(2,round(0.5*cfg.numRBGs));
cfg.traffic.maxBurstTti = max(cfg.traffic.minBurstTti,cfg.numRBGs);
cfg.search.verbose = logical(numericEnvOrDefault('HUAWEI_FINAL_VERBOSE',0));
end

function cfg = applyEnvOverrides(cfg)
cfg.numUEs = numericEnvOrDefault('HUAWEI_FINAL_NUM_UES',cfg.numUEs);
cfg.numRBGs = numericEnvOrDefault('HUAWEI_FINAL_NUM_RBGS',cfg.numRBGs);
cfg.numTxAntennas = numericEnvOrDefault('HUAWEI_FINAL_NUM_TX',cfg.numTxAntennas);
cfg.numRxAntennas = numericEnvOrDefault('HUAWEI_FINAL_NUM_RX',cfg.numRxAntennas);
cfg.maxRank = numericEnvOrDefault('HUAWEI_FINAL_MAX_RANK',cfg.maxRank);
cfg.inner.maxIter = numericEnvOrDefault('HUAWEI_FINAL_INNER_ITER',cfg.inner.maxIter);
cfg.search.maxEvaluations = numericEnvOrDefault('HUAWEI_FINAL_MAX_EVAL',cfg.search.maxEvaluations);
cfg.search.populationSize = numericEnvOrDefault('HUAWEI_FINAL_POPULATION',cfg.search.populationSize);
end

function cfg = applyEdgeProfile(cfg,profile)
switch lower(profile)
    case 'edge_aware'
        cfg.edge.enabled = true;
    case 'non_edge_aware'
        cfg.edge.enabled = false;
    otherwise
        error('Unknown edge profile: %s',profile);
end
end

function cfg = applyRobustProfile(cfg,profile)
switch lower(profile)
    case 'nonrobust'
        cfg.robust.enabled = false;
    case {'robust','default'}
        cfg.robust.enabled = true;
    case 'soft'
        cfg.robust.enabled = true;
        cfg.robust.uncertaintyPenalty = 1.25;
        cfg.robust.channelShrinkage = 0.45;
        cfg.robust.unmeasuredPenalty = 0.50;
        cfg.robust.minimumChannelScale = 0.50;
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

function row = makeRow(scaleName,edgeProfile,robustProfile,method,cfg,searchResult,result,runtimeSeconds)
row = struct();
row.Scale = {scaleName};
row.EdgeProfile = {edgeProfile};
row.RobustProfile = {robustProfile};
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
row.PopulationSize = cfg.search.populationSize;
row.MaxEvaluations = cfg.search.maxEvaluations;
row.Evaluations = searchResult.Evaluations;
row.RuntimeSeconds = runtimeSeconds;
row.EstimatedObjective = result.Objective;
row.EstimatedScore = result.Score;
row.EstimatedMeanExperienceRate = result.ExperienceRate.MeanExperienceRate;
row.EstimatedEdgeExperienceRate5 = result.ExperienceRate.EdgeExperienceRate5;
row.TrueObjective = trueField(result,'SumRate');
row.TrueMeanExperienceRate = trueExperienceField(result,'MeanExperienceRate');
row.TrueEdgeExperienceRate5 = trueExperienceField(result,'EdgeExperienceRate5');
row.TrueMinExperienceRate = trueExperienceField(result,'MinExperienceRate');
row.TrueRate5 = trueField(result,'Rate5');
row.TrueRate10 = trueField(result,'Rate10');
row.TrueJain = trueField(result,'Jain');
row.TotalPower = result.TotalPower;
row.ActiveLinks = result.ActiveLinks;
row.ActiveStreams = result.ActiveStreams;
row.RuntimePerEvaluation = runtimeSeconds/max(1,searchResult.Evaluations);
row.LinkScale = cfg.numDUs * cfg.numUEs * cfg.numRBGs;
row.AntennaLinkScale = cfg.numDUs * cfg.numUEs * cfg.numRBGs * cfg.numTxAntennas;
row.NumEdgeUsers = edgeField(result,'NumEdgeUsers');
row.EdgeUserRatio = edgeField(result,'EdgeUserRatio');
row.MeanEdgeExperienceRate = edgeField(result,'MeanEdgeExperienceRate');
row.MeanNonEdgeExperienceRate = edgeField(result,'MeanNonEdgeExperienceRate');
row.ActiveEdgeLinks = edgeField(result,'ActiveEdgeLinks');
row.ActiveNonEdgeLinks = edgeField(result,'ActiveNonEdgeLinks');
row.RobustEnabled = result.Robust.Enabled;
row.MeanErrorVariance = result.Robust.MeanErrorVariance;
row.MeasuredFraction = result.Robust.MeasuredFraction;
end

function value = trueField(result,name)
if isfield(result,'TrueChannel') && result.TrueChannel.Available && isfield(result.TrueChannel,name)
    value = result.TrueChannel.(name);
else
    value = NaN;
end
end

function value = trueExperienceField(result,name)
if isfield(result,'TrueChannel') && result.TrueChannel.Available && ...
        isfield(result.TrueChannel,'ExperienceRate') && isfield(result.TrueChannel.ExperienceRate,name)
    value = result.TrueChannel.ExperienceRate.(name);
else
    value = NaN;
end
end

function value = edgeField(result,name)
if isfield(result,'Edge') && isfield(result.Edge,name)
    value = result.Edge.(name);
else
    value = NaN;
end
end

function t = addAcceptanceDeltas(t)
t.ReferenceLabel = strings(height(t),1);
t.MeanExperienceLossPct = nan(height(t),1);
t.EdgeExperienceRatioToReference = nan(height(t),1);
t.PowerReductionPct = nan(height(t),1);
for i = 1:height(t)
    same = strcmp(t.EdgeProfile,t.EdgeProfile{i}) & strcmp(t.RobustProfile,t.RobustProfile{i});
    ref = same & strcmpi(t.Method,'inner');
    if ~any(ref), ref = same & strcmpi(t.Method,'basic'); end
    refIdx = find(ref,1,'first');
    if isempty(refIdx), continue; end
    t.ReferenceLabel(i) = string(sprintf('%s/%s/%s', ...
        t.EdgeProfile{refIdx},t.RobustProfile{refIdx},t.Method{refIdx}));
    refMean = t.TrueMeanExperienceRate(refIdx);
    refEdge = t.TrueEdgeExperienceRate5(refIdx);
    refPower = t.TotalPower(refIdx);
    t.MeanExperienceLossPct(i) = 100*(refMean - t.TrueMeanExperienceRate(i))/max(abs(refMean),eps);
    t.EdgeExperienceRatioToReference(i) = t.TrueEdgeExperienceRate5(i)/max(abs(refEdge),eps);
    t.PowerReductionPct(i) = 100*(refPower - t.TotalPower(i))/max(abs(refPower),eps);
end
end

function complexityTable = makeComplexityTable(t)
groups = unique(strcat(t.EdgeProfile,"/",t.RobustProfile,"/",t.Method),'stable');
rows = cell(numel(groups),1);
for gi = 1:numel(groups)
    mask = strcmp(strcat(t.EdgeProfile,"/",t.RobustProfile,"/",t.Method),groups(gi));
    sub = t(mask,:);
    x = double(sub.AntennaLinkScale);
    y = double(sub.RuntimePerEvaluation);
    row = struct();
    row.Group = char(groups(gi));
    row.NumPoints = height(sub);
    row.MinScale = min(x);
    row.MaxScale = max(x);
    row.MeanRuntimePerEvaluation = mean(y);
    if height(sub) >= 2 && numel(unique(x)) >= 2
        p = polyfit(x,y,1);
        yhat = polyval(p,x);
        row.LinearSlope = p(1);
        row.LinearIntercept = p(2);
        row.LinearR2 = 1 - sum((y-yhat).^2)/max(sum((y-mean(y)).^2),eps);
    else
        row.LinearSlope = NaN;
        row.LinearIntercept = NaN;
        row.LinearR2 = NaN;
    end
    rows{gi} = row;
end
complexityTable = struct2table(vertcat(rows{:}));
end

function writeCandidateTable(candidate,outFile)
names = fieldnames(candidate);
rows = cell(numel(names),2);
for i = 1:numel(names)
    value = candidate.(names{i});
    rows{i,1} = names{i};
    if isnumeric(value)
        rows{i,2} = mat2str(value,8);
    else
        rows{i,2} = char(string(value));
    end
end
writetable(cell2table(rows,'VariableNames',{'Parameter','Value'}),outFile);
end

function writeMetricsTable(result,outFile)
metric = {'EstimatedObjective';'EstimatedScore';'TrueObjective';'TrueMeanExperienceRate'; ...
    'TrueEdgeExperienceRate5';'TotalPower';'ActiveLinks';'TrueJain'};
value = [result.Objective; result.Score; trueField(result,'SumRate'); ...
    trueExperienceField(result,'MeanExperienceRate'); ...
    trueExperienceField(result,'EdgeExperienceRate5'); result.TotalPower; ...
    result.ActiveLinks; trueField(result,'Jain')];
writetable(table(metric,value),outFile);
end

function writeExperienceCdf(result,outFile)
if isfield(result,'TrueChannel') && result.TrueChannel.Available
    expRate = result.TrueChannel.ExperienceRate;
else
    expRate = result.ExperienceRate;
end
Rate = expRate.CdfRate(:); %#ok<NASGU>
Probability = expRate.CdfProbability(:); %#ok<NASGU>
writetable(table(Rate,Probability),outFile);
end

function plotFinalResults(t,outFile)
fig = figure('Visible','off','Color','w','Position',[100 100 1320 820]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
plotGrouped(nexttile(layout),t,'TrueObjective','True objective');
plotGrouped(nexttile(layout),t,'TrueEdgeExperienceRate5','True edge p5');
plotGrouped(nexttile(layout),t,'TotalPower','Total power');
plotGrouped(nexttile(layout),t,'RuntimePerEvaluation','Runtime / eval');
title(layout,'Huawei final algorithm comparison','Interpreter','none');
exportgraphics(fig,outFile,'Resolution',180);
close(fig);
end

function plotGrouped(ax,t,fieldName,yLabelText)
labels = categorical(strcat(t.Method," / ",t.EdgeProfile," / ",t.RobustProfile));
bar(ax,labels,t.(fieldName));
grid(ax,'on'); xtickangle(ax,35); ylabel(ax,yLabelText);
end

function plotComplexity(t,outFile)
fig = figure('Visible','off','Color','w','Position',[100 100 1050 620]);
bar(categorical(t.Group),t.MeanRuntimePerEvaluation);
grid on; xtickangle(35);
ylabel('Mean runtime per evaluation');
title('Huawei final complexity trend by method group','Interpreter','none');
exportgraphics(fig,outFile,'Resolution',180);
close(fig);
end

function lightResult = makeLightResult(result)
lightResult = struct();
fields = {'Candidate','Objective','Score','ScoreParts','SumRate','MeanRate','MinRate', ...
    'Rate5','Rate10','Jain','ActiveLinks','TotalPower','ActiveStreams', ...
    'ExperienceRate','Robust','Edge','TrueChannel','history'};
for i = 1:numel(fields)
    name = fields{i};
    if isfield(result,name)
        lightResult.(name) = result.(name);
    end
end
if isfield(lightResult,'TrueChannel')
    lightResult.TrueChannel = trimTrueChannel(lightResult.TrueChannel);
end
end

function trueChannel = trimTrueChannel(trueChannel)
heavyFields = {'SLINR','ratePerStream','userRate'};
for i = 1:numel(heavyFields)
    if isfield(trueChannel,heavyFields{i})
        trueChannel = rmfield(trueChannel,heavyFields{i});
    end
end
end

function lightSearchResult = makeLightSearchResult(searchResult)
lightSearchResult = struct();
fields = {'Method','BestX','BestReducedX','ActiveDimensions','FixedX', ...
    'BestCandidate','BestScore','BestObjective','ObjectiveName','Evaluations', ...
    'History','EvaluationX','EvaluationScore','EvaluationObjective','FinalObjectives','FinalScores'};
for i = 1:numel(fields)
    name = fields{i};
    if isfield(searchResult,name)
        lightSearchResult.(name) = searchResult.(name);
    end
end
end

function writeFinalReport(t,complexityTable,runInfo,outFile)
fid = fopen(outFile,'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'# Huawei Final Algorithm Comparison\n\n');
fprintf(fid,'Created: %s\n\n',runInfo.CreatedAt);
fprintf(fid,'Scale: `%s`.\n\n',runInfo.Scale);
fprintf(fid,'Objective: %s.\n\n',runInfo.Objective);
fprintf(fid,'| Edge | Robust | Method | EstObj | Score | TrueObj | TrueMeanExp | TrueEdgeP5 | Power | Links | Runtime | MeanLoss%% | PowerDrop%% |\n');
fprintf(fid,'|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(t)
    fprintf(fid,'| %s | %s | %s | %.6g | %.6g | %.6g | %.6g | %.6g | %.6g | %d | %.3f | %.3f | %.3f |\n', ...
        t.EdgeProfile{i},t.RobustProfile{i},t.Method{i},t.EstimatedObjective(i), ...
        t.EstimatedScore(i),t.TrueObjective(i),t.TrueMeanExperienceRate(i), ...
        t.TrueEdgeExperienceRate5(i), ...
        t.TotalPower(i),t.ActiveLinks(i),t.RuntimeSeconds(i), ...
        t.MeanExperienceLossPct(i),t.PowerReductionPct(i));
end
fprintf(fid,'\n## Acceptance Notes\n\n');
fprintf(fid,'- `TrueEdgeExperienceRate5` is the Bottom 5%% UE experience-rate point on H_true.\n');
fprintf(fid,'- `MeanExperienceLossPct` and `PowerReductionPct` are relative to the matching edge/robust `inner` baseline when present.\n');
fprintf(fid,'- `huawei_final_complexity_trend.csv` records runtime-per-evaluation versus DU x UE x RBG x Tx scale.\n\n');
fprintf(fid,'## Complexity Summary\n\n');
fprintf(fid,'| Group | Points | MeanRuntimePerEval | LinearSlope | LinearR2 |\n');
fprintf(fid,'|---|---:|---:|---:|---:|\n');
for i = 1:height(complexityTable)
    fprintf(fid,'| %s | %d | %.6g | %.6g | %.4f |\n', ...
        complexityTable.Group{i},complexityTable.NumPoints(i), ...
        complexityTable.MeanRuntimePerEvaluation(i),complexityTable.LinearSlope(i), ...
        complexityTable.LinearR2(i));
end
end

function tag = methodToTag(method)
tag = lower(strrep(method,'+','_'));
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
