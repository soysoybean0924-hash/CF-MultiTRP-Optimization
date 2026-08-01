function result=cf_evaluate_candidate(cfg,scenario,candidate,doOptimize)
%CF_EVALUATE_CANDIDATE Evaluate one b/p/r/W policy in a fixed H scenario.
if nargin<4, doOptimize=true; end

% Build the deterministic initial policy: top-gain DU associations bInit,
% stream rank r, receive subspace Q, and matched-filter-like W baseline.
[bInit,rankUG,Q,Wbaseline]=buildInitialState(cfg,scenario,candidate);
[Wbaseline,~]=normalizeAllDUPower(Wbaseline,cfg.maxDUPower);
pBaseline=powerFromW(Wbaseline);
baseline=computeMetrics(cfg,scenario,Wbaseline,bInit,Q,rankUG,ones(cfg.numUEs,1));
W=Wbaseline; history=emptyHistory();

if doOptimize && cfg.inner.maxIter>0
    % Inner loop alternates between metric evaluation, WPS weights, power
    % constraint multipliers, and a closed-form beamformer update.
    R=cfg.numDUs; U=cfg.numUEs; G=cfg.numRBGs; S=cfg.maxRank;
    lambda=zeros(R,G); mu=zeros(R,G); averageRate=ones(U,1);
    delta=1./((averageRate+cfg.inner.pfEpsilon).^candidate.betaPF);
    objectiveHistory=zeros(cfg.inner.maxIter,1); sumWPSHistory=objectiveHistory;
    activeLinksHistory=objectiveHistory; totalPowerHistory=objectiveHistory;
    fairnessHistory=objectiveHistory; relativeChangeHistory=objectiveHistory;

    for iter=1:cfg.inner.maxIter
        Wold=W;
        current=computeMetrics(cfg,scenario,W,bInit,Q,rankUG,delta);
        % zeta is the quadratic-transform auxiliary variable used to make
        % the beamformer update tractable for the current SLINR state.
        zeta=complex(zeros(S,U,G));
        for g=1:G
            for u=1:U
                for s=1:rankUG(u,g)
                    denominator=current.signalPower(s,u,g)+current.interferencePower(s,u,g)+cfg.noisePower;
                    zeta(s,u,g)=sqrt(delta(u)*(1+current.SLINR(s,u,g)))* ...
                        current.usefulAmplitude(s,u,g)/(denominator+eps);
                end
            end
        end

        pNow=powerFromW(W); alpha=1./(pNow+cfg.inner.alphaEpsilon);
        % lambda discourages too many effective active antenna/stream loads;
        % mu is updated after normalization for per-DU/RBG power violations.
        for g=1:G
            for r=1:R
                weightedLoad=sum(alpha(r,:,g).*pNow(r,:,g),'all');
                if weightedLoad>cfg.numTxAntennas
                    lambda(r,g)=lambda(r,g)+cfg.inner.lambdaStep*(weightedLoad-cfg.numTxAntennas);
                else
                    lambda(r,g)=max(0,lambda(r,g)-0.5*cfg.inner.lambdaStep);
                end
            end
        end

        Wnew=updateBeamformers(cfg,scenario,candidate,bInit,rankUG,Q, ...
            current.SLINR,delta,zeta,alpha,lambda,mu);
        [W,prePower]=normalizeAllDUPower(Wnew,cfg.maxDUPower);
        for g=1:G
            for r=1:R
                violation=prePower(r,g)-cfg.maxDUPower;
                if violation>0
                    mu(r,g)=mu(r,g)+cfg.inner.muStep*violation;
                else
                    mu(r,g)=max(0,mu(r,g)-0.5*cfg.inner.muStep);
                end
            end
        end

        W=ensureMinimumService(cfg,scenario,candidate,W,bInit,Q,rankUG);
        updated=computeMetrics(cfg,scenario,W,bInit,Q,rankUG,delta);
        averageRate=cfg.inner.rateAveragingFactor*averageRate+ ...
            (1-cfg.inner.rateAveragingFactor)*updated.userRate;
        delta=1./((averageRate+cfg.inner.pfEpsilon).^candidate.betaPF);
        pUpdated=powerFromW(W);
        activeLinks=sum(pUpdated(:)>candidate.scheduleThreshold);
        totalPower=sum(pUpdated(:)); sumWPS=sum(updated.WPS(:));
        objective=sumWPS;
        relativeChange=norm(W(:)-Wold(:))/(norm(Wold(:))+eps);
        objectiveHistory(iter)=objective; sumWPSHistory(iter)=sumWPS;
        activeLinksHistory(iter)=activeLinks; totalPowerHistory(iter)=totalPower;
        fairnessHistory(iter)=updated.Jain; relativeChangeHistory(iter)=relativeChange;
        if relativeChange<cfg.inner.tolerance, break; end
    end
    history.objective=objectiveHistory(1:iter); history.sumWPS=sumWPSHistory(1:iter);
    history.activeLinks=activeLinksHistory(1:iter); history.totalPower=totalPowerHistory(1:iter);
    history.Jain=fairnessHistory(1:iter); history.relativeChange=relativeChangeHistory(1:iter);
