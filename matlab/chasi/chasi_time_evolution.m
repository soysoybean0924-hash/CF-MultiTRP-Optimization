function result = chasi_time_evolution(scene,solution,options,traffic)
%CHASI_TIME_EVOLUTION Mobile fading, pilot updates, frozen/fast beams, queue.
%   This is the RX-correlated Gauss-Markov surrogate, not TR 38.901 7.5.
if nargin < 3, options = struct(); end
cfg = scene.config;
windowTti = opt(options,'windowTti',1000);
offeredMbps = opt(options,'offeredMbps',5);
fastPeriod = opt(options,'fastPeriodTti',40);
slowPeriod = opt(options,'slowPeriodTti',340);
beamPolicy = char(opt(options,'beamPolicy','estimated_svd'));
trafficSeed = opt(options,'trafficSeed',cfg.seed);
if windowTti < 340 || mod(windowTti,20) ~= 0 || offeredMbps <= 0 || ...
        fastPeriod <= 0 || slowPeriod <= 0 || mod(fastPeriod,20) || mod(slowPeriod,20)
    error('chasi_time_evolution:Options','Invalid time window, load or update period.');
end
if ~ismember(beamPolicy,{'frozen','estimated_svd'})
    error('chasi_time_evolution:BeamPolicy','Unknown beam policy.');
end
if nargin < 4 || isempty(traffic)
    [busy,tail,terminal] = chasi_traffic(cfg.users,windowTti,trafficSeed, ...
        cfg.trafficModel,cfg.trafficLoad);
else
    busy = logical(traffic.busy); tail = logical(traffic.tail);
    terminal = logical(traffic.terminal);
end
if ~isequal(size(busy),[cfg.users,windowTti]) || ...
        ~isequal(size(tail),size(busy)) || ~isequal(size(terminal),size(busy)) || ...
        any(tail(:) & ~busy(:)) || any(terminal(:) & ~busy(:))
    error('chasi_time_evolution:Traffic','Invalid [UE,TTI] traffic masks.');
end
precoder = solution.precoder;
resources = scene.resources; G = numel(resources); L = size(precoder{1},1);
truth = cell(G,1); est = cell(G,1); cov = cell(G,1);
gain = cell(G,1); linkMask = cell(G,1);
for g = 1:G
    resource = resources(g);
    truth{g} = double(resource.H_true);
    est{g} = double(resource.H);
    cov{g} = double(resource.C);
    gain{g} = double(resource.prior_gain);
    linkMask{g} = false(numel(resource.ueIds),L);
    for k = 1:numel(resource.ueIds)
        for l = 1:L
            linkMask{g}(k,l) = any(reshape(abs(truth{g}(k,l,:,:)),[],1)>0);
        end
    end
