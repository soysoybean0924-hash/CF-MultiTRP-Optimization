%% M3 high-efficiency computing benchmark.
% This staged workflow measures scaling evidence before changing the core
% optimizer. It is intentionally budget-capped so it can be rerun often.
clear; clc; close all;

scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptFolder));
run(fullfile(projectRoot,'setup_project_paths.m'));

runId = getenvOrDefault('M3_EFFICIENCY_RUN_ID', ...
    ['run_' char(datetime('now','Format','yyyyMMdd_HHmmss'))]);
resultRoot = fullfile(projectRoot,'results','m3_efficiency',runId);
profiles = parseList(getenvOrDefault('M3_EFFICIENCY_PROFILES','tiny,small,m3_probe'));
methods = parseList(getenvOrDefault('M3_EFFICIENCY_METHODS','basic,inner,PSO+GA'));
innerIterCap = numericEnvOrDefault('M3_EFFICIENCY_INNER_ITER_CAP',1);
maxEvalCap = numericEnvOrDefault('M3_EFFICIENCY_MAX_EVAL_CAP',2);
populationSize = numericEnvOrDefault('M3_EFFICIENCY_POPULATION_SIZE',2);

if ~exist(resultRoot,'dir')
    mkdir(resultRoot);
end

specs = benchmarkSpecs();
rows = {};
for pi = 1:numel(profiles)
    profileName = profiles{pi};
    spec = findSpec(specs,profileName);
    cfg = makeConfig(spec,innerIterCap,maxEvalCap,populationSize);

    profileDir = fullfile(resultRoot,profileName);
    if ~exist(profileDir,'dir')
        mkdir(profileDir);
    end

    fprintf('\n[M3 efficiency] profile=%s DU=%d UE=%d RBG=%d\n', ...
        profileName,cfg.numDUs,cfg.numUEs,cfg.numRBGs);
    tic;
    scenario = cf_generate_scenario(cfg);
    scenarioSeconds = toc;
    save(fullfile(profileDir,'scenario.mat'),'cfg','scenario','scenarioSeconds','-v7.3');

    for mi = 1:numel(methods)
        method = methods{mi};
        fprintf('  method=%s\n',method);
        tic;
        [searchResult,result] = runEfficiencyMethod(method,cfg,scenario);
        runtimeSeconds = toc;
        [Jtrue,trueDetails] = cf_compute_true_objective(result);
        methodDir = fullfile(profileDir,methodToTag(method));
        if ~exist(methodDir,'dir')
            mkdir(methodDir);
        end
        save(fullfile(methodDir,'result.mat'),'cfg','scenario','searchResult', ...
            'result','Jtrue','trueDetails','runtimeSeconds','scenarioSeconds','-v7.3');
        writetable(searchResult.History,fullfile(methodDir,'search_history.csv'));
        rows{end+1,1} = makeRow(profileName,method,cfg,searchResult,result, ...
            Jtrue,scenarioSeconds,runtimeSeconds); %#ok<SAGROW>
    end
end

summaryTable = struct2table(vertcat(rows{:}));
fitTable = fitScaling(summaryTable);
writetable(summaryTable,fullfile(resultRoot,'efficiency_summary.csv'));
writetable(summaryTable,fullfile(resultRoot,'efficiency_summary.xlsx'));
writetable(fitTable,fullfile(resultRoot,'efficiency_scaling_fit.csv'));
save(fullfile(resultRoot,'efficiency_summary.mat'),'summaryTable','fitTable', ...
    'profiles','methods','innerIterCap','maxEvalCap','populationSize','-v7.3');
plotEfficiency(summaryTable,resultRoot);
writeExplanation(summaryTable,fitTable,resultRoot,profiles,methods, ...
    innerIterCap,maxEvalCap,populationSize);

fprintf('\nFinished M3 efficiency benchmark.\n');
fprintf('Result folder: %s\n',resultRoot);

function specs = benchmarkSpecs()
specs = struct( ...
    'Name',{'tiny','small','m3_probe','m3'}, ...
    'NumDUs',{3,5,7,7}, ...
    'NumUEs',{12,30,100,100}, ...
    'NumRBGs',{10,20,100,100}, ...
    'NumTxAntennas',{8,8,12,12}, ...
    'NumRxAntennas',{2,2,2,2});