end

% Final cleanup: preserve minimum service, optionally repair weak users, and
% normalize once more before converting continuous power p into binary b.
W=ensureMinimumService(cfg,scenario,candidate,W,bInit,Q,rankUG);
pFinal=powerFromW(W); bFinal=double(pFinal>candidate.scheduleThreshold);
if doOptimize && candidate.maxRepairLinks>0
    [W,~,~]=repairWeakUsers(cfg,scenario,candidate,W,bInit,bFinal,Q,rankUG,baseline.userRate);
end
[W,~]=normalizeAllDUPower(W,cfg.maxDUPower);
W=ensureMinimumService(cfg,scenario,candidate,W,bInit,Q,rankUG);
[W,~]=normalizeAllDUPower(W,cfg.maxDUPower);
pFinal=powerFromW(W); bFinal=double(pFinal>candidate.scheduleThreshold);
proposed=computeMetrics(cfg,scenario,W,bFinal,Q,rankUG,ones(cfg.numUEs,1));
baselineExperience=cf_compute_experience_rate(cfg,baseline.ratePerStream,bInit);
proposedExperience=cf_compute_experience_rate(cfg,proposed.ratePerStream,bFinal);
[score,scoreParts]=computeScore(cfg,proposed,baseline,bFinal,pFinal,rankUG);

% Return both proposed and baseline fields so plotting, diagnostics, and
% sensitivity analysis can compare them without rerunning the candidate.
result.Candidate=candidate; result.Score=score; result.ScoreParts=scoreParts;
result.H=scenario.H; result.Q=Q; result.b=bFinal; result.p=pFinal; result.r=rankUG; result.W=W;
result.bInit=bInit; result.SLINR=proposed.SLINR; result.WPS=proposed.WPS;
result.ratePerStream=proposed.ratePerStream; result.userRate=proposed.userRate;
result.SumRate=proposed.SumRate; result.MeanRate=proposed.MeanRate;
result.MinRate=proposed.MinRate; result.Rate5=proposed.Rate5; result.Rate10=proposed.Rate10;
result.Jain=proposed.Jain; result.ActiveLinks=sum(bFinal(:)); result.TotalPower=sum(pFinal(:));
result.ActiveStreams=sum(rankUG(:)); result.ExperienceRate=proposedExperience; result.history=history;
result.baseline.W=Wbaseline; result.baseline.b=bInit; result.baseline.p=pBaseline; result.baseline.r=rankUG;
result.baseline.SLINR=baseline.SLINR; result.baseline.WPS=baseline.WPS;
result.baseline.userRate=baseline.userRate; result.baseline.SumRate=baseline.SumRate;
result.baseline.MeanRate=baseline.MeanRate; result.baseline.MinRate=baseline.MinRate;
result.baseline.Rate5=baseline.Rate5; result.baseline.Rate10=baseline.Rate10;
result.baseline.Jain=baseline.Jain; result.baseline.ActiveLinks=sum(bInit(:));
result.baseline.TotalPower=sum(pBaseline(:)); result.baseline.ExperienceRate=baselineExperience;
result.scenario=scenario;
end

