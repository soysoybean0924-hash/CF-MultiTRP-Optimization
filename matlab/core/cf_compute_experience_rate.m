function experience = cf_compute_experience_rate(cfg,ratePerStream,bMask,traffic)
%CF_COMPUTE_EXPERIENCE_RATE 3GPP-style DL experience-rate proxy.
%
% 3GPP TS 28.554 Sec. 6.3.6.2 defines DL UE throughput using
% ThpVolDl / ThpTimeDl after excluding idle or buffer-empty periods. In the
% If a burst traffic trace is available, non-empty buffer samples and tail
% samples come from that trace. Otherwise each scheduled UE/RBG transmission
% is treated as one non-empty DL sample.

if nargin < 3
    error('cfg, ratePerStream, and bMask are required.');
end
if nargin < 4
    traffic = [];
end

[~,numUEs,numRBGs] = size(ratePerStream);
scheduledMask = squeeze(any(bMask > 0,1));
if isempty(scheduledMask)
    scheduledMask = false(numUEs,numRBGs);
end

rateByUeSample = squeeze(sum(ratePerStream,1));
if isvector(rateByUeSample)
    rateByUeSample = reshape(rateByUeSample,numUEs,numRBGs);
end
rateByUeSample = double(rateByUeSample);
[sampleRate,scheduledSample,trafficInfo] = alignTrafficSamples(rateByUeSample,scheduledMask,traffic);
validSample = scheduledSample & trafficInfo.NonEmptyBufferMask & isfinite(sampleRate) & sampleRate > 0;

keptSample = false(size(validSample));
burstCount = zeros(numUEs,1);
excludedTailSamples = zeros(numUEs,1);
for u = 1:numUEs
    mask = validSample(u,:);
    if ~any(mask)
        continue;
    end
    if trafficInfo.HasTrace
        burstBounds = findBurstBoundsFromIds(mask,trafficInfo.BurstId(u,:));
    else
        burstBounds = findBurstBounds(mask);
    end
    burstCount(u) = size(burstBounds,1);
    for b = 1:size(burstBounds,1)
        firstIndex = burstBounds(b,1);
        lastIndex = burstBounds(b,2);
        burstSamples = firstIndex:lastIndex;
        if trafficInfo.HasTrace
            kept = burstSamples(~trafficInfo.TailSampleMask(u,burstSamples));
            removed = numel(burstSamples) - numel(kept);
            keptSample(u,kept) = true;
            excludedTailSamples(u) = excludedTailSamples(u) + removed;
        elseif isfield(cfg,'experience') && isfield(cfg.experience,'excludeLastBurstSample') && ...
                cfg.experience.excludeLastBurstSample
            if numel(burstSamples) > 1
                keptSample(u,burstSamples(1:end-1)) = true;
                excludedTailSamples(u) = excludedTailSamples(u) + 1;
            elseif keepSingleSampleBursts(cfg)
                keptSample(u,burstSamples) = true;
            else
                excludedTailSamples(u) = excludedTailSamples(u) + 1;
            end
        else
            keptSample(u,burstSamples) = true;
        end
    end
end

thpVolDl = sum(sampleRate .* trafficInfo.SampleVolumeScale .* keptSample,2);
thpTimeDl = sum(trafficInfo.SampleTimeDl .* keptSample,2);
ueExperienceRate = zeros(numUEs,1);
nonzeroTime = thpTimeDl > 0;
ueExperienceRate(nonzeroTime) = thpVolDl(nonzeroTime)./thpTimeDl(nonzeroTime);

sortedRate = sort(ueExperienceRate);
bottomPercentile = cfg.experience.bottomPercentile;
edgeIndex = max(1,ceil(bottomPercentile/100*numUEs));

experience = struct();
experience.Protocol = protocolName(cfg);
experience.SampleAxis = trafficInfo.SampleAxis;
experience.UsesBurstTraffic = trafficInfo.HasTrace;
experience.ThpVolDl = thpVolDl;
experience.ThpTimeDl = thpTimeDl;
experience.UeExperienceRate = ueExperienceRate;
experience.MeanExperienceRate = mean(ueExperienceRate);
experience.MinExperienceRate = min(ueExperienceRate);
experience.EdgeExperienceRate5 = sortedRate(edgeIndex);
experience.BottomPercentile = bottomPercentile;
experience.ScheduledSamples = sum(validSample,2);
experience.KeptSamples = thpTimeDl;
experience.ExcludedTailSamples = excludedTailSamples;
experience.BurstCount = burstCount;
experience.CdfRate = sortedRate;
experience.CdfProbability = (1:numUEs)'/numUEs;
experience.ValidSampleMask = validSample;
experience.KeptSampleMask = keptSample;
experience.NonEmptyBufferMask = trafficInfo.NonEmptyBufferMask;
experience.TailSampleMask = trafficInfo.TailSampleMask;
end

function [sampleRate,scheduledSample,info] = alignTrafficSamples(rateByUeSample,scheduledMask,traffic)
[U,G] = size(rateByUeSample);
hasTrace = isstruct(traffic) && isfield(traffic,'NonEmptyBufferMask') && ...
    ~isempty(traffic.NonEmptyBufferMask);
if hasTrace
    T = size(traffic.NonEmptyBufferMask,2);
    sampleIndex = 1 + mod((0:T-1),G);
    sampleRate = rateByUeSample(:,sampleIndex);
    scheduledSample = scheduledMask(:,sampleIndex);
    info.NonEmptyBufferMask = logical(traffic.NonEmptyBufferMask);
    info.BurstId = traffic.BurstId;
    info.TailSampleMask = logical(traffic.TailSampleMask);
    info.SampleVolumeScale = traffic.SampleVolumeScale;
    info.SampleTimeDl = traffic.SampleTimeDl;
    info.SampleAxis = traffic.SampleAxis;
    info.HasTrace = true;
else
    sampleRate = rateByUeSample;
    scheduledSample = scheduledMask;
    info.NonEmptyBufferMask = true(U,G);
    info.BurstId = zeros(U,G);
    info.TailSampleMask = false(U,G);
    info.SampleVolumeScale = ones(U,G);
    info.SampleTimeDl = ones(U,G);
    info.SampleAxis = cfgSampleAxisFallback();
    info.HasTrace = false;
end
end

function axisName = cfgSampleAxisFallback()
axisName = 'RBG';
end

function bounds = findBurstBounds(mask)
mask = logical(mask(:)');
starts = find(mask & [true ~mask(1:end-1)]);
stops = find(mask & [~mask(2:end) true]);
bounds = [starts(:),stops(:)];
end

function bounds = findBurstBoundsFromIds(mask,burstId)
ids = unique(burstId(mask));
ids(ids == 0) = [];
bounds = zeros(numel(ids),2);
for i = 1:numel(ids)
    samples = find(mask & burstId == ids(i));
    bounds(i,:) = [samples(1),samples(end)];
end
end

function value = keepSingleSampleBursts(cfg)
value = true;
if isfield(cfg,'experience') && isfield(cfg.experience,'keepSingleSampleBursts')
    value = logical(cfg.experience.keepSingleSampleBursts);
end
end

function name = protocolName(cfg)
if isfield(cfg,'experience') && isfield(cfg.experience,'protocol')
    name = cfg.experience.protocol;
else
    name = '3GPP TS 28.554 6.3.6.2 proxy';
end
end
