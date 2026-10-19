function build_study_atlas(figures)
%BUILD_STUDY_ATLAS Produce sixteen editable, source-grounded CHASI diagrams.
% From repository root: addpath('docs/study_materials_20261019/atlas'); build_study_atlas
if nargin<1, figures=1:16; end
if any(figures<1 | figures>16 | figures~=fix(figures))
    error('CHASI:AtlasFigure','Figure numbers must be integers in 1..16');
end
out=fileparts(mfilename('fullpath'));
ids={'calls','formal_flow','network','ports','srs_csi','resources',...
    'wmmse_admm','signal','metrics','lifecycle','languages','dynamic',...
    'research_map','legacy_search','nonuniform_boundary','resource_time'};
titles={'Actual MATLAB calls','Formal native MATLAB chain',...
    'Seven-site / twenty-one-TRP topology','Antenna and matrix axes',...
    'UE / TRP / CPU: SRS and CSI','Scheduling, serving, rank, and power',...
    'WMMSE outer loop and centralized ADMM','CPU / TRP / UE: downlink model',...
    'True-channel SE to experience proxy','Variable lifecycle and saved fields',...
    'MATLAB formal chain and Python reference','Optional dynamic replay boundary',...
    'Challenge, scene, method and evidence','Independent GA PSO SRACOS search',...
    'SRS quality and robust research boundary',...
    '273 RB, seventeen SRS hops and CSI age'};
for n=figures
    [f,a]=canvas(n,titles{n});
    switch n
        case 1, calls(a);
        case 3, topology(a);
        case 4, antenna(a);
        case {5,8}, lanes(a,n);
        case 12, dynamicBoundary(a);
        case 14, legacySearch(a);
        case 15, robustBoundary(a);
        case 16, resourceTime(a);
        otherwise, flow(a,n);
    end
    drawnow;
    exportgraphics(f,fullfile(out,sprintf('%02d_%s.png',n,ids{n})),'Resolution',220);
    exportgraphics(f,fullfile(out,sprintf('%02d_%s.pdf',n,ids{n})),'ContentType','vector');
    exportgraphics(f,fullfile(out,sprintf('%02d_%s.svg',n,ids{n})),'ContentType','vector');
    close(f);
