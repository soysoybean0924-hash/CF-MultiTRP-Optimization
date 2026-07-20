%% Local sensitivity test for nine outer strategy parameters.
% This script keeps the original Cell-Free evaluation path intact and adds
% an experiment layer for one-at-a-time local perturbations.

clear; clc; close all;

scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptFolder));
run(fullfile(projectRoot,'setup_project_paths.m'));

resultsDir = fullfile(projectRoot,'results','local_sensitivity');
profile = 'quick';
seedList = 1:5;

run_local_sensitivity_profile(profile,seedList,resultsDir);
