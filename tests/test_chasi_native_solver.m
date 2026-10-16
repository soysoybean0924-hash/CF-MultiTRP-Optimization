function test_chasi_native_solver()
% Explicit two-resource input for the canonical complex matrix solver.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab','chasi'));
resources=repmat(struct('H',[],'H_true',[],'C',[],'C_stat',[], ...
    'servingMask',[],'ueIds',[],'rb_count',[],'tx_rb_count',[], ...
    'prior_gain',[]),1,2);
for g=1:2
    H=complex(zeros(2,2,4,4)); C=complex(zeros(2,2,4,4));
    for k=1:2
        for l=1:2
            for r=1:4
                for n=1:4
                    H(k,l,r,n)=(.12+.02*k+.01*l+.003*r+.002*n)* ...
                        exp(1i*(.1*k-.07*l+.04*r+.03*n+.02*g));
                end
                C(k,l,r,r)=.002*(1+.1*k+.1*l);
            end
        end
    end
    resources(g).H=H; resources(g).H_true=H;
    resources(g).C=C; resources(g).C_stat=C;
    resources(g).servingMask=logical([1 0;1 1]);
    resources(g).ueIds=[1 2];
    resources(g).rb_count=15+g; resources(g).tx_rb_count=15+g;
    resources(g).prior_gain=[.01 .01;1 1];
    resources(g).home_trp=[1;2];
end
cfg=struct('rank',2,'budget',.1,'outer_iterations',1, ...
    'admm_iterations',12,'cg_iterations',20,'branch','matrix_pf_statistical', ...
    'users',2,'pf_floor',.01,'eps_abs',1e-5,'eps_rel',1e-4);
out=chasi_matrix_wmmse(resources,cfg);
assert(isfield(out,'precoder') && isfield(out,'rxCombiner'));
assert(isfield(out,'mseWeight') && isfield(out,'mseMatrix'));
assert(numel(out.precoder)==2 && numel(out.mseMatrix)==2);
assert(isequal(size(out.precoder{1}),[2 2 4 2]));
assert(isequal(size(out.rxCombiner{1}),[2 4 2]));
assert(isequal(size(out.mseWeight{1}),[2 2 2]));
assert(isequal(size(out.mseMatrix{1}),[2 2 2]));
assert(max(out.power)<=cfg.budget+1e-7);
assert(norm(reshape(out.precoder{1}(1,2,:,:),[],1))<1e-12);
for g=1:2
    for k=1:2
        e=reshape(out.mseMatrix{g}(k,:,:),2,2);
        w=reshape(out.mseWeight{g}(k,:,:),2,2);
        assert(norm(e*w-eye(2),'fro')<1e-8);
        assert(abs(out.rate{g}(k)+real(log(det(e)))/log(2))<1e-8);
    end
end
assert(isfinite(out.optimization_objective));
assert(numel(out.estimated_per_ue_rate)==2);
assert(numel(out.true_per_ue_rate)==2);
assert(~isempty(out.trajectory) && ~isempty(out.last_admm_history));
assert(out.max_power_violation<1e-7);

% The nominal branch removes estimated error covariance from WMMSE state.
cfg.outer_iterations=0;
nominal=cfg; nominal.branch='matrix_pf_nominal';
statistical=chasi_matrix_wmmse(resources,cfg,out.precoder);
nominalOut=chasi_matrix_wmmse(resources,nominal,out.precoder);
assert(nominalOut.estimated_sum_rate>statistical.estimated_sum_rate);
assert(strcmp(nominalOut.branch,'matrix_pf_nominal'));
idealCfg=cfg; idealCfg.branch='ideal';
idealOut=chasi_matrix_wmmse(resources,idealCfg,out.precoder);
assert(abs(idealOut.estimated_sum_rate-nominalOut.estimated_sum_rate)<1e-10);
nominalCfg=cfg; nominalCfg.branch='matrix_nominal';
nominalSumOut=chasi_matrix_wmmse(resources,nominalCfg,out.precoder);
assert(abs(nominalSumOut.optimization_objective-idealOut.optimization_objective)<1e-10);
sumCfg=cfg; sumCfg.branch='matrix_statistical';
sumOut=chasi_matrix_wmmse(resources,sumCfg,out.precoder);
assert(abs(sumOut.optimization_objective-sumOut.estimated_sum_rate)<1e-10);
assert(sumOut.estimated_sum_rate<nominalOut.estimated_sum_rate);
edgeCfg=cfg; edgeCfg.branch='matrix_edge_weighted';
edgeOut=chasi_matrix_wmmse(resources,edgeCfg,out.precoder);
assert(edgeOut.userWeight{1}(1)>edgeOut.userWeight{1}(2));
assert(edgeOut.optimization_objective>edgeOut.estimated_sum_rate);
startCfg=cfg; startCfg.initializationMode='svd';
svdOut=chasi_matrix_wmmse(resources,startCfg);
startCfg.initializationMode='home_biased';
homeOut=chasi_matrix_wmmse(resources,startCfg);
assert(norm(homeOut.precoder{1}(:)-svdOut.precoder{1}(:))>1e-5);
startCfg.initializationMode='jittered'; startCfg.seed=17;
startCfg.initializationSeed=3;
jitterA=chasi_matrix_wmmse(resources,startCfg);
jitterB=chasi_matrix_wmmse(resources,startCfg);
assert(norm(jitterA.precoder{1}(:)-jitterB.precoder{1}(:))<1e-12);
assert(norm(jitterA.precoder{1}(:)-svdOut.precoder{1}(:))>1e-5);
assert(max(jitterA.power)<=cfg.budget+1e-7);
startCfg.initializationMode='unsupported';
try
    chasi_matrix_wmmse(resources,startCfg);
    error('Expected unsupported initialization failure');
catch err
    assert(contains(err.message,'Unsupported initialization mode'));
end
fprintf('CHASI_NATIVE_SOLVER_PASS\n');
end
