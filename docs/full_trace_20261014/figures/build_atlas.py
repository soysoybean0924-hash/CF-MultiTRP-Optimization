"""Render the audit's nine editable SVG diagrams and PNG previews.

Illustrative layout coordinates are not simulated radio coordinates. The
selected CF links in figure 01 are checked against the saved scene manifest.
No optimizer or experiment is executed by this file.
"""
from pathlib import Path
from html import escape
from math import atan2, cos, sin, dist
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
WIDTH, HEIGHT = 1900, 1080
FONT = 'C:/Windows/Fonts/msyh.ttc'
F = {n: ImageFont.truetype(FONT, n) for n in (18, 20, 23, 27, 37)}
INK, BLUE, GREEN, RED, PURPLE, GOLD = '#203344','#28649b','#13826e','#c34d40','#7353a5','#ad681e'
PALETTE = {'data':BLUE,'service':GREEN,'interference':RED,'control':PURPLE,'model':GOLD}


def n(x,y,title,detail): return (x,y,title,detail)
def e(a,b,label,kind='data',at=None): return (a,b,label,kind,at)


# Each arrow has an ID; see ../11_图集与箭头索引.md for formula, axes, source and next consumer.
FIGS = [
('01_cf_saved_topology','CF 保存场景局部拓扑：资源组 3',
 'R: UE0 serve={TRP0,TRP1}; UE23 serve={TRP0,TRP2}; 三 TRP 同址不同扇区。只显示两个 UE。',
 {'cpu':n(760,150,'集中计算位置','无 CPU/前传实体'),
  't0':n(130,335,'TRP 0','(450,450)m；发 UE0/23'), 't1':n(130,580,'TRP 1','(450,450)m；发 UE0'),
  't2':n(130,810,'TRP 2','(450,450)m；发 UE23'),
  'u0':n(1370,470,'UE 0','(509.016,546.121)m'), 'u23':n(1370,790,'UE 23','(500.576,308.927)m')},
 [e('cpu','t0','F05 cfg/serve；无前传包','control',(395,250)),
  e('t0','u0','F03 H00 V00 s0：有用','service',(560,375)),
  e('t1','u0','F03 H01 V10 s0：有用','service',(825,635)),
  e('t2','u0','F03 H02 V2,23 s23：干扰','interference',(965,820)),
  e('t0','u23','F03 H23,0 V0,23 s23：服务','service',(515,910)),
  e('u0','t0','F06 两行 SRS 观测模型','model',(970,255))],
 'F01 x_l=sum_i V_li s_i；F02 y_k=sum_i(sum_l H_kl V_li)s_i+n；F04 s_hat=U^H y [solver.py:75,94]'),

('02_mathworks_topology','MathWorks 连接拓扑：示意，非随机坐标',
 'O: 当前页脚本 20 AP/4 UE，每 UE 最近 2 AP；本图仅选 3 AP/2 UE 解释重叠服务。',
 {'cpu':n(760,140,'CPU','计算/调度；非无线发射'),
  'a':n(120,430,'AP A','示意服务 UE k'), 'b':n(760,430,'AP B','示意共享 AP'),
  'c':n(1400,430,'AP C','示意服务 UE j'),
  'uk':n(440,800,'UE k','服务集 {A,B}'), 'uj':n(1080,800,'UE j','服务集 {B,C}')},
 [e('cpu','a','M01 前传/控制','control',(340,280)),e('cpu','b','M03 W/波形或 TB','control',(900,320)),
  e('cpu','c','M01 前传/控制','control',(1370,280)),e('a','uk','M04 PDSCH 服务','service',(270,650)),
  e('b','uk','M04 PDSCH 服务','service',(720,640)),e('b','uj','M04 PDSCH 服务','service',(1050,660)),
  e('c','uj','M04 PDSCH 服务','service',(1480,650)),e('c','uk','M05 非服务干扰（理论）','interference',(1110,770))],
 'O01 M_k=nearest2(d_mk) [页面:128-149]；O02 Hhat_k=stack_m H_mk；O05 X_m=sum_{k:m in M_k}X_mk'),

('03_mathworks_central','MathWorks 集中式：UE / AP / CPU',
 'O: 当前页 49-78；CPU 计算并应用 DL W；AP 中继信道参数和波形。上/下行分开。',
 {'ue_srs':n(100,245,'UE：SRS','已配置后探测'), 'ap_srs':n(760,245,'AP：接收 SRS','中继 path gains/filters'),
  'cpu_csi':n(1420,245,'CPU：CSI 与 W','O02/O03 ZF'),
  'ue_dl':n(100,565,'UE：PDSCH','下行接收'), 'ap_dl':n(760,565,'AP：中继','O05 X_m=sum_k X_mk'),
  'cpu_dl':n(1420,565,'CPU：编码/预编码','O04 生成 X_mk'),
  'ue_ul':n(100,840,'UE：PUSCH','UL TPMI'), 'ap_ul':n(760,840,'AP：中继','收到的上行波形'),
  'cpu_ul':n(1420,840,'CPU：UL 检测','CP/FFT/LS/MMSE/LLR')},
 [e('ue_srs','ap_srs','M02 SRS 无线','model',(475,195)),e('ap_srs','cpu_csi','M06 path gains/filters','control',(1115,195)),
  e('cpu_dl','ap_dl','M07 已预编码波形','control',(1115,515)),e('ap_dl','ue_dl','M08 PDSCH','service',(520,515)),
  e('ue_ul','ap_ul','M09 PUSCH + TPMI','model',(465,785)),e('ap_ul','cpu_ul','M10 接收波形','control',(1120,785))],
 'O02 Hhat_k=stack_m H_mk^ul；O03 W_k=[(Hhat^H Hhat)^-1 Hhat^H]^H；O05 X_m=sum_k X_mk'),

('04_mathworks_distributed','MathWorks 分布式：UE / AP / CPU',
 'O: 当前页 49-78；CPU 仍算 W，AP 应用 W_mk 并上送 UL LLR；不是分布式 ADMM。',
 {'ue_srs':n(100,245,'UE：SRS','无线探测'), 'ap_srs':n(760,245,'AP：本地 CSI','H_mk^ul'),
  'cpu_csi':n(1420,245,'CPU：拼接并算 W','O02/O03'),
  'ue_dl':n(100,565,'UE：PDSCH','下行接收'), 'ap_dl':n(760,565,'AP：应用 W_mk','O04/O05'),
  'cpu_dl':n(1420,565,'CPU：编码 TB','下发 TB + W_mk'),
  'ue_ul':n(100,840,'UE：PUSCH','UL TPMI'), 'ap_ul':n(760,840,'AP：均衡/LLR','本地 UL PHY'),
  'cpu_ul':n(1420,840,'CPU：LLR 合并','O06 最终 TB 检测')},
 [e('ue_srs','ap_srs','M02 SRS 无线','model',(475,195)),e('ap_srs','cpu_csi','M11 局部 CSI','control',(1115,195)),
  e('cpu_dl','ap_dl','M12 TB + W_mk','control',(1115,515)),e('ap_dl','ue_dl','M08 PDSCH','service',(520,515)),
  e('ue_ul','ap_ul','M09 PUSCH + TPMI','model',(465,785)),e('ap_ul','cpu_ul','M13 LLR_mk','control',(1120,785))],
 'O04 W_k=stack_m W_mk；O05 X_m=sum_k X_mk；O06 LLR_k=sum_m LLR_mk；W 在 CPU 计算，AP 应用'),

('05_cf_actual_swimlane','CF 当前实际代码：UE / TRP / 集中进程',
 'S/M: 无真实 CPU/TRP/UE 消息对象；无线箭头为协方差模型等效，不是运行中的波形包。',
 {'ue_srs':n(100,245,'UE：无 SRS 波形','2 UL Tx→4 DL Rx 行假设'),
  'trp_obs':n(760,245,'TRP：无接收对象','H_true→yc/ys 数组'),
  'proc_csi':n(1420,245,'集中进程：场景/CSI','H_est,C,serve'),
  'ue_dl':n(100,565,'UE：等效接收','F02 y=sum Hx+n'),
  'trp_dl':n(760,565,'TRP：等效发射','F01 x=sum V s'),
  'proc_v':n(1420,565,'集中进程：求解 V','solver.solve / 旧 cf_eval'),
  'metric':n(760,840,'同进程：最终评价','H_true,V→SE/体验')},
 [e('ue_srs','trp_obs','F06 SRS 观测模型','model',(475,195)),
  e('trp_obs','proc_csi','F06 H_est,C 数组','control',(1115,195)),
  e('proc_csi','proc_v','F05 固定 serve/rank','control',(1490,420)),
  e('proc_v','trp_dl','F12 V；无前传包','control',(1115,515)),
  e('trp_dl','ue_dl','F01/F02 等效 DL','service',(520,515)),
  e('ue_dl','metric','F13 H_true logdet','model',(505,785))],
 '无下行调制/OFDM/ACK RLC；旧 MATLAB W 与 CHASI V 是两条入口；图中 CPU 列只表示一个进程'),

('06_w_v_interface','旧 W、新 V、官方 W_k：接口与去向',
 'S/O: 实线是已执行传递，红色虚线表示未发现的默认转换/源码继承。',
 {'old_h':n(120,250,'旧 H_est,Q','[Nr,M,R,U,G]'), 'old_w':n(780,250,'旧 W 波束','[M,S,R,U,G]；含功率'),
  'old_o':n(1440,250,'旧指标','b/p/SLINR/J_true'),
  'new_h':n(120,580,'CHASI H_est,C','[K,L,4,64]'), 'new_v':n(780,580,'新 V 预编码','[L,K,64,d]；自由复矩阵'),
  'new_o':n(1440,580,'新指标','U/E/W_mse 与 KPI'),
  'mw':n(780,845,'官方 W_k','CPU ZF，按 AP 分块')},
 [e('old_h','old_w','L05 MRT样式→旧内层'),e('old_w','old_o','L06 p=||W||²'),
  e('new_h','new_v','F07 SVD→F12 ADMM'),e('new_v','new_o','F08-F13 HV→KPI'),
  e('old_w','new_v','X01 默认无 W→V 导入','interference',(780,470)),
  e('mw','new_v','X02 无已证源码继承','interference',(800,790))],
 '旧 p=sum_s||W||²；新 P_l=sum_g a_g||V_gl||²；新 W_mse=E^-1；参考论文 v_k=标量接收器'),

('07_wmmse_admm','矩阵 WMMSE 外轮与集中 ADMM 内轮',
 'S: solver.py:94-124,136-276,291-441；服务/rank 固定；返回可行 Z 后回溯。',
 {'v':n(100,280,'当前 V','serve 外 0；P_l<=20W'),
  'uw':n(550,280,'U/E/W + PF omega','F08-F10'), 'qb':n(1000,280,'M/B/D/Q 算子','F11 固定 U/W'),
  'cg':n(1450,280,'CG 原变量 X','F12 线性系统'),
  'proj':n(1450,660,'投影副本 Z','跨组 TRP 功率'),
  'dual':n(850,660,'缩放对偶 Y','Y+=X-Z；rho 调整'),
  'accept':n(160,660,'回溯接受 V','目标/变化/ADMM 门槛')},
 [e('v','uw','F08 Ryy→U/E/W'),e('uw','qb','F11 U/W/omega→Q/B'),
  e('qb','cg','F12 (aQ+rhoI/2)X=...'),e('cg','proj','F12 Z=Proj(X+Y)'),
  e('proj','dual','F12 Y+=X-Z'),e('dual','accept','F12 返回 Z，不是 X'),
  e('accept','v','F12 V_old+alpha(Z-V_old)','control',(170,505))],
 'ADMM: primal+dual+CG；外轮: 目标变化+V变化+最近 ADMM 达标；局部停止不证明全局最优'),

('08_metric_flow','从最终 V 到物理 SE 和体验代理',
 'S: solver.rates/evaluate/protocol_contract；无 ACKed RLC、BLER 或正式验收判定。',
 {'v':n(100,300,'最终 V_g','[L,K_g,64,d]'), 'h':n(100,610,'H_true','[K_g,L,4,64]'),
  'g':n(550,300,'G_ki=sum_l H_kl V_li','[4,d] 相干和'),
  'se':n(1000,300,'真组 SE / UE SE','logdet 差；sum_g a_g'),
  'traffic':n(1000,610,'busy/tail/terminal','[N,TTI] 业务样本'),
  'exp':n(1450,300,'体验率/分位数','volume/valid_time'),
  'out':n(1450,610,'summary/图','run.py + 独立绘图')},
 [e('v','g','F13 V'),e('h','g','F13 H_true'),e('g','se','F13 logdet(all)-logdet(int)'),
  e('se','exp','F13 RB*12*30kHz*TTI'),e('traffic','exp','F13 有效样本/需求门控'),
  e('exp','out','F13 JSON/CSV/图')],
 'r_true=log2det(I+sum_i G_kiG_ki^H)-log2det(I+sum_{i!=k}G_kiG_ki^H)；capacity bit!=ACKed RLC'),

('09_callgraph','真实入口与调用边界',
 'S: 旧 MATLAB、MATLAB→Python 桥、条件原生 PF 并存；它们不是连续替换的单条链。',
 {'old_e':n(100,270,'旧 ablation 入口','run_controlled_outer_ablation'),
  'old_c':n(650,270,'cf_search→cf_eval','旧 b/p/r/W，J_true'),
  'old_o':n(1420,270,'旧结果','CSV/MAT/图'),
  'bridge':n(100,610,'CHASI MATLAB 入口','run_chasi_formal.m'),
  'py':n(650,610,'Python run/solve/eval','H_est,C→V'),
  'py_o':n(1420,610,'CHASI 结果','summary/NPZ/MAT'),
  'native':n(650,850,'条件原生矩阵 PF','cf_chasi_native_resources')},
 [e('old_e','old_c','L17 cfg/scenario/x'),e('old_c','old_o','L15 result/History'),
  e('bridge','py','B01 CLI 标量，非 H/W'),e('py','py_o','B02 V/U/W+metrics'),
  e('old_c','native','B03 chasiNative.enabled','control',(690,740)),
  e('native','py','X03 未替换 Python 正式入口','interference',(1080,820))],
 '旧 objective=J_true；原生条件 objective=估计 PF；Python 分支目标各异；保存结果须按入口和 branch 分辨'),
]


