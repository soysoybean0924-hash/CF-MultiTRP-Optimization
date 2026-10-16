function test_chasi_native_entry()
% Native end-to-end contract at formal 21-TRP/210-UE dimensions.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab','chasi'));
outDir=tempname;
cfg=chasi_config(struct('seed',43,'outerIterations',0,...
    'maxInterferenceDistanceM',100,'prbUtilization',0.30,...
    'scheduleMode','precise_shared_rb','branches',{{'matrix_nominal'}},...
    'outputDir',outDir));
result=chasi_run(cfg);
assert(strcmp(result.language,'MATLAB'));
assert(result.scene_dimensions.trps==21 && result.scene_dimensions.users==210);
assert(isfile(fullfile(outDir,'summary.json')));
assert(isfile(fullfile(outDir,'scene.mat')));
assert(isfile(fullfile(outDir,'matrix_nominal_precoders.mat')));
assert(isfile(fullfile(outDir,'matrix_nominal_per_ue.csv')));
saved=load(fullfile(outDir,'matrix_nominal_precoders.mat'));
assert(isfield(saved,'precoder') && isfield(saved,'rxCombiner'));
assert(isfield(saved,'mseWeight') && isfield(saved,'mseMatrix'));
assert(~isfield(saved,'W')); % no beam/MSE ambiguity in current output
assert(all(result.branches.matrix_nominal.per_trp_power_watt<=cfg.powerWattPerTrp+1e-6));
fprintf('CHASI_NATIVE_ENTRY_PASS %s\n',outDir);
end
