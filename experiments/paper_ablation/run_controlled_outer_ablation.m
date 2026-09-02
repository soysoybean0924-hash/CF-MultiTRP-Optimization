%% Controlled outer-only and outer+inner ablation for the paper track.
% This experiment keeps the search objective, scenario seed, candidate
% decoder, and evaluation budget matched while toggling only the inner loop.
clear; clc; close all;

scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptFolder));
run(fullfile(projectRoot,'setup_project_paths.m'));

runId = getenvOrDefault('PAPER_ABLATION_RUN_ID', ...
    ['run_' char(datetime('now','Format','yyyyMMdd_HHmmss'))]);
resultRoot = getenvOrDefault('PAPER_ABLATION_RESULT_ROOT', ...
    fullfile(projectRoot,'results','paper_ablation',runId));
scaleNames = parseList(getenvOrDefault('PAPER_ABLATION_SCALES','S1,S2,S3,S4'));
seedList = parseNumericList(getenvOrDefault('PAPER_ABLATION_SEEDS','1:10'));
methods = parseList(getenvOrDefault('PAPER_ABLATION_METHODS', ...
    'basic,inner,GA-only,PSO-only,PGSAO-only,GA+Inner,PSO+Inner,PGSAO+Inner'));
maxEvaluations = numericEnvOrDefault('PAPER_ABLATION_MAX_EVAL',32);
populationSize = numericEnvOrDefault('PAPER_ABLATION_POPULATION',8);
innerMaxIter = numericEnvOrDefault('PAPER_ABLATION_INNER_ITER',12);
numRBGs = numericEnvOrDefault('PAPER_ABLATION_NUM_RBGS',4);
numTx = numericEnvOrDefault('PAPER_ABLATION_NUM_TX',8);
numRx = numericEnvOrDefault('PAPER_ABLATION_NUM_RX',2);
verboseSearch = logical(numericEnvOrDefault('PAPER_ABLATION_VERBOSE',0));

if ~exist(resultRoot,'dir')
    mkdir(resultRoot);
end

runInfo = struct();
runInfo.CreatedAt = char(datetime('now','Format','yyyy-MM-dd HH:mm:ss'));
runInfo.RunId = runId;
runInfo.ResultRoot = resultRoot;
runInfo.ScaleNames = scaleNames;
runInfo.SeedList = seedList;
runInfo.Methods = methods;
runInfo.Objective = 'maximize J_true = scheduled sum log2(1+SINR)';
runInfo.HybridMethod = 'PGSAO';
runInfo.MaxEvaluations = maxEvaluations;
runInfo.PopulationSize = populationSize;
runInfo.InnerMaxIter = innerMaxIter;
runInfo.NumRBGs = numRBGs;
runInfo.NumTxAntennas = numTx;
runInfo.NumRxAntennas = numRx;

specs = controlledScaleSpecs();
rawRows = {};
convergenceRows = {};
rowIndex = 0;
convIndex = 0;

