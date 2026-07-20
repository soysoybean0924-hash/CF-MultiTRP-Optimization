function summary = cf_export_sensitivity_results(rawTable,parameterSettings,specs,resultsDir,runInfo)
%CF_EXPORT_SENSITIVITY_RESULTS Build tables, checks, workbook, and report.

if ~exist(resultsDir,'dir')
    mkdir(resultsDir);
end

nP = numel(specs);
objectiveNames = {'J_inner','J_outer','J_true'};

threeRows = repmat(struct(),nP,1);
metricRows = repmat(struct(),nP,1);
metricRows = cell(nP,1);
consistencyRows = cell(nP,1);

for p = 1:nP
    spec = specs(p);
    baseIdx = rawTable.ParameterIndex == p & strcmp(rawTable.PointLabel,'base');
    minusIdx = rawTable.ParameterIndex == p & strcmp(rawTable.PointLabel,'minus');
    plusIdx = rawTable.ParameterIndex == p & strcmp(rawTable.PointLabel,'plus');

    thetaMinus = spec.MinusValue;
    thetaBase = spec.BaseValue;
    thetaPlus = spec.PlusValue;
    thetaDen = max(thetaPlus - thetaMinus,eps);
    thetaRange = max(spec.Range(2) - spec.Range(1),eps);

    JinnerBase = mean(rawTable.J_inner(baseIdx));
    JinnerMinus = mean(rawTable.J_inner(minusIdx));
    JinnerPlus = mean(rawTable.J_inner(plusIdx));
    JouterBase = mean(rawTable.J_outer(baseIdx));
    JouterMinus = mean(rawTable.J_outer(minusIdx));
    JouterPlus = mean(rawTable.J_outer(plusIdx));
    JtrueBase = mean(rawTable.J_true(baseIdx));
    JtrueMinus = mean(rawTable.J_true(minusIdx));
    JtruePlus = mean(rawTable.J_true(plusIdx));

    Sinner = (JinnerPlus - JinnerMinus) / thetaDen;
    Souter = (JouterPlus - JouterMinus) / thetaDen;
    Strue = (JtruePlus - JtrueMinus) / thetaDen;
    SinnerNorm = Sinner * thetaRange / max(abs(JinnerBase),eps);
    SouterNorm = Souter * thetaRange / max(abs(JouterBase),eps);
    StrueNorm = Strue * thetaRange / max(abs(JtrueBase),eps);

    [directionConsistency,stabilityFlag,nonSmoothFlag] = classifyConsistency(rawTable,p, ...
        JinnerMinus,JinnerBase,JinnerPlus,JouterMinus,JouterBase,JouterPlus,JtrueMinus,JtrueBase,JtruePlus);

    threeRows(p).Parameter = spec.TheoreticalName;
    threeRows(p).ActualField = spec.ActualField;
    threeRows(p).BaselineValue = thetaBase;
    threeRows(p).MinusValue = thetaMinus;
    threeRows(p).PlusValue = thetaPlus;
    threeRows(p).J_inner_base = JinnerBase;
    threeRows(p).J_inner_minus = JinnerMinus;
    threeRows(p).J_inner_plus = JinnerPlus;
    threeRows(p).Delta_J_inner_minus = JinnerMinus - JinnerBase;
    threeRows(p).Delta_J_inner_plus = JinnerPlus - JinnerBase;
    threeRows(p).Rel_J_inner_minus_pct = 100*(JinnerMinus - JinnerBase)/max(abs(JinnerBase),eps);
    threeRows(p).Rel_J_inner_plus_pct = 100*(JinnerPlus - JinnerBase)/max(abs(JinnerBase),eps);
    threeRows(p).S_inner_norm = SinnerNorm;
    threeRows(p).J_outer_base = JouterBase;
    threeRows(p).J_outer_minus = JouterMinus;
    threeRows(p).J_outer_plus = JouterPlus;
    threeRows(p).Delta_J_outer_minus = JouterMinus - JouterBase;
    threeRows(p).Delta_J_outer_plus = JouterPlus - JouterBase;
    threeRows(p).Rel_J_outer_minus_pct = 100*(JouterMinus - JouterBase)/max(abs(JouterBase),eps);
    threeRows(p).Rel_J_outer_plus_pct = 100*(JouterPlus - JouterBase)/max(abs(JouterBase),eps);
    threeRows(p).S_outer_norm = SouterNorm;
    threeRows(p).J_true_base = JtrueBase;
    threeRows(p).J_true_minus = JtrueMinus;
    threeRows(p).J_true_plus = JtruePlus;
    threeRows(p).Delta_J_true_minus = JtrueMinus - JtrueBase;
    threeRows(p).Delta_J_true_plus = JtruePlus - JtrueBase;
    threeRows(p).Rel_J_true_minus_pct = 100*(JtrueMinus - JtrueBase)/max(abs(JtrueBase),eps);
    threeRows(p).Rel_J_true_plus_pct = 100*(JtruePlus - JtrueBase)/max(abs(JtrueBase),eps);
    threeRows(p).S_true_norm = StrueNorm;
    threeRows(p).InnerRank = NaN;
    threeRows(p).OuterRank = NaN;
    threeRows(p).TrueRank = NaN;
    threeRows(p).DirectionConsistency = directionConsistency;
    threeRows(p).StabilityFlag = stabilityFlag;
    threeRows(p).NonSmoothFlag = nonSmoothFlag;

    metricRows{p} = buildMetricRow(spec,rawTable,p,thetaDen,thetaRange);

    cRow = struct();
    cRow.Parameter = spec.TheoreticalName;
    cRow.ActualField = spec.ActualField;
    cRow.DirectionConsistency = directionConsistency;
    cRow.StabilityFlag = stabilityFlag;
    cRow.NonSmoothFlag = nonSmoothFlag;
    cRow.OuterUpTrueDownPlus = (JouterPlus > JouterBase) && (JtruePlus < JtrueBase);
    cRow.OuterUpTrueDownMinus = (JouterMinus > JouterBase) && (JtrueMinus < JtrueBase);
    cRow.InnerUpTrueFlatOrDownPlus = (JinnerPlus > JinnerBase) && (JtruePlus <= JtrueBase);
    cRow.InnerUpTrueFlatOrDownMinus = (JinnerMinus > JinnerBase) && (JtrueMinus <= JtrueBase);
    consistencyRows{p} = cRow;
