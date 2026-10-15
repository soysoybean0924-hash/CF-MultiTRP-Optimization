function build_atlas()
%BUILD_ATLAS Rebuild the CF/MathWorks teaching atlas. No solver is run.
% Run from any directory: build_atlas
% Source evidence and arrow IDs: ../11_图集与箭头索引.md
out = fileparts(mfilename('fullpath'));
draw_topology(out);
draw_interference(out);
draw_mathworks_topology(out);
draw_lane(out,'03_mathworks_central','MathWorks centralized: UE / AP / CPU','central');
draw_lane(out,'04_mathworks_distributed','MathWorks distributed: UE / AP / CPU','distributed');
draw_lane(out,'05_cf_actual_swimlane','CF project: modeled UE / TRP / central process','cf');
draw_interface(out);
draw_wmmse(out);
draw_metrics(out);
draw_calls(out);
fprintf('Exported 10 PDF + 10 PNG from MATLAB to %s\n',out);
end

function [f,a]=canvas(titleText,subText)
f=figure('Visible','off','Color','w','Position',[60 60 1600 900], ...
    'Renderer','painters','InvertHardcopy','off');
a=axes('Parent',f,'Position',[0.035 0.045 0.93 0.91]);
hold(a,'on'); axis(a,[0 100 0 100]); axis(a,'normal'); axis(a,'off');
txt(a,2,97,titleText,21,'bold',palette('navy'),'left');
txt(a,2,92.8,subText,11,'normal',palette('muted'),'left');
end

function c=palette(k)
switch k
 case 'navy', c=[.08 .20 .34];
 case 'blue', c=[.12 .37 .63];
 case 'pale', c=[.89 .95 .98];
 case 'gray', c=[.69 .74 .78];
 case 'muted', c=[.36 .44 .50];
 case 'green', c=[.13 .55 .41];
 case 'orange', c=[.88 .45 .18];
 case 'purple', c=[.48 .34 .69];
 case 'red', c=[.78 .30 .28];
end
end

function txt(a,x,y,s,sz,weight,color,align)
text(a,x,y,s,'Interpreter','none','FontName','Microsoft YaHei', ...
 'FontSize',sz,'FontWeight',weight,'Color',color, ...
 'HorizontalAlignment',align,'VerticalAlignment','middle','Clipping','off');
end

function eq(a,x,y,s,sz,align)
text(a,x,y,['$' s '$'],'Interpreter','latex','FontSize',sz,'Color',palette('navy'), ...
 'HorizontalAlignment',align,'VerticalAlignment','middle','Clipping','off');
end

function box(a,x,y,w,h,titleText,formula)
rectangle(a,'Position',[x-w/2 y-h/2 w h],'Curvature',.14, ...
 'FaceColor',palette('pale'),'EdgeColor',palette('blue'),'LineWidth',1.2);
txt(a,x,y+1.6,titleText,10,'normal',palette('navy'),'center');
if ~isempty(formula)
 fs=10; if numel(formula)>50, fs=9; end
 eq(a,x,y-2.0,formula,fs,'center');
end
end

function arrow(a,x1,y1,x2,y2,col,style,lw)
if nargin<8, lw=1.5; end
line(a,[x1 x2],[y1 y2],'Color',col,'LineStyle',style,'LineWidth',lw);
theta=atan2(y2-y1,x2-x1); len=1.35; wid=.55;
p=[x2 y2; x2-len*cos(theta)+wid*sin(theta) y2-len*sin(theta)-wid*cos(theta); ...
 x2-len*cos(theta)-wid*sin(theta) y2-len*sin(theta)+wid*cos(theta)];
patch(a,p(:,1),p(:,2),col,'EdgeColor',col);
end