end
function calls(a)
box(a,15,50,24,11,'chasi_run','owner: call + save');
box(a,50,75,24,10,'chasi_config','cfg');
box(a,50,55,24,10,'chasi_generate_scene','Htrue,Hhat,C,b,chi');
box(a,50,35,24,10,'chasi_traffic','busy,tail,terminal');
box(a,85,65,24,10,'chasi_matrix_wmmse','w,A,E,Omega,eta');
box(a,85,35,24,10,'chasi_evaluate','true SE, experience');
c=[.12 .37 .63];g=[.12 .55 .4];
arr(a,27,53,38,75,'',c);arr(a,27,50,38,55,'',c);arr(a,27,47,38,35,'',c);
line(a,[15 15 85],[56 84 84],'Color',c,'LineWidth',1.5);
arr(a,85,84,85,70,'MATLAB call',c);
line(a,[15 15 85],[44 18 18],'Color',c,'LineWidth',1.5);
arr(a,85,18,85,30,'MATLAB call',c);
arr(a,62,57,73,65,'resources',g,'--');
arr(a,62,35,73,35,'traffic',g,'--');
arr(a,85,60,85,40,'precoder',g,'--');
txt(a,5,88,'Blue solid = chasi_run call; green dashed = arrays passed to solver/evaluator.',10,'normal',[.34 .43 .5],'left');
foot(a,'Call evidence: chasi_run.m:39-45,90-97. chasi_run saves scene.mat before optimization, then precoder MAT, per-UE CSV and summary JSON.');
end
function legacySearch(a)
box(a,16,73,24,12,'9-D candidate / L03','cf_decode_candidate');
box(a,48,79,22,11,'GA operator','cf_search>gaPhase');
box(a,48,62,22,11,'PSO operator','cf_search>psoPhase');
box(a,48,45,22,11,'SRACOS guidance','cf_search>pgsaoSearch');
box(a,80,69,27,12,'old evaluator','cf_evaluate_candidate');
box(a,80,41,27,12,'J_old / L07,L15','old SINR and rate');
blue=[.12 .37 .63]; red=[.68 .10 .10];
arr(a,28,75,37,79,'candidate',blue);
arr(a,28,72,37,62,'candidate',blue);
arr(a,28,69,37,45,'candidate',blue);
arr(a,59,79,66,72,'trial',blue);
arr(a,59,62,66,68,'trial',blue);
arr(a,59,45,69,63,'guided trial',blue);
arr(a,80,63,80,47,'evaluate',blue);
line(a,[10 90],[25 25],'Color',red,'LineStyle','--','LineWidth',1.6);
txt(a,50,20,'No call from formal chasi_run to cf_search; optional legacy adapter is a separate branch.',11,'bold',red,'center');
foot(a,'Old search budget counts candidate evaluations. Optional chasiNative changes ObjectiveName to estimated PF; it does not turn the formal scene into an outer search loop.');
end
function robustBoundary(a)
box(a,15,70,22,12,'SRS quality','pilot SNR + age / C10');
box(a,41,70,22,12,'Hhat and C','posterior / C11-C12');
box(a,67,70,22,12,'A,E,Omega','state / C17-C19');
box(a,90,70,17,12,'Q,B,D','C24-C26');
green=[.12 .55 .4]; red=[.68 .10 .10];
arr(a,26,70,30,70,'observation',green,'--');
arr(a,52,70,56,70,'statistics',green,'--');
arr(a,78,70,81.5,70,'MSE',green,'--');
line(a,[5 95],[53 53],'Color',red,'LineStyle','--','LineWidth',1.6);
txt(a,50,49,'CURRENT CODE ABOVE    /    RESEARCH PROPOSAL BELOW',11,'bold',red,'center');
box(a,32,32,31,12,'calibrated ellipsoid','full covariance + coverage');
box(a,72,32,31,12,'worst-case optimization','risk objective + KPI proof');
arr(a,48,32,56,32,'proposal',red,'--');
foot(a,'C_stat is only a 4x4 receive-side marginal covariance. No calibrated full channel ellipsoid or worst-case solver is called by chasi_run.');
end
function dynamicBoundary(a)
blue=[.12 .37 .63]; green=[.12 .55 .4]; red=[.68 .10 .10];
box(a,16,76,25,11,'static solution','w, Htrue / C32');
box(a,48,76,25,11,'optional time replay','timeEvolutionTti > 0');
box(a,81,76,25,11,'SRS / CSI refresh','Hhat(t), C(t) / C38');
arr(a,28.5,76,35.5,76,'scene + w',blue);
arr(a,60.5,76,68.5,76,'20 TTI steps',blue);
box(a,29,44,28,11,'estimated SVD','default beam policy');
box(a,75,44,28,11,'online WMMSE','optional matrix branch');
line(a,[81 81 29],[70.5 61 61],'Color',green,'LineWidth',1.5);
arr(a,29,61,29,49.5,'Hhat,C',green,'--');
arr(a,81,70.5,75,49.5,'Hhat,C',red,'--');
box(a,52,23,33,10,'rate + queue replay','true H, updated w / C32-C37');
arr(a,29,38.5,42,27.5,'w',blue);
arr(a,75,38.5,62,27.5,'w',blue);
foot(a,'Online update uses the current matrix branch with fixed schedule/service/rank. Only a deterministic 1-UE test passes; no formal 210/420 mobile run or Python online parity.');
end
function resourceTime(a)
red=[.68 .10 .10]; blue=[.12 .37 .63];
box(a,18,77,27,12,'273 data RB','16 groups x 16 + final 17');
box(a,50,77,27,12,'17 SRS hops','20 ms per hop; 340 ms cycle');
box(a,82,77,27,12,'CSI-RS age','40 TTI measurement period');
txt(a,8,59,'SRS frequency group',12,'bold',red,'left');
for g=1:17
    x=8+(g-1)*5.05;
    h=7;if g==17,h=9;end
    rectangle(a,'Position',[x 43 3.3 h],'FaceColor',red,'EdgeColor',red);
    if ismember(g,[1 2 3 16 17])
        txt(a,x+1.65,38,num2str(g),10,'normal',blue,'center');
    end
