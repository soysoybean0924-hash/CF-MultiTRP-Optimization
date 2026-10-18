function chasi_recompute_saved_state(runDir, outputPath)
%CHASI_RECOMPUTE_SAVED_STATE Recompute A/E/Omega at exactly saved w.
% Offline diagnostic only; outer_iterations=0 avoids any optimization step.
if nargin<2 || isempty(outputPath) || isfile(outputPath)
    error('CHASI:StateProbeOutput','A new output path is required');
end
saved=load(fullfile(runDir,'scene.mat'),'scene','cfg');
final=load(fullfile(runDir,'matrix_statistical_precoders.mat'),...
    'precoder','rxCombiner','mseMatrix','mseWeight');
cfg=saved.cfg;
solverCfg=struct('rank',cfg.rank,'budget',cfg.powerWattPerTrp,...
    'outer_iterations',0,'branch','matrix_statistical','users',cfg.users,...
    'pf_floor',cfg.pfRateFloorBitsPerSHz);
state=chasi_matrix_wmmse(saved.scene.resources,solverCfg,final.precoder);
group=10; localUeIdx=18;
resource=saved.scene.resources(group);
H=resource.H; C=resource.C; precoder=final.precoder{group};
[K,L,Nr,Nt]=size(H); numStreams=cfg.rank;
rxCovariance=eye(Nr); wanted=complex(zeros(Nr,numStreams));
for dataUeIdx=1:K
    effectiveChannel=complex(zeros(Nr,numStreams));
    for l=1:L
        effectiveChannel=effectiveChannel+...
            reshape(H(localUeIdx,l,:,:),Nr,Nt)*...
            reshape(precoder(l,dataUeIdx,:,:),Nt,numStreams);
    end
    rxCovariance=rxCovariance+effectiveChannel*effectiveChannel';
    if dataUeIdx==localUeIdx, wanted=effectiveChannel; end
end
for l=1:L
    power=sum(abs(precoder(l,:,:,:)).^2,'all');
    rxCovariance=rxCovariance+power*reshape(C(localUeIdx,l,:,:),Nr,Nr);
end
recomputedA=reshape(state.rxCombiner{group}(localUeIdx,:,:),4,cfg.rank);
recomputedE=reshape(state.mseMatrix{group}(localUeIdx,:,:),cfg.rank,cfg.rank);
recomputedOmega=reshape(state.mseWeight{group}(localUeIdx,:,:),cfg.rank,cfg.rank);
savedA=reshape(final.rxCombiner{group}(localUeIdx,:,:),4,cfg.rank);
savedE=reshape(final.mseMatrix{group}(localUeIdx,:,:),cfg.rank,cfg.rank);
savedOmega=reshape(final.mseWeight{group}(localUeIdx,:,:),cfg.rank,cfg.rank);
fprintf('saved_recomputed_A_max=%.17g\n',max(abs(recomputedA-savedA),[],'all'));
fprintf('saved_recomputed_E_max=%.17g\n',max(abs(recomputedE-savedE),[],'all'));
fprintf('saved_recomputed_Omega_max=%.17g\n',max(abs(recomputedOmega-savedOmega),[],'all'));
save(outputPath,'recomputedA','recomputedE','recomputedOmega',...
    'savedA','savedE','savedOmega','rxCovariance','wanted','-v7');
end
