function test_chasi_topology()
% Explicit-input topology contract; no channel or solver work.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab','chasi'));
for usersPerCell=[10 11 20]
    cfg=chasi_config(struct('usersPerCell',usersPerCell));
    angleUniform=repmat(linspace(0.01,0.99,usersPerCell)',1,cfg.trps);
    radiusUniform=repmat(linspace(0.01,0.99,usersPerCell)',1,cfg.trps);
    [trp,ue,home,topology]=chasi_geometry_from_samples(cfg,angleUniform,radiusUniform);
    assert(isequal(size(topology.site_xy),[7 2]));
    assert(isequal(size(trp),[21 2]));
    assert(isequal(size(ue),[cfg.users 2]));
    assert(isequal(topology.trp_site_id(:),repelem((1:7)',3)));
    assert(isequal(topology.trp_sector_id(:),repmat((1:3)',7,1)));
    assert(isequal(topology.trp_cell_id(:),(1:21)'));
    assert(isequal(topology.trp_azimuth_deg(:),repmat([0;120;240],7,1)));
    assert(isequal(home(:),repelem((1:21)',usersPerCell)));
    siteDistances=sqrt(sum((topology.site_xy-topology.site_xy(1,:)).^2,2));
    assert(max(abs(siteDistances(2:end)-300))<1e-10);
    for l=1:21
        ids=find(home==l);
        delta=ue(ids,:)-trp(l,:);
        radii=hypot(delta(:,1),delta(:,2));
        expected=sqrt(25^2+(150^2-25^2)*radiusUniform(:,l));
        assert(max(abs(radii-expected))<1e-10);
        ueBearing=atan2(delta(:,2),delta(:,1));
        center=topology.trp_azimuth_deg(l)*pi/180;
        offsets=angle(exp(1i*(ueBearing-center)));
        assert(all(abs(offsets)<=pi/3+1e-12));
    end
end
legacyCfg=chasi_config(struct('usersPerCell',10,...
    'ueSpatialSampling','legacy_sqrt_radius'));
zerosDraw=zeros(10,21);
quarterDraw=ones(10,21)/4;
[trp,ue,home]=chasi_geometry_from_samples(...
    legacyCfg,zerosDraw,quarterDraw);
assert(max(abs(hypot(ue(:,1)-trp(home,1),...
    ue(:,2)-trp(home,2))-87.5))<1e-10);
fprintf('CHASI_TOPOLOGY_PASS\n');
end