end
line(a,[8 92],[34 34],'Color',blue,'LineWidth',1.6);
arr(a,8,34,92,34,'t = 0 ... 340 ms',blue);
txt(a,9,24,'Each hop measures 16 RB; hop 17 measures 17 RB. Data weighting uses transmitted RB / 273 (C07).',11,'normal',blue,'left');
txt(a,9,18,'30% traffic load and 30-50% PRB utilization are separate acceptance quantities.',11,'bold',red,'left');
foot(a,'C07-C10; chasi_config.m and chasi_generate_scene.m. Bars show group metadata and timing, not sampled SRS waveforms or calibrated CSI ages.');
end
fprintf('Wrote %d PNG and %d PDF diagrams to %s\n',numel(figures),numel(figures),out);
end
function [f,a]=canvas(n,titleText)
f=figure('Visible','off','Color','w','Position',[60 60 1600 900],...
    'Renderer','painters','InvertHardcopy','off');
a=axes('Parent',f,'Position',[.04 .045 .92 .91]);
hold(a,'on');axis(a,[0 100 0 100]);axis(a,'normal');axis(a,'off');
txt(a,2,96,sprintf('%02d  %s',n,titleText),20,'bold',[.68 .10 .10],'left');
txt(a,2,91,'Code baseline 3efa44c; formulas C01-C38 / L01-L17 / Z01-Z03 / R01-R04',10,'normal',[.4 .32 .31],'left');
end
function txt(a,x,y,s,z,w,c,align)
text(a,x,y,s,'Interpreter','none','FontName','Arial','FontSize',z,...
    'FontWeight',w,'Color',c,'HorizontalAlignment',align,...
    'VerticalAlignment','middle','Clipping','off');
end
function math(a,x,y,s,z)
text(a,x,y,['$' s '$'],'Interpreter','latex','FontSize',z,...
    'Color',[.08 .20 .34],'HorizontalAlignment','center',...
    'VerticalAlignment','middle','Clipping','off');
end
function box(a,x,y,w,h,t,sub)
rectangle(a,'Position',[x-w/2 y-h/2 w h],'Curvature',.12,...
    'FaceColor',[1 .95 .82],'EdgeColor',[.68 .10 .10],'LineWidth',1.3);
txt(a,x,y+1.5,t,11,'bold',[.08 .20 .34],'center');
txt(a,x,y-2,sub,9,'normal',[.34 .43 .5],'center');
end
function arr(a,x1,y1,x2,y2,label,col,style)
if nargin<8,style='-';end
line(a,[x1 x2],[y1 y2],'Color',col,'LineStyle',style,'LineWidth',1.6);
t=atan2(y2-y1,x2-x1);u=1.3;v=.5;
p=[x2,y2;x2-u*cos(t)+v*sin(t),y2-u*sin(t)-v*cos(t);...
    x2-u*cos(t)-v*sin(t),y2-u*sin(t)+v*cos(t)];
patch(a,p(:,1),p(:,2),col,'EdgeColor',col);
if ~isempty(label)
    txt(a,(x1+x2)/2,(y1+y2)/2+2,label,9,'normal',col,'center');
end
end
function foot(a,s)
line(a,[2 98],[13 13],'Color',[.75 .8 .84]);
txt(a,2,8,s,9,'normal',[.34 .43 .5],'left');
end
function icon(a,x,y,kind)
c=[.08 .20 .34];
switch kind
    case 'cpu'
        rectangle(a,'Position',[x-2.4 y-2 4.8 4],...
            'FaceColor',[.89 .95 .98],'EdgeColor',c,'LineWidth',1.7);
        rectangle(a,'Position',[x-1 y-1 2 2],'EdgeColor',c);
        for q=-1:1
            line(a,[x+q x+q],[y+2 y+2.7],'Color',c);
        end
    case 'trp'
        line(a,[x x],[y-2.5 y+2],'Color',c,'LineWidth',1.7);
        line(a,[x-2 x x+2],[y-2.5 y+2 y-2.5],'Color',c,'LineWidth',1.4);
        line(a,[x-1.2 x+1.2],[y-.7 y-.7],'Color',c);
        plot(a,x,y+2,'.','Color',c,'MarkerSize',10);
    case 'ue'
        rectangle(a,'Position',[x-1.1 y-2.5 2.2 5],...
            'Curvature',.15,'EdgeColor',c,'LineWidth',1.6);
        line(a,[x-.7 x+.7],[y+1.7 y+1.7],'Color',c);
