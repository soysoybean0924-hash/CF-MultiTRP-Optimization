function candidate = cf_decode_candidate(x,cfg)
%CF_DECODE_CANDIDATE Map normalized x in [0,1]^9 to mixed parameters.
x=reshape(double(x),1,[]);
if numel(x)~=cfg.search.dimension
    error('Candidate must contain %d normalized variables.',cfg.search.dimension);
end
x=min(max(x,cfg.search.lowerBound),cfg.search.upperBound);
candidate.x=x;
% Continuous parameters use linear or log-scale maps depending on whether a
% multiplicative range is more natural. Count-like parameters are rounded.
candidate.betaPF=linearMap(x(1),cfg.search.betaPFRange);
candidate.numConnections=integerMap(x(2),cfg.search.numConnectionsRange);
candidate.scheduleThreshold=logMap(x(3),cfg.search.scheduleThresholdRange);
candidate.rhoLink=logMap(x(4),cfg.search.rhoLinkRange);
candidate.rhoPower=logMap(x(5),cfg.search.rhoPowerRange);
if cfg.maxRank<=1
    candidate.maxRank=1;
else
    % maxRank is binary in the normalized vector: lower half selects one
    % stream, upper half permits two streams when cfg.maxRank allows it.
    candidate.maxRank=min(1+double(x(6)>=0.5),cfg.maxRank);
end
candidate.rankThreshold=linearMap(x(7),cfg.search.rankThresholdRange);
candidate.repairPower=linearMap(x(8),cfg.search.repairPowerRange);
candidate.maxRepairLinks=integerMap(x(9),cfg.search.maxRepairLinksRange);
end
function value=linearMap(t,range)
value=range(1)+t*(range(2)-range(1));
end
function value=logMap(t,range)
value=10^(log10(range(1))+t*(log10(range(2))-log10(range(1))));
end
function value=integerMap(t,range)
value=round(linearMap(t,range)); value=min(max(value,ceil(range(1))),floor(range(2)));
end
