function test_chasi_solver_mixed_precision
% Solver arithmetic should not depend on whether saved H/C use single storage.
addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'matlab','chasi'));
stream=RandStream('mt19937ar','Seed',1729);
resource=struct;
resource.H=complex(single(randn(stream,2,1,4,64)/2),...
    single(randn(stream,2,1,4,64)/2));
resource.C=single(repmat(reshape(eye(4)*.03,1,1,4,4),2,1,1,1));
resource.C_stat=resource.C;
resource.servingMask=true(1,2);
resource.rb_count=16; resource.tx_rb_count=16;
initial=complex(randn(stream,1,2,64,2),randn(stream,1,2,64,2))*.03;
cfg=struct('rank',2,'budget',1e6,'outer_iterations',0,'branch','matrix_sum');
singleStored=chasi_matrix_wmmse(resource,cfg,{initial});
resource.H=double(resource.H); resource.C=double(resource.C);
resource.C_stat=double(resource.C_stat);
doubleStored=chasi_matrix_wmmse(resource,cfg,{initial});
delta=max(abs(singleStored.mseWeight{1}-doubleStored.mseWeight{1}),[],'all');
assert(delta<1e-12,'CHASI:MixedPrecision','Single storage changed Omega by %.3g',delta);
fprintf('PASS mixed precision Omega %.3g\n',delta);
end
