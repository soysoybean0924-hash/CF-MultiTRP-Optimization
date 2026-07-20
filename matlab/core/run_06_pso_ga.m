%% 06 - PSO exploration followed by GA refinement
clear; clc; close all; scriptFolder=fileparts(mfilename('fullpath')); projectRoot=fileparts(fileparts(scriptFolder)); run(fullfile(projectRoot,'setup_project_paths.m'));
cfg=cf_default_config('quick'); scenario=cf_generate_scenario(cfg);
searchResult=cf_search('PSO+GA',cfg,scenario,cfg.search); result=searchResult.BestResult;
comparisonTable=cf_print_result(result,'06 PSO + GA outer search');
cf_plot_search(searchResult); cf_plot_result(result,'06 PSO then GA best policy');