for si = 1:numel(scaleNames)
    spec = findScaleSpec(specs,scaleNames{si});
    for seedIndex = 1:numel(seedList)
        seed = seedList(seedIndex);
        cfg = makeControlledConfig(spec,seed,numRBGs,numTx,numRx, ...
            innerMaxIter,maxEvaluations,populationSize,verboseSearch);
        scenario = cf_generate_scenario(cfg);

        scaleDir = fullfile(resultRoot,spec.Name,sprintf('seed_%03d',seed));
        if ~exist(scaleDir,'dir')
            mkdir(scaleDir);
        end
        scenarioInfo = makeScenarioInfo(cfg,scenario); %#ok<NASGU>
        save(fullfile(scaleDir,'scenario_info.mat'),'cfg','scenarioInfo','seed','spec','-v7.3');

        for mi = 1:numel(methods)
            method = methods{mi};
            fprintf('[paper ablation] scale=%s seed=%d method=%s\n',spec.Name,seed,method);
            tic;
            [searchResult,result,methodMeta] = runAblationMethod(method,cfg,scenario);
            runtimeSeconds = toc;
            [Jtrue,trueDetails] = cf_compute_true_objective(result);

            methodDir = fullfile(scaleDir,methodToTag(method));
            if ~exist(methodDir,'dir')
                mkdir(methodDir);
            end
            lightResult = makeLightResult(result); %#ok<NASGU>
            lightSearchResult = makeLightSearchResult(searchResult); %#ok<NASGU>
            save(fullfile(methodDir,'result_light.mat'),'cfg','lightSearchResult', ...
                'lightResult','methodMeta','Jtrue','trueDetails','runtimeSeconds','-v7.3');
            writetable(searchResult.History,fullfile(methodDir,'search_history.csv'));
            writeCandidateTable(searchResult.BestCandidate,fullfile(methodDir,'best_candidate.csv'));

            rowIndex = rowIndex + 1;
            rawRows{rowIndex,1} = makeRawRow(spec,seed,method,methodMeta,cfg, ...
                searchResult,result,Jtrue,trueDetails,runtimeSeconds); %#ok<SAGROW>

            history = searchResult.History;
            for hi = 1:height(history)
                convIndex = convIndex + 1;
                convergenceRows{convIndex,1} = makeConvergenceRow(spec,seed,method, ...
                    methodMeta,cfg,history(hi,:)); %#ok<SAGROW>
            end
        end
    end
end

rawTable = struct2table(vertcat(rawRows{:}));
convergenceTable = struct2table(vertcat(convergenceRows{:}));
statisticsTable = buildStatistics(rawTable);
ablationTable = filterScale(rawTable,'S2');
if isempty(ablationTable)
    ablationTable = rawTable;
end
runtimeTable = rawTable(:,{'Scale','Seed','Method','MethodFamily','InnerEnabled', ...
    'NumDUs','NumUEs','NumRBGs','NumTxAntennas','Evaluations','RuntimeSeconds', ...
    'RuntimePerEvaluation','InnerIterations','J_true'});

writetable(ablationTable,fullfile(resultRoot,'ablation_comparison.csv'));
writetable(rawTable,fullfile(resultRoot,'scale_comparison.csv'));
writetable(statisticsTable,fullfile(resultRoot,'multiseed_statistics.csv'));
writetable(convergenceTable,fullfile(resultRoot,'convergence_comparison.csv'));
writetable(runtimeTable,fullfile(resultRoot,'runtime_comparison.csv'));
save(fullfile(resultRoot,'controlled_outer_ablation_results.mat'), ...
    'rawTable','statisticsTable','convergenceTable','runtimeTable','ablationTable','runInfo','-v7.3');

plotAlgorithmComparison(statisticsTable,fullfile(resultRoot,'fig1_algorithm_jtrue.png'));
plotScaleComparison(statisticsTable,fullfile(resultRoot,'fig2_jtrue_vs_trp.png'));
plotMeanStd(statisticsTable,fullfile(resultRoot,'fig3_multiseed_mean_std.png'));
plotConvergence(convergenceTable,fullfile(resultRoot,'fig4_convergence_curve.png'));
plotRuntimeTradeoff(statisticsTable,fullfile(resultRoot,'fig5_performance_vs_runtime.png'));
writeReport(statisticsTable,rawTable,runInfo,fullfile(resultRoot,'paper_ablation_report.md'));

fprintf('\nFinished controlled paper ablation.\n');
fprintf('Result folder: %s\n',resultRoot);
fprintf('Main CSV:      %s\n',fullfile(resultRoot,'multiseed_statistics.csv'));

function specs = controlledScaleSpecs()
specs = struct( ...
    'Name',{'S1','S2','S3','S4'}, ...
    'NumDUs',{4,8,12,16}, ...
    'NumUEs',{8,16,24,32});
end

function spec = findScaleSpec(specs,name)
idx = find(strcmpi({specs.Name},name),1);
if isempty(idx)
    error('Unknown controlled scale "%s". Use S1, S2, S3, or S4.',name);
end
spec = specs(idx);
end

