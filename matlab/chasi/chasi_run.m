function summary=chasi_run(options)
%CHASI_RUN Formal CHASI scenario, solver, evaluation and output in MATLAB.
% No Python process, Python module, or pre-generated scene is used here.
if nargin<1, options=struct(); end
if isfield(options,'rbGroups')
    options=rmfield(options,intersect(fieldnames(options),{'users','rbGroups'}));
end
cfg=chasi_config(options);
if cfg.timeEvolutionTti>0 && strcmp(cfg.srsMode,'pilot_reuse_gaussian')
    error('chasi_run:UnsupportedReplaySRS',...
        'Time evolution with pilot reuse is unavailable in the reference implementation.');
end
if ischar(cfg.branches) || isstring(cfg.branches)
    branches=strtrim(strsplit(char(cfg.branches),','));
else
    branches=cfg.branches;
end
supported={'ideal','matrix_nominal','matrix_statistical','matrix_edge_weighted',...
    'matrix_pf_nominal','matrix_pf_uniform','matrix_pf_uniform_relative',...
    'matrix_pf_statistical','no_cooperation'};
if isempty(branches) || any(~ismember(branches,supported))
    error('chasi_run:UnsupportedBranch',...
        'Native MATLAB branch unavailable: %s',strjoin(setdiff(branches,supported),','));
end
if isempty(cfg.outputDir)
    root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
    cfg.outputDir=fullfile(root,'results','chasi_matlab',...
        ['run_' datestr(now,'yyyymmdd_HHMMSS_FFF')]);
end
if isfolder(cfg.outputDir)
    existing=dir(cfg.outputDir);
    if numel(existing)>2
        error('chasi_run:OutputExists','Output directory is not empty: %s',cfg.outputDir);
    end
else
    mkdir(cfg.outputDir);
end
scene=chasi_generate_scene(cfg);
[busy,tail,terminal]=chasi_traffic(cfg.users,cfg.durationTti,cfg.seed,...
    cfg.trafficModel,cfg.trafficLoad);
traffic=struct('busy',busy,'tail',tail,'terminal',terminal);
save(fullfile(cfg.outputDir,'scene.mat'),'scene','traffic','cfg','-v7.3');
write_json(fullfile(cfg.outputDir,'config.json'),cfg);
write_json(fullfile(cfg.outputDir,'events.json'),scene.events);
groups=repmat(struct('rb_start',0,'rb_count',0,'tx_rb_count',0,...
    'resourceWeightNu',0,'ueIds',[],...
    'serving_trps_by_user',{{}},'measured',false,'age_ms',0),1,numel(scene.resources));
for g=1:numel(scene.resources)
    resource=scene.resources(g);
    groups(g).rb_start=resource.rb_start;
    groups(g).rb_count=resource.rb_count;
    groups(g).tx_rb_count=resource.tx_rb_count;
    groups(g).ueIds=resource.ueIds(:).';
    groups(g).resourceWeightNu=resource.resourceWeightNu;
    groups(g).measured=resource.measured;
    groups(g).age_ms=resource.age_ms;
    links=cell(1,numel(resource.ueIds));
    for localUeIdx=1:numel(links)
        links{localUeIdx}=find(resource.servingMask(:,localUeIdx)).';
    end
    groups(g).serving_trps_by_user=links;
end
manifest=struct('indexing','MATLAB one-based','trp_xy_m',scene.trp_xy,...
    'ue_xy_m',scene.ue_xy,'ue_home_trp',scene.home,'groups',groups);
write_json(fullfile(cfg.outputDir,'scene_manifest.json'),manifest);
summary=struct();
summary.language='MATLAB';
summary.entry='matlab/chasi/chasi_run.m';
summary.config=cfg;
summary.scene_dimensions=struct('sites',cfg.sites,'trps',cfg.trps,...
    'users',cfg.users,'tx_ports',cfg.txPorts,'ue_rx_ports',cfg.ueRxPorts,...
    'ue_tx_ports',cfg.ueTxPorts,'rb',cfg.rbTotal,'rbg',numel(scene.resources));
summary.scenario=struct('allocated_prb_fraction_by_trp',scene.active_prb_ratio,...
    'srs_modeled_group_rb',sum([scene.resources([scene.resources.measured]).rb_count]),...
    'srs_nominal_hop_rb',min(cfg.rbTotal,cfg.srsHops*16),...
    'srs_last_data_rb_measurement_status','unresolved: last data RB shares group posterior',...
    'srs_age_ms_by_group',[scene.resources.age_ms],...
    'measurement_coverage_by_group',[scene.resources.measured],...
    'independent_calibration',scene.calibration);
