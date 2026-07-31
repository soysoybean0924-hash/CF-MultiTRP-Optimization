%% Repository smoke tests.
clear; clc; close all;

projectRoot = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(projectRoot,'setup_project_paths.m'));
assert(exist(fullfile(projectRoot,'experiments','m3_testbed','run_m3_full9_testbed.m'),'file') == 2);
assert(exist('run_m3_full9_testbed','file') == 2);

cfg = cf_default_config('m3');
assert(cfg.numDUs == 7);
assert(cfg.numUEs == 100);
assert(cfg.numRBGs == 100);
assert(cfg.numTxAntennas == 12);
assert(cfg.numRxAntennas == 2);

quickCfg = cf_default_config('quick');
quickCfg.inner.maxIter = 2;
quickCfg.search.verbose = false;
scenario = cf_generate_scenario(quickCfg);
candidate = cf_decode_candidate(quickCfg.defaultX,quickCfg);

basicResult = cf_evaluate_candidate(quickCfg,scenario,candidate,false);
[basicTrue,basicDetails] = cf_compute_true_objective(basicResult);
assert(isfinite(basicResult.Score));
assert(basicDetails.valueMatchesSumRate);
assert(abs(basicTrue - basicResult.SumRate) <= 1e-8*max(1,abs(basicResult.SumRate)));
assert(abs(basicResult.Score - basicTrue) <= 1e-8*max(1,abs(basicTrue)));

innerResult = cf_evaluate_candidate(quickCfg,scenario,candidate,true);
[innerTrue,innerDetails] = cf_compute_true_objective(innerResult);
assert(isfinite(innerResult.Score));
assert(innerDetails.valueMatchesSumRate);
assert(abs(innerTrue - innerResult.SumRate) <= 1e-8*max(1,abs(innerResult.SumRate)));
assert(abs(innerResult.Score - innerTrue) <= 1e-8*max(1,abs(innerTrue)));

quickCfg.search.maxEvaluations = 2;
quickCfg.search.populationSize = 2;
quickCfg.search.eliteCount = 1;
quickCfg.search.activeDimensions = [1 4];
quickCfg.search.fixedX = quickCfg.defaultX;
reducedSearch = cf_search('PSO',quickCfg,scenario,quickCfg.search);
assert(reducedSearch.Evaluations == 2);
assert(numel(reducedSearch.BestX) == quickCfg.search.dimension);
assert(all(abs(reducedSearch.BestX(setdiff(1:9,[1 4])) - quickCfg.defaultX(setdiff(1:9,[1 4]))) < eps));

fprintf('Smoke tests passed: M3 config and quick evaluation pipeline are valid.\n');
