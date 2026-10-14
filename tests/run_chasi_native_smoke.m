% Light native MATLAB PF and existing candidate-interface smoke test.
root=fileparts(fileparts(mfilename('fullpath')));
run(fullfile(root,'setup_project_paths.m'));
cfg=cf_default_config('quick');
cfg.chasiNative.enabled=true;
cfg.chasiNative.branch='matrix_pf_nominal';
cfg.chasiNative.rbCounts=[91 91 91];
cfg.chasiNative.scheduleMask=false(cfg.numUEs,cfg.numRBGs);
cfg.chasiNative.scheduleMask(1:2,:)=true;
cfg.chasiNative.budget=20;
cfg.chasiNative.pfFloor=.01;
cfg.chasiNative.covarianceRule='srs_scalar_isotropic_est_gain';
cfg.chasiNative.outer_iterations=1;
cfg.chasiNative.admm_iterations=6;
cfg.chasiNative.cg_iterations=10;
scene=cf_generate_scenario(cfg);
ca=cf_decode_candidate(cfg.defaultX,cfg);
ca.numConnections=1; ca.maxRank=1;
cb=ca; cb.numConnections=2;
a=cf_evaluate_candidate(cfg,scene,ca,true);
b=cf_evaluate_candidate(cfg,scene,cb,true);
assert(strcmp(a.Backend,'chasi_native_pf'));
assert(isfinite(a.Objective) && isfinite(b.Objective));
assert(a.MaxPowerViolation<1e-6 && b.MaxPowerViolation<1e-6);
assert(nnz(a.ServiceMasks{1})==2 && nnz(b.ServiceMasks{1})==4);
fprintf('native candidate smoke: objective %.9f -> %.9f, links %d -> %d\n',...
    a.Objective,b.Objective,nnz(a.ServiceMasks{1}),nnz(b.ServiceMasks{1}));
cfg.search.populationSize=2; cfg.search.maxEvaluations=2;
cfg.search.activeDimensions=[2 6];
opts=cfg.search; opts.activeDimensions=[2 6]; opts.maxEvaluations=2;
opts.populationSize=2; opts.initialDesignX=[0 0;1 1]; opts.verbose=false;
search=cf_search('GA',cfg,scene,opts);
assert(search.Evaluations==2);
assert(strcmp(search.ObjectiveName,'estimated_PF_log1p_aggregate_rate_over_floor'));
assert(all(isfinite(search.EvaluationObjective)));
fprintf('native outer search: %d evaluations, best %.9f\n',...
    search.Evaluations,search.BestObjective);
