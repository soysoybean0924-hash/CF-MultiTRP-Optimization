%% Compare local sensitivity rankings across quick, standard, and paper profiles.
clear; clc; close all;

scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptFolder));
run(fullfile(projectRoot,'setup_project_paths.m'));

profiles = {'quick','standard','paper'};
seedList = 1:5;
resultRoot = fullfile(projectRoot,'results','local_sensitivity_profiles');

summaries = cell(numel(profiles),1);
for k = 1:numel(profiles)
    profile = profiles{k};
    resultsDir = fullfile(resultRoot,profile);
    summaries{k} = run_local_sensitivity_profile(profile,seedList,resultsDir);
end

comparisonRows = cell(0,1);
rowIndex = 0;
for k = 1:numel(profiles)
    profile = profiles{k};
    ranking = summaries{k}.rankingTable;
    three = summaries{k}.threeObjectiveTable;
    for i = 1:height(ranking)
        rowIndex = rowIndex + 1;
        row = struct();
        row.Profile = profile;
        row.Parameter = ranking.Parameter{i};
        row.ActualField = ranking.ActualField{i};
        row.InnerRank = ranking.InnerRank(i);
        row.OuterRank = ranking.OuterRank(i);
        row.TrueRank = ranking.TrueRank(i);
        row.CompositeRank = ranking.CompositeRank(i);
        row.S_inner_norm = ranking.S_inner_norm(i);
        row.S_outer_norm = ranking.S_outer_norm(i);
        row.S_true_norm = ranking.S_true_norm(i);
        row.DirectionConsistency = three.DirectionConsistency{i};
        row.StabilityFlag = three.StabilityFlag{i};
        row.TrueSensitivityClass = ranking.TrueSensitivityClass{i};
        row.Recommendation = ranking.Recommendation{i};
        comparisonRows{rowIndex,1} = row; %#ok<SAGROW>
    end
end

comparisonTable = struct2table(vertcat(comparisonRows{:}));
if ~exist(resultRoot,'dir')
    mkdir(resultRoot);
end
writetable(comparisonTable,fullfile(resultRoot,'profile_sensitivity_comparison.csv'));
save(fullfile(resultRoot,'profile_sensitivity_comparison.mat'),'comparisonTable','summaries','profiles','seedList');

fprintf('\nFinished profile comparison.\n');
fprintf('Comparison CSV: %s\n',fullfile(resultRoot,'profile_sensitivity_comparison.csv'));
