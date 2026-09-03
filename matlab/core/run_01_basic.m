%% 01 - Basic Cell-Free multi-DU / multi-UE model
% Baseline smoke example: build one quick scenario, decode the default
% search vector, and evaluate the initial policy without inner optimization.
clear; clc; close all; 
scriptFolder=fileparts(mfilename('fullpath')); 
projectRoot=fileparts(fileparts(scriptFolder)); 
run(fullfile(projectRoot,'setup_project_paths.m'));
cfg=cf_default_config('quick'); scenario=cf_generate_scenario(cfg);
candidate=cf_decode_candidate(cfg.defaultX,cfg); candidate.maxRank=1;
% doOptimize=false keeps this run focused on the raw initial b/p/r/W policy.
result=cf_evaluate_candidate(cfg,scenario,candidate,false);
comparisonTable=cf_print_result(result,'01 Basic Cell-Free model');
cf_plot_result(result,'01 Basic Cell-Free: b/p/r/W/H');
H=result.H; W=result.W; b=result.b; p=result.p; r=result.r;
