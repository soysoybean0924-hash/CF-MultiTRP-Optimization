%% Plot four focused Huawei probe comparison groups.
clear; clc; close all;

scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptFolder));
run(fullfile(projectRoot,'setup_project_paths.m'));

runId = getenvOrDefault('HUAWEI_PROBE_PLOT_RUN_ID','huawei_probe_matrix_20260809');
resultRoot = fullfile(projectRoot,'results','huawei_robust',runId);
summaryFile = fullfile(resultRoot,'huawei_final_algorithm_comparison.csv');
outDir = fullfile(resultRoot,'four_group_plots');
if ~exist(outDir,'dir')
    mkdir(outDir);
end

t = readtable(summaryFile,'TextType','string');

groups = {
    'group1_basic_vs_inner', ...
    'Group 1: basic vs inner, edge-aware nonrobust', ...
    t(t.EdgeProfile=="edge_aware" & t.RobustProfile=="nonrobust" & ismember(t.Method,["basic","inner"]),:);
    'group2_robust_effect_inner', ...
    'Group 2: robust effect on inner', ...
    t(t.EdgeProfile=="edge_aware" & ismember(t.RobustProfile,["nonrobust","robust"]) & t.Method=="inner",:);
    'group3_outer_search_nonrobust', ...
    'Group 3: outer search, edge-aware nonrobust', ...
    t(t.EdgeProfile=="edge_aware" & t.RobustProfile=="nonrobust" & t.Method~="basic",:);
    'group4_outer_search_robust', ...
    'Group 4: outer search, edge-aware robust', ...
    t(t.EdgeProfile=="edge_aware" & t.RobustProfile=="robust" & t.Method~="basic",:)
    };

for i = 1:size(groups,1)
    tag = groups{i,1};
    titleText = groups{i,2};
    subTable = groups{i,3};
    if isempty(subTable)
        warning('No rows found for %s.',tag);
        continue;
    end
    plotOneGroup(subTable,titleText,fullfile(outDir,[tag '.png']));
end

fprintf('Huawei four-group plots written to: %s\n',outDir);

function plotOneGroup(t,titleText,outFile)
labels = makeLabels(t);
metrics = {
    'TrueObjective','J true / max function';
    'EstimatedScore','Score';
    'TrueRate5','Bottom 5% rate';
    'TrueJain','Jain fairness';
    'TotalPower','Total power';
    'ActiveLinks','Active links'
    };

fig = figure('Visible','off','Color','w','Position',[80 80 1500 850]);
layout = tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
for k = 1:size(metrics,1)
    ax = nexttile(layout);
    fieldName = metrics{k,1};
    bar(ax,categorical(labels),t.(fieldName));
    grid(ax,'on');
    ylabel(ax,metrics{k,2},'Interpreter','none');
    xtickangle(ax,25);
end
title(layout,titleText,'Interpreter','none');
exportgraphics(fig,outFile,'Resolution',180);
close(fig);
end

function labels = makeLabels(t)
if numel(unique(t.Method)) == 1
    labels = strcat(t.RobustProfile," / ",t.Method);
elseif numel(unique(t.RobustProfile)) == 1
    labels = t.Method;
else
    labels = strcat(t.RobustProfile," / ",t.Method);
end
end

function value = getenvOrDefault(name,defaultValue)
value = getenv(name);
if isempty(value)
    value = defaultValue;
end
end
