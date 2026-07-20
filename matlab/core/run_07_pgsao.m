%% 07 - PGSAO
% PGSAO mixes particle bests, global best guidance, crossover, and mutation
% as a compact population search variant.
clear; clc; close all; scriptFolder=fileparts(mfilename('fullpath')); projectRoot=fileparts(fileparts(scriptFolder)); run(fullfile(projectRoot,'setup_project_paths.m'));
cfg=cf_default_config('quick'); scenario=cf_generate_scenario(cfg);
searchResult=cf_search('PGSAO',cfg,scenario,cfg.search); result=searchResult.BestResult;
comparisonTable=cf_print_result(result,'07 PGSAO outer search');
cf_plot_search(searchResult); cf_plot_result(result,'07 PGSAO best policy');
