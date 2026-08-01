function traffic = cf_generate_burst_traffic(cfg)
%CF_GENERATE_BURST_TRAFFIC Generate per-UE DL burst samples for experience rate.
%
% The trace models the validation-scene burst traffic controls: PRB
% utilization, tail-packet data fraction, and tail TTI fraction. Samples are
% lightweight UE x time masks and can be reused by cf_compute_experience_rate.

if ~isfield(cfg,'traffic') || ~isfield(cfg.traffic,'model') || ...
        ~strcmpi(cfg.traffic.model,'burst')
    traffic = struct();
    return;
end

rng(cfg.traffic.seed,'twister');
U = cfg.numUEs;
T = trafficSamples(cfg);
if ~isfield(cfg,'prbUtilizationRange')
    utilRange = [cfg.loadRatio cfg.loadRatio];
else
    utilRange = cfg.prbUtilizationRange;
end
utilization = utilRange(1) + (utilRange(2)-utilRange(1))*rand(U,1);

nonEmpty = false(U,T);
burstId = zeros(U,T);
tailMask = false(U,T);
volumeScale = ones(U,T);
sampleTime = ones(U,T);
burstRows = {};
nextBurstId = 1;
for u = 1:U
    targetSamples = max(1,round(utilization(u)*T));
    usedSamples = 0;
    cursor = randi(max(1,min(T,ceil(0.1*T))));
    while usedSamples < targetSamples && cursor <= T
        remaining = targetSamples - usedSamples;
        len = min([remaining,randomBurstLength(cfg),T-cursor+1]);
        if len <= 0
            break;
        end
        samples = cursor:(cursor+len-1);
        nonEmpty(u,samples) = true;
        burstId(u,samples) = nextBurstId;
        tailCount = max(1,ceil(cfg.traffic.tailTtiFraction*len));
        tailStart = max(1,numel(samples)-tailCount+1);
        tailSamples = samples(tailStart:end);
        tailMask(u,tailSamples) = true;
        volumeScale(u,tailSamples) = cfg.traffic.tailDataFraction / ...
            max(cfg.traffic.tailTtiFraction,eps);
        burstRows{end+1,1} = [u,nextBurstId,samples(1),samples(end),len,tailCount]; %#ok<AGROW>
        nextBurstId = nextBurstId + 1;
        usedSamples = usedSamples + len;
        gap = randi(max(1,round(0.15*T)));
        cursor = cursor + len + gap;
        if cursor > T && usedSamples < targetSamples
            openSamples = find(~nonEmpty(u,:));
            addCount = min(numel(openSamples),targetSamples-usedSamples);
            if addCount > 0
                selected = openSamples(1:addCount);
                nonEmpty(u,selected) = true;
                burstId(u,selected) = nextBurstId;
                tailMask(u,selected(end)) = true;
                volumeScale(u,selected(end)) = cfg.traffic.tailDataFraction / ...
                    max(cfg.traffic.tailTtiFraction,eps);
                burstRows{end+1,1} = [u,nextBurstId,selected(1),selected(end),addCount,1]; %#ok<AGROW>
                nextBurstId = nextBurstId + 1;
            end
            break;
        end
    end
end

traffic = struct();
traffic.Model = 'burst';
traffic.NumSamples = T;
traffic.SampleAxis = 'TTI';
traffic.NonEmptyBufferMask = nonEmpty;
traffic.BurstId = burstId;
traffic.TailSampleMask = tailMask;
traffic.SampleVolumeScale = volumeScale;
traffic.SampleTimeDl = sampleTime;
traffic.TargetPrbUtilization = utilization;
traffic.ActualPrbUtilization = mean(nonEmpty,2);
traffic.TailDataFraction = cfg.traffic.tailDataFraction;
traffic.TailTtiFraction = cfg.traffic.tailTtiFraction;
traffic.BurstTable = burstTable(burstRows);
end

function T = trafficSamples(cfg)
if isfield(cfg.traffic,'numSamples') && ~isempty(cfg.traffic.numSamples)
    T = max(1,round(cfg.traffic.numSamples));
else
    T = cfg.numRBGs;
end
end

function len = randomBurstLength(cfg)
lo = cfg.traffic.minBurstTti;
hi = cfg.traffic.maxBurstTti;
mid = cfg.traffic.meanBurstTti;
len = round(max(lo,min(hi,mid + 0.35*mid*randn)));
end

function t = burstTable(rows)
if isempty(rows)
    t = table();
    return;
end
matrix = vertcat(rows{:});
t = array2table(matrix,'VariableNames', ...
    {'UE','BurstId','StartSample','EndSample','Length','TailSamples'});
end
