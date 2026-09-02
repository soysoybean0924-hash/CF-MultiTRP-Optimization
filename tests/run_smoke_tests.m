%% Repository smoke tests.
clear; clc; close all;

projectRoot = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(projectRoot,'setup_project_paths.m'));
assert(exist(fullfile(projectRoot,'experiments','m3_testbed','run_m3_full9_testbed.m'),'file') == 2);
assert(exist('run_m3_full9_testbed','file') == 2);
assert(exist('m3_testbed_search','file') == 2);
assert(exist(fullfile(projectRoot,'experiments','m3_efficiency','run_m3_efficiency_benchmark.m'),'file') == 2);
assert(exist('run_m3_efficiency_benchmark','file') == 2);
assert(exist(fullfile(projectRoot,'experiments','huawei_robust','run_huawei_robust_comparison.m'),'file') == 2);
assert(exist('run_huawei_robust_comparison','file') == 2);
assert(exist(fullfile(projectRoot,'experiments','huawei_robust','run_huawei_robust_scale_suite.m'),'file') == 2);
assert(exist('run_huawei_robust_scale_suite','file') == 2);
assert(exist(fullfile(projectRoot,'experiments','huawei_robust','run_huawei_final_algorithm_comparison.m'),'file') == 2);
assert(exist('run_huawei_final_algorithm_comparison','file') == 2);
assert(exist(fullfile(projectRoot,'experiments','paper_ablation','run_controlled_outer_ablation.m'),'file') == 2);
assert(exist('run_controlled_outer_ablation','file') == 2);
assert(exist('cf_compute_experience_rate','file') == 2);
assert(exist('cf_generate_burst_traffic','file') == 2);
assert(exist('cf_apply_srs_measurement_model','file') == 2);

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
assert(huaweiCfg.edge.enabled);
assert(huaweiCfg.edge.pathlossThresholdDb == 3);
assert(huaweiCfg.robust.enabled);
huaweiProbeCfg = huaweiCfg;
huaweiProbeCfg.numUEs = huaweiProbeCfg.numDUs;
huaweiProbeCfg.numRBGs = 2;
huaweiProbeCfg.numTxAntennas = 4;
huaweiProbeCfg.numRxAntennas = 2;
huaweiProbeScenario = cf_generate_scenario(huaweiProbeCfg);
assert(size(huaweiProbeScenario.H,3) == huaweiCfg.numDUs);
assert(size(huaweiProbeScenario.H,4) == huaweiProbeCfg.numUEs);
assert(size(huaweiProbeScenario.H,5) == huaweiProbeCfg.numRBGs);
assert(isfield(huaweiProbeScenario,'H_true'));
assert(isfield(huaweiProbeScenario,'H_est'));
assert(isfield(huaweiProbeScenario,'srs'));
assert(size(huaweiProbeScenario.H_true,3) == huaweiCfg.numDUs);
assert(size(huaweiProbeScenario.srs.SrsPresinrDb,1) == huaweiCfg.numDUs);
assert(size(huaweiProbeScenario.srs.SrsPresinrDb,2) == huaweiProbeCfg.numUEs);
assert(size(huaweiProbeScenario.srs.SrsPresinrDb,3) == huaweiProbeCfg.numRBGs);
assert(any(huaweiProbeScenario.srs.SrsMeasuredMask(:)));
assert(all(huaweiProbeScenario.srs.ErrorVariance(:) >= 0));
assert(norm(huaweiProbeScenario.H_true(:)-huaweiProbeScenario.H_est(:)) > 0);
assert(isfield(huaweiProbeScenario,'edge'));
assert(numel(huaweiProbeScenario.edge.EdgeUserMask) == huaweiProbeCfg.numUEs);
assert(huaweiProbeScenario.edge.NumEdgeUsers + huaweiProbeScenario.edge.NumNonEdgeUsers == huaweiProbeCfg.numUEs);
assert(all(huaweiProbeScenario.edge.ServingDUCount(huaweiProbeScenario.edge.EdgeUserMask) >= huaweiProbeCfg.edge.minServingDUs));
assert(numel(unique(huaweiProbeScenario.siteIndex)) == huaweiCfg.numSites);
assert(all(ismember(unique(huaweiProbeScenario.cellIndex),1:huaweiCfg.cellsPerSite)));
assert(isfield(huaweiProbeScenario,'traffic'));
assert(size(huaweiProbeScenario.traffic.NonEmptyBufferMask,1) == huaweiProbeCfg.numUEs);
assert(size(huaweiProbeScenario.traffic.NonEmptyBufferMask,2) == huaweiProbeCfg.traffic.numSamples);
assert(any(huaweiProbeScenario.traffic.NonEmptyBufferMask(:)));
assert(any(huaweiProbeScenario.traffic.TailSampleMask(:)));

quickCfg = cf_default_config('quick');
quickCfg.inner.maxIter = 2;
quickCfg.search.verbose = false;
scenario = cf_generate_scenario(quickCfg);
candidate = cf_decode_candidate(quickCfg.defaultX,quickCfg);

