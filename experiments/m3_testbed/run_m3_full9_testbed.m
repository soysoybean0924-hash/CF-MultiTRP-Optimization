%% M3 full-scale 9-D testbed.
% Staging workflow for unconfirmed changes: always run the full M3 scale,
% all seven comparison methods, and the complete 9-D search vector.
clear; clc; close all;

scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptFolder));
run(fullfile(projectRoot,'setup_project_paths.m'));

methods = {'basic','inner','GA','PSO','GA+PSO','PSO+GA','PGSAO'};
runId = getenvOrDefault('M3_TESTBED_RUN_ID', ...
    ['run_' char(datetime('now','Format','yyyyMMdd_HHmmss'))]);
resultRoot = fullfile(projectRoot,'results','m3_testbed',runId);
maxEvalCap = numericEnvOrDefault('M3_TESTBED_MAX_EVAL_CAP',16);
populationSize = numericEnvOrDefault('M3_TESTBED_POPULATION_SIZE',8);
innerIterCap = numericEnvOrEmpty('M3_TESTBED_INNER_ITER_CAP');

if ~exist(resultRoot,'dir')
    mkdir(resultRoot);
end

cfg = cf_default_config('m3');
cfg.search.activeDimensions = [];
cfg.search.fixedX = [];
cfg = applyBudgetCaps(cfg,maxEvalCap,populationSize,innerIterCap);
scenario = cf_generate_scenario(cfg);
save(fullfile(resultRoot,'scenario.mat'),'cfg','scenario','-v7.3');

runInfo = struct();
runInfo.createdAt = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
runInfo.runId = runId;
runInfo.resultRoot = resultRoot;
runInfo.methods = methods;
runInfo.objective = 'J_true = scheduled sum log2(1+SINR)';
runInfo.searchSpace = 'full 9-D normalized candidate vector';
runInfo.maxEvalCap = maxEvalCap;
runInfo.populationSize = populationSize;
runInfo.innerIterCap = innerIterCap;
runInfo.defaultCandidateInjected = true;

summaryRows = cell(numel(methods),1);
for mi = 1:numel(methods)
    method = methods{mi};
    methodDir = fullfile(resultRoot,methodToTag(method));
    if ~exist(methodDir,'dir')
        mkdir(methodDir);
    end

    resultFile = fullfile(methodDir,'search_result.mat');
    fprintf('\n[M3 testbed] run=%s method=%s\n',runId,method);
    if exist(resultFile,'file')
        loaded = load(resultFile,'cfg','searchResult','result','comparisonTable', ...
            'Jtrue','trueDetails','runtimeSeconds');
        resultCfg = loaded.cfg;
        searchResult = loaded.searchResult;
        result = loaded.result;
        comparisonTable = loaded.comparisonTable; %#ok<NASGU>
        Jtrue = loaded.Jtrue;
        trueDetails = loaded.trueDetails;
        runtimeSeconds = loaded.runtimeSeconds;
        fprintf('  Existing result loaded: %s\n',resultFile);
    else
        tic;
        searchResult = runMethod(method,cfg,scenario);
        runtimeSeconds = toc;
        result = searchResult.BestResult;
        [Jtrue,trueDetails] = cf_compute_true_objective(result);
        comparisonTable = cf_print_result(result,sprintf('M3 testbed %s',method));
        resultCfg = cfg;

        save(resultFile,'cfg','searchResult','result','comparisonTable', ...
            'Jtrue','trueDetails','runtimeSeconds','runInfo','-v7.3');
        writetable(searchResult.History,fullfile(methodDir,'search_history.csv'));
        writetable(comparisonTable,fullfile(methodDir,'best_result_metrics.csv'));
        writeCandidateTable(searchResult.BestCandidate,fullfile(methodDir,'best_candidate.csv'));
    end

    summaryRows{mi} = makeSummaryRow(method,resultCfg,searchResult,result, ...
        Jtrue,trueDetails,runtimeSeconds);
end

summaryTable = struct2table(vertcat(summaryRows{:}));
writetable(summaryTable,fullfile(resultRoot,'algorithm_comparison.csv'));
writetable(summaryTable,fullfile(resultRoot,'algorithm_comparison.xlsx'));
save(fullfile(resultRoot,'algorithm_comparison.mat'),'summaryTable','runInfo','-v7.3');

plotTestbedResults(summaryTable,fullfile(resultRoot,'fig_m3_full9_testbed_comparison.png'));
writeExplanation(summaryTable,runInfo,fullfile(resultRoot,'M3_testbed_explanation.md'));
writeTextReport(summaryTable,runInfo,fullfile(resultRoot,'M3_testbed_report.txt'));

fprintf('\nFinished M3 full-scale 9-D testbed.\n');
fprintf('Result folder: %s\n',resultRoot);
fprintf('Summary CSV:   %s\n',fullfile(resultRoot,'algorithm_comparison.csv'));
fprintf('Explanation:   %s\n',fullfile(resultRoot,'M3_testbed_explanation.md'));