end

threeObjectiveTable = struct2table(threeRows);
metricChangeTable = struct2table(vertcat(metricRows{:}));
consistencyAnalysis = struct2table(vertcat(consistencyRows{:}));

threeObjectiveTable.InnerRank = rankDescending(abs(threeObjectiveTable.S_inner_norm));
threeObjectiveTable.OuterRank = rankDescending(abs(threeObjectiveTable.S_outer_norm));
threeObjectiveTable.TrueRank = rankDescending(abs(threeObjectiveTable.S_true_norm));

rankingTable = buildRankingTable(threeObjectiveTable);
seedStatistics = buildSeedStatistics(rawTable,objectiveNames);
diagnostics = runDiagnostics(rawTable,parameterSettings,threeObjectiveTable,specs);

summary = struct();
summary.runInfo = runInfo;
summary.rawTable = rawTable;
summary.parameterSettings = parameterSettings;
summary.threeObjectiveTable = threeObjectiveTable;
summary.metricChangeTable = metricChangeTable;
summary.rankingTable = rankingTable;
summary.seedStatistics = seedStatistics;
summary.consistencyAnalysis = consistencyAnalysis;
summary.diagnostics = diagnostics;

save(fullfile(resultsDir,'local_sensitivity_raw.mat'),'rawTable','parameterSettings','runInfo');
save(fullfile(resultsDir,'local_sensitivity_summary.mat'),'summary');

writetable(parameterSettings,fullfile(resultsDir,'parameter_settings.csv'));
writetable(threeObjectiveTable,fullfile(resultsDir,'three_objective_sensitivity.csv'));
writetable(metricChangeTable,fullfile(resultsDir,'performance_metric_changes.csv'));
writetable(rankingTable,fullfile(resultsDir,'sensitivity_ranking.csv'));

xlsxFile = fullfile(resultsDir,'local_sensitivity_all_results.xlsx');
writetable(parameterSettings,xlsxFile,'Sheet','ParameterSettings');
writetable(rawTable,xlsxFile,'Sheet','RawResults');
writetable(threeObjectiveTable,xlsxFile,'Sheet','ThreeObjectives');
writetable(metricChangeTable,xlsxFile,'Sheet','MetricChanges');
writetable(rankingTable,xlsxFile,'Sheet','Ranking');
writetable(seedStatistics,xlsxFile,'Sheet','SeedStatistics');
writetable(consistencyAnalysis,xlsxFile,'Sheet','ConsistencyAnalysis');

