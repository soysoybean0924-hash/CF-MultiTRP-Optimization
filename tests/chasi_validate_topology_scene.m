function chasi_validate_topology_scene(outputJson,figureBase)
% Full scene generation only; no solver, traffic replay, or formal run.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(root,'matlab','chasi'));
records=cell(1,2);
for caseId=1:2
    usersPerCell=[10 20];
    cfg=chasi_config(struct('usersPerCell',usersPerCell(caseId),...
        'seed',20261011));
    started=tic;
    scene=chasi_generate_scene(cfg);
    top=scene.topology;
    decodedTopology=jsondecode(jsonencode(top));
    assert(isequal(decodedTopology.trp_cell_id(:),(1:21)'));
    assert(size(unique(round(top.site_xy,10),'rows'),1)==7);
    assert(isequal(scene.trp_xy,repelem(top.site_xy,3,1)));
    assert(isequal(top.trp_cell_id(:),(1:21)'));
    assert(isequal(top.trp_site_id(:),repelem((1:7)',3)));
    assert(isequal(top.trp_sector_id(:),repmat((1:3)',7,1)));
    counts=accumarray(scene.home,1,[21 1]);
    assert(all(counts==cfg.usersPerCell));
    center=scene.trp_xy(scene.home,:);
    delta=scene.ue_xy-center;
    radii=hypot(delta(:,1),delta(:,2));
    bearings=atan2(delta(:,2),delta(:,1));
    offsets=angle(exp(1i*(bearings-top.trp_azimuth_deg(scene.home)*pi/180)));
    assert(all(radii>=cfg.ueInnerRadiusM-1e-9 & ...
        radii<=cfg.cellOuterRadiusM+1e-9));
    assert(all(abs(offsets)<=pi/3+1e-9));
    radialArea=(radii.^2-cfg.ueInnerRadiusM^2)/...
        (cfg.cellOuterRadiusM^2-cfg.ueInnerRadiusM^2);
    sorted=sort(radialArea);
    n=numel(sorted);
    ks=max(max((1:n)'/n-sorted),max(sorted-(0:n-1)'/n));
    siteDistances=zeros(21,1);
    pairIdx=0;
    for a=1:6
        for b=a+1:7
            pairIdx=pairIdx+1;
            siteDistances(pairIdx)=norm(top.site_xy(a,:)-top.site_xy(b,:));
        end
    end
    assert(min(siteDistances)>299.999999);
    crossSiteServes=0;
    totalServes=0;
    for g=1:numel(scene.resources)
        resource=scene.resources(g);
        for localUeIdx=1:numel(resource.ueIds)
            globalUeId=resource.ueIds(localUeIdx);
            assert(resource.home_trp(localUeIdx)==scene.home(globalUeId));
            assert(resource.servingMask(scene.home(globalUeId),localUeIdx));
            servers=find(resource.servingMask(:,localUeIdx));
            totalServes=totalServes+numel(servers);
            crossSiteServes=crossSiteServes+sum(...
                top.trp_site_id(servers)~=top.trp_site_id(scene.home(globalUeId)));
        end
    end
    record=struct('seed',cfg.seed,'num_sites',size(top.site_xy,1),...
        'num_trps',size(scene.trp_xy,1),'num_ues',cfg.users,...
        'users_per_cell_min',min(counts),'users_per_cell_max',max(counts),...
        'min_site_spacing_m',min(siteDistances),...
        'min_home_distance_m',min(radii),'max_home_distance_m',max(radii),...
        'out_of_boundary_ues',sum(radii<cfg.ueInnerRadiusM | ...
            radii>cfg.cellOuterRadiusM | abs(offsets)>pi/3),...
        'radial_area_mean',mean(radialArea),...
        'radial_area_ks_statistic',ks,...
        'radial_area_ks_5pct_limit',1.36/sqrt(n),...
        'cross_site_service_links',crossSiteServes,...
        'total_service_links',totalServes,...
        'scene_generation_seconds',toc(started),...
        'sampling',cfg.ueSpatialSampling);
    records{caseId}=record;
    fprintf('TOPOLOGY_SCENE_%d_UE %s\n',cfg.users,jsonencode(record));
    if caseId==1 && nargin>=2 && ~isempty(figureBase)
        chasi_plot_cell_layout(scene,figureBase);
    end
    clear scene
end
if nargin>=1 && ~isempty(outputJson)
    fid=fopen(outputJson,'w');
    assert(fid>0); cleanup=onCleanup(@() fclose(fid));
    fwrite(fid,jsonencode([records{:}],'PrettyPrint',true),'char');
end
end
