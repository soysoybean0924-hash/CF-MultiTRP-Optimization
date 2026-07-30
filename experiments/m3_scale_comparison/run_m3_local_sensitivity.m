%% M3 local sensitivity experiment.
% Runs the existing nine-parameter local sensitivity workflow at the full
% M3 scale: 7 DUs, 100 UEs, 100 RBGs, and 2x12 MIMO.
clear; clc; close all;

scriptFolder = fileparts(mfilename('fullpath'));
projectRoot = fileparts(fileparts(scriptFolder));
run(fullfile(projectRoot,'setup_project_paths.m'));

resultRoot = getenvOrDefault('M3_RESULT_ROOT',fullfile(projectRoot,'results','M3_scale_comparison'));
resultsDir = fullfile(resultRoot,'m3_local_sensitivity');
seedList = parseSeedList(getenvOrDefault('M3_SENSITIVITY_SEEDS','1'));

summary = run_local_sensitivity_profile('m3',seedList,resultsDir); %#ok<NASGU>

fprintf('\nFinished M3 local sensitivity.\n');
fprintf('Result folder: %s\n',resultsDir);
fprintf('Ranking CSV:   %s\n',fullfile(resultsDir,'sensitivity_ranking.csv'));
fprintf('Report:        %s\n',fullfile(resultsDir,'local_sensitivity_report.txt'));

function value = getenvOrDefault(name,defaultValue)
value = getenv(name);
if isempty(value)
    value = defaultValue;
end
end

function seedList = parseSeedList(raw)
parts = regexp(strtrim(raw),'[,\s]+','split');
seedList = zeros(1,numel(parts));
for i = 1:numel(parts)
    seedList(i) = str2double(parts{i});
end
if isempty(seedList) || any(~isfinite(seedList))
    error('M3_SENSITIVITY_SEEDS must be a comma- or space-separated numeric list.');
end
seedList = unique(round(seedList),'stable');
end