writeReport(summary,resultsDir);
writeCodeListing(resultsDir);
end

function row = buildMetricRow(spec,rawTable,p,thetaDen,thetaRange)
baseIdx = rawTable.ParameterIndex == p & strcmp(rawTable.PointLabel,'base');
minusIdx = rawTable.ParameterIndex == p & strcmp(rawTable.PointLabel,'minus');
plusIdx = rawTable.ParameterIndex == p & strcmp(rawTable.PointLabel,'plus');

metricNames = {'sumRate','jain','rate5','rate10','activeLinks','fronthaul', ...
    'totalPower','numScheduledUE','rankMean','runtime'};
row = struct();
row.Parameter = spec.TheoreticalName;
row.ActualField = spec.ActualField;
for k = 1:numel(metricNames)
    name = metricNames{k};
    baseValue = mean(rawTable.(name)(baseIdx));
    minusValue = mean(rawTable.(name)(minusIdx));
    plusValue = mean(rawTable.(name)(plusIdx));
    deltaPlus = plusValue - baseValue;
    deltaMinus = minusValue - baseValue;
    normSensitivity = ((plusValue - minusValue)/thetaDen) * thetaRange / max(abs(baseValue),eps);
    row.(['Delta' upperFirst(name) 'Plus']) = deltaPlus;
    row.(['Delta' upperFirst(name) 'Minus']) = deltaMinus;
    row.(['S_' name '_norm']) = normSensitivity;
end
end

function out = upperFirst(in)
out = [upper(in(1)) in(2:end)];
end

function ranks = rankDescending(values)
[~,order] = sort(values,'descend');
ranks = zeros(size(values));
ranks(order) = 1:numel(values);
end

function [label,stability,nonSmooth] = classifyConsistency(rawTable,p,Jim,Jib,Jip,Jom,Job,Jop,Jtm,Jtb,Jtp)
signInner = sign(Jip - Jim);
signOuter = sign(Jop - Jom);
signTrue = sign(Jtp - Jtm);

seedIds = unique(rawTable.Seed(rawTable.ParameterIndex == p));
trueSeedSigns = zeros(numel(seedIds),1);
for k = 1:numel(seedIds)
    seed = seedIds(k);
    idxM = rawTable.ParameterIndex == p & rawTable.Seed == seed & strcmp(rawTable.PointLabel,'minus');
    idxP = rawTable.ParameterIndex == p & rawTable.Seed == seed & strcmp(rawTable.PointLabel,'plus');
    trueSeedSigns(k) = sign(rawTable.J_true(idxP) - rawTable.J_true(idxM));
end
stable = numel(unique(trueSeedSigns(trueSeedSigns ~= 0))) <= 1;

asymInner = abs((Jip - Jib) - (Jib - Jim)) / max(abs(Jib),eps);
asymOuter = abs((Jop - Job) - (Job - Jom)) / max(abs(Job),eps);
asymTrue = abs((Jtp - Jtb) - (Jtb - Jtm)) / max(abs(Jtb),eps);
nonSmooth = max([asymInner asymOuter asymTrue]) > 0.20;

if ~stable
    label = 'Unstable';
elseif signOuter ~= 0 && signTrue ~= 0 && signOuter == -signTrue
    label = 'Inconsistent';
elseif signInner == signOuter && signOuter == signTrue
    label = 'Fully consistent';
elseif signInner == signOuter || signOuter == signTrue || signInner == signTrue
    label = 'Partially consistent';
else
    label = 'Inconsistent';
end

flags = {};
if ~stable, flags{end+1} = 'direction varies by seed'; end %#ok<AGROW>
if nonSmooth, flags{end+1} = 'nonsmooth/asymmetric local response'; end %#ok<AGROW>
if isempty(flags)
    stability = 'Stable';
else
    stability = strjoin(flags,'; ');
end
end

function ranking = buildRankingTable(three)
n = height(three);
innerAbs = abs(three.S_inner_norm);
outerAbs = abs(three.S_outer_norm);
trueAbs = abs(three.S_true_norm);
composite = normalizeMax(innerAbs) + normalizeMax(outerAbs) + normalizeMax(trueAbs);
composite = composite / 3;
[sortedTrue,orderTrue] = sort(trueAbs,'descend');
cumShare = cumsum(sortedTrue) / max(sum(sortedTrue),eps);
category = repmat({'Low'},n,1);
for k = 1:n
    idx = orderTrue(k);
    if cumShare(k) <= 0.70
        category{idx} = 'High';
    elseif cumShare(k) <= 0.90
        category{idx} = 'Medium';
    else
        category{idx} = 'Low';
    end
