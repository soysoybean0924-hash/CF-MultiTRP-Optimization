%% 04 - Outer PSO
clear; clc; close all; scriptFolder=fileparts(mfilename('fullpath')); projectRoot=fileparts(fileparts(scriptFolder)); run(fullfile(projectRoot,'setup_project_paths.m'));
cfg=cf_default_config('quick'); scenario=cf_generate_scenario(cfg);
searchResult=cf_search('PSO',cfg,scenario,cfg.search); result=searchResult.BestResult;
comparisonTable=cf_print_result(result,'04 PSO outer search');
cf_plot_search(searchResult); cf_plot_result(result,'04 PSO best Cell-Free policy');
