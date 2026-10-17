function test_chasi_srs_timing()
% SRS hop timing must follow the configured period, not a hidden 20-TTI literal.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab','chasi'));
cfg=chasi_config(struct('seed',19,'srsPeriodTti',170,...
    'durationTti',170,'decisionTti',10,'maxInterferenceDistanceM',100));
scene=chasi_generate_scene(cfg);
assert(cfg.srsHopIntervalTti==10);
assert(scene.events(11).srs_group==2);
assert(scene.resources(2).measured && scene.resources(2).age_ms==0);
assert(~scene.resources(3).measured);
fprintf('CHASI_SRS_TIMING_PASS\n');
end