function [bInit,rankUG,Q,W]=buildInitialState(cfg,scenario,candidate)
R=cfg.numDUs; U=cfg.numUEs; G=cfg.numRBGs; M=cfg.numTxAntennas;
Nr=cfg.numRxAntennas; Smax=cfg.maxRank; H=scenario.H;
bInit=zeros(R,U,G);
% For each UE/RBG, select the strongest candidate.numConnections DUs by
% channel gain. This forms the initial binary association tensor bInit.
for g=1:G
    for u=1:U
        [~,order]=sort(scenario.channelGain(:,u,g),'descend');
        count=min(candidate.numConnections,R); bInit(order(1:count),u,g)=1;
    end
end
rankUG=ones(U,G); Q=complex(zeros(Nr,U,G,Smax));
% The receive subspace Q and stream count r come from the SVD of the stacked
% selected-DU channel. rankThreshold decides whether the second stream is
% strong enough to keep.
for g=1:G
    for u=1:U
        selected=find(bInit(:,u,g)>0); Hstack=complex(zeros(Nr,M*numel(selected))); offset=0;
        for k=1:numel(selected)
            r=selected(k); Hstack(:,offset+(1:M))=H(:,:,r,u,g); offset=offset+M;
        end
        [leftVectors,singularValues,~]=svd(Hstack,'econ'); sigma=diag(singularValues); selectedRank=1;
        if candidate.maxRank>=2 && Nr>=2 && numel(sigma)>=2
            if sigma(2)^2/(sigma(1)^2+eps)>=candidate.rankThreshold, selectedRank=2; end
        end
        selectedRank=min([selectedRank,candidate.maxRank,Smax,size(leftVectors,2)]);
        rankUG(u,g)=selectedRank;
        Q(:,u,g,1:selectedRank)=reshape(leftVectors(:,1:selectedRank),Nr,1,1,selectedRank);
    end
end
W=complex(zeros(M,Smax,R,U,G));
% Initialize each active precoder along the effective channel direction.
for g=1:G
    for r=1:R
        for u=1:U
            if bInit(r,u,g)==0, continue; end
            for s=1:rankUG(u,g)
                hEff=H(:,:,r,u,g)'*Q(:,u,g,s); W(:,s,r,u,g)=hEff/(norm(hEff)+eps);
            end
        end
    end
end
end

