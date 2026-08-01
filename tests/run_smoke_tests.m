%% Repository smoke tests.
clear; clc; close all;

projectRoot = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(projectRoot,'setup_project_paths.m'));
assert(exist(fullfile(projectRoot,'experiments','m3_testbed','run_m3_full9_testbed.m'),'file') == 2);
assert(exist('run_m3_full9_testbed','file') == 2);
assert(exist('m3_testbed_search','file') == 2);
assert(exist(fullfile(projectRoot,'experiments','m3_efficiency','run_m3_efficiency_benchmark.m'),'file') == 2);
assert(exist('run_m3_efficiency_benchmark','file') == 2);

cfg = cf_default_config('m3');
assert(cfg.numDUs == 7);
assert(cfg.numUEs == 100);
assert(cfg.numRBGs == 100);
assert(cfg.numTxAntennas == 12);
assert(cfg.numRxAntennas == 2);

huaweiCfg = cf_default_config('huawei');
assert(huaweiCfg.numSites == 7);
assert(huaweiCfg.cellsPerSite == 3);
assert(huaweiCfg.numDUs == 21);
assert(huaweiCfg.numUEs == 315);
assert(huaweiCfg.numRBGs == 273);
assert(huaweiCfg.numTxAntennas == 64);
assert(huaweiCfg.numRxAntennas == 4);
assert(huaweiCfg.antenna.baseStationTrx == 64);
assert(huaweiCfg.measurement.srsPeriodTti == 340);
assert(huaweiCfg.measurement.srsHoppingFactor == 17);
assert(huaweiCfg.measurement.csiRsPeriodTti == 40);
huaweiProbeCfg = huaweiCfg;
huaweiProbeCfg.numUEs = huaweiProbeCfg.numDUs;
huaweiProbeCfg.numRBGs = 2;
huaweiProbeCfg.numTxAntennas = 4;
huaweiProbeCfg.numRxAntennas = 2;
huaweiProbeScenario = cf_generate_scenario(huaweiProbeCfg);
assert(size(huaweiProbeScenario.H,3) == huaweiCfg.numDUs);
assert(size(huaweiProbeScenario.H,4) == huaweiProbeCfg.numUEs);
assert(size(huaweiProbeScenario.H,5) == huaweiProbeCfg.numRBGs);
assert(numel(unique(huaweiProbeScenario.siteIndex)) == huaweiCfg.numSites);
assert(all(ismember(unique(huaweiProbeScenario.cellIndex),1:huaweiCfg.cellsPerSite)));

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