function searchResult = runMethod(method,cfg,scenario)
methodKey = upper(strrep(char(method),' ',''));
switch methodKey
    case 'BASIC'
        candidate = cf_decode_candidate(cfg.defaultX,cfg);
        result = cf_evaluate_candidate(cfg,scenario,candidate,false);
        searchResult = singleEvaluationResult(methodKey,cfg.defaultX,candidate,result);
    case 'INNER'
        candidate = cf_decode_candidate(cfg.defaultX,cfg);
        result = cf_evaluate_candidate(cfg,scenario,candidate,true);
        searchResult = singleEvaluationResult(methodKey,cfg.defaultX,candidate,result);
    otherwise
        searchResult = m3_testbed_search(method,cfg,scenario,cfg.search);
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
searchResult.ObjectiveName = 'J_true';
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

function cfg = applyBudgetCaps(cfg,maxEvalCap,populationSize,innerIterCap)
cfg.search.maxEvaluations = max(1,round(min(cfg.search.maxEvaluations,maxEvalCap)));
cfg.search.populationSize = max(1,round(min(populationSize,cfg.search.maxEvaluations)));
cfg.search.eliteCount = min(cfg.search.eliteCount,max(0,cfg.search.populationSize-1));
if ~isempty(innerIterCap)
    cfg.inner.maxIter = max(0,round(min(cfg.inner.maxIter,innerIterCap)));
end
end

function row = makeSummaryRow(method,cfg,searchResult,result,Jtrue,trueDetails,runtimeSeconds)
candidate = searchResult.BestCandidate;
row = struct();
row.Method = method;
row.NumDUs = cfg.numDUs;
row.NumUEs = cfg.numUEs;
row.NumRBGs = cfg.numRBGs;
row.NumTxAntennas = cfg.numTxAntennas;
row.NumRxAntennas = cfg.numRxAntennas;
row.SearchDimensions = cfg.search.dimension;
row.InnerMaxIter = cfg.inner.maxIter;
row.InnerIterations = result.history.iterations;
row.InnerConverged = result.history.converged;
row.InnerStopReason = {result.history.stopReason};
row.PopulationSize = cfg.search.populationSize;
row.MaxEvaluations = cfg.search.maxEvaluations;
row.Evaluations = searchResult.Evaluations;
row.RuntimeSeconds = runtimeSeconds;
row.Objective = searchResult.BestObjective;
row.Score = searchResult.BestScore;
row.J_true = Jtrue;
row.SumRate = result.SumRate;
row.MeanRate = result.MeanRate;
row.MinRate = result.MinRate;
row.Rate5 = result.Rate5;
row.Rate10 = result.Rate10;
row.Jain = result.Jain;
row.ActiveLinks = result.ActiveLinks;
row.TotalPower = result.TotalPower;
row.ActiveStreams = result.ActiveStreams;
row.NumScheduledUE = trueDetails.numScheduledUE;
row.Best_betaPF = candidate.betaPF;
row.Best_numConnections = candidate.numConnections;
row.Best_scheduleThreshold = candidate.scheduleThreshold;
row.Best_rhoLink = candidate.rhoLink;
row.Best_rhoPower = candidate.rhoPower;
row.Best_maxRank = candidate.maxRank;
row.Best_rankThreshold = candidate.rankThreshold;
row.Best_repairPower = candidate.repairPower;
row.Best_maxRepairLinks = candidate.maxRepairLinks;
end

