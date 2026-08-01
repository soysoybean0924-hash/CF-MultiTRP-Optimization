function measurement = cf_apply_srs_measurement_model(cfg,Htrue,distance)
%CF_APPLY_SRS_MEASUREMENT_MODEL Build ideal/nonideal SRS channel estimates.
%
% Htrue is the validation channel. Hest is the channel available to the
% scheduler and beam-weight calculation. For Huawei-style nonideal SRS,
% Presinr controls estimation error, measured RBs follow the SRS hopping
% pattern, and unmeasured RBs receive a larger uncertainty.

if nargin < 3
    distance = [];
end

[Nr,M,R,U,G] = size(Htrue);
mode = measurementMode(cfg);
measuredMask = true(R,U,G);
srsPresinrDb = inf(R,U,G);
errorVariance = zeros(R,U,G);

if strcmpi(mode,'ideal')
    Hest = Htrue;
else
    rng(measurementSeed(cfg),'twister');
    measuredMask = buildSrsMeasuredMask(cfg,R,U,G);
    srsPresinrDb = buildPresinr(cfg,Htrue,distance);
    linearPresinr = 10.^(srsPresinrDb/10);
    baseError = 1./(1+linearPresinr);
    baseError(~measuredMask) = baseError(~measuredMask) * cfg.measurement.unmeasuredErrorMultiplier;
    errorVariance = min(max(baseError,cfg.measurement.minimumErrorVariance), ...
        cfg.measurement.maximumErrorVariance);
    Hest = addEstimationError(Htrue,errorVariance,Nr,M,R,U,G);
end

measurement = struct();
measurement.Mode = mode;
measurement.H_true = Htrue;
measurement.H_est = Hest;
measurement.SrsPresinrDb = srsPresinrDb;
measurement.SrsMeasuredMask = measuredMask;
measurement.ErrorVariance = errorVariance;
measurement.UncertaintyStd = sqrt(errorVariance);
measurement.ChannelGainTrue = channelGainFromH(Htrue);
measurement.ChannelGainEstimated = channelGainFromH(Hest);
measurement.Description = 'H_true is used for validation; H_est is used by current scheduling code through scenario.H.';
end

function mode = measurementMode(cfg)
mode = 'ideal';
if isfield(cfg,'measurement') && isfield(cfg.measurement,'mode')
    mode = cfg.measurement.mode;
elseif strcmpi(cfg.profile,'huawei')
    mode = 'nonideal';
end
end

function seed = measurementSeed(cfg)
seed = cfg.seedChannel + 1009;
if isfield(cfg,'measurement') && isfield(cfg.measurement,'seed')
    seed = cfg.measurement.seed;
end
end

function measuredMask = buildSrsMeasuredMask(cfg,R,U,G)
measuredMask = false(R,U,G);
rbPerHop = min(G,fieldOrDefault(cfg.measurement,'srsRbPerHop',G));
lastHopRb = min(G,fieldOrDefault(cfg.measurement,'srsLastHopRb',rbPerHop));
hops = max(1,fieldOrDefault(cfg.measurement,'srsHoppingFactor',ceil(G/rbPerHop)));
for u = 1:U
    hop = mod(u-1,hops) + 1;
    firstRb = (hop-1)*rbPerHop + 1;
    count = rbPerHop;
    if hop == hops
        count = lastHopRb;
    end
    if firstRb > G
        firstRb = 1 + mod(firstRb-1,G);
    end
    rb = firstRb:min(G,firstRb+count-1);
    if isempty(rb)
        rb = 1:min(G,count);
    end
    measuredMask(:,u,rb) = true;
end
if ~any(measuredMask(:))
    measuredMask(:) = true;
end
end

function presinrDb = buildPresinr(cfg,Htrue,distance)
[~,~,R,U,G] = size(Htrue);
gain = channelGainFromH(Htrue);
gainDb = 10*log10(gain+eps);
gainDb = gainDb - median(gainDb(:));
if isempty(distance)
    distancePenalty = zeros(R,U);
else
    d = max(distance,cfg.minimumDistance);
    distancePenalty = cfg.measurement.presinrDistancePenaltyDb * ...
        log10(d/cfg.referenceDistance) / max(log10(max(d(:))/cfg.referenceDistance),eps);
end
shadow = cfg.measurement.presinrShadowStdDb * randn(R,U,G);
presinrDb = cfg.measurement.presinrReferenceDb + gainDb + shadow;
for g = 1:G
    presinrDb(:,:,g) = presinrDb(:,:,g) - distancePenalty;
end
presinrDb = min(max(presinrDb,-20),30);
end

function Hest = addEstimationError(Htrue,errorVariance,Nr,M,R,U,G)
noise = (randn(Nr,M,R,U,G)+1i*randn(Nr,M,R,U,G))/sqrt(2);
Hest = complex(zeros(size(Htrue)));
for g = 1:G
    for u = 1:U
        for r = 1:R
            err = errorVariance(r,u,g);
            signalScale = sqrt(max(0,1-err));
            noiseScale = sqrt(err) * rms(abs(Htrue(:,:,r,u,g)),'all');
            Hest(:,:,r,u,g) = signalScale*Htrue(:,:,r,u,g) + noiseScale*noise(:,:,r,u,g);
        end
    end
end
end

function gain = channelGainFromH(H)
[~,~,R,U,G] = size(H);
gain = zeros(R,U,G);
for g = 1:G
    for r = 1:R
        for u = 1:U
            h = H(:,:,r,u,g);
            gain(r,u,g) = sum(abs(h(:)).^2);
        end
    end
end
end

function value = fieldOrDefault(s,name,defaultValue)
if isfield(s,name)
    value = s.(name);
else
    value = defaultValue;
end
end
