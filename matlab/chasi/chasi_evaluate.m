function metrics = chasi_evaluate(scene,solution,traffic)
%CHASI_EVALUATE Held-out true-channel rates and burst-aware throughput proxy.
%   Input resource H_true is [scheduled UE,TRP,RX,TX], precoder{g} is
%   [TRP,scheduled UE,TX,rank]. Traffic fields are [global UE,TTI] masks.
cfg = scene.config;
numUEs = cfg.users; T = cfg.durationTti;
if nargin < 3 || isempty(traffic)
    [busy,tail,terminal] = chasi_traffic(numUEs,T,cfg.seed,cfg.trafficModel,cfg.trafficLoad);
elseif isstruct(traffic)
    busy = logical(traffic.busy); tail = logical(traffic.tail);
    terminal = logical(traffic.terminal);
elseif iscell(traffic) && numel(traffic) == 3
    busy = logical(traffic{1}); tail = logical(traffic{2});
    terminal = logical(traffic{3});
else
    error('chasi_evaluate:Traffic','Traffic must be a struct or three-mask cell.');
end
if ~isequal(size(busy),[numUEs,T]) || ~isequal(size(tail),[numUEs,T]) || ...
        ~isequal(size(terminal),[numUEs,T]) || any(tail(:) & ~busy(:)) || ...
        any(terminal(:) & ~busy(:))
    error('chasi_evaluate:Traffic','Traffic masks must be valid [UE,TTI] arrays.');
end
precoders = solution.precoder;
resources = scene.resources;
if numel(precoders) ~= numel(resources)
    error('chasi_evaluate:Groups','Resource and precoder group counts differ.');
end
G = numel(resources); L = size(precoders{1},1);
perPhysical = zeros(numUEs,1); perGroup = zeros(numUEs,G);
scheduled = false(numUEs,1); allocatedRb = zeros(numUEs,1);
scheduledGroups = zeros(numUEs,1); serviceOccurrences = zeros(numUEs,1);
weightedPower = zeros(numUEs,1); volume = zeros(numUEs,1);
occupied = zeros(21,T); trpPower = zeros(L,1);
omittedExpected = 0; modeledNoise = 0; omittedMax = 0;
demand = ones(numUEs,T); demand(tail) = 2/7;
for g = 1:G
    resource = resources(g); precoder = precoders{g};
    ids = resource.ue_ids(:); K = numel(ids);
    if any(ids < 1 | ids > numUEs) || numel(unique(ids)) ~= K || ...
            size(resource.H_true,1) ~= K || ...
            size(precoder,1) ~= L || size(precoder,2) ~= K
        error('chasi_evaluate:Shape','Inconsistent resource or precoder axes.');
    end
    weight = rb_weight(resource);
    rr = true_rates(resource.H_true,precoder);
    perGroup(ids,g) = rr;
    perPhysical(ids) = perPhysical(ids) + rr*weight;
    trpNorm = squeeze(sum(sum(sum(abs(precoder).^2,4),3),2));
    trpNorm = reshape(trpNorm,L,1);
    trpPower = trpPower + weight*trpNorm;
    omitted = resource.omitted_gain * trpNorm * 4;
    omittedExpected = omittedExpected + sum(omitted)*weight;
    modeledNoise = modeledNoise + K*4*weight;
    if ~isempty(omitted), omittedMax = max(omittedMax,max(omitted)); end
    groupOccupied = false(L,T);
    for ki = 1:K
        u = ids(ki);
        scheduled(u) = true;
        allocatedRb(u) = allocatedRb(u) + 273*weight;
        scheduledGroups(u) = scheduledGroups(u) + 1;
        activeTrp = false(L,1);
        for l = 1:L
            activeTrp(l) = any(abs(reshape(precoder(l,ki,:,:),[],1)) > 1e-10);
        end
        serviceOccurrences(u) = serviceOccurrences(u) + nnz(activeTrp);
        weightedPower(u) = weightedPower(u) + ...
            weight*sum(abs(reshape(precoder(:,ki,:,:),[],1)).^2);
        usable = busy(u,:) & ~terminal(u,:);
        volume(u) = volume(u) + sum(double(usable).*demand(u,:)) * ...
            rr(ki) * (273*weight) * 12*cfg.scsHz * cfg.ttiMs/1000;
        groupOccupied(activeTrp,:) = groupOccupied(activeTrp,:) | repmat(busy(u,:),nnz(activeTrp),1);
    end
    occupied(1:L,:) = occupied(1:L,:) + (273*weight)*double(groupOccupied);
