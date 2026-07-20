%% 02 - H -> W -> SLINR -> WPS iterative model
% Inner-loop example: start from the default candidate and run the WPS/SCA-
% like beamformer updates before reporting the proposed policy.
clear; clc; close all; scriptFolder=fileparts(mfilename('fullpath')); projectRoot=fileparts(fileparts(scriptFolder)); run(fullfile(projectRoot,'setup_project_paths.m'));
cfg=cf_default_config('quick'); scenario=cf_generate_scenario(cfg);
candidate=cf_decode_candidate(cfg.defaultX,cfg);
result=cf_evaluate_candidate(cfg,scenario,candidate,true);
comparisonTable=cf_print_result(result,'02 Inner WPS/SLINR iteration');
cf_plot_result(result,'02 H-W-SLINR-WPS iteration');
H=result.H; W=result.W; b=result.b; p=result.p; r=result.r;
SLINR=result.SLINR; WPS=result.WPS;
