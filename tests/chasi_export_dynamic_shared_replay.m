function outputPath=chasi_export_dynamic_shared_replay(runDir,outputPath)
%CHASI_EXPORT_DYNAMIC_SHARED_REPLAY Freeze w/Htrue and reuse saved traffic.
% This offline parity fixture isolates queue/rate aggregation from stochastic
% mobility and pilot noise; it is not the online matrix-WMMSE branch.
if nargin<2 || isempty(outputPath) || isfile(outputPath)
    error('CHASI:DynamicParityOutput','A new separate output MAT path is required');
end
saved=load(fullfile(runDir,'scene.mat'),'scene','traffic','cfg');
scene=saved.scene;
if saved.cfg.users~=210 || size(saved.traffic.busy,2)~=340
    error('CHASI:DynamicParityShape','Expected saved 210-UE/340-TTI formal input');
end
scene.config.speedKmh=0;
solution=load(fullfile(runDir,'matrix_statistical_precoders.mat'),'precoder');
options=struct('windowTti',340,'offeredMbps',saved.cfg.offeredMbps,...
    'fastPeriodTti',saved.cfg.fastPeriodTti,...
    'slowPeriodTti',saved.cfg.slowPeriodTti,'beamPolicy','frozen');
replay=chasi_time_evolution(scene,solution,options,saved.traffic);
save(outputPath,'replay','options','-v7');
fprintf('CHASI_DYNAMIC_SHARED_REPLAY=%s\n',outputPath);
end
