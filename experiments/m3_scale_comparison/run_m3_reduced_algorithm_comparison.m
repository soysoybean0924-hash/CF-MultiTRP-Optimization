%% M3 reduced-dimension algorithm comparison.
% Selects the most sensitive searchable parameters from the M3 sensitivity
% ranking, fixes the remaining normalized variables at cfg.defaultX, and
% reruns the same M3 baseline/search method set in the reduced subspace.
clear; clc; close all;

scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptFolder));
run(fullfile(projectRoot,'setup_project_paths.m'));

resultRoot = getenvOrDefault('M3_RESULT_ROOT',fullfile(projectRoot,'results','M3_scale_comparison'));
sensitivityDir = fullfile(resultRoot,'m3_local_sensitivity');
sensitivityFile = fullfile(sensitivityDir,'sensitivity_ranking.csv');
if ~exist(sensitivityFile,'file')
    error('Sensitivity ranking not found: %s. Run run_m3_local_sensitivity first.',sensitivityFile);
end

ranking = readtable(sensitivityFile,'TextType','string');
[activeDimensions,selectedParameters,skippedParameters] = selectSearchDimensions(ranking,3);

cfg = cf_default_config('m3');
cfg = applyBudgetCaps(cfg,numericEnvOrDefault('M3_REDUCED_MAX_EVAL_CAP',8), ...
    numericEnvOrDefault('M3_REDUCED_INNER_ITER_CAP',2));
cfg.search.activeDimensions = activeDimensions;
cfg.search.fixedX = cfg.defaultX;

methods = {'basic','inner','GA','PSO','GA+PSO','PSO+GA','PGSAO'};
profile = 'm3_reduced3';
profileDir = fullfile(resultRoot,profile);
if ~exist(profileDir,'dir')
    mkdir(profileDir);
end

scenario = cf_generate_scenario(cfg);
save(fullfile(profileDir,'scenario.mat'), ...
    'cfg','scenario','activeDimensions','selectedParameters','skippedParameters','-v7.3');

summaryRows = cell(numel(methods),1);
for mi = 1:numel(methods)
    method = methods{mi};
    methodDir = fullfile(profileDir,methodToTag(method));
    if ~exist(methodDir,'dir')
        mkdir(methodDir);
    end
    resultFile = fullfile(methodDir,'search_result.mat');
    fprintf('\n[M3 reduced] method=%s activeDims=%s\n',method,mat2str(activeDimensions));
    if exist(resultFile,'file')
        loaded = load(resultFile,'cfg','searchResult','result','Jtrue','trueDetails','runtimeSeconds');
        resultCfg = loaded.cfg;
        searchResult = loaded.searchResult;
        result = loaded.result;
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
        comparisonTable = cf_print_result(result,sprintf('%s %s reduced search',profile,method));
        resultCfg = cfg;

        save(resultFile, ...
            'cfg','searchResult','result','comparisonTable','Jtrue','trueDetails', ...
            'runtimeSeconds','activeDimensions','selectedParameters','skippedParameters','-v7.3');
        writetable(searchResult.History,fullfile(methodDir,'search_history.csv'));
        writetable(comparisonTable,fullfile(methodDir,'best_result_metrics.csv'));
        writeCandidateTable(searchResult.BestCandidate,fullfile(methodDir,'best_candidate.csv'));
    end
    summaryRows{mi} = makeSummaryRow(profile,method,resultCfg,searchResult,result, ...
        Jtrue,trueDetails,runtimeSeconds,activeDimensions,selectedParameters);
end

summaryTable = struct2table(vertcat(summaryRows{:}));
writetable(summaryTable,fullfile(profileDir,'reduced_algorithm_comparison.csv'));
writetable(summaryTable,fullfile(profileDir,'reduced_algorithm_comparison.xlsx'));
save(fullfile(profileDir,'reduced_algorithm_comparison.mat'), ...
    'summaryTable','activeDimensions','selectedParameters','skippedParameters','-v7.3');
writeReducedReport(summaryTable,selectedParameters,skippedParameters, ...
    fullfile(profileDir,'M3_reduced_algorithm_comparison_report.txt'));

fprintf('\nFinished M3 reduced-dimension comparison.\n');
fprintf('Result folder: %s\n',profileDir);
fprintf('Selected parameters: %s\n',strjoin(selectedParameters,', '));

function [activeDimensions,selectedParameters,skippedParameters] = selectSearchDimensions(ranking,k)
map = searchDimensionMap();
ranking = sortrows(ranking,'TrueRank','ascend');
activeDimensions = [];
selectedParameters = strings(0,1);
skippedParameters = strings(0,1);
for i = 1:height(ranking)
    field = char(ranking.ActualField(i));
    if isKey(map,field)
        activeDimensions(end+1) = map(field); %#ok<AGROW>
        selectedParameters(end+1,1) = ranking.Parameter(i); %#ok<AGROW>
    else
        skippedParameters(end+1,1) = ranking.Parameter(i); %#ok<AGROW>
    end
    if numel(activeDimensions) >= k
        break;
    end