function icon(a,x,y,kind,scale)
if nargin<5,scale=1;end
c=palette('navy');
switch kind
 case 'cpu'
  rectangle(a,'Position',[x-2.3*scale y-2*scale 4.6*scale 4*scale], ...
   'FaceColor',palette('pale'),'EdgeColor',c,'LineWidth',1.5);
  rectangle(a,'Position',[x-1.2*scale y-1*scale 2.4*scale 2*scale], ...
   'EdgeColor',c,'LineWidth',1.2);
  for q=-1:1, line(a,[x+q*1.2*scale x+q*1.2*scale], ...
    [y+2*scale y+2.8*scale],'Color',c,'LineWidth',1.2); end
 case 'trp'
  line(a,[x x],[y-2.8*scale y+2*scale],'Color',c,'LineWidth',1.5);
  line(a,[x-2*scale x x+2*scale],[y-2.8*scale y+2*scale y-2.8*scale], ...
   'Color',c,'LineWidth',1.3);
  line(a,[x-1.5*scale x+1.5*scale],[y-1*scale y-1*scale], ...
   'Color',c,'LineWidth',1.0);
  line(a,[x-1.1*scale x+1.1*scale],[y+.3*scale y+.3*scale], ...
   'Color',c,'LineWidth',1.0);
  plot(a,x,y+2.25*scale,'.','Color',c,'MarkerSize',10);
 case 'ue'
  rectangle(a,'Position',[x-1.25*scale y-2.5*scale 2.5*scale 5*scale], ...
   'Curvature',.15,'FaceColor','w','EdgeColor',c,'LineWidth',1.5);
  line(a,[x-.75*scale x+.75*scale],[y+1.75*scale y+1.75*scale], ...
   'Color',c,'LineWidth',.8);
  plot(a,x,y-1.85*scale,'.','Color',c,'MarkerSize',5);
end
end

function legend_line(a,x,y,col,style,label)
line(a,[x x+5],[y y],'Color',col,'LineStyle',style,'LineWidth',1.6);
txt(a,x+6,y,label,9,'normal',palette('muted'),'left');
end

function output(f,out,name)
drawnow;
exportgraphics(f,fullfile(out,[name '.png']),'Resolution',220);
exportgraphics(f,fullfile(out,[name '.pdf']),'ContentType','vector');
close(f);
end

function draw_topology(out)
[f,a]=canvas('CF saved group 3: CPU / TRP / UE service topology', ...
 'Illustrative layout, NOT radio coordinates; selected service links from saved scene_manifest.json (RB 48–63).');
icon(a,50,84,'cpu',1.4); txt(a,50,78,'Central process (no implemented fronthaul)',11,'bold',palette('navy'),'center');
sites=[19 50 81]; cols={palette('green'),palette('orange'),palette('purple'),palette('blue')};
for j=1:3
 arrow(a,50,77,sites(j),66,palette('gray'),'-',.85);
 for q=0:2
  xx=sites(j)+(q-1)*7; icon(a,xx,60,'trp',.95);
  txt(a,xx,54,sprintf('TRP %d',(j-1)*3+q),9,'normal',palette('navy'),'center');
 end
 txt(a,sites(j),69,sprintf('Site %d: 3 co-located sectors',j-1),10,'normal',palette('muted'),'center');
end
ue=[12 35 60 85]; uy=[24 21 24 21]; ids=[0 23 32 62];
for i=1:4
 icon(a,ue(i),uy(i),'ue',1.2);txt(a,ue(i),uy(i)-6,sprintf('UE %d',ids(i)),11,'bold',palette('navy'),'center');
end
% Exact saved g=3 masks: 0->{0,1}, 23->{0,2}, 32->{3,4}, 62->{6,7}.
tx=[12 19 12 26 43 50 74 81];rx=[1 1 2 2 3 3 4 4];
for i=1:numel(tx)
 group=ceil(i/2); arrow(a,tx(i),52,ue(rx(i)),uy(rx(i))+5,cols{group},'--',1.7);
end
legend_line(a,6,9,palette('gray'),'-','logical CPU–TRP link; no CF message object');
legend_line(a,43,9,palette('green'),'--','DL service, one color per UE');
legend_line(a,73,9,palette('red'),':','interference: Fig. 02b');
output(f,out,'01_cf_saved_topology');
end

function draw_interference(out)
[f,a]=canvas('CF local link: useful coherent sum and other-user interference', ...
 'Saved group 3 subset: UE 0 served by TRP 0/1; UE 23 by TRP 0/2. Remaining group users still contribute interference.');
