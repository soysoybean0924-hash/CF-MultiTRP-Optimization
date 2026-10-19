function chasi_plot_cell_layout(scene,outputBase)
%CHASI_PLOT_CELL_LAYOUT Plot actual UE draws and assumed annular-sector cells.
% The cell boundary is a project assumption, not a traced acceptance contour.
if nargin<2 || isempty(outputBase)
    error('CHASI:CellLayoutOutput','An output base path is required');
end
top=scene.topology;
site=top.site_xy;
colors=lines(size(site,1));
fig=figure('Visible','off','Color','w','Position',[100 100 1450 1150]);
ax=axes(fig,'Position',[.07 .11 .77 .79]); hold(ax,'on'); axis(ax,'equal');
inner=top.cell_inner_radius_m;
outer=top.cell_outer_radius_m;
half=top.cell_half_width_deg*pi/180;
boundaryHandle=gobjects(1);
directionHandle=gobjects(1);
for l=1:size(scene.trp_xy,1)
    siteId=top.trp_site_id(l);
    origin=scene.trp_xy(l,:);
    bearing=top.trp_azimuth_deg(l)*pi/180;
    theta=linspace(bearing-half,bearing+half,90);
    for radius=[inner outer]
        h=plot(ax,origin(1)+radius*cos(theta),...
            origin(2)+radius*sin(theta),':','Color',colors(siteId,:),...
            'LineWidth',.95);
        if l==1 && radius==outer, boundaryHandle=h; end
    end
    for edge=[theta(1) theta(end)]
        plot(ax,origin(1)+[inner outer]*cos(edge),...
            origin(2)+[inner outer]*sin(edge),':',...
            'Color',colors(siteId,:),'LineWidth',.95);
    end
    h=quiver(ax,origin(1),origin(2),...
        68*cos(bearing),68*sin(bearing),0,'Color',[.06 .23 .43],...
        'LineWidth',1.25,'MaxHeadSize',.33);
    if l==1, directionHandle=h; end
    labelPoint=origin+103*[cos(bearing) sin(bearing)];
    text(ax,labelPoint(1),labelPoint(2),sprintf('T%02d',l),...
        'FontSize',8,'FontWeight','bold','Color',[.05 .19 .35],...
        'HorizontalAlignment','center','BackgroundColor','w','Margin',1);
end
ueHandle=gobjects(1);
for siteId=1:size(site,1)
    ids=find(top.trp_site_id(scene.home)==siteId);
    h=scatter(ax,scene.ue_xy(ids,1),scene.ue_xy(ids,2),...
        19,colors(siteId,:),'filled','MarkerFaceAlpha',.75);
    if siteId==1, ueHandle=h; end
end
siteHandle=scatter(ax,site(:,1),site(:,2),140,[.03 .17 .35],...
    '^','filled','MarkerEdgeColor','w','LineWidth',.8);
for siteId=1:size(site,1)
    text(ax,site(siteId,1)+10,site(siteId,2)+10,sprintf('S%d',siteId),...
        'FontSize',11,'FontWeight','bold','Color',[.02 .15 .32],...
        'BackgroundColor','w','Margin',1);
end
plot(ax,[site(1,1) site(2,1)],site(1,2)+[10 10],'-',...
    'Color',[.42 .46 .52],'LineWidth',.7);
text(ax,mean(site(1:2,1)),site(1,2)+18,'300 m site spacing',...
    'HorizontalAlignment','center','FontSize',9,'BackgroundColor','w');
xlim(ax,[min(site(:,1))-outer-20,max(site(:,1))+outer+20]);
ylim(ax,[min(site(:,2))-outer-20,max(site(:,2))+outer+20]);
xlabel(ax,'x (m)'); ylabel(ax,'y (m)'); grid(ax,'on');
title(ax,sprintf('CHASI generated topology: 7 sites / 21 cells / %d UEs',...
    size(scene.ue_xy,1)),'FontSize',16,'Color',[.03 .16 .32]);
legend(ax,[siteHandle ueHandle directionHandle boundaryHandle],...
    {'site (3 co-located TRPs)','UE (color = home site)',...
    'sector azimuth','modeled cell boundary'},...
    'Location','eastoutside','FontSize',9);
annotation(fig,'textbox',[.09 .015 .82 .055],...
    'String',sprintf(['Seed %d. T01-T21 = TRP/cell ID; azimuths 0/120/240 deg. ',...
    'Dotted 25-150 m annular sectors are a project assumption; ',...
    'the acceptance image does not define cell contours.'],scene.config.seed),...
    'EdgeColor','none','FontSize',9,'Color',[.25 .29 .35]);
exportgraphics(fig,[outputBase '.pdf'],'ContentType','vector');
% Raster preview is rendered from this vector PDF in the delivery stage;
% batch MATLAB PNG export was inconsistent on the current Windows renderer.
close(fig);
end