function cfg = makeControlledConfig(spec,seed,numRBGs,numTx,numRx,innerMaxIter,maxEvaluations,populationSize,verboseSearch)
cfg = cf_default_config('standard');
cfg.profile = ['paper_ablation_' lower(spec.Name)];
cfg.numDUs = spec.NumDUs;
cfg.numUEs = spec.NumUEs;
cfg.numRBGs = numRBGs;
cfg.numTxAntennas = numTx;
cfg.numRxAntennas = numRx;
cfg.maxRank = min(2,numRx);
cfg.inner.maxIter = max(0,round(innerMaxIter));
cfg.search.maxEvaluations = max(1,round(maxEvaluations));
cfg.search.populationSize = min(max(1,round(populationSize)),cfg.search.maxEvaluations);
cfg.search.eliteCount = min(cfg.search.eliteCount,max(0,cfg.search.populationSize-1));
cfg.search.numConnectionsRange = [1 min(4,cfg.numDUs)];
cfg.search.maxRepairLinksRange = [0 min(4,cfg.numDUs*cfg.numRBGs)];
cfg.search.verbose = verboseSearch;
cfg.seedPosition = 1000 + seed;
cfg.seedChannel = 2000 + seed;
cfg.seedSearch = 3000 + seed;
cfg.traffic.seed = 4000 + seed;
if isfield(cfg,'measurement') && isfield(cfg.measurement,'seed')
    cfg.measurement.seed = 5000 + seed;
end
end

function [searchResult,result,info] = runAblationMethod(method,cfg,scenario)
methodKey = upper(strrep(char(method),' ',''));
candidate = cf_decode_candidate(cfg.defaultX,cfg);
info = decodeMethodInfo(methodKey);
switch methodKey
    case 'BASIC'
        result = cf_evaluate_candidate(cfg,scenario,candidate,false);
        searchResult = singleEvaluationResult(methodKey,cfg.defaultX,candidate,result,false);
    case 'INNER'
        result = cf_evaluate_candidate(cfg,scenario,candidate,true);
        searchResult = singleEvaluationResult(methodKey,cfg.defaultX,candidate,result,true);
    otherwise
        options = cfg.search;
        options.enableInnerOptimization = info.InnerEnabled;
        searchResult = cf_search(info.SearchMethod,cfg,scenario,options);
        result = searchResult.BestResult;
end
end

function info = decodeMethodInfo(methodKey)
info = struct();
info.InnerEnabled = true;
info.SearchMethod = '';
info.MethodFamily = 'baseline';
switch methodKey
    case 'BASIC'
        info.MethodFamily = 'basic';
        info.InnerEnabled = false;
    case 'INNER'
        info.MethodFamily = 'inner_only';
        info.InnerEnabled = true;
    case 'GA-ONLY'
        info.MethodFamily = 'outer_only';
        info.SearchMethod = 'GA';
        info.InnerEnabled = false;
    case 'PSO-ONLY'
        info.MethodFamily = 'outer_only';
        info.SearchMethod = 'PSO';
        info.InnerEnabled = false;
    case 'PGSAO-ONLY'
        info.MethodFamily = 'hybrid_outer_only';
        info.SearchMethod = 'PGSAO';
        info.InnerEnabled = false;
    case 'GA+INNER'
        info.MethodFamily = 'single_outer_inner';
        info.SearchMethod = 'GA';
    case 'PSO+INNER'
        info.MethodFamily = 'single_outer_inner';
        info.SearchMethod = 'PSO';
    case 'PGSAO+INNER'
        info.MethodFamily = 'hybrid_outer_inner';
        info.SearchMethod = 'PGSAO';
    otherwise
        error('Unknown ablation method "%s".',methodKey);
end
end

function searchResult = singleEvaluationResult(method,bestX,candidate,result,innerEnabled)
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
searchResult.InnerOptimizationEnabled = innerEnabled;
searchResult.History = table(1,result.Objective,result.Score,result.Objective,result.Score, ...
    'VariableNames',{'Evaluation','Objective','Score','BestObjective','BestScore'});
searchResult.EvaluationX = bestX;
searchResult.EvaluationScore = result.Score;
searchResult.EvaluationObjective = result.Objective;
searchResult.FinalPopulation = bestX;
searchResult.FinalObjectives = result.Objective;
searchResult.FinalScores = result.Score;
end