end

function spec = findSpec(specs,name)
idx = find(strcmpi({specs.Name},name),1);
if isempty(idx)
    error('Unknown efficiency profile "%s".',name);
end
spec = specs(idx);
end

function cfg = makeConfig(spec,innerIterCap,maxEvalCap,populationSize)
cfg = cf_default_config('m3');
cfg.profile = ['efficiency_' lower(spec.Name)];
cfg.numDUs = spec.NumDUs;
cfg.numUEs = spec.NumUEs;
cfg.numRBGs = spec.NumRBGs;
cfg.numTxAntennas = spec.NumTxAntennas;
cfg.numRxAntennas = spec.NumRxAntennas;
cfg.inner.maxIter = max(0,round(innerIterCap));
cfg.search.maxEvaluations = max(1,round(maxEvalCap));
cfg.search.populationSize = min(max(1,round(populationSize)),cfg.search.maxEvaluations);
cfg.search.eliteCount = min(cfg.search.eliteCount,max(0,cfg.search.populationSize-1));
cfg.search.verbose = false;
cfg.search.numConnectionsRange = [1 min(4,cfg.numDUs)];
cfg.search.maxRepairLinksRange = [0 min(4,cfg.numDUs*cfg.numRBGs)];
end

function [searchResult,result] = runEfficiencyMethod(method,cfg,scenario)
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

function row = makeRow(profileName,method,cfg,searchResult,result,Jtrue,scenarioSeconds,runtimeSeconds)
row = struct();
row.Profile = {profileName};
row.Method = {method};
row.NumDUs = cfg.numDUs;
row.NumUEs = cfg.numUEs;
row.NumRBGs = cfg.numRBGs;
row.NumTxAntennas = cfg.numTxAntennas;
row.NumRxAntennas = cfg.numRxAntennas;
row.NumLinks = cfg.numDUs*cfg.numUEs*cfg.numRBGs;
row.NumAntennaLinks = row.NumLinks*cfg.numTxAntennas*cfg.numRxAntennas;
row.InnerMaxIter = cfg.inner.maxIter;
row.MaxEvaluations = cfg.search.maxEvaluations;
row.PopulationSize = cfg.search.populationSize;
row.Evaluations = searchResult.Evaluations;
row.ScenarioSeconds = scenarioSeconds;
row.RuntimeSeconds = runtimeSeconds;
row.RuntimePerEvaluation = runtimeSeconds/max(1,searchResult.Evaluations);
row.Objective = searchResult.BestObjective;
row.Score = searchResult.BestScore;
row.J_true = Jtrue;
row.SumRate = result.SumRate;
row.Jain = result.Jain;
row.ActiveLinks = result.ActiveLinks;
row.TotalPower = result.TotalPower;
end

function fitTable = fitScaling(summaryTable)
methods = unique(summaryTable.Method,'stable');
rows = {};
for i = 1:numel(methods)
    method = methods{i};
    idx = strcmp(summaryTable.Method,method);
    x = double(summaryTable.NumLinks(idx));
    y = double(summaryTable.RuntimeSeconds(idx));
    valid = isfinite(x) & isfinite(y) & x > 0 & y > 0;
    row = struct();
    row.Method = {method};
    row.NumPoints = sum(valid);
    if sum(valid) >= 2
        p = polyfit(log10(x(valid)),log10(y(valid)),1);
        yhat = polyval(p,log10(x(valid)));
        ssRes = sum((log10(y(valid))-yhat).^2);
        ssTot = sum((log10(y(valid))-mean(log10(y(valid)))).^2);
        row.LogLogSlope = p(1);
        row.LogLogIntercept = p(2);
        row.RSquared = 1 - ssRes/max(ssTot,eps);
    else
        row.LogLogSlope = NaN;
        row.LogLogIntercept = NaN;
        row.RSquared = NaN;
    end
    rows{end+1,1} = row; %#ok<AGROW>
end
fitTable = struct2table(vertcat(rows{:}));
end