summary.branches=struct();
for bi=1:numel(branches)
    branch=branches{bi};
    solverCfg=solver_config(cfg,branch);
    started=tic;
    if strcmp(branch,'no_cooperation')
        solution=chasi_no_cooperation(scene.resources,solverCfg);
    else
        solution=chasi_matrix_wmmse(scene.resources,solverCfg);
    end
    metrics=chasi_evaluate(scene,solution,traffic);
    runtime=toc(started);
    precoder=solution.precoder;
    rxCombiner=solution.rxCombiner;
    mseWeight=solution.mseWeight;
    mseMatrix=solution.mseMatrix;
    userWeight=solution.userWeight;
    servingMask={scene.resources.servingMask};
    scheduleMask=scene.scheduleMask;
    ueIds={scene.resources.ueIds};
    resourceWeightNu=[scene.resources.resourceWeightNu];
    numStreams=cfg.rank;
    resultSchemaVersion=3;
    save(fullfile(cfg.outputDir,[branch '_precoders.mat']),...
        'precoder','rxCombiner','mseWeight','mseMatrix','userWeight',...
        'servingMask','scheduleMask','ueIds','resourceWeightNu','numStreams',...
        'resultSchemaVersion','-v7.3');
    perUE=table((1:cfg.users)',metrics.per_ue_physical_bits_per_s_hz(:),...
        metrics.per_ue_experience_mbps(:),metrics.per_ue_valid_tti(:),...
        'VariableNames',{'ue_id','physical_bits_per_s_hz',...
        'experience_mbps','valid_tti'});
    writetable(perUE,fullfile(cfg.outputDir,[branch '_per_ue.csv']));
    record=struct('status','completed','converged',solution.converged,...
        'reason',solution.reason,'runtime_seconds',runtime,...
        'optimization_objective',solution.optimization_objective,...
        'optimizer_visible_sum_proxy_bits_per_s_hz',solution.estimated_sum_rate,...
        'max_power_violation_watt',solution.max_power_violation,...
        'per_trp_power_watt',solution.power,...
        'stream_rank',numStreams,'result_schema_version',resultSchemaVersion,...
        'evaluation',metrics,...
        'precoders_mat_file',[branch '_precoders.mat'],...
        'per_ue_csv_file',[branch '_per_ue.csv'],...
        'trajectory',solution.trajectory);
    if cfg.timeEvolutionTti>0
        replayOptions=struct('windowTti',cfg.timeEvolutionTti,...
            'offeredMbps',cfg.offeredMbps,'fastPeriodTti',cfg.fastPeriodTti,...
            'slowPeriodTti',cfg.slowPeriodTti);
        timeEvolution=chasi_time_evolution(scene,solution,replayOptions);
        save(fullfile(cfg.outputDir,[branch '_time_evolution.mat']),...
            'timeEvolution','-v7.3');
        record.time_evolution=rmfield(timeEvolution,...
            {'delivered_bits_tti','completed_tti','events'});
        record.time_evolution_mat_file=[branch '_time_evolution.mat'];
    end
    summary.branches.(branch)=record;
    write_json(fullfile(cfg.outputDir,'summary.json'),summary);
end
end

function out=solver_config(cfg,branch)
out=struct('rank',cfg.rank,'budget',cfg.powerWattPerTrp,...
    'outer_iterations',cfg.outerIterations,'outer_rel_tol',cfg.outerRelTol,...
    'outer_precoder_tol',cfg.outerPrecoderRelTol,...
    'admm_iterations',cfg.admmIterations,...
    'cg_iterations',cfg.cgIterations,'eps_abs',cfg.epsAbs,...
    'eps_rel',cfg.epsRel,'rho',0.05,'branch',branch,...
    'pf_floor',cfg.pfRateFloorBitsPerSHz,'users',cfg.users,...
    'initializationMode',cfg.initializationMode,...
    'initializationSeed',cfg.initializationSeed,'seed',cfg.seed);
end

function write_json(path,value)
encoded=jsonencode(value,'PrettyPrint',true);
file=fopen(path,'w','n','UTF-8');
if file<0, error('chasi_run:OutputWrite','Cannot write %s',path); end
cleanup=onCleanup(@() fclose(file));
fwrite(file,encoded,'char');
end