function row = makeRawRow(spec,seed,method,info,cfg,searchResult,result,Jtrue,trueDetails,runtimeSeconds)
row = struct();
row.Scale = {spec.Name};
row.Seed = seed;
row.Method = {method};
row.MethodFamily = {info.MethodFamily};
row.SearchMethod = {info.SearchMethod};
row.InnerEnabled = info.InnerEnabled;
row.NumDUs = cfg.numDUs;
row.NumUEs = cfg.numUEs;
row.NumRBGs = cfg.numRBGs;
row.NumTxAntennas = cfg.numTxAntennas;
row.NumRxAntennas = cfg.numRxAntennas;
row.MaxRankCfg = cfg.maxRank;
row.PopulationSize = cfg.search.populationSize;
row.MaxEvaluations = cfg.search.maxEvaluations;
row.Evaluations = searchResult.Evaluations;
row.InnerMaxIter = cfg.inner.maxIter;
row.InnerIterations = result.history.iterations;
row.InnerConverged = result.history.converged;
row.InnerStopReason = {result.history.stopReason};
row.RuntimeSeconds = runtimeSeconds;
row.RuntimePerEvaluation = runtimeSeconds / max(1,searchResult.Evaluations);
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
row.SeedPosition = cfg.seedPosition;
row.SeedChannel = cfg.seedChannel;
row.SeedSearch = cfg.seedSearch;
row.Best_betaPF = searchResult.BestCandidate.betaPF;
row.Best_numConnections = searchResult.BestCandidate.numConnections;
row.Best_scheduleThreshold = searchResult.BestCandidate.scheduleThreshold;
row.Best_rhoLink = searchResult.BestCandidate.rhoLink;
row.Best_rhoPower = searchResult.BestCandidate.rhoPower;
row.Best_maxRank = searchResult.BestCandidate.maxRank;
row.Best_rankThreshold = searchResult.BestCandidate.rankThreshold;
row.Best_repairPower = searchResult.BestCandidate.repairPower;
row.Best_maxRepairLinks = searchResult.BestCandidate.maxRepairLinks;
end

function row = makeConvergenceRow(spec,seed,method,info,cfg,h)
row = struct();
row.Scale = {spec.Name};
row.Seed = seed;
row.Method = {method};
row.MethodFamily = {info.MethodFamily};
row.InnerEnabled = info.InnerEnabled;
row.NumDUs = cfg.numDUs;
row.NumUEs = cfg.numUEs;
row.NumRBGs = cfg.numRBGs;
row.NumTxAntennas = cfg.numTxAntennas;
row.MaxEvaluations = cfg.search.maxEvaluations;
row.Evaluation = h.Evaluation;
row.Objective = h.Objective;
row.Score = h.Score;
row.BestObjective = h.BestObjective;
row.BestScore = h.BestScore;
end

function stats = buildStatistics(raw)
keys = unique(raw(:,{'Scale','Method'}),'rows','stable');
rows = cell(height(keys),1);
for i = 1:height(keys)
    mask = strcmp(raw.Scale,keys.Scale{i}) & strcmp(raw.Method,keys.Method{i});
    sub = raw(mask,:);
    x = sub.J_true;
    row = struct();
    row.Scale = keys.Scale(i);
    row.Method = keys.Method(i);
    row.MethodFamily = sub.MethodFamily(1);
    row.InnerEnabled = sub.InnerEnabled(1);
    row.NumDUs = sub.NumDUs(1);
    row.NumUEs = sub.NumUEs(1);
    row.NumRBGs = sub.NumRBGs(1);
    row.NumTxAntennas = sub.NumTxAntennas(1);
    row.NumRxAntennas = sub.NumRxAntennas(1);
    row.SeedCount = height(sub);
    row.J_true_mean = mean(x);
    row.J_true_std = std(x);
    row.J_true_median = median(x);
    row.J_true_best = max(x);
    row.J_true_worst = min(x);
    row.J_true_ci95 = 1.96 * row.J_true_std / sqrt(max(1,height(sub)));
    row.RuntimeSeconds_mean = mean(sub.RuntimeSeconds);
    row.RuntimeSeconds_std = std(sub.RuntimeSeconds);
    row.RuntimePerEvaluation_mean = mean(sub.RuntimePerEvaluation);
    row.Evaluations = mode(sub.Evaluations);
    row.MaxEvaluations = mode(sub.MaxEvaluations);
    row.InnerIterations_mean = mean(sub.InnerIterations);
    row.InnerMaxIter = mode(sub.InnerMaxIter);
    row.ActiveLinks_mean = mean(sub.ActiveLinks);
    row.TotalPower_mean = mean(sub.TotalPower);
    row.Jain_mean = mean(sub.Jain);
    rows{i} = row;
