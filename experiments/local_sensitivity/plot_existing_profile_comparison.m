%% Plot the existing quick/standard/paper sensitivity comparison CSV.
clear; clc; close all;

scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptFolder));
run(fullfile(projectRoot,'setup_project_paths.m'));

resultRoot = fullfile(projectRoot,'results','local_sensitivity_profiles');
comparisonCsv = fullfile(resultRoot,'profile_sensitivity_comparison.csv');
cf_plot_profile_sensitivity_comparison(comparisonCsv,resultRoot);

fprintf('Comparison heatmap: %s\n',fullfile(resultRoot,'fig08_profile_true_sensitivity_heatmap.png'));
