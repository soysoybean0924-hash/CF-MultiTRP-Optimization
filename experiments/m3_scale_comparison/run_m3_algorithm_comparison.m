%% M3 scale and algorithm comparison.
% Runs quick/standard/paper/M3 profiles under the same baseline and outer
% search method set, then exports all raw and comparison results into one
% M3-named result folder.
clear; clc; close all;

scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptFolder));
run(fullfile(projectRoot,'setup_project_paths.m'));

profiles = {'quick','standard','paper','m3'};
methods = {'basic','inner','GA','PSO','GA+PSO','PSO+GA','PGSAO'};
resultRoot = getenvOrDefault('M3_RESULT_ROOT',fullfile(projectRoot,'results','M3_scale_comparison'));
maxEvalCap = numericEnvOrEmpty('M3_MAX_EVAL_CAP');
innerIterCap = numericEnvOrEmpty('M3_INNER_ITER_CAP');

if ~exist(resultRoot,'dir')
    mkdir(resultRoot);
end

runInfo = struct();
runInfo.createdAt = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
runInfo.profiles = profiles;
runInfo.methods = methods;
runInfo.resultRoot = resultRoot;
runInfo.maxEvalCap = maxEvalCap;
runInfo.innerIterCap = innerIterCap;

summaryRows = cell(numel(profiles)*numel(methods),1);
rowIndex = 0;

for pi = 1:numel(profiles)
    profile = profiles{pi};
    cfg = cf_default_config(profile);
    cfg = applyBudgetCaps(cfg,maxEvalCap,innerIterCap);
    scenario = cf_generate_scenario(cfg);
    profileDir = fullfile(resultRoot,profile);
    if ~exist(profileDir,'dir')
        mkdir(profileDir);
    end
    save(fullfile(profileDir,'scenario.mat'),'cfg','scenario','-v7.3');

    for mi = 1:numel(methods)
        method = methods{mi};
        methodTag = methodToTag(method);
        methodDir = fullfile(profileDir,methodTag);
        if ~exist(methodDir,'dir')
            mkdir(methodDir);
        end

        fprintf('\n[M3 comparison] profile=%s method=%s\n',profile,method);
        resultFile = fullfile(methodDir,'search_result.mat');
        if exist(resultFile,'file')
            loaded = load(resultFile,'cfg','searchResult','result','Jtrue','trueDetails','runtimeSeconds');
            resultCfg = cfg;
            if isfield(loaded,'cfg')
                resultCfg = loaded.cfg;
            end
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
            comparisonTable = cf_print_result(result,sprintf('%s %s M3 comparison',profile,method));
            resultCfg = cfg;

            save(resultFile, ...
                'cfg','searchResult','result','comparisonTable','Jtrue','trueDetails','runtimeSeconds','-v7.3');
            writetable(searchResult.History,fullfile(methodDir,'search_history.csv'));
            writetable(comparisonTable,fullfile(methodDir,'best_result_metrics.csv'));
            writeCandidateTable(searchResult.BestCandidate,fullfile(methodDir,'best_candidate.csv'));
        end

        rowIndex = rowIndex + 1;
        summaryRows{rowIndex} = makeSummaryRow(profile,method,resultCfg,searchResult, ...
            result,Jtrue,trueDetails,runtimeSeconds);
    end
end

summaryTable = struct2table(vertcat(summaryRows{:}));
writetable(summaryTable,fullfile(resultRoot,'algorithm_profile_comparison.csv'));
writetable(summaryTable,fullfile(resultRoot,'algorithm_profile_comparison.xlsx'));
save(fullfile(resultRoot,'algorithm_profile_comparison.mat'), ...
    'summaryTable','runInfo','profiles','methods','-v7.3');
writeComparisonReport(summaryTable,runInfo,fullfile(resultRoot,'M3_algorithm_comparison_report.txt'));

fprintf('\nFinished M3 scale comparison.\n');
fprintf('Result folder: %s\n',resultRoot);
fprintf('Summary CSV:   %s\n',fullfile(resultRoot,'algorithm_profile_comparison.csv'));
fprintf('Report:        %s\n',fullfile(resultRoot,'M3_algorithm_comparison_report.txt'));