end
valid = sum((busy & ~terminal) & scheduled,2);
experience = nan(numUEs,1); good = valid > 0;
experience(good) = volume(good)./(valid(good)*cfg.ttiMs/1000);
expGood = experience(good)/1e6;
zeroIncluded = experience/1e6; zeroIncluded(~good) = 0;
powerMean = mean(trpPower); powerMax = max(trpPower);
if isempty(trpPower), powerMean = 0; powerMax = 0; end
metrics = struct();
metrics.users_total = numUEs;
metrics.users_with_valid_samples = nnz(good);
metrics.users_without_valid_samples = nnz(~good);
metrics.valid_sample_count = sum(valid);
metrics.duration_tti = T;
metrics.physical_mean_bits_per_s_hz = mean(perPhysical);
metrics.physical_sum_bits_per_s_hz = sum(perPhysical);
metrics.experience_mean_mbps_valid_ues = mean_or_nan(expGood);
metrics.experience_bottom5_mbps_valid_ues = percentile_or_nan(expGood,5);
metrics.experience_bottom5_mbps_all_ues_zero_included = percentile_or_nan(zeroIncluded,5);
metrics.static_experience_cdf_candidates = cdf_candidates(expGood,nnz(~good));
metrics.acceptance_contract = acceptance_contract();
metrics.experience_zero_included_mean_mbps = mean(zeroIncluded);
metrics.allocated_prb_fraction_mean = mean(scene.active_prb_ratio);
metrics.actual_prb_fraction_mean = mean(occupied(:)/cfg.rbTotal);
metrics.offered_load_target = cfg.trafficLoad;
metrics.traffic_model = cfg.trafficModel;
metrics.traffic_load_definition = 'target UE x TTI buffer-nonempty fraction only in target_busy_fraction mode; not confirmed Huawei 30% offered load';
metrics.actual_busy_ue_tti_fraction = mean(busy(:));
metrics.actual_tail_tti_fraction_of_busy = nnz(tail)/max(nnz(busy),1);
metrics.actual_tail_demand_fraction_of_arrivals = sum(demand(tail))/max(sum(demand(busy)),1);
metrics.total_bursts_started_proxy = nnz(terminal);
metrics.omitted_interference_expected_over_noise = omittedExpected/max(modeledNoise,1e-30);
metrics.omitted_interference_max_ue_rbg_normalized_power = omittedMax;
metrics.trp_power_watt_mean = powerMean;
metrics.trp_power_watt_max = powerMax;
metrics.total_radiated_power_watt = sum(trpPower);
metrics.energy_scope = 'radiated TX power only; PA/baseband/fronthaul energy unavailable';
metrics.sample_definition = sprintf('per UE, busy DL TTIs except terminal TTI of each burst; window [0,%d) TTI; users without valid samples reported separately',T);
metrics.per_ue_physical_bits_per_s_hz = perPhysical;
metrics.per_ue_experience_mbps = experience/1e6;
metrics.per_ue_weighted_tx_power_watt = weightedPower;
metrics.per_ue_allocated_rb = allocatedRb;
metrics.per_ue_scheduled_groups = scheduledGroups;
metrics.per_ue_service_trp_occurrences = serviceOccurrences;
metrics.per_ue_busy_tti = sum(busy,2);
metrics.per_ue_tail_tti = sum(tail,2);
metrics.per_ue_terminal_tti = sum(terminal,2);
metrics.per_ue_valid_tti = valid;
metrics.per_ue_delivered_bits_proxy = volume;
end

function rbWeight = rb_weight(resource)
if isfield(resource,'tx_rb_count') && ~isempty(resource.tx_rb_count)
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
        else, interference = interference + effective*effective'; end
    end
    allSignal = interference + signal*signal';
    out(k) = max(0,(real(log(det(allSignal))) - real(log(det(interference))))/log(2));
end
end

function value = mean_or_nan(x)
if isempty(x), value = NaN; else, value = mean(x); end
end

function value = percentile_or_nan(x,percentile)
if isempty(x), value = NaN; return; end
x = sort(x(:));
position = 1 + (numel(x)-1)*percentile/100;
lo = floor(position); hi = ceil(position);
value = x(lo) + (position-lo)*(x(hi)-x(lo));
end

function out = cdf_candidates(values,missing)
out = struct('fraction',0.05,'valid_only',cdf_one(values), ...
    'missing_as_zero',cdf_one([values(:);zeros(missing,1)]), ...
    'missing_count',missing,'acceptance_missing_policy',[]);
end

function out = cdf_one(values)
values = sort(values(:)); n = numel(values);
out = struct('sample_count',n,'empirical_inverse_cdf_mbps',NaN, ...
    'linear_percentile_mbps',NaN,'lower_tail_mean_mbps',NaN,'lower_tail_count',0);
if n == 0, return; end
lowerN = max(1,ceil(0.05*n));
out.empirical_inverse_cdf_mbps = values(lowerN);
out.linear_percentile_mbps = percentile_or_nan(values,5);
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
