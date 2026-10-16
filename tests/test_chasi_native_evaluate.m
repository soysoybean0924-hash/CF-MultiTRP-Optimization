function tests = test_chasi_native_evaluate
tests = functiontests(localfunctions);
end

function testTrueChannelBusyTailAndTerminal(testCase)
addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'matlab', 'chasi'));
cfg = struct('users',2,'durationTti',4,'ttiMs',1,'rbTotal',273, ...
    'scsHz',30000,'seed',1,'trafficModel','legacy_bursts','trafficLoad',0.3);
h = complex(zeros(1,1,4,64)); h(1,1,1,1) = 1;
resource = struct('H_true',h,'ueIds',1,'servingMask',true, ...
    'tx_rb_count',273,'rb_count',273,'omitted_gain',zeros(1,1), ...
    'prior_gain',ones(1,1));
scene = struct('config',cfg,'resources',resource,'active_prb_ratio',1);
v = complex(zeros(1,1,64,1)); v(1,1,1,1) = 1;
solution = struct('precoder',{{v}});
busy = logical([1 1 1 0;0 0 0 0]);
tail = logical([0 1 1 0;0 0 0 0]);
terminal = logical([0 0 1 0;0 0 0 0]);
m = chasi_evaluate(scene,solution,struct('busy',busy,'tail',tail,'terminal',terminal));
verifyEqual(testCase,m.per_ue_physical_bits_per_s_hz,[1;0],'AbsTol',1e-12);
verifyEqual(testCase,m.per_ue_valid_tti,[2;0]);
verifyEqual(testCase,m.per_ue_delivered_bits_proxy(1),126360,'AbsTol',1e-8);
verifyEqual(testCase,m.per_ue_experience_mbps(1),63.18,'AbsTol',1e-10);
verifyTrue(testCase,isnan(m.per_ue_experience_mbps(2)));
verifyEqual(testCase,m.total_radiated_power_watt,1,'AbsTol',1e-12);
verifyEqual(testCase,m.actual_prb_fraction_mean,3/84,'AbsTol',1e-12);
end

function testTrafficReproducibleAndTerminalSubset(testCase)
addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))), 'matlab', 'chasi'));
[busy,tail,terminal] = chasi_traffic(3,100,7,'target_busy_fraction',0.3);
[busy2,tail2,terminal2] = chasi_traffic(3,100,7,'target_busy_fraction',0.3);
verifyEqual(testCase,busy,busy2);
verifyEqual(testCase,tail,tail2);
verifyEqual(testCase,terminal,terminal2);
verifyTrue(testCase,all(tail(:) <= busy(:)));
verifyTrue(testCase,all(terminal(:) <= busy(:)));
end
