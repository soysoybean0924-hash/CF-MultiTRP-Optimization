function chasi_plot_topology(scene,outputBase,groupIndex)
%CHASI_PLOT_TOPOLOGY Actual saved coordinates with one group's service links.
% CPU is an annotation (not a simulated radio site or geographic point).
if nargin<3, groupIndex=1; end
if nargin<2 || isempty(outputBase)
    error('CHASI:TopologyOutput','An output base path is required.');
end
if ischar(scene) || isstring(scene)
    source=char(scene);
    if endsWith(source,'.json')
        manifest=jsondecode(fileread(source));
        if groupIndex<1 || groupIndex>numel(manifest.groups)
            error('CHASI:TopologyGroup','Invalid manifest group index');
        end
        group=manifest.groups(groupIndex);
        if isfield(group,'ueIds')
            ids=double(group.ueIds(:));
        else
            ids=double(group.ue_ids(:)); % Historical v2 manifest conversion.
        end
        mask=false(size(manifest.trp_xy_m,1),numel(ids));
        for k=1:numel(ids)
            if iscell(group.serving_trps_by_user)
                links=group.serving_trps_by_user{k};
            else
                links=group.serving_trps_by_user(k,:);
            end
            mask(double(links),k)=true;
        end
        resource=struct('ueIds',ids,'servingMask',mask);
        scene=struct('trp_xy',manifest.trp_xy_m,...
            'ue_xy',manifest.ue_xy_m,...
            'resources',repmat(resource,1,groupIndex));
    else
        loaded=load(source,'scene');
        scene=loaded.scene;
    end
end
if groupIndex<1 || groupIndex>numel(scene.resources)
    error('CHASI:TopologyGroup','Invalid group index');
end
resource=scene.resources(groupIndex);
if isfield(resource,'servingMask')
    servingMask=resource.servingMask;
elseif isfield(resource,'serve')
    % Explicit historical scene-reading conversion; never used by solve.
    servingMask=resource.serve;
else
    error('CHASI:TopologyMask','Scene lacks a serving mask');
end
sites=scene.trp_xy(1:3:end,:);
numSites=size(sites,1);
fig=figure('Visible','off','Color','w','Position',[100 100 1150 900]);
ax=axes(fig); hold(ax,'on'); axis(ax,'equal'); grid(ax,'on');
scatter(ax,scene.ue_xy(:,1),scene.ue_xy(:,2),12,[.72 .78 .85],'filled');
if ~isfield(resource,'ueIds')
    resource.ueIds=resource.ue_ids; % Historical v2 MAT scene conversion.
end
colors=lines(max(1,numel(resource.ueIds)));
for k=1:numel(resource.ueIds)
    u=resource.ueIds(k);
    for l=find(servingMask(:,k)).'
        plot(ax,[scene.trp_xy(l,1),scene.ue_xy(u,1)],...
            [scene.trp_xy(l,2),scene.ue_xy(u,2)],'--',...
            'Color',colors(k,:),'LineWidth',.8);
    end
end
for siteId=1:numSites
    x=sites(siteId,1); y=sites(siteId,2);
    scatter(ax,x,y,170,[.08 .27 .48],'^','filled');
    firstTrp=3*(siteId-1)+1;
    text(ax,x+8,y+8,sprintf('S%d / TRP%d-%d',...
        siteId,firstTrp,firstTrp+2),'FontSize',9,...
        'Color',[.06 .20 .38],'BackgroundColor','w');
end
ids=resource.ueIds(:);
scatter(ax,scene.ue_xy(ids,1),scene.ue_xy(ids,2),30,colors(1:numel(ids),:),'filled');
for k=1:numel(ids)
    text(ax,scene.ue_xy(ids(k),1)+3,scene.ue_xy(ids(k),2)+3,...
        sprintf('UE%d',ids(k)),'FontSize',7,'Color',colors(k,:));
end
xAll=[scene.trp_xy(:,1);scene.ue_xy(:,1)];
yAll=[scene.trp_xy(:,2);scene.ue_xy(:,2)];
xlim(ax,[min(xAll)-35,max(xAll)+35]);
ylim(ax,[min(yAll)-35,max(yAll)+35]);
xlabel(ax,'x (m)'); ylabel(ax,'y (m)');
title(ax,sprintf('CHASI actual sampled coordinates; group %d service links',groupIndex));
subtitle(ax,sprintf('%d sites, %d co-sited TRPs, %d global UEs, %d UEs in shown group',...
    numSites,size(scene.trp_xy,1),size(scene.ue_xy,1),numel(ids)));
exportgraphics(fig,[outputBase '.pdf'],'ContentType','vector');
exportgraphics(fig,[outputBase '.png'],'Resolution',180);
close(fig);
end
