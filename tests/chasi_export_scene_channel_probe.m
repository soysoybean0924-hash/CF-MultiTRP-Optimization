function outputPath=chasi_export_scene_channel_probe(runDir,outputPath,groupIndex)
%CHASI_EXPORT_SCENE_CHANNEL_PROBE Copy one saved MATLAB group for offline audit.
% This is read-only with respect to the formal result and never feeds the run.
if nargin<3, groupIndex=1; end
if nargin<2 || isempty(outputPath)
    error('CHASI:ProbeOutput','A separate output MAT path is required');
end
if isfile(outputPath)
    error('CHASI:ProbeOutput','Refusing to overwrite %s',outputPath);
end
saved=load(fullfile(runDir,'scene.mat'),'scene','cfg');
scene=saved.scene; cfg=saved.cfg;
if groupIndex<1 || groupIndex>numel(scene.resources)
    error('CHASI:ProbeGroup','Invalid resource group');
end
resource=scene.resources(groupIndex);
if ~strcmp(cfg.srsMode,'awgn_independent')
    error('CHASI:ProbeMode','Independent-posterior probe only');
end
H_true=resource.H_true;
H_est=resource.H;
errorCovariance=resource.C;
priorGain=resource.prior_gain;
omittedGain=resource.omitted_gain;
srsRxRows=cfg.srsRxRows;
pilotSnrDb=cfg.pilotSnrDb;
csiRsSnrDb=cfg.csiRsSnrDb;
ageMs=resource.age_ms;
csiAgeMs=mod(cfg.decisionTti,cfg.csiRsPeriodTti)*cfg.ttiMs;
ageCoherenceMs=cfg.ageCoherenceMs;
measured=resource.measured;
save(outputPath,'H_true','H_est','errorCovariance','priorGain',...
    'omittedGain','srsRxRows','pilotSnrDb','csiRsSnrDb',...
    'ageMs','csiAgeMs','ageCoherenceMs','measured','-v7');
fprintf('CHASI_SCENE_CHANNEL_PROBE=%s\n',outputPath);
end
