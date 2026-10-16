function test_chasi_native_config()
% Contract for the formal MATLAB scene; no Python interpreter is involved.
projectRoot=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot,'matlab','chasi'));
cfg=chasi_config();
assert(cfg.sites==7 && cfg.sectorsPerSite==3 && cfg.trps==21);
assert(cfg.usersPerCell==10 && cfg.users==210);
assert(cfg.txPorts==64 && cfg.ueRxPorts==4 && cfg.ueTxPorts==2);
assert(cfg.rbTotal==273 && numel(cfg.rbGroups)==17);
assert(sum([cfg.rbGroups.count])==273);
assert(cfg.usersPerActiveCellRb==2 && cfg.rank==2);
assert(all(cfg.srsRxRows==[1 2]));
cfg=chasi_config(struct('usersPerCell',20,'rank',4,'scheduleMode','precise_shared_rb'));
assert(cfg.users==420 && cfg.usersPerActiveCellRb==4);
assert(cfg.rank==4 && strcmp(cfg.scheduleMode,'precise_shared_rb'));
try
    chasi_config(struct('rank',5));
    error('Expected rank validation failure');
catch err
    assert(contains(err.identifier,'InvalidRank'));
end
fprintf('CHASI_NATIVE_CONFIG_PASS\n');
end