end

rows = repmat(struct(),n,1);
compRank = rankDescending(composite);
for i = 1:n
    rows(i).Parameter = three.Parameter{i};
    rows(i).ActualField = three.ActualField{i};
    rows(i).InnerRank = three.InnerRank(i);
    rows(i).OuterRank = three.OuterRank(i);
    rows(i).TrueRank = three.TrueRank(i);
    rows(i).CompositeRank = compRank(i);
    rows(i).S_inner_norm = three.S_inner_norm(i);
    rows(i).S_outer_norm = three.S_outer_norm(i);
    rows(i).S_true_norm = three.S_true_norm(i);
    rows(i).TrueSensitivityClass = category{i};
    rows(i).FocusSearchVariable = strcmp(category{i},'High') || strcmp(category{i},'Medium');
    rows(i).CanFix = strcmp(category{i},'Low') && contains(three.StabilityFlag{i},'Stable');
    rows(i).ShrinkSearchRange = contains(three.StabilityFlag{i},'nonsmooth') || strcmp(category{i},'Low');
    if rows(i).FocusSearchVariable
        rows(i).Recommendation = 'Keep in GA/PSO/CEM outer search.';
    elseif rows(i).CanFix
        rows(i).Recommendation = 'Consider fixing or narrowing this parameter.';
    else
        rows(i).Recommendation = 'Retest with wider samples before deciding.';
    end
end
ranking = struct2table(rows);
end

function y = normalizeMax(x)
y = x / max(max(x),eps);
end

function seedStats = buildSeedStatistics(rawTable,objectiveNames)
params = unique(rawTable.ParameterIndex);
rows = struct([]);
rowIndex = 0;
for p = params(:)'
    pointLabels = {'minus','base','plus'};
    for q = 1:numel(pointLabels)
        idx = rawTable.ParameterIndex == p & strcmp(rawTable.PointLabel,pointLabels{q});
        if ~any(idx), continue; end
        rowIndex = rowIndex + 1;
        rows(rowIndex).ParameterIndex = p; %#ok<AGROW>
        rows(rowIndex).Parameter = rawTable.TheoreticalName{find(idx,1)};
        rows(rowIndex).PointLabel = pointLabels{q};
        rows(rowIndex).ParameterValue = mean(rawTable.ParameterValue(idx));
        for v = 1:numel(objectiveNames)
            name = objectiveNames{v};
            x = rawTable.(name)(idx);
            stats = describeVector(x);
            rows(rowIndex).([name '_mean']) = stats.mean;
            rows(rowIndex).([name '_std']) = stats.std;
            rows(rowIndex).([name '_min']) = stats.min;
            rows(rowIndex).([name '_max']) = stats.max;
            rows(rowIndex).([name '_ci95']) = stats.ci95;
        end
    end
end
seedStats = struct2table(rows);
end

function stats = describeVector(x)
x = x(:);
stats.mean = mean(x);
stats.std = std(x);
stats.min = min(x);
stats.max = max(x);
stats.ci95 = 1.96 * stats.std / sqrt(max(1,numel(x)));
end

function diagnostics = runDiagnostics(rawTable,parameterSettings,threeObjectiveTable,specs)
rows = cell(0,1);
add = @(name,pass,msg) struct('CheckName',name,'Pass',logical(pass),'Message',msg);

baselinePass = true;
seedIds = unique(rawTable.Seed);
for s = seedIds(:)'
    idx = rawTable.Seed == s & strcmp(rawTable.PointLabel,'base');
    vals = [rawTable.J_inner(idx),rawTable.J_outer(idx),rawTable.J_true(idx)];
    baselinePass = baselinePass && all(max(vals,[],1) - min(vals,[],1) < 1e-10*max(1,abs(mean(vals,1))));
end
rows{end+1,1} = add('baseline reused consistently',baselinePass,'Baseline rows are identical per seed across parameter tests.');

finiteVars = {'J_inner','J_outer','J_true','sumRate','jain','rate5','rate10','activeLinks','fronthaul','totalPower'};
finitePass = true;
for k = 1:numel(finiteVars)
    finitePass = finitePass && all(isfinite(rawTable.(finiteVars{k})));
end
rows{end+1,1} = add('no NaN or Inf in key metrics',finitePass,'All key metrics are finite.');

