function tests = test_chasi_native_time_evolution
tests = functiontests(localfunctions);
end

function testBurstTerminalTtiExcluded(testCase)
addChasi();
busy = logical([1 1 1 0 1 1 0;0 0 0 0 0 0 0]);
terminal = logical([0 0 1 0 0 1 0;0 0 0 0 0 0 0]);
bits = [100 200 999 0 400 999 0;zeros(1,7)];
result = chasi_burst_metrics(bits,busy,terminal,100);
verifyEqual(testCase,result.valid_burst_samples,2);
verifyEqual(testCase,result.per_ue_burst_mbps{1},[0.0015,0.004],'AbsTol',1e-12);
verifyEqual(testCase,result.bursts_without_valid_tti,0);
end

function testCompleteSecondDropsTerminalAndMissing(testCase)
addChasi();
busy = false(2,10); busy(1,1:3) = true;
terminal = false(2,10); terminal(1,3) = true;
bits = zeros(2,10); bits(1,1:3) = [100 200 999];
result = chasi_second_metrics(bits,busy,terminal,100);
verifyEqual(testCase,result.complete_seconds,1);
verifyEqual(testCase,result.valid_tti_total,2);
verifyEqual(testCase,result.valid_ue_second_samples,1);
verifyEqual(testCase,result.per_ue_second_mbps(1,1),0.0015,'AbsTol',1e-12);
verifyTrue(testCase,isnan(result.per_ue_second_mbps(2,1)));
end

function testQueueReplayTerminalCompletion(testCase)
addChasi();
cfg = struct('users',1,'trps',1,'seed',7,'ttiMs',1,'scsHz',30000, ...
    'speedKmh',0,'frequencyGhz',3.5,'csiRsPeriodTti',20, ...
    'srsPeriodTti',340,'srsHops',17,'srsHopIntervalTti',20, ...
    'pilotSnrDb',10,'csiRsSnrDb',10,'srsRxRows',1, ...
    'powerWattPerTrp',2,'serviceTrps',1,'rbTotal',273, ...
    'trafficModel','legacy_bursts','trafficLoad',0.3);
h = complex(zeros(1,1,4,64)); h(1,1,1,1) = 1;
res = struct('H_true',h,'H',h,'C',complex(zeros(1,1,4,4)), ...
    'ueIds',1,'servingMask',true,'prior_gain',1,'rb_count',273, ...
    'tx_rb_count',273);
scene = struct('config',cfg,'resources',res,'active_prb_ratio',1, ...
    'ue_xy',[0 0],'trp_xy',[0 0],'home',1);
v = complex(zeros(1,1,64,1)); v(1,1,1,1) = 1;
solution = struct('precoder',{{v}});
busy = false(1,340); busy(1,1:3) = true;
tail = false(1,340); terminal = false(1,340); terminal(1,3) = true;
opts = struct('windowTti',340,'offeredMbps',0.1,'beamPolicy','frozen');
r = chasi_time_evolution(scene,solution,opts,struct('busy',busy,'tail',tail,'terminal',terminal));
verifyEqual(testCase,r.per_ue_delivered_mbit,0.0002,'AbsTol',1e-12);
verifyEqual(testCase,r.per_ue_valid_tti,2);
verifyEqual(testCase,r.completed_bursts,1);
verifyEqual(testCase,r.per_burst_throughput_proxy.per_ue_burst_mbps{1},0.1,'AbsTol',1e-12);
end

function addChasi()
addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'matlab','chasi'));
end
