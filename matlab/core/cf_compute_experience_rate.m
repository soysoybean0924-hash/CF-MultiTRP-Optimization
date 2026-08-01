function experience = cf_compute_experience_rate(cfg,ratePerStream,bMask)
%CF_COMPUTE_EXPERIENCE_RATE 3GPP-style DL experience-rate proxy.
%
% 3GPP TS 28.554 Sec. 6.3.6.2 defines DL UE throughput using
% ThpVolDl / ThpTimeDl after excluding idle or buffer-empty periods. In the
% current simulator there is no packet-buffer time sequence yet, so each
% scheduled UE/RBG transmission is treated as one non-empty DL sample. The
% last sample of each contiguous burst is excluded by default, matching the
% protocol intent that the tail packet can distort throughput.

if nargin < 3
    error('cfg, ratePerStream, and bMask are required.');
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
validSample = scheduledMask & isfinite(rateByUeSample) & rateByUeSample > 0;

keptSample = false(numUEs,numRBGs);
burstCount = zeros(numUEs,1);
excludedTailSamples = zeros(numUEs,1);
for u = 1:numUEs
    mask = validSample(u,:);
    if ~any(mask)
        continue;
    end
    burstBounds = findBurstBounds(mask);
    burstCount(u) = size(burstBounds,1);
    for b = 1:size(burstBounds,1)
        firstIndex = burstBounds(b,1);
        lastIndex = burstBounds(b,2);
        burstSamples = firstIndex:lastIndex;
        if isfield(cfg,'experience') && isfield(cfg.experience,'excludeLastBurstSample') && ...
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

thpVolDl = sum(rateByUeSample .* keptSample,2);
thpTimeDl = sum(keptSample,2);
ueExperienceRate = zeros(numUEs,1);
nonzeroTime = thpTimeDl > 0;
ueExperienceRate(nonzeroTime) = thpVolDl(nonzeroTime)./thpTimeDl(nonzeroTime);

sortedRate = sort(ueExperienceRate);
bottomPercentile = cfg.experience.bottomPercentile;
edgeIndex = max(1,ceil(bottomPercentile/100*numUEs));

experience = struct();
experience.Protocol = protocolName(cfg);
experience.SampleAxis = cfg.experience.sampleAxis;
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
end

function bounds = findBurstBounds(mask)
mask = logical(mask(:)');
starts = find(mask & [true ~mask(1:end-1)]);
stops = find(mask & [~mask(2:end) true]);
bounds = [starts(:),stops(:)];
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
