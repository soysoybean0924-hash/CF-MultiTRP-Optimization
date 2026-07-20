function scenario = cf_generate_scenario(cfg)
%CF_GENERATE_SCENARIO Generate fixed geometry and Nr x M x R x U x G H.

rng(cfg.seedPosition,'twister');
duXY = [cfg.areaX*rand(cfg.numDUs,1), cfg.areaY*rand(cfg.numDUs,1)];
ueXY = [cfg.areaX*rand(cfg.numUEs,1), cfg.areaY*rand(cfg.numUEs,1)];
duPosition = [duXY, cfg.duHeight*ones(cfg.numDUs,1)];
uePosition = [ueXY, cfg.ueHeight*ones(cfg.numUEs,1)];

Nr=cfg.numRxAntennas; M=cfg.numTxAntennas;
R=cfg.numDUs; U=cfg.numUEs; G=cfg.numRBGs;
rng(cfg.seedChannel,'twister');
H = complex(zeros(Nr,M,R,U,G));
distance = zeros(R,U);
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
end