end
end
function topology(a)
icon(a,50,81,'cpu');txt(a,50,75,'central MATLAB process (logical CPU)',11,'bold',[.08 .20 .34],'center');
for m=1:7
    cx=12+(m-1)*12.5;
    arr(a,50,73,cx,64,'',[.70 .75 .79]);
    for q=1:3,icon(a,cx+(q-2)*3,59,'trp');end
    txt(a,cx,52,sprintf('site %d / TRP %d-%d',m,3*m-2,3*m),8,'normal',[.08 .20 .34],'center');
end
icon(a,42,29,'ue');icon(a,26,29,'ue');
txt(a,42,22,'UE 41 (k)',12,'bold',[.08 .20 .34],'center');
txt(a,26,22,'UE 78 (j)',12,'bold',[.08 .20 .34],'center');
% Exact group-3 membership in formal420_20261017_schema3_named_final/scene_manifest.json:
% UE 41 <- TRP 3,16; UE 78 <- TRP 4,6. These are one-based MATLAB IDs.
arr(a,15,51,40,35,'',[.12 .55 .4],'--');
arr(a,71.5,51,44,35,'',[.12 .55 .4],'--');
arr(a,21.5,51,24,35,'',[.49 .36 .68],'--');
arr(a,27.5,51,28,35,'',[.49 .36 .68],'--');
arr(a,71.5,48,29,30,'',[.78 .29 .27],':');
line(a,[5 9],[86 86],'Color',[.12 .55 .4],'LineStyle','--','LineWidth',1.6);
txt(a,10,86,'UE 41 served by TRP 3/16',9,'normal',[.12 .55 .4],'left');
line(a,[36 40],[86 86],'Color',[.49 .36 .68],'LineStyle','--','LineWidth',1.6);
txt(a,41,86,'UE 78 served by TRP 4/6',9,'normal',[.49 .36 .68],'left');
line(a,[68 72],[86 86],'Color',[.78 .29 .27],'LineStyle',':','LineWidth',1.6);
txt(a,73,86,'UE 41 data interferes at UE 78',9,'normal',[.78 .29 .27],'left');
math(a,50,16,'y_k=\sum_j\sum_l H^{\rm true}_{klg}w_{ljg}s_j+n_k',13);
foot(a,'Service IDs: saved 420-UE seed-20261011 group 3 manifest. Layout is schematic, NOT saved coordinates. Gray CPU-TRP lines are logical.');
end
function antenna(a)
box(a,17,68,26,12,'Acceptance array','8 H x 4 V x 2 pol');
box(a,50,68,26,12,'Implemented Tx axis','64 optimization dimensions');
box(a,83,68,26,12,'UE ports','2 UL SRS / 4 DL Rx');
arr(a,30,68,37,68,'',[.78 .29 .27],'--');
arr(a,63,68,70,68,'H[4,64]',[.12 .37 .63]);
txt(a,50,53,'No array manifold or calibrated physical port mapping in the code',10,'normal',[.78 .29 .27],'center');
math(a,50,44,'H_{klg}:4\times64,\quad w_{ljg}:64\times r',18);
math(a,50,29,'P_{SRS}:2\times4,\quad C_{klg}:4\times4',17);
foot(a,'C06/C11/C14: 4x64 correlated-Gaussian H does not implement 2D dual-polarized array response, reciprocity calibration, or port map.');
end
function lanes(a,n)
xx=[18 50 82];names={'UE','TRP (modeled)','CPU / MATLAB'};kinds={'ue','trp','cpu'};
for i=1:3
    icon(a,xx(i),80,kinds{i});
    txt(a,xx(i),74,names{i},12,'bold',[.08 .20 .34],'center');
    line(a,[xx(i) xx(i)],[69 18],'Color',[.08 .20 .34]);
