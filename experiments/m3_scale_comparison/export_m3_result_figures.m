function export_m3_result_figures(resultRoot)
%EXPORT_M3_RESULT_FIGURES Export M3 comparison plots and a markdown summary.
if nargin < 1 || isempty(resultRoot)
    projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    resultRoot = fullfile(projectRoot,'results','M3_true_objective_comparison');
end

figDir = fullfile(resultRoot,'figures');
if ~exist(figDir,'dir')
    mkdir(figDir);
end

fullTable = loadOrBuildFullSummary(resultRoot);
reducedFile = fullfile(resultRoot,'m3_reduced3','reduced_algorithm_comparison.csv');
if exist(reducedFile,'file')
    reducedTable = readtable(reducedFile,'TextType','string');
else
    reducedTable = table();
end

sensitivityFile = fullfile(resultRoot,'m3_local_sensitivity','sensitivity_ranking.csv');
threeObjectiveFile = fullfile(resultRoot,'m3_local_sensitivity','three_objective_sensitivity.csv');
if exist(sensitivityFile,'file')
    sensitivityTable = readtable(sensitivityFile,'TextType','string');
else
    sensitivityTable = table();
end
if exist(threeObjectiveFile,'file')
    threeObjectiveTable = readtable(threeObjectiveFile,'TextType','string');
else
    threeObjectiveTable = table();
end

if ~isempty(fullTable)
    m3Full = fullTable(strcmp(string(fullTable.Profile),'m3'),:);
    if ~isempty(m3Full)
        plotAlgorithmBars(m3Full,fullfile(figDir,'fig_m3_full9_algorithm_comparison.png'), ...
            'M3 full 9-D true-objective comparison');
    end
end
if ~isempty(reducedTable)
    plotAlgorithmBars(reducedTable,fullfile(figDir,'fig_m3_reduced3_algorithm_comparison.png'), ...
        'M3 reduced 3-D true-objective comparison');
end
if ~isempty(threeObjectiveTable)
    plotSensitivityBars(threeObjectiveTable,fullfile(figDir,'fig_m3_parameter_sensitivity_all.png'));
end

writeMarkdownSummary(fullTable,reducedTable,sensitivityTable,threeObjectiveTable, ...
    fullfile(resultRoot,'M3_results_summary.md'));
fprintf('M3 figures and summary exported under %s\n',resultRoot);
end

function summaryTable = loadOrBuildFullSummary(resultRoot)
summaryFile = fullfile(resultRoot,'algorithm_profile_comparison.csv');
if exist(summaryFile,'file')
    summaryTable = readtable(summaryFile,'TextType','string');
    return;
end
files = dir(fullfile(resultRoot,'*','*','search_result.mat'));
rows = cell(0,1);
rowIndex = 0;
for i = 1:numel(files)
    f = fullfile(files(i).folder,files(i).name);
    rel = extractAfter(string(f),string(resultRoot) + filesep);
    parts = split(rel,filesep);
    if numel(parts) < 3
        continue;
    end
    profile = char(parts(1));
    if strcmp(profile,'m3_reduced3') || strcmp(profile,'m3_local_sensitivity')
        continue;
    end
    method = char(parts(2));
    s = load(f,'cfg','searchResult','result','Jtrue','trueDetails','runtimeSeconds');
    rowIndex = rowIndex + 1;
    rows{rowIndex,1} = makeRow(profile,method,s.cfg,s.searchResult,s.result, ...
        s.Jtrue,s.trueDetails,s.runtimeSeconds); %#ok<AGROW>
end
if isempty(rows)
    summaryTable = table();
else
    summaryTable = struct2table(vertcat(rows{:}));
    writetable(summaryTable,summaryFile);
end
end

function row = makeRow(profile,method,cfg,searchResult,result,Jtrue,trueDetails,runtimeSeconds)
row = struct();
row.Profile = profile;
row.Method = method;
row.NumDUs = cfg.numDUs;
row.NumUEs = cfg.numUEs;
row.NumRBGs = cfg.numRBGs;
row.NumTxAntennas = cfg.numTxAntennas;
row.NumRxAntennas = cfg.numRxAntennas;
row.InnerMaxIter = cfg.inner.maxIter;
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

function plotAlgorithmBars(t,outFile,plotTitle)
[~,order] = sort(string(t.Method));
t = t(order,:);
fig = figure('Visible','off','Color','w','Position',[100 100 1200 760]);
layout = tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
plotOne(nexttile(layout),t.Method,t.SumRate,'SumRate');
plotOne(nexttile(layout),t.Method,t.BestScore,'BestScore');
plotOne(nexttile(layout),t.Method,t.Jain,'Jain index');
plotOne(nexttile(layout),t.Method,t.RuntimeSeconds,'Runtime seconds');
title(layout,plotTitle,'Interpreter','none');
exportgraphics(fig,outFile,'Resolution',180);
close(fig);
end

