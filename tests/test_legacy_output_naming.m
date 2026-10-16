% Focused contract for the old MATLAB candidate and PSO result shape.
projectRoot=fileparts(fileparts(mfilename('fullpath')));
run(fullfile(projectRoot,'setup_project_paths.m'));
cfg=cf_default_config('quick');
cfg.numDUs=2; cfg.numUEs=3; cfg.numRBGs=1;
cfg.inner.maxIter=0;
cfg.search.populationSize=2; cfg.search.maxEvaluations=4;
cfg.search.enableInnerOptimization=false; cfg.search.verbose=false;
scenario=cf_generate_scenario(cfg);
candidate=cf_decode_candidate(cfg.defaultX,cfg);
result=cf_evaluate_candidate(cfg,scenario,candidate,false);
assert(isfield(result,'legacyBeamformer'));
assert(~isfield(result,'W'));
assert(size(result.legacyBeamformer,4)==cfg.numUEs);
assert(all(isfinite(result.legacyBeamformer(:))));

searchResult=cf_search('PSO',cfg,scenario,cfg.search);
assert(searchResult.Evaluations==cfg.search.maxEvaluations);
assert(isfield(searchResult.BestResult,'legacyBeamformer'));
assert(~isfield(searchResult.BestResult,'W'));
assert(isfinite(searchResult.BestObjective));
fprintf('Old MATLAB output naming and PSO smoke passed.\n');
