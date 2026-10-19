function scene = chasi_generate_scene(cfg)
%CHASI_GENERATE_SCENE Native formal 21-TRP / 273-RB CHASI scene.
% H and H_true are [scheduled UE, TRP, 4 RX, 64 TX]. C is the RX
% posterior covariance; the full error covariance is I_64 kron C.
if nargin==0, cfg=chasi_config(); end
assert(cfg.trps==21 && cfg.ueRxPorts==4 && cfg.txPorts==64);
rngGeometry=RandStream('mt19937ar','Seed',cfg.seed);
rngTrue=RandStream('mt19937ar','Seed',cfg.seed+201);
rngCsi=RandStream('mt19937ar','Seed',cfg.seed+202);
rngSrs=RandStream('mt19937ar','Seed',cfg.seed+203);
rngReuse=RandStream('mt19937ar','Seed',cfg.seed+204);
rxCorrelation=0.35.^abs((1:4)'-(1:4));
rxChol=chol(rxCorrelation,'lower');
[trp,ue,home,topology]=geometry(cfg,rngGeometry);
[usersByGroup,activeRatio,active,txCounts]=schedule(cfg,rngGeometry,home);
gains=zeros(cfg.users,cfg.trps);
for globalUeId=1:cfg.users
    for l=1:cfg.trps
        delta=ue(globalUeId,:)-trp(l,:);
        gains(globalUeId,l)=link_gain(cfg,norm(delta),atan2(delta(2),delta(1)),l,rngGeometry);
    end
end
homeGain=median(gains(sub2ind(size(gains),(1:cfg.users)',home)));
if strcmp(cfg.srsMode,'awgn_independent')
    calibration=calibrate(cfg,rxCorrelation);
else
    calibration=struct('status','not applicable: pilot reuse', ...
        'model','synthetic equal-power pilot reuse with Gaussian current/past correlation');
end
template=struct('H',[],'H_true',[],'C',[],'C_stat',[],'servingMask',[], ...
    'ueIds',[],'home_trp',[],'rb_start',0,'rb_count',0,'tx_rb_count',0, ...
    'srs_rb_start',0,'srs_rb_count',0, ...
    'resourceWeightNu',0, ...
    'prior_gain',[],'omitted_gain',[],'age_ms',0,'measured',false, ...
    'srs_diagnostic',[]);
resources=repmat(template,1,cfg.srsHops);
for g=1:cfg.srsHops
    ids=usersByGroup{g};
    k=numel(ids);
    serve=false(cfg.trps,k);
    H=complex(zeros(k,cfg.trps,4,64,'single'));
    Htrue=H;
    C=complex(zeros(k,cfg.trps,4,4,'single'));
    omitted=zeros(k,cfg.trps,'single');
    first=(g-1)*cfg.srsHopIntervalTti;
    measured=cfg.decisionTti>=first;
    if measured
        measuredAt=first+floor((cfg.decisionTti-first)/cfg.srsPeriodTti)*cfg.srsPeriodTti;
        age=(cfg.decisionTti-measuredAt)*cfg.ttiMs;
    else
        age=-1;
    end
    csiAge=mod(cfg.decisionTti,cfg.csiRsPeriodTti)*cfg.ttiMs;
    for localUeIdx=1:k
        globalUeId=ids(localUeIdx);
        distances=sqrt(sum((trp-ue(globalUeId,:)).^2,2));
        [~,nearest]=sort(distances);
        candidates=[home(globalUeId);nearest(nearest~=home(globalUeId) & active(nearest,g))];
        serve(candidates(1:min(cfg.serviceTrps,numel(candidates))),localUeIdx)=true;
        for l=1:cfg.trps
            if distances(l)>cfg.maxInterferenceDistanceM && ~serve(l,localUeIdx)
                omitted(localUeIdx,l)=gains(globalUeId,l);
                continue
            end
            gain=gains(globalUeId,l);
            truth=sqrt(gain)*rxChol*complex_normal(rngTrue,4,64);
            nc=gain/10^(cfg.csiRsSnrDb/10)*exp(2*csiAge/cfg.ageCoherenceMs);
            prior=gain*rxCorrelation;
            precision=prior\eye(4)+eye(4)/nc;
            yc=truth+sqrt(nc)*complex_normal(rngCsi,4,64);
            rhs=yc/nc;
            % Consume SRS noise for every modeled link, even before its
            % first measurement, so decision-time changes keep future draws.
            srsNoise=complex_normal(rngSrs,2,64);
            if measured && strcmp(cfg.srsMode,'awgn_independent')
                rows=cfg.srsRxRows;
                ns=gain/10^(cfg.pilotSnrDb/10)*exp(2*age/cfg.ageCoherenceMs);
                ys=truth(rows,:)+sqrt(ns)*srsNoise;
                precision(rows,rows)=precision(rows,rows)+eye(numel(rows))/ns;
                rhs(rows,:)=rhs(rows,:)+ys/ns;
            end
            posterior=precision\eye(4);
            H(localUeIdx,l,:,:)=reshape(single(posterior*rhs),1,1,4,64);
            Htrue(localUeIdx,l,:,:)=reshape(single(truth),1,1,4,64);
            C(localUeIdx,l,:,:)=reshape(single(posterior),1,1,4,4);
        end
    end
    diagnostics=struct([]);
    if measured && k>0 && strcmp(cfg.srsMode,'pilot_reuse_gaussian')
        pilotIds=mod(ids-1,cfg.srsPilotSequences)+1;
        noise=homeGain/10^(cfg.pilotSnrDb/10);
        for l=1:cfg.trps
            modeled=omitted(:,l)==0;
            if ~any(modeled), continue; end
            means=reshape(H(:,l,:,:),k,4,64);
            truth=reshape(Htrue(:,l,:,:),k,4,64);
            cov=reshape(C(:,l,:,:),k,4,4);
            [means,cov,diag]=reuse_update(means,cov,truth,gains(ids,l), ...
                modeled,pilotIds,noise,cfg.srsRxRows,age,cfg.ageCoherenceMs,...
                rxCorrelation,rxChol,rngReuse);
            H(:,l,:,:)=reshape(single(means),k,1,4,64);
            C(:,l,:,:)=reshape(single(cov),k,1,4,4);
            diag.trp_id=l;
            if isempty(diagnostics)
                diagnostics=diag;
            else
                diagnostics(end+1)=diag; %#ok<AGROW>
            end
        end
    end
    r=template;
    r.H=H; r.H_true=Htrue; r.C=C; r.C_stat=C;
    r.servingMask=serve; r.ueIds=ids(:); r.home_trp=home(ids(:));
    r.rb_start=cfg.rbGroups(g).start;
    r.rb_count=cfg.rbGroups(g).count; r.tx_rb_count=txCounts(g);
    r.srs_rb_start=cfg.rbGroups(g).start;
    r.srs_rb_count=cfg.srsRbCounts(g);
    r.resourceWeightNu=double(txCounts(g))/cfg.rbTotal;
    r.prior_gain=single(gains(ids,:)); r.omitted_gain=omitted;
    r.age_ms=age; r.measured=measured; r.srs_diagnostic=diagnostics;
    resources(g)=r;
end
events=repmat(struct('tti',0,'ms',0,'srs_group',0,'csi_rs',false),1,cfg.durationTti+1);
for t=0:cfg.durationTti
    events(t+1).tti=t;
    events(t+1).ms=t*cfg.ttiMs;
    if mod(t,cfg.srsHopIntervalTti)==0
        events(t+1).srs_group=mod(t/cfg.srsHopIntervalTti,cfg.srsHops)+1;
    end
    events(t+1).csi_rs=mod(t,cfg.csiRsPeriodTti)==0;
end
scheduleMask=false(cfg.users,cfg.srsHops);
for g=1:cfg.srsHops
    scheduleMask(resources(g).ueIds,g)=true;
end
scene=struct('config',cfg,'trp_xy',trp,'ue_xy',ue,'home',home, ...
    'topology',topology, ...
    'scheduleMask',scheduleMask, ...
    'resources',resources,'events',events,'active_prb_ratio',activeRatio, ...
    'calibration',calibration);
end

function [trp,ue,home,topology]=geometry(cfg,stream)
angleUniform=zeros(cfg.usersPerCell,cfg.trps);
radiusUniform=zeros(cfg.usersPerCell,cfg.trps);
for l=1:cfg.trps
    angleUniform(:,l)=rand(stream,cfg.usersPerCell,1);
    radiusUniform(:,l)=rand(stream,cfg.usersPerCell,1);
end
[trp,ue,home,topology]=chasi_geometry_from_samples(cfg,angleUniform,radiusUniform);
end

function [users,ratio,active,txCounts]=schedule(cfg,stream,home)
counts=[cfg.rbGroups.count];
active=false(cfg.trps,cfg.srsHops);
target=round(cfg.prbUtilization*cfg.rbTotal);
txCounts=zeros(1,cfg.srsHops);
if strcmp(cfg.scheduleMode,'precise_shared_rb')
    remaining=target;
    for g=randperm(stream,cfg.srsHops)
        txCounts(g)=min(counts(g),remaining);
        remaining=remaining-txCounts(g);
        if remaining==0, break; end
    end
    active(:,:)=repmat(txCounts>0,cfg.trps,1);
else
    for l=1:cfg.trps
        order=randperm(stream,cfg.srsHops);
        running=0;
        for g=order
            if running+counts(g)<=target+9
                active(l,g)=true;
                running=running+counts(g);
            end
            if running>=target-8, break; end
        end
    end
    txCounts=counts;
end
pools=cell(cfg.trps,1);
for l=1:cfg.trps
    ids=find(home==l);
    pools{l}=ids(randperm(stream,numel(ids)));
end
cursors=ones(cfg.trps,1);
users=cell(1,cfg.srsHops);
for g=1:cfg.srsHops
    selected=[];
    for l=find(active(:,g))'
        for j=1:cfg.usersPerActiveCellRb
            pos=mod(cursors(l)-1,numel(pools{l}))+1;
            selected(end+1,1)=pools{l}(pos); %#ok<AGROW>
            cursors(l)=cursors(l)+1;
        end
    end
    users{g}=selected;
end
ratio=active*txCounts(:)/cfg.rbTotal;
end

function gain=link_gain(cfg,d,bearing,l,stream)
offset=angle(exp(1i*(bearing-mod(l-1,3)*2*pi/3)));
sector=0.08+0.92*max(cos(offset),0)^4;
if strcmp(cfg.channelMode,'geometry_correlated_surrogate')
    gain=0.025*(max(d,10)/100)^(-3.2)*sector;
    return
end
typ=cfg.channelMode(1:3);
los=rand(stream)<los_probability(d,typ);
pl=outdoor_pathloss(d,cfg.frequencyGhz,typ,los);
if los, shadowStdDb=4; elseif strcmp(typ,'umi'), shadowStdDb=7.82; else, shadowStdDb=6; end
pl=pl+shadowStdDb*randn(stream);
gain=10^(-pl/10)*sector/(cfg.noiseWattPerRb*cfg.rbTotal);
end

function losProbability=los_probability(d,typ)
if d<=18, losProbability=1; return; end
minDistanceRatio=18/d;
if strcmp(typ,'umi')
    losProbability=minDistanceRatio+(1-minDistanceRatio)*exp(-d/36);
else
    losProbability=minDistanceRatio+(1-minDistanceRatio)*exp(-d/63); % h_UT=1.5 m; UMa correction vanishes.
end
end

function pl=outdoor_pathloss(d,fc,typ,los)
d=max(d,10);
if strcmp(typ,'umi'), hbs=10; else, hbs=25; end
hut=1.5;
d3=hypot(d,hbs-hut);
breakpoint=4*(hbs-1)*(hut-1)*fc*1e9/3e8;
if strcmp(typ,'umi')
    los1=32.4+21*log10(d3)+20*log10(fc);
    los2=32.4+40*log10(d3)+20*log10(fc)-9.5*log10(breakpoint^2+(hbs-hut)^2);
    if d<=breakpoint, losPl=los1; else, losPl=los2; end
    nlosPl=max(losPl,35.3*log10(d3)+22.4+21.3*log10(fc));
else
    los1=28+22*log10(d3)+20*log10(fc);
    los2=28+40*log10(d3)+20*log10(fc)-9*log10(breakpoint^2+(hbs-hut)^2);
    if d<=breakpoint, losPl=los1; else, losPl=los2; end
    nlosPl=max(losPl,13.54+39.08*log10(d3)+20*log10(fc));
end
if los, pl=losPl; else, pl=nlosPl; end
end

function z=complex_normal(stream,m,n)
z=(randn(stream,m,n)+1i*randn(stream,m,n))/sqrt(2);
end

function cal=calibrate(cfg,rxCorrelation)
gain=0.05;
ns=gain/10^(cfg.pilotSnrDb/10);
nc=gain/10^(cfg.csiRsSnrDb/10);
prior=gain*rxCorrelation;
rows=cfg.srsRxRows;
precision=prior\eye(4)+eye(4)/nc;
precision(rows,rows)=precision(rows,rows)+eye(numel(rows))/ns;
posterior=precision\eye(4);
stream=RandStream('mt19937ar','Seed',cfg.seed+101);
n=5000;
h=chol(prior,'lower')*complex_normal(stream,4,n);
yc=h+sqrt(nc)*complex_normal(stream,4,n);
ys=h(rows,:)+sqrt(ns)*complex_normal(stream,2,n);
rhs=yc/nc;
rhs(rows,:)=rhs(rows,:)+ys/ns;
residual=h-posterior*rhs;
empirical=residual*residual'/n;
cal=struct('seed',cfg.seed+101,'samples',n, ...
    'model','two-port SRS plus four-port CSI-RS matrix LMMSE; train-only Monte Carlo', ...
    'relative_covariance_fro_error',norm(empirical-posterior,'fro')/norm(posterior,'fro'), ...
    'analytic_covariance_trace',real(trace(posterior)), ...
    'empirical_covariance_trace',real(trace(empirical)));
end

function [output,cov,diag]=reuse_update(means,cov,truth,gain,modeled,pilots,noise,rows,age,coherence,rxCorrelation,cholRx,stream)
% Marginal posterior only: co-pilot cross-UE posterior blocks are omitted.
[k,nr,nt]=size(means);
means=double(means); cov=double(cov); truth=double(truth);
timeCorrelation=exp(-age/coherence);
for i=find(~modeled)'
    cov(i,:,:)=reshape(gain(i)*rxCorrelation,1,nr,nr);
    truth(i,:,:)=reshape(sqrt(gain(i))*cholRx*complex_normal(stream,nr,nt),1,nr,nt);
end
past=zeros(k,nr,nt);
for i=1:k
    innovation=sqrt(gain(i))*cholRx*complex_normal(stream,nr,nt);
    past(i,:,:)=reshape(timeCorrelation*reshape(truth(i,:,:),nr,nt)+sqrt(max(0,1-timeCorrelation^2))*innovation,1,nr,nt);
end
output=means;
snr=[]; sinr=[]; collision=[]; observed=[];
for pid=unique(pilots(:))'
    idx=find(pilots==pid);
    total=reshape(sum(past(idx,rows,:),1),numel(rows),nt);
    y=total+sqrt(noise)*complex_normal(stream,numel(rows),nt);
    expected=timeCorrelation*reshape(sum(means(idx,rows,:),1),numel(rows),nt);
    S=noise*eye(numel(rows));
    for i=idx(:)'
        prior=reshape(cov(i,:,:),nr,nr);
        observedCov=timeCorrelation^2*prior+(1-timeCorrelation^2)*gain(i)*rxCorrelation;
        S=S+observedCov(rows,rows);
    end
    residual=y-expected;
    for i=idx(:)'
        if ~modeled(i), continue; end
        prior=reshape(cov(i,:,:),nr,nr);
        kalman=timeCorrelation*prior(:,rows)/S;
        output(i,:,:)=reshape(reshape(means(i,:,:),nr,nt)+kalman*residual,1,nr,nt);
        updated=prior-kalman*(timeCorrelation*prior(rows,:));
        cov(i,:,:)=reshape((updated+updated')/2,1,nr,nr);
        desired=reshape(past(i,rows,:),numel(rows),nt);
        interference=total-desired;
        signal=mean(abs(desired(:)).^2);
        snr(end+1)=signal/noise; %#ok<AGROW>
        sinr(end+1)=signal/(noise+mean(abs(interference(:)).^2)); %#ok<AGROW>
        collision(end+1)=numel(idx)-1; %#ok<AGROW>
        observed(end+1)=i; %#ok<AGROW>
    end
end
diag=struct('signal_to_awgn_linear',snr,'signal_to_interference_plus_awgn_linear',sinr, ...
    'co_pilot_user_count',collision,'observed_group_user_indices',observed, ...
    'pilot_noise_variance',noise,'measurement_age_ms',age, ...
    'current_past_correlation',timeCorrelation,'pilot_sequences_in_group',numel(unique(pilots)), ...
    'modeled_observed_links',nnz(modeled));
end