end
stats = struct2table(vertcat(rows{:}));
stats = addReferenceDeltas(stats);
end

function stats = addReferenceDeltas(stats)
stats.ImprovementVsInnerPct = nan(height(stats),1);
stats.ImprovementVsBasicPct = nan(height(stats),1);
stats.ImprovementVsHybridOnlyPct = nan(height(stats),1);
stats.ImprovementVsGAInnerPct = nan(height(stats),1);
stats.ImprovementVsPSOInnerPct = nan(height(stats),1);
for i = 1:height(stats)
    same = strcmp(stats.Scale,stats.Scale{i});
    stats.ImprovementVsBasicPct(i) = improvement(stats.J_true_mean(i),lookupMean(stats,same,'basic'));
    stats.ImprovementVsInnerPct(i) = improvement(stats.J_true_mean(i),lookupMean(stats,same,'inner'));
    stats.ImprovementVsHybridOnlyPct(i) = improvement(stats.J_true_mean(i),lookupMean(stats,same,'PGSAO-only'));
    stats.ImprovementVsGAInnerPct(i) = improvement(stats.J_true_mean(i),lookupMean(stats,same,'GA+Inner'));
    stats.ImprovementVsPSOInnerPct(i) = improvement(stats.J_true_mean(i),lookupMean(stats,same,'PSO+Inner'));
end
end

function base = lookupMean(stats,scaleMask,method)
idx = scaleMask & strcmp(stats.Method,method);
if any(idx)
    base = stats.J_true_mean(find(idx,1));
else
    base = NaN;
end
end

function pct = improvement(value,baseline)
if isnan(baseline)
    pct = NaN;
else
    pct = 100 * (value - baseline) / max(abs(baseline),eps);
end
end

function out = filterScale(t,scaleName)
out = t(strcmp(t.Scale,scaleName),:);
end

function info = makeScenarioInfo(cfg,scenario)
info = struct();
info.profile = cfg.profile;
info.numDUs = cfg.numDUs;
info.numUEs = cfg.numUEs;
info.numRBGs = cfg.numRBGs;
info.numTxAntennas = cfg.numTxAntennas;
info.numRxAntennas = cfg.numRxAntennas;
info.seedPosition = cfg.seedPosition;
info.seedChannel = cfg.seedChannel;
info.seedSearch = cfg.seedSearch;
info.channelNorm = norm(scenario.H(:));
info.distanceMean = mean(scenario.distance(:));
info.distanceMax = max(scenario.distance(:));
end

function lightResult = makeLightResult(result)
lightResult = struct();
fields = {'Candidate','Objective','Score','ScoreParts','SumRate','MeanRate','MinRate', ...
    'Rate5','Rate10','Jain','ActiveLinks','TotalPower','ActiveStreams','history', ...
    'ExperienceRate','Robust','Edge','TrueChannel'};
for i = 1:numel(fields)
    if isfield(result,fields{i})
        lightResult.(fields{i}) = result.(fields{i});
    end
end
end

function lightSearchResult = makeLightSearchResult(searchResult)
lightSearchResult = struct();
fields = {'Method','BestX','BestReducedX','ActiveDimensions','FixedX','BestCandidate', ...
    'BestScore','BestObjective','ObjectiveName','Evaluations','History', ...
    'InnerOptimizationEnabled','EvaluationScore','EvaluationObjective', ...
    'FinalObjectives','FinalScores'};