end
if n==5
    box(a,18,62,22,9,'SRS 2 ports','P_srs Htrue / C11');
    box(a,50,51,22,9,'Observation','Ys + Gaussian noise');
    box(a,82,40,22,9,'Posterior CSI','Hhat[4,64], C[4,4]');
    box(a,82,26,22,9,'WMMSE input','Hhat,C / C18');
    arr(a,29,61,39,52,'SRS 16...17 RB',[.89 .47 .18]);
    arr(a,61,50,71,41,'statistics (model)',[.12 .55 .4]);
    arr(a,82,35,82,31,'Hhat,C',[.12 .37 .63]);
    foot(a,'17 hops x 20 TTI = 340 TTI; final hop 17 RB. No actual SRS waveform, IQ forwarding, or TRP-local estimator is simulated.');
else
    box(a,82,62,22,9,'Computed w','[21,K,64,r] / C26');
    box(a,50,51,22,9,'TRP model x_l','sum_j w_lj s_j / C15');
    box(a,18,40,22,9,'UE model y_k','sum_l H_kl x_l+n / C16');
    box(a,18,26,22,9,'Combine','A_k^H y_k / C18');
    arr(a,71,61,61,52,'precoder blocks',[.12 .55 .4]);
    arr(a,39,50,29,41,'DL radio model',[.89 .47 .18]);
    arr(a,18,35,18,31,'useful + j interference',[.12 .37 .63]);
    foot(a,'Physical signal equations are model equivalents; the code computes complex covariances and log-det rates, not symbols or OFDM waveforms.');
end
end
function flow(a,n)
switch n
case 2
    t={'config / C01','scene / C02-C13','traffic + scene.mat','WMMSE / C14-C31','evaluate / C32-C36','save MAT/CSV/JSON'};
    s={'chasi_config','Htrue,Hhat,C,b,chi','chasi_traffic','chasi_matrix_wmmse','chasi_evaluate','chasi_run'};
    footer='This is execution order: scene.mat is written before solving; the optional dynamic replay runs after static evaluation and before final summary.';
case 6
    t={'RB use / C08','schedule b / C09','serve chi / C09','fixed rank r=2','precoder w / C14','power p / C26'};
    s={'tx_rb_count','ueIds by group','home+nearest active','DL Rx=4 upper bound','masked complex matrix','sum_g nu_g ||w||^2'};
    footer='nu_g = transmitted data RB / 273 enters objective, true rates and cross-group budget once; trafficLoad=.30 is separate.';
case 7
    t={'current w / C14','A,E,Omega / C18-C20','eta,Q,B,D / C22-C25','dual,residual / C29-C30','projection z / C29','CG x / C28'};
    s={'outer input','fix w','fix A/Omega','inner stop','cross-group power','linear system'};
    footer='C30: primal and dual residuals must each meet epsilon plus CG test. Saved 210/420 traces reach inner cap 12 and outer cap 2, not tolerance stop; feasible z is returned.';
case 9
    t={'Htrue,w / C32','effective channel','log-det R_SE','sum_g nu_g R_SE','busy/tail/terminal','experience proxy'};
    s={'held-out model','coherent TRP sum','bit/s/Hz','per global UE','chasi_traffic','volume/valid time'};
    footer='No waveform or ACK/BLER. Valid-only and missing-as-zero bottom 5% are both reported; neither establishes formal TS28.554 acceptance.';
case 10
    t={'cfg + seed','scene resources','solver state','true evaluation','MAT saved','JSON/CSV saved'};
    s={'chasi_config','Htrue,Hhat,C,b,chi','w,A,E,Omega,eta','SE, rate, power','scene/precoders','manifest/summary/perUE'};
    footer='CHASI v1/v2 fields convert only in chasi_load_precoder_result; legacy CF result.W is rejected. New schema separates precoder and mseWeight.';
case 11
    t={'MATLAB config','MATLAB scene','MATLAB solver','Python config','Python scenario','Python solver'};
    s={'formal native','formal native','formal native','independent reference','not called by MATLAB','explicit-input parity only'};
    footer='No formal Python bridge. Five tiny fixtures pass; saved 420-UE full solve passes explicit-input parity. 210-UE final Omega misses absolute threshold by 1.98e-6.';
case 12
    t={'static w/Htrue','optional time step','CSI age update','fast SVD reset','queue replay','online WMMSE'};
    s={'formal default','timeEvolutionTti>0','modeled observation','default beam policy','delivered bits','optional matrix branch'};
    footer='Online WMMSE refreshes w from updated estimated H/C at fast periods; schedule/service/rank stay fixed. One deterministic 1-UE test passes; no 210/420 mobile or Python parity proof.';