function Wnew=updateBeamformers(cfg,scenario,candidate,bInit,rankUG,Q,SLINR,delta,zeta,alpha,lambda,mu)
R=cfg.numDUs; U=cfg.numUEs; G=cfg.numRBGs; M=cfg.numTxAntennas; Smax=cfg.maxRank;
H=scenario.H; Wnew=complex(zeros(M,Smax,R,U,G)); identityM=eye(M);
for g=1:G
    for r=1:R
        % commonA aggregates how DU r's beam affects all users on this RBG.
        commonA=complex(zeros(M,M));
        for up=1:U
            for sp=1:rankUG(up,g)
                hEff=H(:,:,r,up,g)'*Q(:,up,g,sp);
                commonA=commonA+abs(zeta(sp,up,g))^2*(hEff*hEff');
            end
        end
        for u=1:U
            if bInit(r,u,g)==0, continue; end
            penalty=lambda(r,g)*alpha(r,u,g)+mu(r,g);
            systemMatrix=commonA+(penalty+cfg.inner.regularization)*identityM;
            for s=1:rankUG(u,g)
                hEff=H(:,:,r,u,g)'*Q(:,u,g,s);
                scale=conj(zeta(s,u,g))*sqrt(delta(u)*(1+SLINR(s,u,g)));
                Wnew(:,s,r,u,g)=systemMatrix\(scale*hEff);
            end
        end
    end
end
end

function metrics=computeMetrics(cfg,scenario,W,bMask,Q,rankUG,delta)
R=cfg.numDUs; U=cfg.numUEs; G=cfg.numRBGs; Smax=cfg.maxRank; H=scenario.H;
SLINR=zeros(Smax,U,G); WPS=SLINR; signalPower=SLINR; interferencePower=SLINR;
usefulAmplitude=complex(zeros(Smax,U,G));
for g=1:G
    activeColumns=false(1,Smax*U);
    queryColumns=false(1,Smax*U);
    Wmasked=complex(zeros(cfg.numTxAntennas*R,Smax*U));
    Hquery=complex(zeros(cfg.numTxAntennas*R,Smax*U));
    for up=1:U
        for sp=1:rankUG(up,g)
            col=(sp-1)*U+up;
            activeColumns(col)=true;
            queryColumns(col)=true;
            Hquery(:,col)=effectiveChannelVector(H,Q,up,g,sp,R,cfg.numTxAntennas);
            for r=1:R
                if bMask(r,up,g)>0
                    rows=(r-1)*cfg.numTxAntennas+(1:cfg.numTxAntennas);
                    Wmasked(rows,col)=W(:,sp,r,up,g);
                end
            end
        end
    end
    activeIndex=find(activeColumns);
    queryIndex=find(queryColumns);
    if isempty(activeIndex) || isempty(queryIndex)
        continue;
    end
    amplitudeMatrix=Hquery(:,queryIndex)'*Wmasked(:,activeIndex);
    totalPowerByQuery=sum(abs(amplitudeMatrix).^2,2);
    [signalIsActive,signalLocations]=ismember(queryIndex,activeIndex);
    for qi=1:numel(queryIndex)
        col=queryIndex(qi);
        u=mod(col-1,U)+1;
        s=floor((col-1)/U)+1;
        if signalIsActive(qi)
            useful=amplitudeMatrix(qi,signalLocations(qi));
        else
            useful=0;
        end
        usefulAmplitude(s,u,g)=useful; signalPower(s,u,g)=abs(useful)^2;
        interference=max(real(totalPowerByQuery(qi)-signalPower(s,u,g)),0);
        interferencePower(s,u,g)=interference;
        SLINR(s,u,g)=signalPower(s,u,g)/(interference+cfg.noisePower+eps);
        % WPS is the weighted proportional-scheduling objective term
        % used by the inner loop, not the final J_true diagnostic.
        WPS(s,u,g)=delta(u)*log(1+SLINR(s,u,g));
    end
end
ratePerStream=log2(1+SLINR); userRate=zeros(U,1);
for u=1:U, userRate(u)=sum(ratePerStream(:,u,:),'all'); end
sortedRate=sort(userRate); idx5=max(1,ceil(0.05*U)); idx10=max(1,ceil(0.10*U));
metrics.SLINR=SLINR; metrics.WPS=WPS; metrics.signalPower=signalPower;
metrics.interferencePower=interferencePower; metrics.usefulAmplitude=usefulAmplitude;
metrics.ratePerStream=ratePerStream; metrics.userRate=userRate;
metrics.SumRate=sum(userRate); metrics.MeanRate=mean(userRate); metrics.MinRate=min(userRate);
metrics.Rate5=sortedRate(idx5); metrics.Rate10=sortedRate(idx10);
metrics.Jain=(sum(userRate)^2)/(U*sum(userRate.^2)+eps);
end

function hVector=effectiveChannelVector(H,Q,u,g,s,R,M)
q=Q(:,u,g,s);
hVector=complex(zeros(M*R,1));
for r=1:R
    rows=(r-1)*M+(1:M);
    hVector(rows)=H(:,:,r,u,g)'*q;
end
end

function p=powerFromW(W)
[~,S,R,U,G]=size(W); p=zeros(R,U,G);
for g=1:G
    for r=1:R
        for u=1:U
            for s=1:S, p(r,u,g)=p(r,u,g)+norm(W(:,s,r,u,g))^2; end
        end
    end
end
end

function [W,prePower]=normalizeAllDUPower(W,maxPower)
[~,S,R,U,G]=size(W); prePower=zeros(R,G);
for g=1:G
    for r=1:R
        total=0;
        for u=1:U
            for s=1:S, total=total+norm(W(:,s,r,u,g))^2; end
        end
        prePower(r,g)=total;
        if total>maxPower, W(:,:,r,:,g)=sqrt(maxPower/(total+eps)).*W(:,:,r,:,g); end
    end
end
end

function W=ensureMinimumService(cfg,scenario,candidate,W,bInit,Q,rankUG)
p=powerFromW(W);
% If a UE lost all links after thresholding, add a small protected beam on
% its strongest initial DU/RBG so every UE remains represented.
for u=1:cfg.numUEs
    if any(p(:,u,:)>candidate.scheduleThreshold,'all'), continue; end
    bestGain=-inf; bestR=1; bestG=1;
    for g=1:cfg.numRBGs
        for r=1:cfg.numDUs
            if bInit(r,u,g)>0 && scenario.channelGain(r,u,g)>bestGain
                bestGain=scenario.channelGain(r,u,g); bestR=r; bestG=g;
            end
        end
    end
    hEff=scenario.H(:,:,bestR,u,bestG)'*Q(:,u,bestG,1);
    protectPower=max([cfg.inner.minimumServicePower,10*candidate.scheduleThreshold,10*eps]);
    W(:,1,bestR,u,bestG)=sqrt(protectPower)*hEff/(norm(hEff)+eps);
    for s=2:rankUG(u,bestG), W(:,s,bestR,u,bestG)=0; end
    [W,~]=normalizeAllDUPower(W,cfg.maxDUPower); p=powerFromW(W);
end
end

function [W,bFinal,pFinal]=repairWeakUsers(cfg,scenario,candidate,W,bInit,bFinal,Q,rankUG,baselineRate)
current=computeMetrics(cfg,scenario,W,bFinal,Q,rankUG,ones(cfg.numUEs,1));
% Optional weak-user repair reactivates a limited number of previously
% selected links when a user's final rate falls below a baseline fraction.
for u=1:cfg.numUEs
    target=cfg.inner.fairnessRepairRatio*baselineRate(u);
    if current.userRate(u)>=target, continue; end
    candidates=[];
    for g=1:cfg.numRBGs
        for r=1:cfg.numDUs
            if bInit(r,u,g)>0 && bFinal(r,u,g)==0
                candidates=[candidates;r,g,scenario.channelGain(r,u,g)]; %#ok<AGROW>
            end
        end
    end
    if isempty(candidates), continue; end
    [~,order]=sort(candidates(:,3),'descend'); candidates=candidates(order,:); repairCount=0;
    for k=1:size(candidates,1)
        if repairCount>=candidate.maxRepairLinks, break; end
        r=candidates(k,1); g=candidates(k,2);
        hEff=scenario.H(:,:,r,u,g)'*Q(:,u,g,1);
        W(:,1,r,u,g)=sqrt(candidate.repairPower)*hEff/(norm(hEff)+eps);
        [W,~]=normalizeAllDUPower(W,cfg.maxDUPower); pFinal=powerFromW(W);
        bFinal=double(pFinal>candidate.scheduleThreshold);
        current=computeMetrics(cfg,scenario,W,bFinal,Q,rankUG,ones(cfg.numUEs,1));
        repairCount=repairCount+1;
        if current.userRate(u)>=target, break; end
    end
end
pFinal=powerFromW(W); bFinal=double(pFinal>candidate.scheduleThreshold);
end

function [score,parts]=computeScore(cfg,proposed,baseline,bFinal,pFinal,rankUG)
activeLinks=sum(bFinal(:)); totalPower=sum(pFinal(:)); activeStreams=sum(rankUG(:));
% The optimization score follows the paper-style max objective used in this
% project: maximize the scheduled sum log2(1+SINR). Resource, fairness, and
% power values are retained only as diagnostics.
minLoss=max(0,baseline.MinRate-proposed.MinRate);
rate10Loss=max(0,baseline.Rate10-proposed.Rate10);
jainLoss=max(0,cfg.score.jainTarget-proposed.Jain);
benefit=cfg.score.wSumRate*proposed.SumRate+cfg.score.wJain*proposed.Jain+ ...
    cfg.score.wMinRate*proposed.MinRate+cfg.score.wRate10*proposed.Rate10;
cost=cfg.score.wActiveLinks*activeLinks+cfg.score.wPower*totalPower+cfg.score.wStreams*activeStreams;
penalty=cfg.score.wMinRateLoss*minLoss+cfg.score.wRate10Loss*rate10Loss+cfg.score.wJainTarget*jainLoss;
legacyWeightedScore=benefit-cost-penalty;
score=proposed.SumRate;
parts.Objective='scheduled sum log2(1+SINR)';
parts.Benefit=benefit; parts.Cost=cost; parts.Penalty=penalty;
parts.LegacyWeightedScore=legacyWeightedScore;
parts.MinRateLoss=minLoss; parts.Rate10Loss=rate10Loss; parts.JainTargetLoss=jainLoss;
end

function h=emptyHistory()
h.objective=[]; h.sumWPS=[]; h.activeLinks=[]; h.totalPower=[]; h.Jain=[]; h.relativeChange=[];
end