for i = 1:numel(fields)
    if isfield(searchResult,fields{i})
        lightSearchResult.(fields{i}) = searchResult.(fields{i});
    end
end
end

function writeCandidateTable(candidate,outFile)
names = fieldnames(candidate);
rows = cell(numel(names),2);
for i = 1:numel(names)
    rows{i,1} = names{i};
    value = candidate.(names{i});
    if isnumeric(value)
        rows{i,2} = mat2str(value,8);
    else
        rows{i,2} = char(string(value));
    end
end
writetable(cell2table(rows,'VariableNames',{'Parameter','Value'}),outFile);
end

function plotAlgorithmComparison(stats,outFile)
scaleMask = strcmp(stats.Scale,'S2');
if ~any(scaleMask)
    scaleMask = strcmp(stats.Scale,stats.Scale{1});
end
sub = stats(scaleMask,:);
fig = figure('Visible','off','Color','w','Position',[100 100 1100 560]);
bar(categorical(sub.Method),sub.J_true_mean);
grid on; xtickangle(35);
ylabel('J true mean');
title(sprintf('Algorithm comparison at %s',sub.Scale{1}),'Interpreter','none');
exportgraphics(fig,outFile,'Resolution',180);
close(fig);
end

function plotScaleComparison(stats,outFile)
fig = figure('Visible','off','Color','w','Position',[100 100 1100 620]);
hold on; grid on;
methods = unique(stats.Method,'stable');
for i = 1:numel(methods)
    sub = stats(strcmp(stats.Method,methods{i}),:);
    plot(sub.NumDUs,sub.J_true_mean,'-o','LineWidth',1.5,'DisplayName',methods{i});
end
xlabel('TRP / DU count'); ylabel('J true mean');
title('J true versus TRP scale','Interpreter','none');
legend('Location','bestoutside','Interpreter','none');
exportgraphics(fig,outFile,'Resolution',180);
close(fig);
end

function plotMeanStd(stats,outFile)
scaleMask = strcmp(stats.Scale,'S2');
if ~any(scaleMask)
    scaleMask = strcmp(stats.Scale,stats.Scale{1});
end
sub = stats(scaleMask,:);
fig = figure('Visible','off','Color','w','Position',[100 100 1100 560]);
errorbar(1:height(sub),sub.J_true_mean,sub.J_true_std,'o','LineWidth',1.5);
grid on; xlim([0 height(sub)+1]);
set(gca,'XTick',1:height(sub),'XTickLabel',sub.Method); xtickangle(35);
ylabel('J true mean +/- std');
title(sprintf('Multi-seed variation at %s',sub.Scale{1}),'Interpreter','none');
exportgraphics(fig,outFile,'Resolution',180);
close(fig);
end

function plotConvergence(conv,outFile)
fig = figure('Visible','off','Color','w','Position',[100 100 1100 620]);
hold on; grid on;
targetMethods = {'GA+Inner','PSO+Inner','PGSAO+Inner','PGSAO-only'};
for i = 1:numel(targetMethods)
    mask = strcmp(conv.Method,targetMethods{i}) & strcmp(conv.Scale,'S2');
    if ~any(mask)
        mask = strcmp(conv.Method,targetMethods{i});
    end
    if ~any(mask)
        continue;
    end
    sub = conv(mask,:);
    evals = unique(sub.Evaluation);
    y = zeros(numel(evals),1);
    for k = 1:numel(evals)
        y(k) = mean(sub.BestObjective(sub.Evaluation == evals(k)));
    end
    plot(evals,y,'-o','LineWidth',1.5,'DisplayName',targetMethods{i});
end
xlabel('Objective evaluations'); ylabel('Best-so-far J true');
title('Convergence comparison','Interpreter','none');
legend('Location','best','Interpreter','none');
exportgraphics(fig,outFile,'Resolution',180);
close(fig);
end