case 13
    t={'Challenge image','Acceptance scene','System proposal','MATLAB model','Saved evaluation','Acceptance gap'};
    s={'edge, power, scale','7 sites; 273 RB; SRS','WMMSE + distributed ADMM','centralized WMMSE-ADMM','SE, experience proxy','protocol + baselines pending'};
    footer='Requirements come from the three original images. The system PDF proposes distributed ADMM; current MATLAB uses one centralized solver. Results do not establish acceptance.';
case 14
    t={'9-D candidate / L03','GA mutation','PSO velocity','SRACOS guidance','cf_evaluate_candidate','old Objective / L15'};
    s={'cf_decode_candidate','cf_search','cf_search','adaptive search','old H and SINR / L01-L14','scheduled sum log2(1+SINR)'};
    footer='Independent matlab/core chain. No call from chasi_run to cf_search; L16 is only an optional legacy candidate adapter, not formal scene evaluation.';
case 15
    t={'SRS quality / C10','Hhat and C / C11-C12','statistical MSE / C17','quadratic / C24-C26','ellipsoid calibration','worst-case + KPI proof'};
    s={'pilot SNR, age, reuse','4x64 H; 4x4 C','implemented branch','implemented in MATLAB','RESEARCH PROPOSAL','NOT IMPLEMENTED'};
    footer='Measured posterior covariance is not a calibrated uncertainty ellipsoid. Robust worst-case constraints, protocol KPI and convergence evidence remain future research.';
end
for i=1:6
    row=ceil(i/3);col=mod(i-1,3)+1;x=17+33*(col-1);y=70-30*(row-1);
    box(a,x,y,27,12,t{i},s{i});
    if col<3 && ~(n==7 && row==2) && ~(n==12 && i==5)
        arr(a,x+13.6,y,x+19.4,y,'',[.12 .37 .63]);
    end
end
if ~ismember(n,[11 12 14])
    arr(a,83,64,83,46,'next',[.12 .37 .63]);
end
if n==7
    arr(a,69.4,40,63.6,40,'z',[.12 .37 .63]);
    arr(a,36.4,40,30.6,40,'dual',[.12 .37 .63]);
    arr(a,17,46.2,17,63.8,'outer update',[.12 .55 .4],'--');
    math(a,51,22,'\mathrm{res}_{\rm pri}=\|x-z\|_F,\quad\mathrm{res}_{\rm dual}=\rho\|z-z^{\rm old}\|_F\quad\mathrm{(C30)}',14);
elseif n==6
    math(a,50,22,'b_{kg}\in\{0,1\},\ \chi_{lkg}\in\{0,1\},\ \nu_g=n_g^{\rm tx}/273',15);
elseif n==9
    math(a,50,22,'R_{{\rm SE},kg}=\log_2\det(I+F_{kk}F_{kk}^{H}R_{I,k}^{-1})',15);
elseif n==12
    line(a,[83 83 17],[64 53 53],'Color',[.12 .37 .63],'LineWidth',1.5);
    arr(a,17,53,17,46,'CSI to SVD',[.12 .37 .63]);
    math(a,50,22,'H^{+}=\varphi\sqrt{\beta^{+}/\beta}H+\sqrt{(1-\varphi^2)\beta^{+}}L_{\rm rx}Z',13);
    line(a,[70 96],[31 31],'Color',[.78 .29 .27],'LineStyle','--');
elseif n==14
    arr(a,83,64,83,46,'old evaluator',[.12 .37 .63]);
    line(a,[9 95],[24 24],'Color',[.68 .10 .10],'LineStyle','--','LineWidth',1.5);
    txt(a,50,20,'Boundary: no program call to formal chasi_run or its matrix solver',12,'bold',[.68 .10 .10],'center');
elseif n==15
    line(a,[68 96],[31 31],'Color',[.68 .10 .10],'LineStyle','--','LineWidth',2);
    txt(a,50,20,'Implemented statistical branch                  |                  proposed robust extension',11,'bold',[.68 .10 .10],'center');
end
foot(a,footer);
end