tx=[19 50 77];for j=1:3,icon(a,tx(j),69,'trp',1.6);txt(a,tx(j),61,sprintf('TRP %d',j-1),12,'bold',palette('navy'),'center');end
icon(a,33,30,'ue',1.7);icon(a,69,30,'ue',1.7);
txt(a,33,22,'UE 0',12,'bold',palette('navy'),'center');txt(a,69,22,'UE 23',12,'bold',palette('navy'),'center');
arrow(a,19,58,31,36,palette('green'),'--',2);arrow(a,50,58,35,36,palette('green'),'--',2);
arrow(a,19,58,67,36,palette('purple'),'--',2);arrow(a,77,58,71,36,palette('purple'),'--',2);
arrow(a,77,55,37,33,palette('red'),':',1.6);
eq(a,7,81,'G_{0,0}=H_{0,0}V_{0,0}+H_{0,1}V_{1,0}',14,'left');
eq(a,53,81,'G_{0,23}=H_{0,0}V_{0,23}+H_{0,2}V_{2,23}',14,'left');
eq(a,8,12,'y_0=G_{0,0}s_0+\sum_{i\ne 0}G_{0,i}s_i+n_0',16,'left');
txt(a,7,6,'H: 4×64; V: 64×d; G: 4×d. Green/purple dashed: service. Red dotted: UE 23 data interfering at UE 0.',10,'normal',palette('muted'),'left');
output(f,out,'02_cf_local_interference');
end

function draw_mathworks_topology(out)
[f,a]=canvas('MathWorks cell-free example: CPU / AP / UE topology', ...
 'Conceptual nearest-two connection example, NOT a replay of generated positions or actual AP IDs. Current online page: 20 AP, 4 UE.');
icon(a,50,84,'cpu',1.4);txt(a,50,77,'CPU: scheduling + joint CSI / W',11,'bold',palette('navy'),'center');
apx=[13 28 43 58 73 88];
for m=1:numel(apx)
 arrow(a,50,74,apx(m),62,palette('gray'),'-',.8);
 icon(a,apx(m),57,'trp',1.05);
 txt(a,apx(m),50,sprintf('AP %c','A'+m-1),10,'normal',palette('navy'),'center');
end
icon(a,32,23,'ue',1.4);icon(a,71,23,'ue',1.4);
txt(a,32,16,'UE k',11,'bold',palette('navy'),'center');
txt(a,71,16,'UE j',11,'bold',palette('navy'),'center');
arrow(a,28,48,30,29,palette('green'),'--',1.7);
arrow(a,43,48,34,29,palette('green'),'--',1.7);
arrow(a,58,48,69,29,palette('purple'),'--',1.7);
arrow(a,73,48,73,29,palette('purple'),'--',1.7);
txt(a,50,11,'The page sorts horizontal AP–UE distances, then selects the nearest 2 APs per UE (O01). Labels A–F are illustrative.',10,'normal',palette('muted'),'center');
legend_line(a,14,5,palette('gray'),'-','ideal fronthaul');
legend_line(a,44,5,palette('green'),'--','UE k service');
legend_line(a,71,5,palette('purple'),'--','UE j service');
output(f,out,'02_mathworks_topology');
end

function lane_base(a)
xx=[16 50 84]; kinds={'ue','trp','cpu'}; names={'UE','AP / TRP','CPU / process'};
for i=1:3
 icon(a,xx(i),85,kinds{i},1.1);
 txt(a,xx(i),78,names{i},12,'bold',palette('navy'),'center');
 line(a,[xx(i) xx(i)],[73 9],'Color',palette('gray'),'LineWidth',1,'LineStyle',':');
end
txt(a,2,80,'time ↓',9,'normal',palette('muted'),'left');
end

function link(a,from,to,y,label,col,style)
xx=[16 50 84];
if from<to, x1=xx(from)+11.8;x2=xx(to)-11.8;
else, x1=xx(from)-11.8;x2=xx(to)+11.8;end
arrow(a,x1,y,x2,y,col,style,1.5);
txt(a,(x1+x2)/2,y+5.4,label,8,'normal',col,'center');
end

function draw_lane(out,name,titleText,mode)
switch mode
 case 'central', sub='Official current page: AP relays path gains/filters and waveforms; CPU estimates CSI and applies DL W.';
 case 'distributed', sub='Official current page: AP estimates local CSI and applies CPU-computed DL W block; UL AP sends LLR.';
 otherwise, sub='CF model equivalent only: no CPU/AP/UE message objects, SRS waveform, PDSCH or PUSCH PHY.';
