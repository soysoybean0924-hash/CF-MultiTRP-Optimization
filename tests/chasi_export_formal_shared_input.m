function outputPath=chasi_export_formal_shared_input(runDir,outputPath)
%CHASI_EXPORT_FORMAL_SHARED_INPUT Export one saved native run for offline parity.
% Neither this exporter nor its Python consumer participates in chasi_run.
if nargin<2 || isempty(outputPath) || isfile(outputPath)
    error('CHASI:FormalParityOutput','A new separate output MAT path is required');
end
saved=load(fullfile(runDir,'scene.mat'),'scene','cfg');
scene=saved.scene; cfg=saved.cfg;
if numel(scene.resources)~=17 || cfg.trps~=21 || ~ismember(cfg.users,[210 420])
    error('CHASI:FormalParityShape','Expected saved formal CHASI scene');
end
solverCfg=struct('rank',cfg.rank,'budget',cfg.powerWattPerTrp,...
    'outer_iterations',0,'outer_rel_tol',cfg.outerRelTol,...
    'outer_precoder_tol',cfg.outerPrecoderRelTol,...
    'admm_iterations',cfg.admmIterations,'cg_iterations',cfg.cgIterations,...
    'eps_abs',cfg.epsAbs,'eps_rel',cfg.epsRel,'rho',0.05,...
    'branch','matrix_statistical','pf_floor',cfg.pfRateFloorBitsPerSHz,...
    'users',cfg.users,'initializationMode',cfg.initializationMode,...
    'initializationSeed',cfg.initializationSeed,'seed',cfg.seed,...
    'probe_fixed_receiver_weight',true);
initial=chasi_matrix_wmmse(scene.resources,solverCfg);
summary=jsondecode(fileread(fullfile(runDir,'summary.json')));
initialObjective=summary.branches.matrix_statistical.trajectory(1).objective;
if abs(initial.optimization_objective-initialObjective)>1e-7
    error('CHASI:FormalParityInitial','Saved trajectory disagrees with regenerated initial precoder');
end
final=load(fullfile(runDir,'matrix_statistical_precoders.mat'),...
    'precoder','rxCombiner','mseMatrix','mseWeight','userWeight');
resources=scene.resources;
initialPrecoder=initial.precoder;
initialRxCombiner=initial.rxCombiner;
initialMseMatrix=initial.mseMatrix;
initialMseWeight=initial.mseWeight;
initialUserWeight=initial.userWeight;
initialQuadraticProbe=initial.fixed_receiver_weight_probe;
finalPrecoder=final.precoder;
finalRxCombiner=final.rxCombiner;
finalMseMatrix=final.mseMatrix;
finalMseWeight=final.mseWeight;
finalUserWeight=final.userWeight;
save(outputPath,'resources','initialPrecoder','finalPrecoder',...
    'initialRxCombiner','initialMseMatrix','initialMseWeight',...
    'initialUserWeight','initialQuadraticProbe',...
    'finalRxCombiner','finalMseMatrix','finalMseWeight','finalUserWeight',...
    'cfg','initialObjective','-v7');
fprintf('CHASI_FORMAL_SHARED_INPUT=%s\n',outputPath);
end
