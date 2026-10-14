function [resources,solverCfg] = cf_chasi_native_resources(cfg,scenario,candidate)
%CF_CHASI_NATIVE_RESOURCES Explicit old-MATLAB-scene to matrix-PF contract.
% Existing H_est/H_true are reused. No channel or schedule is generated here.
if ~isfield(cfg,'chasiNative') || ~isfield(cfg.chasiNative,'enabled') || ~cfg.chasiNative.enabled
    error('cf_chasi_native_resources:Disabled','Set cfg.chasiNative.enabled=true');
end
n=cfg.chasiNative;
required={'branch','rbCounts','scheduleMask','budget','pfFloor'};
for j=1:numel(required)
    if ~isfield(n,required{j}), error('Missing cfg.chasiNative.%s',required{j}); end
end
if ~isfield(scenario,'H_est') || ~isfield(scenario,'H_true')
    error('Both existing H_est and held-out H_true are required');
end
if ~isequal(size(scenario.H_est),size(scenario.H_true))
    error('H_est and H_true axes differ');
end
[Nr,Nt,L,U,G]=size(scenario.H_est);
if ~isequal(size(n.scheduleMask),[U,G]) || numel(n.rbCounts)~=G || ...
        any(n.rbCounts<=0) || sum(n.rbCounts)~=273
    error('Explicit U-by-G scheduleMask and RB counts summing to 273 are required');
end
if ~isfield(scenario,'channelGain') || ~isequal(size(scenario.channelGain),[L,U,G])
    error('Existing estimated L-by-U-by-G channelGain is required for service selection');
end
if ~isscalar(cfg.noisePower) || cfg.noisePower<=0
    error('Positive scalar noisePower is required for unit-noise normalization');
end
if candidate.numConnections<1 || candidate.numConnections>L
    error('Candidate numConnections outside 1..L');
end
if candidate.maxRank<1 || candidate.maxRank>min(Nr,Nt)
    error('Candidate rank outside receive/transmit dimension');
end
base=cf_decode_candidate(cfg.defaultX,cfg);
fixed={'betaPF','scheduleThreshold','rhoLink','rhoPower',...
       'rankThreshold','repairPower','maxRepairLinks'};
for j=1:numel(fixed)
    name=fixed{j};
    if abs(double(candidate.(name))-double(base.(name)))>1e-10*max(1,abs(double(base.(name))))
        error('Native PF does not implement candidate field %s; keep it fixed',name);
    end
end
if isfield(n,'covarianceRule')
    rule=char(n.covarianceRule);
else
    error('Set explicit cfg.chasiNative.covarianceRule');
end
switch rule
    case 'explicit_rx_covariance'
        if ~isfield(n,'errorCovariance') || ...
                ~isequal(size(n.errorCovariance),[Nr,Nr,L,U,G])
            error('Explicit Nr-by-Nr-by-L-by-U-by-G covariance required');
        end
    case 'srs_scalar_isotropic_est_gain'
        if ~isfield(scenario,'srs') || ~isfield(scenario.srs,'ErrorVariance') || ...
                ~isequal(size(scenario.srs.ErrorVariance),[L,U,G])
            error('Existing SRS scalar ErrorVariance required');
        end
    otherwise
        error('Unsupported covarianceRule %s',rule);
end
resources=repmat(struct('H',[],'H_true',[],'C',[],'C_stat',[],...
    'serve',[],'ue_ids',[],'rb_count',[],'tx_rb_count',[],...
    'prior_gain',[]),1,G);
for g=1:G
    ids=find(n.scheduleMask(:,g)); K=numel(ids);
    if K==0, error('Group %d has no scheduled UE; empty groups need explicit handling',g); end
    hEst=complex(zeros(K,L,Nr,Nt)); hTrue=complex(zeros(K,L,Nr,Nt));
    cov=complex(zeros(K,L,Nr,Nr)); gain=zeros(K,L); serve=false(L,K);
    for k=1:K
        u=ids(k); [~,order]=sort(scenario.channelGain(:,u,g),'descend');
        serve(order(1:candidate.numConnections),k)=true;
        for l=1:L
            hEst(k,l,:,:)=reshape(scenario.H_est(:,:,l,u,g)/sqrt(cfg.noisePower),1,1,Nr,Nt);
            hTrue(k,l,:,:)=reshape(scenario.H_true(:,:,l,u,g)/sqrt(cfg.noisePower),1,1,Nr,Nt);
            gain(k,l)=scenario.channelGain(l,u,g)/(Nr*Nt*cfg.noisePower);
            if strcmp(rule,'explicit_rx_covariance')
                c=n.errorCovariance(:,:,l,u,g)/cfg.noisePower;
            else
                c=scenario.srs.ErrorVariance(l,u,g)*gain(k,l)*eye(Nr);
            end
            cov(k,l,:,:)=reshape((c+c')/2,1,1,Nr,Nr);
        end
    end
    resources(g).H=hEst; resources(g).H_true=hTrue;
    resources(g).C=cov; resources(g).C_stat=cov;
    resources(g).serve=serve; resources(g).ue_ids=ids(:);
    resources(g).rb_count=n.rbCounts(g);
    resources(g).tx_rb_count=n.rbCounts(g);
    resources(g).prior_gain=gain;
end
solverCfg=struct('branch',char(n.branch),'rank',candidate.maxRank,...
    'users',U,'budget',n.budget,'pf_floor',n.pfFloor);
copy={'outer_iterations','outer_rel_tol','outer_v_tol','admm_iterations',...
    'cg_iterations','eps_abs','eps_rel','rho'};
for j=1:numel(copy)
    if isfield(n,copy{j}), solverCfg.(copy{j})=n.(copy{j}); end
end
end
