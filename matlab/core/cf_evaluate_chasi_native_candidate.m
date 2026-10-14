function result = cf_evaluate_chasi_native_candidate(cfg,scenario,candidate,doOptimize)
%CF_EVALUATE_CHASI_NATIVE_CANDIDATE Native matrix-PF candidate evaluation.
if nargin<4, doOptimize=true; end
projectRoot=fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectRoot,'experiments','chasi_formal','migration_20261013'));
[resources,solverCfg]=cf_chasi_native_resources(cfg,scenario,candidate);
if ~doOptimize, solverCfg.outer_iterations=0; end
ticId=tic;
native=chasi_matrix_wmmse(resources,solverCfg);
result=struct();
result.Backend='chasi_native_pf';
result.ObjectiveName='estimated_PF_log1p_aggregate_rate_over_floor';
result.Objective=native.optimization_objective;
result.Score=result.Objective;
result.ScoreName=result.ObjectiveName;
result.Candidate=candidate;
result.Native=native;
result.ServiceMasks={resources.serve};
result.ScheduledUEIDs={resources.ue_ids};
result.TotalPower=sum(native.power);
result.MaxPowerViolation=native.max_power_violation;
result.SumRate=native.true_sum_rate;
result.MeanRate=mean(native.true_per_ue_rate);
result.Rate5=native.true_rate5;
result.Rate10=localPercentile(native.true_per_ue_rate,10);
result.TrueChannel=struct('PerUEBitsPerSecondPerHz',native.true_per_ue_rate,...
    'SumRate',native.true_sum_rate);
result.ActiveLinks=sum(cellfun(@(v) nnz(sum(abs(v).^2,[3,4])>1e-20),native.V));
result.history=struct('iterations',numel(native.trajectory)-1,...
    'stopReason',native.reason,'converged',native.converged);
result.RuntimeSeconds=toc(ticId);
result.InputContract=struct('noiseNormalization','H/sqrt(noisePower)',...
    'powerDefinition','sum_g (tx_rb_count/273)*frobenius(V_lg)^2',...
    'covarianceRule',cfg.chasiNative.covarianceRule);
if isfield(cfg.chasiNative,'outputFile') && ~isempty(cfg.chasiNative.outputFile)
    path=char(cfg.chasiNative.outputFile);
    if isfile(path), error('Refusing to overwrite existing native result: %s',path); end
    save(path,'result','-v7.3');
end
end

function value=localPercentile(x,p)
x=sort(x(:)); n=numel(x);
if n==0, value=NaN; return; end
t=(n-1)*p/100; lo=floor(t)+1; hi=ceil(t)+1;
value=x(lo)+(t-floor(t))*(x(hi)-x(lo));
end
