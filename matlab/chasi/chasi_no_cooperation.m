function out = chasi_no_cooperation(resources, cfg)
%CHASI_NO_COOPERATION Home-TRP local SVD beams at full shared TRP power.
% resources(g).home_trp is a one-based TRP ID for each scheduled UE.
% Only each home link's estimated H is used to construct its precoder.
if isempty(resources)
    error('CHASI:NoCooperationResources','Explicit resources are required');
end
if ~isfield(cfg,'rank') || ~isfield(cfg,'budget') || ~isfield(cfg,'users')
    error('CHASI:NoCooperationConfig','rank, budget, and users are required');
end
G=numel(resources); L=size(resources(1).H,2); rank=cfg.rank;
localResources=resources; precoder=cell(1,G);
for g=1:G
    resource=resources(g);
    [K,localL,Nr,Nt]=size(resource.H);
    if localL~=L || rank<1 || rank>min(Nr,Nt) || ...
            ~isfield(resource,'home_trp') || numel(resource.home_trp)~=K
        error('CHASI:NoCooperationAxes','Invalid H, rank, or home_trp axes');
    end
    if ~isfield(resource,'ueIds') || numel(resource.ueIds)~=K
        error('CHASI:NoCooperationUsers','Each resource needs ueIds');
    end
    homes=double(resource.home_trp(:));
    if any(homes<1 | homes>L | homes~=floor(homes))
        error('CHASI:NoCooperationHome','home_trp must contain one-based TRP IDs');
    end
    localResources(g).servingMask=false(L,K);
    precoder{g}=complex(zeros(L,K,Nt,rank));
    for k=1:K
        l=homes(k);
        localResources(g).servingMask(l,k)=true;
        h=reshape(resource.H(k,l,:,:),Nr,Nt);
        [~,~,rightVectors]=svd(h,'econ');
        precoder{g}(l,k,:,:)=reshape(rightVectors(:,1:rank),1,1,Nt,rank);
    end
end

% A shared power budget spans all resource groups at each TRP.
power=zeros(L,1);
for g=1:G
    weight=resourceWeight(resources(g));
    for l=1:L
        power(l)=power(l)+weight*sum(abs(precoder{g}(l,:,:,:)).^2,'all');
    end
end
for l=1:L
    if power(l)<=0, continue; end
    factor=sqrt(cfg.budget/power(l));
    for g=1:G
        precoder{g}(l,:,:,:)=factor*precoder{g}(l,:,:,:);
    end
end

% Reuse the matrix state and true-channel rate calculation at zero outer steps.
% Its nominal branch sets error covariance to zero without altering precoder.
stateCfg=cfg;
stateCfg.branch='matrix_pf_nominal';
stateCfg.outer_iterations=0;
if ~isfield(stateCfg,'pf_floor'), stateCfg.pf_floor=.01; end
out=chasi_matrix_wmmse(localResources,stateCfg,precoder);
out.branch='no_cooperation';
out.optimization_objective=out.estimated_sum_rate;
out.weighted_proxy=out.estimated_sum_rate;
out.userWeight=cellfun(@(precoderBlock) ones(size(precoderBlock,2),1),precoder, ...
    'UniformOutput',false);
out.trajectory(1).objective=out.estimated_sum_rate;
out.trajectory(1).weighted_proxy=out.estimated_sum_rate;
out.reason='local_mrt_full_budget_no_cooperation';
out.converged=true;
end

function weight=resourceWeight(resource)
if isfield(resource,'resourceWeightNu') && ~isempty(resource.resourceWeightNu)
    weight=double(resource.resourceWeightNu);
elseif isfield(resource,'tx_rb_count') && ~isempty(resource.tx_rb_count)
    weight=double(resource.tx_rb_count)/273;
elseif isfield(resource,'rb_count') && ~isempty(resource.rb_count)
    weight=double(resource.rb_count)/273;
else
    error('CHASI:NoCooperationWeight','Resource RB count is required');
end
if ~isscalar(weight) || ~isfinite(weight) || weight<0
    error('CHASI:NoCooperationWeight','Resource RB weight must be nonnegative');
end
end