function plotRuntimeTradeoff(stats,outFile)
fig = figure('Visible','off','Color','w','Position',[100 100 1000 620]);
scatter(stats.RuntimeSeconds_mean,stats.J_true_mean,60,stats.NumDUs,'filled');
grid on; xlabel('Mean runtime seconds'); ylabel('J true mean');
title('Performance versus runtime','Interpreter','none');
text(stats.RuntimeSeconds_mean,stats.J_true_mean,stats.Method,'Interpreter','none', ...
    'VerticalAlignment','bottom','FontSize',8);
colorbar; exportgraphics(fig,outFile,'Resolution',180);
close(fig);
end

function writeReport(stats,raw,runInfo,outFile)
fid = fopen(outFile,'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'# Controlled Multi-TRP Outer Ablation Report\n\n');
fprintf(fid,'Created: %s\n\n',runInfo.CreatedAt);
fprintf(fid,'Objective: %s.\n\n',runInfo.Objective);
fprintf(fid,'Hybrid method: %s. Outer-only rows set `enableInnerOptimization=false`; outer+inner rows set it to true.\n\n',runInfo.HybridMethod);
fprintf(fid,'Budget: maxEvaluations=%d, populationSize=%d, innerMaxIter=%d, seeds=%s.\n\n', ...
    runInfo.MaxEvaluations,runInfo.PopulationSize,runInfo.InnerMaxIter,mat2str(runInfo.SeedList));
fprintf(fid,'## Stage Judgments\n\n');
for si = 1:numel(runInfo.ScaleNames)
    scale = runInfo.ScaleNames{si};
    sub = stats(strcmp(stats.Scale,scale),:);
    if isempty(sub)
        continue;
    end
    proposed = lookupMean(stats,strcmp(stats.Scale,scale),'PGSAO+Inner');
    inner = lookupMean(stats,strcmp(stats.Scale,scale),'inner');
    hybridOnly = lookupMean(stats,strcmp(stats.Scale,scale),'PGSAO-only');
    gaInner = lookupMean(stats,strcmp(stats.Scale,scale),'GA+Inner');
    psoInner = lookupMean(stats,strcmp(stats.Scale,scale),'PSO+Inner');
    basic = lookupMean(stats,strcmp(stats.Scale,scale),'basic');
    fprintf(fid,'- %s: PGSAO+Inner mean %.6g; vs inner %s; vs PGSAO-only %s; vs GA+Inner %s; vs PSO+Inner %s; vs basic %s.\n', ...
        scale,proposed,judgment(proposed,inner),judgment(proposed,hybridOnly), ...
        judgment(proposed,gaInner),judgment(proposed,psoInner),judgment(proposed,basic));
end
fprintf(fid,'\n## Files\n\n');
fprintf(fid,'- ablation_comparison.csv\n');
fprintf(fid,'- scale_comparison.csv\n');
fprintf(fid,'- multiseed_statistics.csv\n');
fprintf(fid,'- convergence_comparison.csv\n');
fprintf(fid,'- runtime_comparison.csv\n\n');
fprintf(fid,'Raw rows: %d.\n',height(raw));
end

function text = judgment(value,baseline)
if isnan(value) || isnan(baseline)
    text = 'not tested';
elseif value > baseline
    text = 'supports improvement';
elseif abs(value-baseline) <= 1e-10*max(1,abs(baseline))
    text = 'tied';
else
    text = 'not supported';
end
end

function tag = methodToTag(method)
tag = lower(strrep(strrep(method,'+','_'),'-','_'));
end

function value = getenvOrDefault(name,defaultValue)
value = getenv(name);
if isempty(value)
    value = defaultValue;
end
end

function list = parseList(raw)
parts = regexp(strtrim(raw),'[,\s]+','split');
list = parts(~cellfun('isempty',parts));
end

function values = parseNumericList(raw)
raw = strtrim(raw);
colonParts = regexp(raw,'^(\d+):(\d+)$','tokens','once');
if ~isempty(colonParts)
    values = str2double(colonParts{1}):str2double(colonParts{2});
    return;
end
parts = parseList(raw);
values = zeros(1,numel(parts));
for i = 1:numel(parts)
    values(i) = str2double(parts{i});
end
if isempty(values) || any(~isfinite(values))
    error('Seed list must be numeric, for example 1:10 or 1,2,3.');
end
values = unique(round(values),'stable');
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
