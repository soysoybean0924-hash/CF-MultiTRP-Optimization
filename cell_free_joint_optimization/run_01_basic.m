%% 01 - Basic Cell-Free multi-DU / multi-UE model
clear; clc; close all; rootFolder=fileparts(mfilename('fullpath')); addpath(rootFolder);
cfg=cf_default_config('quick'); scenario=cf_generate_scenario(cfg);
candidate=cf_decode_candidate(cfg.defaultX,cfg); candidate.maxRank=1;
result=cf_evaluate_candidate(cfg,scenario,candidate,false);
comparisonTable=cf_print_result(result,'01 Basic Cell-Free model');
cf_plot_result(result,'01 Basic Cell-Free: b/p/r/W/H');
H=result.H; W=result.W; b=result.b; p=result.p; r=result.r;