end
stream = RandStream('mt19937ar','Seed',cfg.seed+90817);
ueXy = scene.ue_xy;
heading = rand(stream,cfg.users,1)*2*pi;
velocity = (cfg.speedKmh/3.6)*[cos(heading),sin(heading)];
valid = sum(busy & ~terminal,2);
served = zeros(cfg.users,1); allocated = zeros(cfg.users,1);
volume = zeros(cfg.users,1); offered = zeros(cfg.users,1);
queue = zeros(cfg.users,1); completed = zeros(cfg.users,1);
deliveredTti = zeros(cfg.users,windowTti);
completedTti = false(cfg.users,windowTti);
occupiedRbTti = 0; physicalSum = 0; maxViolation = 0;
fd = (cfg.speedKmh/3.6)*cfg.frequencyGhz*1e9/299792458;
timeCorrelation = besselj(0,2*pi*fd*20*cfg.ttiMs/1000);
rxCorrelation = 0.35.^abs((1:4)'-(1:4)); cholRx = chol(rxCorrelation,'lower');
events = repmat(struct('tti',0,'srs_group',0,'csi_rs',false, ...
    'fast_beam_update',false,'slow_association_review',false, ...
    'association_changes_deferred',0,'mean_displacement_m',0, ...
    'max_trp_power_watt',0),windowTti/20,1);
ticId = tic;
for t = 0:20:windowTti-20
    if t > 0
        oldXy = ueXy; ueXy = ueXy + velocity*(20*cfg.ttiMs/1000);
        for g = 1:G
            ids = resources(g).ueIds(:);
            for localUeIdx = 1:numel(ids)
                globalUeId = ids(localUeIdx);
                for l = find(linkMask{g}(localUeIdx,:))
                    oldD = max(norm(oldXy(globalUeId,:)-scene.trp_xy(l,:)),10);
                    newD = max(norm(ueXy(globalUeId,:)-scene.trp_xy(l,:)),10);
                    newGain = gain{g}(localUeIdx,l)*(oldD/newD)^3.2;
                    drift = sqrt(newGain/max(gain{g}(localUeIdx,l),1e-30));
                    z = (randn(stream,4,64)+1i*randn(stream,4,64))/sqrt(2);
                    innovation = sqrt(newGain)*cholRx*z;
                    truth{g}(localUeIdx,l,:,:) = reshape(timeCorrelation*drift*reshape(truth{g}(localUeIdx,l,:,:),4,64) + ...
                        sqrt(max(0,1-timeCorrelation^2))*innovation,1,1,4,64);
                    est{g}(localUeIdx,l,:,:) = timeCorrelation*drift*est{g}(localUeIdx,l,:,:);
                    priorCov = reshape(cov{g}(localUeIdx,l,:,:),4,4);
                    cov{g}(localUeIdx,l,:,:) = reshape((timeCorrelation*drift)^2*priorCov + ...
                        (1-timeCorrelation^2)*newGain*rxCorrelation,1,1,4,4);
                    gain{g}(localUeIdx,l) = newGain;
                end
            end
        end
    end
    srsGroup = mod(t/20,17)+1;
    csiEvent = mod(t,cfg.csiRsPeriodTti)==0;
    if t > 0
        for g = 1:G
            if ~csiEvent && g ~= srsGroup, continue; end
            K = numel(resources(g).ueIds);
            for k = 1:K
                for l = find(linkMask{g}(k,:))
                    base = gain{g}(k,l);
                    hMean = reshape(est{g}(k,l,:,:),4,64);
                    c = reshape(cov{g}(k,l,:,:),4,4);
                    hTrue = reshape(truth{g}(k,l,:,:),4,64);
                    if csiEvent
                        [hMean,c] = posterior(hMean,c,hTrue,1:4, ...
                            base/10^(cfg.csiRsSnrDb/10),stream);
                    end
                    if g == srsGroup
                        [hMean,c] = posterior(hMean,c,hTrue,cfg.srsRxRows, ...
                            base/10^(cfg.pilotSnrDb/10),stream);
                    end
                    est{g}(k,l,:,:) = reshape(hMean,1,1,4,64);
                    cov{g}(k,l,:,:) = reshape(c,1,1,4,4);
                end
            end
        end
    end
    fast = strcmp(beamPolicy,'estimated_svd') && t>0 && mod(t,fastPeriod)==0;
    slow = t>0 && mod(t,slowPeriod)==0;
    if fast
        precoder = fast_svd(resources,est,precoder,cfg.powerWattPerTrp);
    end
    changes = 0;
    if slow
        for g = 1:G
            resource = resources(g); ids = resource.ueIds(:);
            for localUeIdx = 1:numel(ids)
                globalUeId = ids(localUeIdx); old = find(resource.servingMask(:,localUeIdx));
                active = unique(scene.home(ids));
                distances = vecnorm(scene.trp_xy(active,:)-ueXy(globalUeId,:),2,2);
                [~,order] = sort(distances); ordered = active(order);
                proposed = [scene.home(globalUeId);ordered(ordered~=scene.home(globalUeId))];
                proposed = proposed(1:min(cfg.serviceTrps,numel(proposed)));
                changes = changes + ~isequal(sort(old),sort(proposed));
            end
        end
    end
    capacity = zeros(cfg.users,1);
    for g = 1:G
        ids = resources(g).ueIds(:); K = numel(ids);
        if K == 0, continue; end
        rbWeight = rb_weight(resources(g)); rb = 273*rbWeight;
        rr = true_rates(truth{g},precoder{g});
        capacity(ids) = capacity(ids) + rr*rb*12*cfg.scsHz*cfg.ttiMs/1000;
        physicalSum = physicalSum + sum(rr)*rbWeight*20/windowTti;
        allocated(ids) = allocated(ids) + rb*20;
        for l = 1:L
            tx = false(K,1);
            for k = 1:K
                tx(k) = any(reshape(abs(precoder{g}(l,k,:,:)),[],1)>1e-10);
            end
            if any(tx)
                occupiedRbTti = occupiedRbTti + rb*nnz(any(busy(ids(tx),t+(1:20)),1));
            end
        end
    end
    for tt = t+(1:20)
        demand = ones(cfg.users,1); demand(tail(:,tt)) = 2/7;
        incoming = double(busy(:,tt)).*demand*offeredMbps*1e6*cfg.ttiMs/1000;
        queue = queue + incoming; offered = offered + incoming;
        sent = min(queue,capacity); queue = queue-sent;
        qualified = busy(:,tt) & ~terminal(:,tt);
        deliveredTti(:,tt) = sent.*qualified;
        volume = volume + deliveredTti(:,tt);
        served = served + double(sent>0 & busy(:,tt));
        completedTti(:,tt) = terminal(:,tt) & queue<1;
        completed = completed + double(completedTti(:,tt));
    end
    powers = power_by_trp(resources,precoder,L);
    maxViolation = max(maxViolation,max(max(powers-cfg.powerWattPerTrp,0)));
    e = t/20+1;
    events(e).tti = t; events(e).srs_group = srsGroup;
    events(e).csi_rs = csiEvent; events(e).fast_beam_update = fast;
    events(e).slow_association_review = slow;
    events(e).association_changes_deferred = changes;
    events(e).mean_displacement_m = mean(vecnorm(ueXy-scene.ue_xy,2,2));
    events(e).max_trp_power_watt = max(powers);
end
validUsers = valid>0; experience = nan(cfg.users,1);
experience(validUsers) = volume(validUsers)./(valid(validUsers)*cfg.ttiMs/1000)/1e6;
zeroExperience = experience; zeroExperience(~validUsers) = 0;
result = struct();
result.model = 'mobile RX-correlated Gauss-Markov; J0(2pi fD Delta); not full 38.901';
if strcmp(beamPolicy,'frozen'), decision = 'initial power/beam frozen';
else, decision = 'initial matrix WMMSE power; estimated-SVD fast beam refresh'; end
result.decision = [decision '; association review every 340 TTI with changes deferred'];
result.beam_policy = beamPolicy; result.traffic_seed = trafficSeed;
result.second_level_burst_filtered_proxy = chasi_second_metrics(deliveredTti,busy,terminal,cfg.ttiMs);
result.per_burst_throughput_proxy = chasi_burst_metrics(deliveredTti,busy,terminal,cfg.ttiMs);
result.completed_burst_ue_second_candidate = completed_candidate(deliveredTti,busy,terminal,completedTti,cfg.ttiMs);
result.acceptance_contract = acceptance_contract();
result.actual_busy_ue_tti_fraction = mean(busy(:));
result.actual_tail_tti_fraction_of_busy = nnz(tail)/max(nnz(busy),1);
result.window_tti = windowTti; result.window_seconds = windowTti*cfg.ttiMs/1000;
result.offered_mbps_per_active_ue = offeredMbps;
result.fast_period_tti = fastPeriod; result.slow_period_tti = slowPeriod;
result.configured_srs_snr_db = cfg.pilotSnrDb;
result.srs_condition_below_minus10_db = cfg.pilotSnrDb < -10;
result.doppler_hz = fd; result.twenty_tti_fading_correlation = timeCorrelation;
result.srs_events = numel(events); result.csi_rs_events = nnz([events.csi_rs]);
result.fast_updates = nnz([events.fast_beam_update]);
result.slow_reviews = nnz([events.slow_association_review]);
result.deferred_association_changes = sum([events.association_changes_deferred]);
result.users_with_valid_samples = nnz(validUsers);
result.valid_tti_total = sum(valid);
result.completed_bursts = sum(completed); result.total_bursts = nnz(terminal);
result.experience_bottom5_mbps_valid = linear_percentile(experience(validUsers),5);
result.experience_bottom5_mbps_all_zero_included = linear_percentile(zeroExperience,5);
result.experience_mean_mbps_valid = mean_or_nan(experience(validUsers));
result.physical_sum_bits_per_s_hz_time_mean = physicalSum;
result.allocated_prb_fraction_mean = mean(scene.active_prb_ratio);
result.actual_prb_fraction_mean = occupiedRbTti/(L*cfg.rbTotal*windowTti);
result.max_power_violation_watt = maxViolation;
result.runtime_seconds = toc(ticId);
result.per_ue_experience_mbps = experience;
result.per_ue_valid_tti = valid; result.per_ue_served_tti = served;
result.per_ue_allocated_rb_tti = allocated;
result.per_ue_completed_bursts = completed;
result.per_ue_offered_mbit = offered/1e6;
result.per_ue_delivered_mbit = volume/1e6;
result.delivered_bits_tti = deliveredTti;
result.completed_tti = completedTti;
result.events = events;
end

function value = opt(options,name,fallback)
if isfield(options,name), value = options.(name); else, value = fallback; end
end

function [updated,posteriorCov] = posterior(mu,c,truth,rows,noiseVar,stream)
rows = rows(:)';
s = c(rows,rows)+noiseVar*eye(numel(rows));
gain = c(:,rows)/s;
noise = sqrt(noiseVar/2)*(randn(stream,numel(rows),size(mu,2)) + ...
    1i*randn(stream,numel(rows),size(mu,2)));
updated = mu + gain*(truth(rows,:)+noise-mu(rows,:));
posteriorCov = c-gain*c(rows,:);
posteriorCov = (posteriorCov+posteriorCov')/2;
end

function updatedPrecoder = fast_svd(resources,est,precoder,budget)
G = numel(resources); L = size(precoder{1},1);
updatedPrecoder = cell(G,1);
for g = 1:G
    updatedPrecoder{g} = zeros(size(precoder{g}),'like',precoder{g});
    K = numel(resources(g).ueIds);
    numStreams = size(precoder{g},4); Nt = size(precoder{g},3);
    for l = 1:L
        for k = 1:K
            if ~resources(g).servingMask(l,k), continue; end
            power = sum(abs(reshape(precoder{g}(l,k,:,:),[],1)).^2);
            if power <= 0, continue; end
            h = reshape(est{g}(k,l,:,:),size(est{g},3),Nt);
            [~,~,right] = svd(h,'econ');
            updatedPrecoder{g}(l,k,:,:) = ...
                reshape(sqrt(power/numStreams)*right(:,1:numStreams), ...
                1,1,Nt,numStreams);
        end
    end
end
powers = power_by_trp(resources,updatedPrecoder,L);
for l = 1:L
    if powers(l) <= budget, continue; end
    lo = 0; hi = 1;
    while projected_power(resources,updatedPrecoder,l,hi) > budget
        hi = hi*2;
    end
    for step = 1:35
        mid = (lo+hi)/2;
        if projected_power(resources,updatedPrecoder,l,mid) > budget, lo = mid;
        else, hi = mid; end
    end
    for g = 1:G
        updatedPrecoder{g}(l,:,:,:) = ...
            updatedPrecoder{g}(l,:,:,:)/(1+hi*rb_weight(resources(g)));
    end
end
end

function power = projected_power(resources,precoder,l,lambda)
power = 0;
for g = 1:numel(resources)
    rbWeight = rb_weight(resources(g));
    power = power + rbWeight* ...
        sum(abs(reshape(precoder{g}(l,:,:,:),[],1)).^2)/(1+lambda*rbWeight)^2;
end
end

function power = power_by_trp(resources,precoder,L)
power = zeros(L,1);
for g = 1:numel(resources)
    rbWeight = rb_weight(resources(g));
    for l = 1:L
        power(l) = power(l)+rbWeight* ...
            sum(abs(reshape(precoder{g}(l,:,:,:),[],1)).^2);
    end
end
end

function rbWeight = rb_weight(resource)
if isfield(resource,'resourceWeightNu') && ~isempty(resource.resourceWeightNu)
    rbWeight = resource.resourceWeightNu;
elseif isfield(resource,'tx_rb_count') && ~isempty(resource.tx_rb_count)
    rbWeight = resource.tx_rb_count/273;
else
    rbWeight = resource.rb_count/273;
end
end

function out = true_rates(h,precoder)
K = size(h,1); L = size(h,2); Nr = size(h,3); Nt = size(h,4);
numStreams = size(precoder,4); out = zeros(K,1);
for k = 1:K
    interference = eye(Nr); signal = zeros(Nr,numStreams);
    for i = 1:K
        effective = zeros(Nr,numStreams);
        for l = 1:L
            effective = effective + reshape(h(k,l,:,:),Nr,Nt)* ...
                reshape(precoder(l,i,:,:),Nt,numStreams);
        end
        if i == k, signal = effective;
        else, interference = interference+effective*effective'; end
    end
    out(k) = max(0,(real(log(det(interference+signal*signal'))) - ...
        real(log(det(interference))))/log(2));
end
end

function value = mean_or_nan(x)
if isempty(x), value = NaN; else, value = mean(x); end
end

function value = linear_percentile(x,percentile)
if isempty(x), value = NaN; return; end
x = sort(x(:)); position = 1+(numel(x)-1)*percentile/100;
lo = floor(position); hi = ceil(position);
value = x(lo)+(position-lo)*(x(hi)-x(lo));
end

function out = completed_candidate(bits,busy,terminal,completed,ttiMs)
perSecond = 1000/ttiMs;
if abs(perSecond-round(perSecond))>1e-9
    error('chasi_time_evolution:Seconds','One second must contain integer TTIs.');
end
perSecond = round(perSecond); [numUEs,T] = size(busy);
seconds = floor(T/perSecond); samples = nan(numUEs,seconds);
eligibleCounts = zeros(numUEs,seconds); completedCounts = zeros(numUEs,seconds);
censoredCross = 0; censoredOpen = 0; terminalOnly = 0; notCompleted = 0;
for globalUeId = 1:numUEs
    active = false; start = 0; volume = 0; eligible = 0;
    for t = 1:T
        if busy(globalUeId,t) && ~active
            active = true; start = t; volume = 0; eligible = 0;
        end
        if ~active, continue; end
        if busy(globalUeId,t) && ~terminal(globalUeId,t)
            volume = volume+bits(globalUeId,t); eligible = eligible+1;
        end
        if terminal(globalUeId,t)
            startSecond = floor((start-1)/perSecond)+1;
            endSecond = floor((t-1)/perSecond)+1;
            if ~completed(globalUeId,t), notCompleted = notCompleted+1;
            elseif eligible==0, terminalOnly = terminalOnly+1;
            elseif startSecond==endSecond && endSecond<=seconds
                s = startSecond;
                if isnan(samples(globalUeId,s)), samples(globalUeId,s)=0; end
                samples(globalUeId,s)=samples(globalUeId,s)+volume;
                eligibleCounts(globalUeId,s)=eligibleCounts(globalUeId,s)+eligible;
                completedCounts(globalUeId,s)=completedCounts(globalUeId,s)+1;
            else, censoredCross = censoredCross+1;
            end
            active = false;
        end
    end
    if active, censoredOpen = censoredOpen+1; end
end
valid = eligibleCounts>0;
samples(valid) = samples(valid)./(eligibleCounts(valid)*ttiMs/1000)/1e6;
vals = samples(valid);
out = struct('counter_scope','simulated capacity/queue proxy, not ACKed RLC SDU', ...
    'aggregation','completed bursts wholly within each complete UE-second', ...
    'complete_seconds',seconds,'potential_ue_second_samples',numUEs*seconds, ...
    'valid_ue_second_samples',numel(vals), ...
    'ue_seconds_without_valid_burst',numUEs*seconds-numel(vals), ...
    'completed_bursts_counted',sum(completedCounts(:)), ...
    'terminal_bursts_not_queue_completed',notCompleted, ...
    'terminal_only_bursts',terminalOnly, ...
    'bursts_crossing_second_censored',censoredCross, ...
    'unfinished_bursts_censored',censoredOpen, ...
    'bottom5_mbps_valid_ue_seconds',linear_percentile(vals,5), ...
    'mean_mbps_valid_ue_seconds',mean_or_nan(vals), ...
    'per_ue_second_mbps',samples, ...
    'per_ue_second_eligible_tti',eligibleCounts, ...
    'per_ue_second_completed_bursts',completedCounts, ...
    'discarded_partial_window_tti',T-seconds*perSecond, ...
    'cdf_candidates',cdf_candidates(vals,numUEs*seconds-numel(vals)), ...
    'formal_edge_mbps',[], ...
    'formal_edge_unresolved_reason','ACKed RLC counter, cross-second burst handling, missing-user policy and CDF quantile convention are not specified by supplied image');
end

function out = cdf_candidates(values,missing)
out = struct('fraction',0.05,'valid_only',cdf_one(values), ...
    'missing_as_zero',cdf_one([values(:);zeros(missing,1)]), ...
    'missing_count',missing,'acceptance_missing_policy',[]);
end

function out = cdf_one(values)
values = sort(values(:)); n = numel(values);
out = struct('sample_count',n,'empirical_inverse_cdf_mbps',[], ...
    'linear_percentile_mbps',[],'lower_tail_mean_mbps',[], ...
    'lower_tail_count',0);
if n==0, return; end
lowerN = max(1,ceil(.05*n));
out.empirical_inverse_cdf_mbps = values(lowerN);
out.linear_percentile_mbps = linear_percentile(values,5);
out.lower_tail_mean_mbps = mean(values(1:lowerN));
out.lower_tail_count = lowerN;
end

function out = acceptance_contract()
out = struct( ...
    'system_srs_sinr_db',[], ...
    'system_srs_sinr_unresolved_reason','receiver, pilot/power assignment, link/time aggregation and interference scope not specified', ...
    'traffic_load_30_percent_pass',[], ...
    'traffic_load_unresolved_reason','official numerator, denominator and interval not specified; UE x TTI busy fraction is a proxy', ...
    'formal_edge_mbps',[], ...
    'acceptance_80_percent_pass',[], ...
    'acceptance_80_percent_interpretation','relative improvement: (candidate_edge-baseline_edge)/(ideal_central_edge-baseline_edge) >= 0.80', ...
    'acceptance_80_percent_reference','ideal-CSI centralized cooperation at 50% PRB', ...
    'acceptance_80_percent_unresolved_reason','formal edge samples, common baseline for this item, eligible UE rule and ideal-CSI reference convergence are not established');
end