function tag = methodToTag(method)
tag = lower(strrep(method,'+','_'));
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

function value = getenvOrDefault(name,defaultValue)
value = getenv(name);
if isempty(value)
    value = defaultValue;
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

function cfg = applyBudgetCaps(cfg,maxEvalCap,innerIterCap)
if ~isempty(maxEvalCap)
    cfg.search.maxEvaluations = max(1,round(min(cfg.search.maxEvaluations,maxEvalCap)));
    cfg.search.populationSize = max(1,round(min(cfg.search.populationSize,cfg.search.maxEvaluations)));
    cfg.search.eliteCount = min(cfg.search.eliteCount,max(0,cfg.search.populationSize-1));
end
if ~isempty(innerIterCap)
    cfg.inner.maxIter = max(0,round(min(cfg.inner.maxIter,innerIterCap)));
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
candidateTable = cell2table(rows,'VariableNames',{'Parameter','Value'});
writetable(candidateTable,outFile);
end

function row = makeSummaryRow(profile,method,cfg,searchResult,result,Jtrue,trueDetails,runtimeSeconds)
candidate = searchResult.BestCandidate;
row = struct();
row.Profile = profile;
row.Method = method;
row.NumDUs = cfg.numDUs;
row.NumUEs = cfg.numUEs;
row.NumRBGs = cfg.numRBGs;
row.NumTxAntennas = cfg.numTxAntennas;
row.NumRxAntennas = cfg.numRxAntennas;
row.MaxRankCfg = cfg.maxRank;
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

function writeComparisonReport(summaryTable,runInfo,outFile)
fid = fopen(outFile,'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'M3 scale algorithm comparison\n');
fprintf(fid,'Created: %s\n',runInfo.createdAt);
fprintf(fid,'Result root: %s\n\n',runInfo.resultRoot);
fprintf(fid,'Profiles: %s\n',strjoin(runInfo.profiles,', '));
fprintf(fid,'Methods: %s\n\n',strjoin(runInfo.methods,', '));
if ~isempty(runInfo.maxEvalCap) || ~isempty(runInfo.innerIterCap)
    fprintf(fid,'Budget caps applied: maxEvalCap=%s, innerIterCap=%s\n\n', ...
        valueText(runInfo.maxEvalCap),valueText(runInfo.innerIterCap));
end

profiles = unique(summaryTable.Profile,'stable');
for pi = 1:numel(profiles)
    profile = profiles{pi};
    idx = strcmp(summaryTable.Profile,profile);
    sub = summaryTable(idx,:);
    [~,bestIdx] = max(sub.BestScore);
    fprintf(fid,'Profile %s\n',profile);
    fprintf(fid,'  Scale: DUs=%d, UEs=%d, RBGs=%d, MIMO=%dx%d, innerIter=%d, maxEval=%d\n', ...
        sub.NumDUs(1),sub.NumUEs(1),sub.NumRBGs(1), ...
        sub.NumRxAntennas(1),sub.NumTxAntennas(1),sub.InnerMaxIter(1),sub.MaxEvaluations(1));
    fprintf(fid,'  Best by Score: %s, Score=%.6g, J_true=%.6g, SumRate=%.6g, runtime=%.3fs\n', ...
        sub.Method{bestIdx},sub.BestScore(bestIdx),sub.J_true(bestIdx), ...
        sub.SumRate(bestIdx),sub.RuntimeSeconds(bestIdx));
    for i = 1:height(sub)
        fprintf(fid,'  - %-6s Score=% .6g J_true=% .6g SumRate=% .6g Jain=%.4f ActiveLinks=%d Runtime=%.3fs\n', ...
            sub.Method{i},sub.BestScore(i),sub.J_true(i),sub.SumRate(i), ...
            sub.Jain(i),sub.ActiveLinks(i),sub.RuntimeSeconds(i));
    end
    fprintf(fid,'\n');
end
end

function text = valueText(value)
if isempty(value)
    text = 'none';
else
    text = num2str(value);
end
end