function plotOne(ax,labels,values,yText)
bar(ax,categorical(labels),values);
grid(ax,'on');
ylabel(ax,strrep(yText,'BestScore','Objective'));
xtickangle(ax,30);
end

function plotSensitivityBars(t,outFile)
[~,order] = sort(abs(t.S_true_norm),'descend');
t = t(order,:);
fig = figure('Visible','off','Color','w','Position',[100 100 1300 760]);
layout = tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');
plotOne(nexttile(layout),t.Parameter,abs(t.S_inner_norm),'|S inner norm|');
plotOne(nexttile(layout),t.Parameter,abs(t.S_outer_norm),'|S outer norm|');
plotOne(nexttile(layout),t.Parameter,abs(t.S_true_norm),'|S true norm|');
title(layout,'M3 local sensitivity ranking','Interpreter','none');
exportgraphics(fig,outFile,'Resolution',180);
close(fig);
end

function writeMarkdownSummary(fullTable,reducedTable,sensitivityTable,threeObjectiveTable,outFile)
fid = fopen(outFile,'w');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'# M3 Results Summary\n\n');
fprintf(fid,'Generated at: %s\n\n',datestr(now,31));
fprintf(fid,'M3 scale: 7 DUs, 100 UEs, 100 RBGs, 2x12 MIMO.\n\n');
fprintf(fid,'Optimization objective: maximize J_true = scheduled sum log2(1+SINR), matching the max objective in the reference figure.\n');
fprintf(fid,'Jain, ActiveLinks, TotalPower, and runtime are reported only as evaluation metrics.\n\n');

writeTableSection(fid,'Full 9-D M3 Algorithm Comparison',filterProfile(fullTable,'m3'));
if ~isempty(threeObjectiveTable)
    fprintf(fid,'## Local Sensitivity Ranking\n\n');
    [~,order] = sort(abs(threeObjectiveTable.S_true_norm),'descend');
    st = threeObjectiveTable(order,:);
    fprintf(fid,'| Rank | Parameter | Actual field | S_inner_norm | S_outer_norm | S_true_norm |\n');
    fprintf(fid,'|---:|---|---|---:|---:|---:|\n');
    for i = 1:height(st)
        fprintf(fid,'| %d | %s | %s | %.6g | %.6g | %.6g |\n',i, ...
            st.Parameter(i),st.ActualField(i),st.S_inner_norm(i), ...
            st.S_outer_norm(i),st.S_true_norm(i));
    end
    fprintf(fid,'\n');
end
if ~isempty(sensitivityTable)
    focusMask = toLogicalColumn(sensitivityTable.FocusSearchVariable);
    focus = sensitivityTable(focusMask,:);
    if ~isempty(focus)
        fprintf(fid,'Most sensitive parameters by ranking recommendation: %s.\n\n', ...
            strjoin(cellstr(focus.Parameter),', '));
    end
end

function mask = toLogicalColumn(values)
if islogical(values)
    mask = values;
elseif isnumeric(values)
    mask = values ~= 0;
else
    mask = strcmpi(string(values),'true') | strcmp(string(values),'1');
end
end
writeTableSection(fid,'Reduced 3-D M3 Algorithm Comparison',reducedTable);
fprintf(fid,'## Figures\n\n');
fprintf(fid,'- figures/fig_m3_full9_algorithm_comparison.png\n');
fprintf(fid,'- figures/fig_m3_parameter_sensitivity_all.png\n');
fprintf(fid,'- figures/fig_m3_reduced3_algorithm_comparison.png\n');
end

function out = filterProfile(t,profile)
if isempty(t)
    out = t;
else
    out = t(strcmp(string(t.Profile),profile),:);
end
end

function writeTableSection(fid,titleText,t)
fprintf(fid,'## %s\n\n',titleText);
if isempty(t)
    fprintf(fid,'No results available yet.\n\n');
    return;
end
fprintf(fid,'| Method | Eval | InnerIter | Objective | J_true | SumRate | Jain | ActiveLinks | RuntimeSeconds |\n');
fprintf(fid,'|---|---:|---:|---:|---:|---:|---:|---:|---:|\n');
for i = 1:height(t)
    fprintf(fid,'| %s | %d | %d | %.6g | %.6g | %.6g | %.4f | %d | %.3f |\n', ...
        t.Method(i),t.Evaluations(i),t.InnerMaxIter(i),t.BestScore(i), ...
        t.J_true(i),t.SumRate(i),t.Jain(i),t.ActiveLinks(i),t.RuntimeSeconds(i));
end
fprintf(fid,'\n');
end
