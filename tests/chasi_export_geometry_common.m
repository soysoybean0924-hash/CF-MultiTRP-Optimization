function chasi_export_geometry_common(outputPath)
%CHASI_EXPORT_GEOMETRY_COMMON Explicit shared uniform draws for topology.
if nargin<1 || isempty(outputPath) || isfile(outputPath)
    error('CHASI:GeometryOutput','A new output MAT path is required');
end
% Historical Python parity fixture deliberately uses the old spatial law.
cfg=chasi_config(struct('usersPerCell',10,...
    'ueSpatialSampling','legacy_sqrt_radius'));
angleUniform=reshape(linspace(.01,.99,cfg.users),cfg.usersPerCell,cfg.trps);
radiusUniform=reshape(linspace(.99,.01,cfg.users),cfg.usersPerCell,cfg.trps);
[trpXy,ueXy,homeTrp]=chasi_geometry_from_samples(cfg,angleUniform,radiusUniform);
save(outputPath,'angleUniform','radiusUniform','trpXy','ueXy','homeTrp','-v7');
fprintf('CHASI_GEOMETRY_COMMON=%s\n',outputPath);
end