def point(a,b):
    ax,ay=a[0]+160,a[1]+54; bx,by=b[0]+160,b[1]+54
    if abs(bx-ax)>abs(by-ay):
        return (a[0]+(320 if bx>ax else 0),ay),(b[0] if bx>ax else b[0]+320,by)
    return (ax,a[1]+(108 if by>ay else 0)),(bx,b[1] if by>ay else b[1]+108)


def draw(fig):
    name,title,note,nodes,edges,formula=fig
    parts=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" viewBox="0 0 {WIDTH} {HEIGHT}">',
           f'<rect width="{WIDTH}" height="{HEIGHT}" fill="#f8fafc"/>',
           f'<text x="50" y="68" font-family="Microsoft YaHei" font-size="37" fill="{INK}">{escape(title)}</text>',
           f'<text x="50" y="110" font-family="Microsoft YaHei" font-size="19" fill="{BLUE}">{escape(note)}</text>']
    im=Image.new('RGB',(WIDTH,HEIGHT),'#f8fafc');d=ImageDraw.Draw(im)
    d.text((50,27),title,font=F[37],fill=INK); d.text((50,83),note,font=F[18],fill=BLUE)
    for a,b,label,kind,at in edges:
        p,q=point(nodes[a],nodes[b]); color=PALETTE[kind]
        parts.append(f'<line x1="{p[0]}" y1="{p[1]}" x2="{q[0]}" y2="{q[1]}" stroke="{color}" stroke-width="4" marker-end="url(#arr)"'+(' stroke-dasharray="11 8"' if kind in ('interference','model') else '')+'/>')
        d.line((*p,*q),fill=color,width=4)
        angle=atan2(q[1]-p[1],q[0]-p[0]);t=(q[0],q[1]);d.polygon([t,(t[0]-17*cos(angle-.45),t[1]-17*sin(angle-.45)),(t[0]-17*cos(angle+.45),t[1]-17*sin(angle+.45))],fill=color)
    for key,(x,y,title2,detail) in nodes.items():
        parts.append(f'<rect x="{x}" y="{y}" width="320" height="108" rx="15" fill="white" stroke="{BLUE}" stroke-width="3"/>')
        parts.append(f'<text x="{x+14}" y="{y+39}" font-family="Microsoft YaHei" font-size="25" fill="{INK}">{escape(title2)}</text>')
        parts.append(f'<text x="{x+14}" y="{y+78}" font-family="Microsoft YaHei" font-size="19" fill="{BLUE}">{escape(detail)}</text>')
        d.rounded_rectangle((x,y,x+320,y+108),radius=15,fill='white',outline=BLUE,width=3)
        d.text((x+14,y+9),title2,font=F[23],fill=INK);d.text((x+14,y+57),detail,font=F[18],fill=BLUE)
    for a,b,label,kind,at in edges:
        p,q=point(nodes[a],nodes[b]);x,y=at or ((p[0]+q[0])/2,min(nodes[a][1],nodes[b][1])-30)
        parts.append(f'<rect x="{x-5}" y="{y-23}" width="{max(200,len(label)*12)}" height="30" fill="white" fill-opacity="0.95"/>')
        parts.append(f'<text x="{x}" y="{y}" font-family="Microsoft YaHei" font-size="18" fill="{PALETTE[kind]}">{escape(label)}</text>')
        bb=d.textbbox((x,y-21),label,font=F[18]);d.rectangle((bb[0]-5,bb[1]-3,bb[2]+5,bb[3]+3),fill='white');d.text((x,y-21),label,font=F[18],fill=PALETTE[kind])
    parts.append('<defs><marker id="arr" markerWidth="12" markerHeight="12" refX="10" refY="6" orient="auto"><path d="M1,1 L10,6 L1,11" fill="none" stroke="#334b5e" stroke-width="2"/></marker></defs>')
    parts.append(f'<rect x="45" y="982" width="1810" height="68" rx="10" fill="#e6edf6"/><text x="60" y="1024" font-family="Microsoft YaHei" font-size="19" fill="{INK}">{escape(formula)}</text></svg>')
    d.rounded_rectangle((45,982,1855,1050),radius=10,fill='#e6edf6');d.text((60,1004),formula,font=F[18],fill=INK)
    (ROOT/f'{name}.svg').write_text('\n'.join(parts),encoding='utf-8')
    im.save(ROOT/f'{name}.png',optimize=True)


if __name__=='__main__':
    for fig in FIGS:
        draw(fig);print(fig[0])
