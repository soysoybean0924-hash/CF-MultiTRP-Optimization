function test_chasi_no_cooperation()
% Explicit home-TRP baseline: local MRT and full cross-resource power.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab','chasi'));
resources=repmat(struct('H',[],'H_true',[],'C',[],'C_stat',[], ...
    'serve',[],'home_trp',[],'ue_ids',[],'rb_count',[], ...
    'tx_rb_count',[],'prior_gain',[]),1,2);
for g=1:2
    H=complex(zeros(2,2,4,4));
    for k=1:2
        for l=1:2
            H(k,l,:,:)=reshape(diag((.12+.02*g+.01*k+.01*l)*(1:4)) ...
                *exp(1i*.1*(k+l)),1,1,4,4);
        end
    end
    resources(g).H=H; resources(g).H_true=H;
    resources(g).C=complex(zeros(2,2,4,4));
    resources(g).C_stat=resources(g).C;
    resources(g).serve=true(2,2);
    resources(g).home_trp=[1;2]; resources(g).ue_ids=[1;2];
    resources(g).rb_count=20; resources(g).tx_rb_count=20;
    resources(g).prior_gain=ones(2,2);
end
cfg=struct('rank',1,'budget',.05,'users',2,'pf_floor',.01);
out=chasi_no_cooperation(resources,cfg);
assert(strcmp(out.branch,'no_cooperation'));
assert(strcmp(out.reason,'local_mrt_full_budget_no_cooperation'));
assert(out.converged);
assert(abs(out.optimization_objective-out.estimated_sum_rate)<1e-10);
assert(all(abs(out.power-cfg.budget)<1e-8));
for g=1:2
    v=out.precoderV{g};
    assert(norm(reshape(v(1,2,:,:),[],1))<1e-12);
    assert(norm(reshape(v(2,1,:,:),[],1))<1e-12);
    assert(norm(reshape(v(1,1,:,:),[],1))>0);
    assert(norm(reshape(v(2,2,:,:),[],1))>0);
    assert(size(out.mseMatrixE{g},1)==2 && ...
        size(out.mseMatrixE{g},2)==1 && size(out.mseMatrixE{g},3)==1);
end
assert(out.max_power_violation<1e-8);
resources(2).tx_rb_count=0;
zeroWeight=chasi_no_cooperation(resources,cfg);
assert(all(abs(zeroWeight.power-cfg.budget)<1e-8));
assert(zeroWeight.max_power_violation<1e-8);
fprintf('CHASI_NO_COOPERATION_PASS\n');
end