end
[f,a]=canvas(titleText,sub);lane_base(a);
switch mode
 case 'central'
  box(a,84,68,23,10,'SRS configuration','');box(a,16,56,23,10,'UE SRS transmit','');
  arrow(a,72,68,28,68,palette('purple'),':',1.2);
  txt(a,50,71,'SRS setup · M01',8,'normal',palette('purple'),'center');
  box(a,50,56,23,10,'AP SRS receive','');link(a,1,2,56,'SRS RF · M02',palette('orange'),'-');
  box(a,50,42,23,10,'Relay path parameters','');box(a,84,42,23,10,'CSI + DL ZF','W_k=\mathrm{ZF}(\hat H_k)');
  link(a,2,3,42,'path gains / filters · M06',palette('purple'),'-');
  box(a,84,27,23,10,'Encode + precode','');box(a,50,27,23,10,'Relay PDSCH','');
  link(a,3,2,27,'precoded waveform · M07',palette('purple'),'-');
  box(a,16,15,23,10,'DL receive','');box(a,50,15,23,10,'AP DL transmit','');
  link(a,2,1,15,'PDSCH RF · M08',palette('green'),'-');
  txt(a,49,6,'PUSCH separate: UE TPMI → AP waveform relay → CPU UL detection (M09–M10).',9,'normal',palette('muted'),'center');
 case 'distributed'
  box(a,84,68,23,10,'SRS configuration','');box(a,16,56,23,10,'UE SRS transmit','');
  arrow(a,72,68,28,68,palette('purple'),':',1.2);
  txt(a,50,71,'SRS setup · M01',8,'normal',palette('purple'),'center');
  box(a,50,56,23,10,'Local CSI estimate','');link(a,1,2,56,'SRS RF · M02',palette('orange'),'-');
  box(a,50,42,23,10,'Send local CSI','');box(a,84,42,23,10,'Stack CSI + ZF','\hat H_k=\mathrm{stack}_m(H_{mk})');
  link(a,2,3,42,'H_mk · M11',palette('purple'),'-');
  box(a,84,27,23,10,'Encode TB; split W','W_k=[W_{m_1k}^T\;W_{m_2k}^T]^T');
  box(a,50,27,23,10,'Apply W_mk; modulate','');link(a,3,2,27,'TB + W_mk · M12',palette('purple'),'-');
  box(a,16,15,23,10,'DL receive','');box(a,50,15,23,10,'AP DL transmit','');
  link(a,2,1,15,'PDSCH RF · M08',palette('green'),'-');
  txt(a,49,6,'PUSCH separate: UE TPMI → AP UL PHY/LLR → CPU soft combination (M09,M13).',9,'normal',palette('muted'),'center');
 otherwise
  box(a,84,68,23,10,'Configure scene','');box(a,16,56,23,10,'No SRS waveform','');
  box(a,50,56,23,10,'Observation model','');link(a,1,2,56,'modeled SRS · F06',palette('orange'),'--');
  box(a,50,42,23,10,'No CSI upload','');box(a,84,42,23,10,'H_est, C, serve','');
  link(a,2,3,42,'same-process arrays · F06',palette('purple'),'--');
  box(a,84,27,23,10,'Central solve V','');box(a,50,27,23,10,'Equivalent x_l','x_l=\sum_i V_{li}s_i');
  link(a,3,2,27,'V array; no fronthaul · F12',palette('purple'),'--');
  box(a,16,15,23,10,'Equivalent y_k','y_k=\sum_lH_{kl}x_l+n_k');
  box(a,50,15,23,10,'Equivalent DL','');link(a,2,1,15,'modeled DL · F01/F02',palette('green'),'--');
  txt(a,49,6,'UE 2 UL Tx → two modeled SRS rows; remaining 4 DL Rx rows via modeled CSI-RS. No PUSCH.',9,'normal',palette('muted'),'center');
end
output(f,out,name);
end

function draw_interface(out)
[f,a]=canvas('Precoder notation and actual interfaces: old W, new V, official W_k', ...
 'All three describe DL transmission in different systems. Red dotted breaks indicate no source-code conversion.');