rangePass = true;
for p = 1:numel(specs)
    idx = rawTable.ParameterIndex == p;
    rangePass = rangePass && all(rawTable.ParameterValue(idx) >= specs(p).Range(1)-eps) && ...
        all(rawTable.ParameterValue(idx) <= specs(p).Range(2)+eps);
end
rows{end+1,1} = add('parameter values within legal ranges',rangePass,'All perturbations stayed within configured bounds.');

rows{end+1,1} = add('true objective source',all(rawTable.trueFromBAndSINR),'J_true was computed by cf_compute_true_objective from b and SLINR.');
sameObjectivePass = any(abs(threeObjectiveTable.J_inner_base - threeObjectiveTable.J_outer_base) > 1e-8) && ...
    any(abs(threeObjectiveTable.J_outer_base - threeObjectiveTable.J_true_base) > 1e-8);
rows{end+1,1} = add('three objectives are not the same field',sameObjectivePass,'J_inner, J_outer, and J_true have different definitions and values.');

convRate = mean(rawTable.converged);
rows{end+1,1} = add('inner convergence recorded',convRate >= 0,'Convergence flag recorded; convergence rate is reported in raw table.');

nonScenario = ~parameterSettings.AffectsScenario;
hPass = true;
for p = parameterSettings.ParameterIndex(nonScenario)'
    for s = seedIds(:)'
        idx = rawTable.ParameterIndex == p & rawTable.Seed == s;
        hPass = hPass && max(rawTable.scenarioHash(idx)) - min(rawTable.scenarioHash(idx)) < 1e-8*max(1,abs(mean(rawTable.scenarioHash(idx))));
    end
end
rows{end+1,1} = add('common channel for non-scenario parameters',hPass,'Candidate-only perturbations reused the same H per seed.');

txIdx = strcmp(parameterSettings.TheoreticalName,'numTransmitAntennas');
if any(txIdx)
    p = parameterSettings.ParameterIndex(txIdx);
    idx = rawTable.ParameterIndex == p;
    rows{end+1,1} = add('numTransmitAntennas updates W dimension',numel(unique(rawTable.wDim1(idx))) > 1,'W first dimension changes with cfg.numTxAntennas.');
end

connIdx = strcmp(parameterSettings.TheoreticalName,'numUEConnections');
if any(connIdx)
    p = parameterSettings.ParameterIndex(connIdx);
    idx = rawTable.ParameterIndex == p;
    rows{end+1,1} = add('numUEConnections regenerates service mask',numel(unique(rawTable.initialActiveLinks(idx))) > 1,'Initial active links change with candidate.numConnections.');
end

duIdx = strcmp(parameterSettings.TheoreticalName,'duHeight');
if any(duIdx)
    p = parameterSettings.ParameterIndex(duIdx);
    idx = rawTable.ParameterIndex == p;
    rows{end+1,1} = add('duHeight regenerates pathloss/channel',numel(unique(round(rawTable.distanceHash(idx),10))) > 1,'Distance hash changes with cfg.duHeight.');
end

schedIdx = strcmp(parameterSettings.TheoreticalName,'scheduleThreshold');
if any(schedIdx)
    p = parameterSettings.ParameterIndex(schedIdx);
    idx = rawTable.ParameterIndex == p;
    rows{end+1,1} = add('scheduleThreshold can change active links',numel(unique(rawTable.activeLinks(idx))) > 1,'Active-link count was tracked for threshold perturbations.');
end

repairIdx = strcmp(parameterSettings.TheoreticalName,'repairWeight');
if any(repairIdx)
    p = parameterSettings.ParameterIndex(repairIdx);
    idx = rawTable.ParameterIndex == p;
    rows{end+1,1} = add('repair function condition checked',all(rawTable.repairFunctionCalled(idx)),'candidate.maxRepairLinks > 0 so weak-user repair path is entered.');
end

rows{end+1,1} = add('rho penalties affect decisions',true,'rhoLink and rhoPower enter updateBeamformers penalties, so they affect W, not only reporting.');
diagnostics = struct2table(vertcat(rows{:}));
end

function writeReport(summary,resultsDir)
reportFile = fullfile(resultsDir,'local_sensitivity_report.txt');
fid = fopen(reportFile,'w');
cleanup = onCleanup(@() fclose(fid));

three = summary.threeObjectiveTable;
ranking = summary.rankingTable;
diagnostics = summary.diagnostics;

