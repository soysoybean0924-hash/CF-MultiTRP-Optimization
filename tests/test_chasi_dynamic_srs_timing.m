function test_chasi_dynamic_srs_timing()
% A nondefault valid SRS period must control optional replay block timing.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab','chasi'));
cfg=chasi_config(struct('seed',19,'srsPeriodTti',170,...
    'durationTti',170,'decisionTti',10,'maxInterferenceDistanceM',100));
scene=chasi_generate_scene(cfg);
solverCfg=struct('rank',cfg.rank,'budget',cfg.powerWattPerTrp,...
    'outer_iterations',0,'branch','matrix_nominal','users',cfg.users);
solution=chasi_matrix_wmmse(scene.resources,solverCfg);
traffic=struct('busy',false(cfg.users,170),'tail',false(cfg.users,170),...
    'terminal',false(cfg.users,170));
replay=chasi_time_evolution(scene,solution,struct('windowTti',170,...
    'fastPeriodTti',10,'slowPeriodTti',170,'beamPolicy','frozen'),traffic);
assert(numel(replay.events)==17);
assert(isequal([replay.events(1:3).tti],[0 10 20]));
assert(isequal([replay.events(1:3).srs_group],[1 2 3]));
assert(replay.srs_hop_interval_tti==10);
fprintf('CHASI_DYNAMIC_SRS_TIMING_PASS\n');
end