box(a,19,71,27,13,'Old MATLAB: W beam','W_{m,s,r,u,g}: M\times 1');
box(a,50,71,27,13,'CHASI: V precoder','V_{g,l,k}: 64\times d');
box(a,81,71,27,13,'MathWorks: W_k ZF','W_k=[W_{m_1k}^T\;\cdots]^T');
txt(a,19,57,'H_est, Q → initialization → inner update',10,'normal',palette('navy'),'center');
txt(a,50,57,'SVD initialization → WMMSE + ADMM',10,'normal',palette('navy'),'center');
txt(a,81,57,'CPU calculates; CPU or AP applies',10,'normal',palette('navy'),'center');
eq(a,19,47,'p_{r,u,g}=\sum_s\|W_{:,s,r,u,g}\|^2',14,'center');
eq(a,50,47,'P_l=\sum_g a_g\sum_k\|V_{g,l,k}\|_F^2',14,'center');
eq(a,81,47,'W_{m_i^k k}=\mathrm{AP\ row\ block}(W_k)',13,'center');
arrow(a,19,54,19,50,palette('blue'),'-',1.5);
arrow(a,50,54,50,50,palette('blue'),'-',1.5);
arrow(a,81,54,81,50,palette('blue'),'-',1.5);
line(a,[32.5 36.5],[79 79],'Color',palette('red'),'LineStyle',':','LineWidth',1.8);
line(a,[63.5 67.5],[79 79],'Color',palette('red'),'LineStyle',':','LineWidth',1.8);
txt(a,34.5,83,'no W→V assignment',9,'bold',palette('red'),'center');
txt(a,65.5,83,'no proven inheritance',9,'bold',palette('red'),'center');
box(a,50,29,43,12,'CHASI W is an MSE weight, not a beam','W_{g,k}^{\mathrm{MSE}}=E_{g,k}^{-1}:d\times d');
txt(a,50,16,'Reference 2023: scalar v_k = receiver; μ_lk = √power with fixed MR direction.',10,'normal',palette('muted'),'center');
legend_line(a,21,7,palette('blue'),'-','actual per-path data flow');
legend_line(a,54,7,palette('red'),':','no implemented interface');
output(f,out,'06_w_v_interface');
end

function draw_wmmse(out)
[f,a]=canvas('Matrix WMMSE outer loop and centralized ADMM inner loop', ...
 'Service mask and rank are fixed. The returned feasible Z is checked by outer-line search; neither stop test proves global optimality.');
rectangle(a,'Position',[5 17 38 68],'Curvature',.05,'EdgeColor',palette('blue'),'LineWidth',1.5);
rectangle(a,'Position',[49 17 46 68],'Curvature',.05,'EdgeColor',palette('purple'),'LineWidth',1.5);
txt(a,24,81,'WMMSE outer loop',13,'bold',palette('blue'),'center');
txt(a,72,81,'ADMM inner loop',13,'bold',palette('purple'),'center');
box(a,24,69,28,10,'Current feasible V','V_{g,l,k}:64\times d');
box(a,24,53,28,10,'Update U, E, W','U=R_{yy}^{-1}G;\;W=E^{-1}');
box(a,24,36,28,10,'Fix U/W, form Q/B','f(V)=\langle V,QV\rangle-2\Re\langle B,V\rangle');
box(a,24,21,28,10,'Accept / stop','V^+=V+\alpha(Z-V)');
arrow(a,24,64,24,58,palette('blue'),'-');arrow(a,24,48,24,41,palette('blue'),'-');
arrow(a,24,31,24,26,palette('blue'),'-');
box(a,72,68,32,10,'CG update primal X','(a_gQ+\rho I/2)X=a_gB+\rho(Z-Y)/2');
box(a,72,52,32,10,'Project copy Z','Z=\Pi_{\mathcal C}(X+Y)');
box(a,72,36,32,10,'Scaled dual Y','Y\leftarrow Y+X-Z');
box(a,72,21,32,10,'Residual test','r=\|X-Z\|;\;s=\rho\|Z-Z^-\|');
arrow(a,72,63,72,57,palette('purple'),'-');arrow(a,72,47,72,41,palette('purple'),'-');
arrow(a,72,31,72,26,palette('purple'),'-');
arrow(a,38,36,56,68,palette('purple'),'-');txt(a,46,58,'Q/B, mask, budget',9,'normal',palette('purple'),'center');
arrow(a,56,21,38,21,palette('purple'),'-');txt(a,47,25,'return feasible Z',9,'normal',palette('purple'),'center');
arrow(a,90,21,93,59,palette('purple'),'-');arrow(a,93,59,88,68,palette('purple'),'-');
txt(a,91,45,'continue',8,'normal',palette('purple'),'center');
arrow(a,8,21,7,68,palette('blue'),'-');arrow(a,7,68,10,69,palette('blue'),'-');
eq(a,49,10,'\sum_g a_g\sum_k\|V_{g,l,k}\|_F^2\leq 20\,\mathrm W\quad\forall l',15,'center');
txt(a,49,5,'Power projection spans all RB groups for each TRP; fixed serve mask zeroes prohibited blocks.',9,'normal',palette('muted'),'center');
output(f,out,'07_wmmse_admm');
end