basicResult = cf_evaluate_candidate(quickCfg,scenario,candidate,false);
[basicTrue,basicDetails] = cf_compute_true_objective(basicResult);
assert(isfinite(basicResult.Score));
assert(isfinite(basicResult.Objective));
assert(basicDetails.valueMatchesSumRate);
assert(abs(basicTrue - basicResult.SumRate) <= 1e-8*max(1,abs(basicResult.SumRate)));
assert(abs(basicResult.Objective - basicTrue) <= 1e-8*max(1,abs(basicTrue)));
assert(abs(basicResult.Score - basicResult.ScoreParts.WeightedEvaluationScore) <= ...
    1e-8*max(1,abs(basicResult.Score)));
assert(isfield(basicResult,'ExperienceRate'));
assert(numel(basicResult.ExperienceRate.UeExperienceRate) == quickCfg.numUEs);
assert(all(basicResult.ExperienceRate.ThpTimeDl >= 0));
assert(isfinite(basicResult.ExperienceRate.EdgeExperienceRate5));
burstExperience = cf_compute_experience_rate(huaweiProbeCfg, ...
    abs(randn(1,huaweiProbeCfg.numUEs,huaweiProbeCfg.numRBGs)), ...
    ones(huaweiProbeCfg.numDUs,huaweiProbeCfg.numUEs,huaweiProbeCfg.numRBGs), ...
    huaweiProbeScenario.traffic);
assert(burstExperience.UsesBurstTraffic);
assert(all(burstExperience.ThpTimeDl <= sum(huaweiProbeScenario.traffic.NonEmptyBufferMask,2)));

innerResult = cf_evaluate_candidate(quickCfg,scenario,candidate,true);
[innerTrue,innerDetails] = cf_compute_true_objective(innerResult);
assert(isfinite(innerResult.Score));
assert(isfinite(innerResult.Objective));
assert(innerDetails.valueMatchesSumRate);
assert(abs(innerTrue - innerResult.SumRate) <= 1e-8*max(1,abs(innerResult.SumRate)));
assert(abs(innerResult.Objective - innerTrue) <= 1e-8*max(1,abs(innerTrue)));
assert(abs(innerResult.Score - innerResult.ScoreParts.WeightedEvaluationScore) <= ...
    1e-8*max(1,abs(innerResult.Score)));
assert(isfield(innerResult.baseline,'ExperienceRate'));
assert(isfinite(innerResult.ExperienceRate.MeanExperienceRate));
assert(isfield(innerResult,'Robust'));
assert(~innerResult.Robust.Enabled);

robustProbeCfg = huaweiProbeCfg;
robustProbeCfg.inner.maxIter = 1;
robustProbeCfg.search.verbose = false;
robustCandidate = cf_decode_candidate(robustProbeCfg.defaultX,robustProbeCfg);
robustResult = cf_evaluate_candidate(robustProbeCfg,huaweiProbeScenario,robustCandidate,true);
assert(robustResult.Robust.Enabled);
assert(robustResult.Robust.MeanErrorVariance > 0);
assert(robustResult.TrueChannel.Available);
assert(isfinite(robustResult.TrueChannel.SumRate));
assert(isfield(robustResult.TrueChannel,'ExperienceRate'));
assert(isfield(robustResult,'Edge'));
assert(robustResult.Edge.Available);
assert(robustResult.Edge.NumEdgeUsers == huaweiProbeScenario.edge.NumEdgeUsers);
nonEdgeUsers = find(huaweiProbeScenario.edge.NonEdgeUserMask);
if ~isempty(nonEdgeUsers)
    assert(all(squeeze(sum(robustResult.bInit(:,nonEdgeUsers,:),1)) == 1,'all'));
end

quickCfg.search.maxEvaluations = 2;
quickCfg.search.populationSize = 2;
quickCfg.search.eliteCount = 1;
quickCfg.search.activeDimensions = [1 4];
quickCfg.search.fixedX = quickCfg.defaultX;
reducedSearch = cf_search('PSO',quickCfg,scenario,quickCfg.search);
assert(reducedSearch.Evaluations == 2);
assert(numel(reducedSearch.BestX) == quickCfg.search.dimension);
assert(all(abs(reducedSearch.BestX(setdiff(1:9,[1 4])) - quickCfg.defaultX(setdiff(1:9,[1 4]))) < eps));
assert(reducedSearch.InnerOptimizationEnabled);

quickCfg.search.enableInnerOptimization = false;
outerOnlySearch = cf_search('PSO',quickCfg,scenario,quickCfg.search);
assert(outerOnlySearch.Evaluations == 2);
assert(~outerOnlySearch.InnerOptimizationEnabled);
assert(outerOnlySearch.BestResult.history.iterations == 0);
assert(strcmp(outerOnlySearch.BestResult.history.stopReason,'not_run'));

fprintf('Smoke tests passed: M3 config and quick evaluation pipeline are valid.\n');