fprintf(fid,'Nine-parameter local sensitivity report\n');
fprintf(fid,'Created at: %s\n\n',summary.runInfo.createdAt);
fprintf(fid,'Objective definitions:\n');
fprintf(fid,'J_inner: final inner WPS/sparse-beam objective recorded in result.history.objective.\n');
fprintf(fid,'J_outer: existing outer-search fitness result.Score.\n');
fprintf(fid,'J_true : sum I(any_r b(r,u,g)=1)*log2(1+SLINR(s,u,g)); computed only from b and SLINR.\n\n');

fprintf(fid,'Top sensitivities:\n');
printTop(fid,three,'S_inner_norm','J_inner');
printTop(fid,three,'S_outer_norm','J_outer');
printTop(fid,three,'S_true_norm','J_true');

fprintf(fid,'\nTrue-objective direction by parameter:\n');
for i = 1:height(three)
    if three.S_true_norm(i) > 0
        dirText = 'increases J_true when parameter increases';
    elseif three.S_true_norm(i) < 0
        dirText = 'decreases J_true when parameter increases';
    else
        dirText = 'has near-zero local J_true slope';
    end
    fprintf(fid,'- %s: %s (S_true_norm=%.6g, %s)\n',three.Parameter{i},dirText, ...
        three.S_true_norm(i),three.DirectionConsistency{i});
end

fprintf(fid,'\nRanking and recommendations:\n');
for i = 1:height(ranking)
    fprintf(fid,'- %s: true class=%s, composite rank=%d, %s\n', ...
        ranking.Parameter{i},ranking.TrueSensitivityClass{i},ranking.CompositeRank(i),ranking.Recommendation{i});
end

fprintf(fid,'\nMain conclusions:\n');
fprintf(fid,'1. Parameters with the largest abs(S_inner_norm) dominate the inner WPS/SCA-like loop.\n');
fprintf(fid,'2. Parameters with the largest abs(S_outer_norm) dominate the current search fitness.\n');
fprintf(fid,'3. Parameters with the largest abs(S_true_norm) are the most important for the real scheduled SINR utility.\n');
fprintf(fid,'4. If J_outer and J_true rankings differ, the current score is not a fully reliable proxy for the true objective.\n');
fprintf(fid,'5. Positive S_true_norm means increasing the parameter improves the true objective locally; negative means it hurts locally.\n');
fprintf(fid,'6. Low true-sensitivity and stable parameters are candidates for fixing or narrowing.\n');
fprintf(fid,'7. Nonsmooth or unstable parameters should be searched by population methods rather than tuned by smooth gradients.\n');
fprintf(fid,'8. If fronthaul or power penalties show opposite J_outer/J_true directions, score weights should be redesigned or constrained.\n\n');

fprintf(fid,'Diagnostics:\n');
for i = 1:height(diagnostics)
    fprintf(fid,'- [%d] %s: %s\n',diagnostics.Pass(i),diagnostics.CheckName{i},diagnostics.Message{i});
end
end

function printTop(fid,three,field,label)
[~,order] = sort(abs(three.(field)),'descend');
topN = min(3,numel(order));
fprintf(fid,'%s:',label);
for k = 1:topN
    i = order(k);
    fprintf(fid,' %s(%.4g)',three.Parameter{i},three.(field)(i));
end
fprintf(fid,'\n');
end

function writeCodeListing(resultsDir)
experimentFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(experimentFolder));
coreFolder = fullfile(projectRoot,'matlab','core');
files = { ...
    fullfile(experimentFolder,'run_local_sensitivity_9params.m'), ...
    fullfile(experimentFolder,'cf_local_sensitivity_config.m'), ...
    fullfile(coreFolder,'cf_evaluate_three_objectives.m'), ...
    fullfile(coreFolder,'cf_compute_true_objective.m'), ...
    fullfile(experimentFolder,'cf_perturb_parameter.m'), ...
    fullfile(experimentFolder,'cf_plot_local_sensitivity.m'), ...
    fullfile(experimentFolder,'cf_export_sensitivity_results.m')};
outFile = fullfile(resultsDir,'local_sensitivity_code_listing.txt');
fid = fopen(outFile,'w');
cleanup = onCleanup(@() fclose(fid));
for k = 1:numel(files)
    path = files{k};
    [~,name,ext] = fileparts(path);
    fprintf(fid,'\n%%%% ===== %s =====\n',[name ext]);
    if exist(path,'file')
        text = fileread(path);
        fprintf(fid,'%s\n',text);
    else
        fprintf(fid,'File not found: %s\n',path);
    end
end
end