end
activeDimensions = unique(activeDimensions,'stable');
selectedParameters = cellstr(selectedParameters);
skippedParameters = cellstr(skippedParameters);
end

function map = searchDimensionMap()
map = containers.Map();
map('candidate.betaPF') = 1;
map('candidate.numConnections') = 2;
map('candidate.scheduleThreshold') = 3;
map('candidate.rhoLink') = 4;
map('candidate.rhoPower') = 5;
map('candidate.rankThreshold') = 7;
map('candidate.repairPower') = 8;
end

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
        searchResult = cf_search(method,cfg,scenario,cfg.search);
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
searchResult.Evaluations = 1;
searchResult.History = table(1,result.Score,result.Score, ...
    'VariableNames',{'Evaluation','Score','BestScore'});
searchResult.EvaluationX = bestX;
searchResult.EvaluationScore = result.Score;
searchResult.FinalPopulation = bestX;
searchResult.FinalScores = result.Score;
end

function row = makeSummaryRow(profile,method,cfg,searchResult,result,Jtrue,trueDetails,runtimeSeconds,activeDimensions,selectedParameters)
row = struct();
row.Profile = profile;
row.Method = method;
row.ActiveDimensions = mat2str(activeDimensions);
row.SelectedParameters = strjoin(selectedParameters,', ');
row.NumDUs = cfg.numDUs;
row.NumUEs = cfg.numUEs;
row.NumRBGs = cfg.numRBGs;
row.NumTxAntennas = cfg.numTxAntennas;
row.NumRxAntennas = cfg.numRxAntennas;
row.InnerMaxIter = cfg.inner.maxIter;
row.PopulationSize = cfg.search.populationSize;
row.MaxEvaluations = cfg.search.maxEvaluations;
row.Evaluations = searchResult.Evaluations;
row.RuntimeSeconds = runtimeSeconds;
row.BestScore = searchResult.BestScore;
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
end

function cfg = applyBudgetCaps(cfg,maxEvalCap,innerIterCap)
cfg.search.maxEvaluations = max(1,round(min(cfg.search.maxEvaluations,maxEvalCap)));
cfg.search.populationSize = max(1,round(min(cfg.search.populationSize,cfg.search.maxEvaluations)));
cfg.search.eliteCount = min(cfg.search.eliteCount,max(0,cfg.search.populationSize-1));
cfg.inner.maxIter = max(0,round(min(cfg.inner.maxIter,innerIterCap)));
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

function tag = methodToTag(method)
tag = lower(strrep(method,'+','_'));
end

function writeCandidateTable(candidate,outFile)
names = fieldnames(candidate);
rows = cell(numel(names),2);
for i = 1:numel(names)
    name = names{i};
    value = candidate.(name);
    if isnumeric(value)
        valueText = mat2str(value,8);
    else
        valueText = char(string(value));
    end
    rows{i,1} = name;
    rows{i,2} = valueText;
end
writetable(cell2table(rows,'VariableNames',{'Parameter','Value'}),outFile);
end

function writeReducedReport(summaryTable,selectedParameters,skippedParameters,outFile)
fid = fopen(outFile,'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'M3 reduced-dimension algorithm comparison\n\n');
fprintf(fid,'Selected searchable parameters: %s\n',strjoin(selectedParameters,', '));
if ~isempty(skippedParameters)
    fprintf(fid,'High-sensitivity parameters skipped because they are not outer-search dimensions: %s\n', ...
        strjoin(skippedParameters,', '));
end
fprintf(fid,'\n');
[~,bestIdx] = max(summaryTable.BestScore);
fprintf(fid,'Best by Score: %s, Score=%.6g, J_true=%.6g, SumRate=%.6g, Runtime=%.3fs\n\n', ...
    summaryTable.Method{bestIdx},summaryTable.BestScore(bestIdx), ...
    summaryTable.J_true(bestIdx),summaryTable.SumRate(bestIdx),summaryTable.RuntimeSeconds(bestIdx));
for i = 1:height(summaryTable)
    fprintf(fid,'- %-6s Score=% .6g J_true=% .6g SumRate=% .6g Jain=%.4f ActiveLinks=%d Runtime=%.3fs\n', ...
        summaryTable.Method{i},summaryTable.BestScore(i),summaryTable.J_true(i), ...
        summaryTable.SumRate(i),summaryTable.Jain(i),summaryTable.ActiveLinks(i), ...
        summaryTable.RuntimeSeconds(i));
end
end