function draw_metrics(out)
[f,a]=canvas('From final precoder to physical-rate and experience proxies', ...
 'CF computes equivalent covariances, not modulation samples or ACKed RLC data. Final rates use H_true.');
box(a,16,72,23,12,'Final V + H_true','G_{ki}=\sum_l H_{kl}^{true}V_{li}');
box(a,50,72,25,12,'Signal / interference','S_k=G_{kk}G_{kk}^H;\;J_k=\sum_{i\ne k}G_{ki}G_{ki}^H');
box(a,84,72,25,12,'Static true SE','\log_2\det(R_{all})-\log_2\det(R_{int})');
arrow(a,28,72,37,72,palette('green'),'-');arrow(a,63,72,71,72,palette('green'),'-');
box(a,84,43,25,12,'RB-weighted UE SE','R_u=\sum_g a_g SE_{g,u}');
box(a,50,43,25,12,'Traffic / valid TTI','\mathrm{busy}\wedge\neg\mathrm{terminal}');
box(a,16,43,25,12,'Experience proxy','\mathrm{volume}/\mathrm{valid\ seconds}');
arrow(a,84,66,84,49,palette('blue'),'-');arrow(a,72,43,63,43,palette('blue'),'-');
arrow(a,37,43,28,43,palette('blue'),'-');
box(a,50,18,42,12,'Saved summary / arrays / plots','V,U,W\;\rightarrow\;\mathrm{NPZ/MAT},\quad KPI\;\rightarrow\;\mathrm{JSON}');
arrow(a,16,37,39,18,palette('blue'),'-');
txt(a,50,7,'True-channel static SE is a model KPI; no PHY BLER, PUSCH, or ACKed RLC throughput in this path.',10,'normal',palette('muted'),'center');
eq(a,50,59,'R_{all}=I_4+S_k+J_k;\quad R_{int}=I_4+J_k',11,'center');
output(f,out,'08_metric_flow');
end

function draw_calls(out)
[f,a]=canvas('Actual execution tracks and the unconnected boundaries', ...
 'Three entry tracks coexist. MATLAB CHASI bridge passes scalar CLI settings, not old H/W arrays.');
labels={'Old MATLAB search','CHASI MATLAB→Python','Conditional MATLAB native'};
ys=[72 48 24];
for i=1:3
 txt(a,3,ys(i)+8,labels{i},12,'bold',palette('navy'),'left');
end
box(a,20,72,23,10,'paper_ablation entry','');box(a,50,72,23,10,'cf_search / cf_eval','');
box(a,81,72,23,10,'J_true / old W','');
arrow(a,32,72,38,72,palette('blue'),'-');arrow(a,62,72,69,72,palette('blue'),'-');
box(a,20,48,23,10,'run_chasi_formal.m','');box(a,50,48,23,10,'Python run / solve','');
box(a,81,48,23,10,'V / U / W / KPI','');
arrow(a,32,48,38,48,palette('green'),'-');arrow(a,62,48,69,48,palette('green'),'-');
box(a,20,24,23,10,'chasiNative.enabled','');box(a,50,24,23,10,'native resources','');
box(a,81,24,23,10,'matrix WMMSE.m','');
arrow(a,32,24,38,24,palette('purple'),'-');arrow(a,62,24,69,24,palette('purple'),'-');
line(a,[50 50],[66 54],'Color',palette('red'),'LineStyle',':','LineWidth',1.5);
line(a,[81 81],[42 30],'Color',palette('red'),'LineStyle',':','LineWidth',1.5);
txt(a,64,60,'no old W→new V conversion',9,'bold',palette('red'),'center');
txt(a,63,36,'not formal CHASI native entry',9,'bold',palette('red'),'center');
legend_line(a,6,8,palette('blue'),'-','connected call');
legend_line(a,42,8,palette('red'),':','no default interface');
output(f,out,'09_callgraph');
end