function plotTestbedResults(summaryTable,outFile)
[~,order] = sort(string(summaryTable.Method));
t = summaryTable(order,:);
fig = figure('Visible','off','Color','w','Position',[100 100 1250 780]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
plotOne(nexttile(layout),t.Method,t.Objective,'Objective J\_true');
plotOne(nexttile(layout),t.Method,t.Jain,'Jain index');
plotOne(nexttile(layout),t.Method,t.ActiveLinks,'Active links');
plotOne(nexttile(layout),t.Method,t.RuntimeSeconds,'Runtime seconds');
title(layout,'M3 testbed full 9-D algorithm comparison','Interpreter','none');
exportgraphics(fig,outFile,'Resolution',180);
close(fig);
end

function plotOne(ax,labels,values,yText)
bar(ax,categorical(labels),values);
grid(ax,'on');
ylabel(ax,yText);
xtickangle(ax,30);
end

function writeExplanation(summaryTable,runInfo,outFile)
fid = fopen(outFile,'w');
cleanup = onCleanup(@() fclose(fid));
[~,objectiveOrder] = sort(summaryTable.Objective,'descend');
[~,jainOrder] = sort(summaryTable.Jain,'descend');
[~,linkOrder] = sort(summaryTable.ActiveLinks,'ascend');
bestObj = summaryTable(objectiveOrder(1),:);
bestJain = summaryTable(jainOrder(1),:);
fewestLinks = summaryTable(linkOrder(1),:);

fprintf(fid,'# M3 Testbed Explanation\n\n');
fprintf(fid,'Generated at: %s\n\n',runInfo.createdAt);
fprintf(fid,'Run ID: `%s`\n\n',runInfo.runId);
fprintf(fid,'Scale: 7 DUs, 100 UEs, 100 RBGs, 2x12 MIMO.\n\n');
fprintf(fid,'Search space: full 9-D normalized candidate vector.\n\n');
fprintf(fid,'Default candidate injection: enabled; cfg.defaultX is the first outer-search candidate.\n\n');
fprintf(fid,'Budget: populationSize=%d, maxEvaluations=%d, innerMaxIter=%d.\n\n', ...
    runInfo.populationSize,summaryTable.MaxEvaluations(1),summaryTable.InnerMaxIter(1));
fprintf(fid,'Optimization objective: maximize `J_true = scheduled sum log2(1+SINR)`.\n');
fprintf(fid,'Score, Jain, ActiveLinks, TotalPower, and Runtime are evaluation metrics only.\n\n');

fprintf(fid,'## Algorithm Comparison\n\n');
fprintf(fid,'| Method | Objective | Score | J_true | Jain | ActiveLinks | TotalPower | RuntimeSeconds |\n');
fprintf(fid,'|---|---:|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(summaryTable)
    fprintf(fid,'| %s | %.6g | %.6g | %.6g | %.4f | %d | %.6g | %.3f |\n', ...
        summaryTable.Method{i},summaryTable.Objective(i),summaryTable.Score(i), ...
        summaryTable.J_true(i),summaryTable.Jain(i),summaryTable.ActiveLinks(i), ...
        summaryTable.TotalPower(i),summaryTable.RuntimeSeconds(i));
end

fprintf(fid,'\n## Result Interpretation\n\n');
fprintf(fid,'- Best objective: `%s` with %.6g.\n',bestObj.Method{1},bestObj.Objective(1));
fprintf(fid,'- Best Jain index: `%s` with %.4f.\n',bestJain.Method{1},bestJain.Jain(1));
fprintf(fid,'- Fewest active links: `%s` with %d links.\n\n',fewestLinks.Method{1},fewestLinks.ActiveLinks(1));
fprintf(fid,'If `basic` is best by objective, it should be treated as a high-link upper baseline rather than a low-cost scheduling solution.\n');
fprintf(fid,'If `inner` beats outer-search methods even after default-candidate injection, the current algorithm update or search-space design is not yet strong enough to improve over the default inner candidate.\n');
fprintf(fid,'If outer-search methods improve objective but worsen Jain or ActiveLinks, the change improves the target max objective but may need engineering constraints later.\n');
end

function writeTextReport(summaryTable,runInfo,outFile)
fid = fopen(outFile,'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'M3 full-scale 9-D testbed\n');
fprintf(fid,'Created: %s\n',runInfo.createdAt);
fprintf(fid,'Run ID: %s\n',runInfo.runId);
fprintf(fid,'Objective: %s\n',runInfo.objective);
fprintf(fid,'Search space: %s\n',runInfo.searchSpace);
fprintf(fid,'Default candidate injected: %d\n',runInfo.defaultCandidateInjected);
fprintf(fid,'Population size: %d\n',runInfo.populationSize);
fprintf(fid,'Result root: %s\n\n',runInfo.resultRoot);
for i = 1:height(summaryTable)
    fprintf(fid,'%-6s Objective=% .6g Score=% .6g J_true=% .6g Jain=%.4f ActiveLinks=%d TotalPower=%.6g Runtime=%.3fs\n', ...
        summaryTable.Method{i},summaryTable.Objective(i),summaryTable.Score(i), ...
        summaryTable.J_true(i),summaryTable.Jain(i),summaryTable.ActiveLinks(i), ...
        summaryTable.TotalPower(i),summaryTable.RuntimeSeconds(i));
end
end

function writeCandidateTable(candidate,outFile)
names = fieldnames(candidate);
rows = cell(numel(names),2);
for i = 1:numel(names)
    name = names{i};
    value = candidate.(name);
    rows{i,1} = name;
    if isnumeric(value)
        rows{i,2} = mat2str(value,8);
    else
        rows{i,2} = char(string(value));
    end
end
writetable(cell2table(rows,'VariableNames',{'Parameter','Value'}),outFile);
end

function tag = methodToTag(method)
tag = lower(strrep(method,'+','_'));
end

function value = getenvOrDefault(name,defaultValue)
value = getenv(name);
if isempty(value)
    value = defaultValue;
end
end

function value = numericEnvOrDefault(name,defaultValue)
raw = getenv(name);
if isempty(raw)
    value = defaultValue;
else
    value = str2double(raw);
    if ~isfinite(value)
        error('Environment variable %s must be numeric.',name);
    end
end
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
