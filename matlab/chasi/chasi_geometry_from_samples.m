function [trp,ue,home]=chasi_geometry_from_samples(cfg,angleUniform,radiusUniform)
%CHASI_GEOMETRY_FROM_SAMPLES Pure topology map from explicit uniform draws.
% Each draw array is [usersPerCell,TRP], with columns in TRP order.
expected=[cfg.usersPerCell,cfg.trps];
if ~isequal(size(angleUniform),expected) || ...
        ~isequal(size(radiusUniform),expected) || ...
        any(~isfinite(angleUniform(:))) || any(~isfinite(radiusUniform(:))) || ...
        any(angleUniform(:)<0 | angleUniform(:)>1) || ...
        any(radiusUniform(:)<0 | radiusUniform(:)>1)
    error('CHASI:GeometrySamples','Expected finite [usersPerCell,TRP] uniforms in [0,1]');
end
site=[450 450];
angles=(0:5)'*pi/3;
site=[site;site+300*[cos(angles) sin(angles)]];
trp=repelem(site,cfg.sectorsPerSite,1);
home=repelem((1:cfg.trps)',cfg.usersPerCell);
ue=zeros(cfg.users,2);
for l=1:cfg.trps
    azimuthRad=mod(l-1,3)*2*pi/3+...
        (angleUniform(:,l)-0.5)*2*pi/3;
    radius=25+125*sqrt(radiusUniform(:,l));
    idx=(l-1)*cfg.usersPerCell+(1:cfg.usersPerCell);
    ue(idx,:)=trp(l,:)+radius.*[cos(azimuthRad) sin(azimuthRad)];
end
end