function plotEfficiency(summaryTable,resultRoot)
fig1 = figure('Visible','off','Color','w','Position',[100 100 900 560]);
ax = axes(fig1);
methods = unique(summaryTable.Method,'stable');
hold(ax,'on');
for i = 1:numel(methods)
    idx = strcmp(summaryTable.Method,methods{i});
    plot(ax,summaryTable.NumLinks(idx),summaryTable.RuntimeSeconds(idx), ...
        '-o','LineWidth',1.5,'DisplayName',methods{i});
end
grid(ax,'on'); set(ax,'XScale','log','YScale','log');
xlabel(ax,'DU x UE x RBG links');
ylabel(ax,'Runtime seconds');
legend(ax,'Location','best','Interpreter','none');
title(ax,'Efficiency scaling: runtime vs candidate link count');
exportgraphics(fig1,fullfile(resultRoot,'fig_runtime_vs_links.png'),'Resolution',180);
close(fig1);

fig2 = figure('Visible','off','Color','w','Position',[100 100 900 560]);
ax = axes(fig2);
bar(ax,categorical(strcat(summaryTable.Profile," / ",summaryTable.Method)), ...
    summaryTable.RuntimePerEvaluation);
grid(ax,'on'); xtickangle(ax,35);
ylabel(ax,'Runtime seconds per evaluation');
title(ax,'Efficiency benchmark: per-evaluation runtime');
exportgraphics(fig2,fullfile(resultRoot,'fig_runtime_per_eval.png'),'Resolution',180);
close(fig2);
end

function writeExplanation(summaryTable,fitTable,resultRoot,profiles,methods,innerIterCap,maxEvalCap,populationSize)
fid = fopen(fullfile(resultRoot,'M3_efficiency_explanation.md'),'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'# M3 Efficiency Benchmark\n\n');
fprintf(fid,'Profiles: `%s`.\n\n',strjoin(profiles,', '));
fprintf(fid,'Methods: `%s`.\n\n',strjoin(methods,', '));
fprintf(fid,'Budget: innerMaxIter=%d, maxEvaluations=%d, populationSize=%d.\n\n', ...
    innerIterCap,maxEvalCap,populationSize);
fprintf(fid,'This benchmark is the measurement layer for the mandatory high-efficiency computing target.\n');
fprintf(fid,'It does not yet claim the final target is met; it provides scaling evidence and bottleneck timing.\n\n');

fprintf(fid,'## Runtime Summary\n\n');
fprintf(fid,'| Profile | Method | Links | RuntimeSeconds | RuntimePerEvaluation | J_true | ActiveLinks | TotalPower |\n');
fprintf(fid,'|---|---|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(summaryTable)
    fprintf(fid,'| %s | %s | %d | %.6g | %.6g | %.6g | %d | %.6g |\n', ...
        summaryTable.Profile{i},summaryTable.Method{i},summaryTable.NumLinks(i), ...
        summaryTable.RuntimeSeconds(i),summaryTable.RuntimePerEvaluation(i), ...
        summaryTable.J_true(i),summaryTable.ActiveLinks(i),summaryTable.TotalPower(i));
end

fprintf(fid,'\n## Scaling Fit\n\n');
fprintf(fid,'Log-log slope is fitted from RuntimeSeconds versus NumLinks. A slope near 1 is closer to linear scaling.\n\n');
fprintf(fid,'| Method | Points | LogLogSlope | RSquared |\n');
fprintf(fid,'|---|---:|---:|---:|\n');
for i = 1:height(fitTable)
    fprintf(fid,'| %s | %d | %.4g | %.4g |\n', ...
        fitTable.Method{i},fitTable.NumPoints(i),fitTable.LogLogSlope(i),fitTable.RSquared(i));
end

fprintf(fid,'\n## Current Judgment\n\n');
fprintf(fid,'- This run establishes the evidence path for the high-efficiency target.\n');
fprintf(fid,'- If slopes are much larger than 1 or M3_probe dominates runtime, the next step should be caching, vectorization, and parallel candidate evaluation.\n');
fprintf(fid,'- A final high-efficiency claim requires an optimized run with improved runtime or near-linear scaling on the same benchmark.\n');
end

function tag = methodToTag(method)
tag = lower(strrep(method,'+','_'));
end

function list = parseList(raw)
parts = strsplit(char(raw),',');
list = {};
for i = 1:numel(parts)
    item = strtrim(parts{i});
    if ~isempty(item)
        list{end+1} = item; %#ok<AGROW>
    end
end
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
