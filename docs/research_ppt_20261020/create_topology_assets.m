function create_topology_assets(outputDir)
% Generate presentation topology from the committed native MATLAB scene.
% This function only generates a scene; it never invokes an optimizer.
if nargin<1, error('outputDir required'); end
if ~exist(outputDir,'dir'), mkdir(outputDir); end
cfg=chasi_config(struct('seed',20261011,'usersPerCell',10));
scene=chasi_generate_scene(cfg);
top=scene.topology;
writematrix([(1:cfg.sites)' top.site_xy],fullfile(outputDir,'sites_seed20261011.csv'));
writematrix([(1:cfg.trps)' top.trp_site_id top.trp_sector_id top.trp_azimuth_deg scene.trp_xy],...
    fullfile(outputDir,'trps_seed20261011.csv'));
writematrix([(1:cfg.users)' scene.home scene.ue_xy],fullfile(outputDir,'ues_seed20261011.csv'));
g=1; local=1; globalId=scene.resources(g).ueIds(local);
served=find(scene.resources(g).servingMask(:,local));
info=struct('source_commit','db9d7e3c71a75f8f9724b743fc78023185b5cddf',...
    'seed',cfg.seed,'users_per_cell',cfg.usersPerCell,'ue_count',cfg.users,...
    'area_sampling',cfg.ueSpatialSampling,'selected_group',g,'selected_ue',globalId,...
    'selected_home_trp',scene.home(globalId),'selected_serving_trps',served(:)',...
    'site_spacing_m',cfg.siteSpacingM,'cell_boundary_status',top.boundary_status);
fid=fopen(fullfile(outputDir,'topology_manifest.json'),'w');
fprintf(fid,'%s',jsonencode(info)); fclose(fid);
draw_full(scene,outputDir);
draw_zoom(scene,g,local,globalId,served,outputDir);
end

function draw_full(scene,outputDir)
t=scene.topology; site=t.site_xy; c=lines(7);
f=figure('Visible','off','Color','w','Position',[20 20 1920 1080]);
ax=axes(f,'Position',[.06 .13 .90 .78]); hold(ax,'on'); axis(ax,'equal');
for l=1:21
  o=scene.trp_xy(l,:); a=t.trp_azimuth_deg(l)*pi/180;
  th=linspace(a-pi/3,a+pi/3,60);
  plot(ax,o(1)+150*cos(th),o(2)+150*sin(th),':','Color',[.78 .84 .9],'LineWidth',.8);
  quiver(ax,o(1),o(2),55*cos(a),55*sin(a),0,'Color',c(t.trp_site_id(l),:),...
    'LineWidth',1.5,'MaxHeadSize',.42);
  q=o+105*[cos(a) sin(a)];
  text(ax,q(1),q(2),sprintf('T%02d',l),'FontSize',10,'FontWeight','bold',...
    'HorizontalAlignment','center','BackgroundColor','w');
end
for s=1:7
  ids=find(t.trp_site_id(scene.home)==s);
  scatter(ax,scene.ue_xy(ids,1),scene.ue_xy(ids,2),23,c(s,:),'filled','MarkerFaceAlpha',.73);
end
scatter(ax,site(:,1),site(:,2),150,[.04 .2 .42],'^','filled','MarkerEdgeColor','w');
for s=1:7
  text(ax,site(s,1)+12,site(s,2)+10,sprintf('S%d · T%02d–T%02d',s,3*s-2,3*s),...
    'FontSize',13,'FontWeight','bold','Color',[.02 .18 .35],'BackgroundColor','w');
end
plot(ax,[site(1,1),site(2,1)],[site(1,2),site(2,2)],'--','Color',[.18 .25 .4],'LineWidth',1.8);
text(ax,600,470,'300 m','FontSize',13,'FontWeight','bold','HorizontalAlignment','center','BackgroundColor','w');
xlim(ax,[110 790]); ylim(ax,[90 810]); xlabel(ax,'x / m'); ylabel(ax,'y / m');
grid(ax,'on'); ax.FontSize=13;
title(ax,'MATLAB 实际场景：7 站址 × 3 共址 TRP，210 UE','FontSize',22);
annotation(f,'textbox',[.08 .015 .85 .075],'String',...
  'seed 20261011；点色=初始归属站；箭头=0°/120°/240°主方向；虚线弧=项目假设的25–150 m扇区范围，非无干扰硬边界。',...
  'EdgeColor','none','FontSize',12,'Color',[.2 .26 .34]);
exportgraphics(f,fullfile(outputDir,'topology_full.pdf'),'ContentType','vector'); close(f);
end

function draw_zoom(scene,g,local,globalId,served,outputDir)
t=scene.topology; home=scene.home(globalId); siteId=t.trp_site_id(home);
o=t.site_xy(siteId,:); c=lines(7);
f=figure('Visible','off','Color','w','Position',[20 20 1920 1080]);
ax=axes(f,'Position',[.07 .14 .86 .74]); hold(ax,'on'); axis(ax,'equal');
for s=1:3
  l=(siteId-1)*3+s; a=t.trp_azimuth_deg(l)*pi/180;
  th=linspace(a-pi/3,a+pi/3,90);
  x=o(1)+150*cos(th); y=o(2)+150*sin(th);
  plot(ax,x,y,':','Color',[.55 .66 .8],'LineWidth',1.5);
  quiver(ax,o(1),o(2),110*cos(a),110*sin(a),0,'Color',c(s,:),...
    'LineWidth',3,'MaxHeadSize',.24);
  q=o+125*[cos(a) sin(a)];
  text(ax,q(1),q(2),sprintf('T%02d  %d°',l,t.trp_azimuth_deg(l)),...
    'FontSize',18,'FontWeight','bold','HorizontalAlignment','center','BackgroundColor','w');
end
ids=find(t.trp_site_id(scene.home)==siteId);
scatter(ax,scene.ue_xy(ids,1),scene.ue_xy(ids,2),38,[.45 .55 .68],'filled');
scatter(ax,o(1),o(2),420,[.04 .2 .42],'^','filled');
text(ax,o(1)+12,o(2)+12,sprintf('S%d：三TRP共址',siteId),'FontSize',20,'FontWeight','bold');
q=scene.ue_xy(globalId,:);
scatter(ax,q(1),q(2),330,[.85 .2 .2],'filled','MarkerEdgeColor','w','LineWidth',2);
text(ax,q(1)+9,q(2)+8,sprintf('UE %d / home T%02d',globalId,home),...
  'FontSize',17,'FontWeight','bold','BackgroundColor','w');
for h=1:numel(served)
  l=served(h); p=scene.trp_xy(l,:);
  plot(ax,[p(1) q(1)],[p(2) q(2)],'-','Color',[.82 .13 .16],...
    'LineWidth',3.2,'LineStyle','--');
end
xlim(ax,o(1)+[-190 190]); ylim(ax,o(2)+[-190 190]); grid(ax,'on');
xlabel(ax,'x / m'); ylabel(ax,'y / m'); ax.FontSize=15;
title(ax,sprintf('站 S%d 放大：UE %d 在资源组 %d 的实际服务集合',siteId,globalId,g),'FontSize',22);
annotation(f,'textbox',[.09 .02 .82 .08],'String',...
  sprintf('实线箭头=扇区主方向；红虚线=服务TRP至UE的协同关系：%s。服务由当前规则固定；扇区几何非天线硬覆盖。',mat2str(served(:)')),...
  'EdgeColor','none','FontSize',13,'Color',[.2 .26 .34]);
exportgraphics(f,fullfile(outputDir,'topology_zoom.pdf'),'ContentType','vector'); close(f);
end
