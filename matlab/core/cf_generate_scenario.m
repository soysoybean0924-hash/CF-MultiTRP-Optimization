function scenario = cf_generate_scenario(cfg)
%CF_GENERATE_SCENARIO Generate fixed geometry and Nr x M x R x U x G H.

% Position and channel seeds are separated so geometry-sensitive parameters
% can be tested independently from small-scale fading randomness.
rng(cfg.seedPosition,'twister');
[duXY,ueXY,siteIndex,cellIndex] = generateLayout(cfg);
duPosition = [duXY, cfg.duHeight*ones(cfg.numDUs,1)];
uePosition = [ueXY, cfg.ueHeight*ones(cfg.numUEs,1)];

Nr=cfg.numRxAntennas; M=cfg.numTxAntennas;
R=cfg.numDUs; U=cfg.numUEs; G=cfg.numRBGs;
rng(cfg.seedChannel,'twister');
H = complex(zeros(Nr,M,R,U,G));
distance = zeros(R,U);
% H(:,:,r,u,g) is the narrowband MIMO channel from DU r to UE u on RBG g.
% Large-scale pathloss is distance based; small-scale fading is Rayleigh.
for r=1:R
    for u=1:U
        d=max(norm(duPosition(r,:)-uePosition(u,:)),cfg.minimumDistance);
        distance(r,u)=d;
        largeScale=(d/cfg.referenceDistance)^(-cfg.pathlossExponent/2);
        for g=1:G
            smallScale=(randn(Nr,M)+1i*randn(Nr,M))/sqrt(2);
            H(:,:,r,u,g)=largeScale*smallScale;
        end
    end
end
if cfg.normalizeChannel
    % Normalization keeps score magnitudes comparable across random seeds and
    % profiles while preserving relative channel structure.
    H=H/sqrt(mean(abs(H(:)).^2)+eps);
end
channelGain=zeros(R,U,G);
for g=1:G
    for r=1:R
        for u=1:U
            h=H(:,:,r,u,g); channelGain(r,u,g)=sum(abs(h(:)).^2);
        end
    end
end
scenario.H=H; scenario.channelGain=channelGain; scenario.distance=distance;
scenario.duPosition=duPosition; scenario.uePosition=uePosition;
scenario.siteIndex=siteIndex; scenario.cellIndex=cellIndex;
scenario.profile=cfg.profile;
if isfield(cfg,'channelModel'), scenario.channelModel=cfg.channelModel; end
if isfield(cfg,'frequencyGHz'), scenario.frequencyGHz=cfg.frequencyGHz; end
end

function [duXY,ueXY,siteIndex,cellIndex] = generateLayout(cfg)
if isfield(cfg,'numSites') && isfield(cfg,'cellsPerSite') && cfg.numDUs == cfg.numSites*cfg.cellsPerSite
    siteXY = generateSevenSiteLayout(cfg);
    duXY = zeros(cfg.numDUs,2);
    siteIndex = zeros(cfg.numDUs,1);
    cellIndex = zeros(cfg.numDUs,1);
    index = 1;
    for s = 1:cfg.numSites
        for c = 1:cfg.cellsPerSite
            angle = 2*pi*(c-1)/cfg.cellsPerSite;
            offset = 0.03*cfg.interSiteDistance*[cos(angle),sin(angle)];
            duXY(index,:) = siteXY(s,:) + offset;
            siteIndex(index) = s;
            cellIndex(index) = c;
            index = index + 1;
        end
    end
    ueXY = generateSectorUsers(cfg,siteXY);
else
    duXY = [cfg.areaX*rand(cfg.numDUs,1), cfg.areaY*rand(cfg.numDUs,1)];
    ueXY = [cfg.areaX*rand(cfg.numUEs,1), cfg.areaY*rand(cfg.numUEs,1)];
    siteIndex = (1:cfg.numDUs)';
    cellIndex = ones(cfg.numDUs,1);
end
end

function siteXY = generateSevenSiteLayout(cfg)
center = [cfg.areaX cfg.areaY]/2;
radius = cfg.interSiteDistance;
siteXY = zeros(cfg.numSites,2);
siteXY(1,:) = center;
for s = 2:cfg.numSites
    angle = 2*pi*(s-2)/max(1,cfg.numSites-1);
    siteXY(s,:) = center + radius*[cos(angle),sin(angle)];
end
siteXY(:,1) = min(max(siteXY(:,1),0),cfg.areaX);
siteXY(:,2) = min(max(siteXY(:,2),0),cfg.areaY);
end

function ueXY = generateSectorUsers(cfg,siteXY)
ueXY = zeros(cfg.numUEs,2);
usersPerCell = floor(cfg.numUEs/cfg.numDUs)*ones(cfg.numDUs,1);
usersPerCell(1:mod(cfg.numUEs,cfg.numDUs)) = usersPerCell(1:mod(cfg.numUEs,cfg.numDUs)) + 1;
cellRadius = 0.5*cfg.interSiteDistance;
index = 1;
for r = 1:cfg.numDUs
    site = ceil(r/cfg.cellsPerSite);
    cell = mod(r-1,cfg.cellsPerSite) + 1;
    boresight = 2*pi*(cell-1)/cfg.cellsPerSite;
    count = usersPerCell(r);
    for u = 1:count
        localAngle = boresight + (rand-0.5)*(2*pi/cfg.cellsPerSite);
        localRadius = cellRadius*sqrt(rand);
        pos = siteXY(site,:) + localRadius*[cos(localAngle),sin(localAngle)];
        ueXY(index,:) = [min(max(pos(1),0),cfg.areaX), min(max(pos(2),0),cfg.areaY)];
        index = index + 1;
    end
end
end
