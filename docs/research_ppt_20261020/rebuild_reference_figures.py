"""Rework the latest hand-edited deck using the five inspected reference diagrams.

The input is never overwritten. Four editable SVGs and native PowerPoint shapes
are generated from one diagram description. Code evidence: db9d7e3 (MATLAB).
"""
from __future__ import annotations

from hashlib import sha256
from pathlib import Path
from lxml import etree as ET
import re

from pptx import Presentation
from pptx.enum.shapes import MSO_SHAPE
from pptx.util import Inches

ROOT = Path(__file__).parent
SOURCE = ROOT / 'CHASI_研究汇报_图示增强版_六图完善_20261020.pptx'
OUTPUT = ROOT / 'CHASI_研究汇报_执行链重绘_20261020.pptx'
FIG = ROOT / 'execution_chain_figures'
FIG.mkdir(exist_ok=True)
EXPECTED = '42db3ceabe177285981f0b9dd13e54d731651db2028671a0ffbf22139127a9b7'

# Load only the drawing helpers from the previous source; its deck-writing main
# loop is intentionally not executed. This keeps the current PPTX as the base.
helper = (ROOT / 'complete_six_figures.py').read_text(encoding='utf-8')
scope: dict = {'__file__': str(ROOT / 'complete_six_figures.py')}
exec(helper.split('\nfor src_name,expected,out_name in SOURCES:')[0], scope)
scope['FIG'] = FIG
Diagram = scope['Diagram']
clear_body = scope['clear_body']
title = scope['title']
note = scope['note']
BLUE, MID, RED, ORANGE, GREEN = (scope[x] for x in ('BLUE', 'MID', 'RED', 'ORANGE', 'GREEN'))
PALE, VERY = scope['PALE'], scope['VERY']


def arrow(d, x1, y1, x2, y2, color=MID, dash=False):
    d.link(x1, y1, x2, y2, color=color, dash=dash, width=2.4)
    sh = d.slide.shapes[-1]
    ns = '{http://schemas.openxmlformats.org/drawingml/2006/main}'
    ln = sh._element.spPr.find(ns + 'ln')
    if ln is not None:
        ET.SubElement(ln, ns + 'tailEnd', {'type': 'triangle', 'w': 'med', 'len': 'med'})


def card(d, x, y, w, h, head, detail, color=MID, fill=VERY, headsize=17, bodysize=14.5):
    d.box(x, y, w, h, fill, color)
    d.box(x, y, w, .44, color, color, .05)
    d.text(x+.08, y+.025, w-.16, .38, head, headsize, True, '#ffffff', True)
    d.text(x+.13, y+.51, w-.26, h-.55, detail, bodysize)


def research(slide):
    clear_body(slide); title(slide, '研究问题与方法')
    d = Diagram(slide, '00_problem_method', y=1.38, h=5.70)
    d.text(.10,.06,3.15,.42,'茶思验收场景中的困难',19,True,BLUE)
    d.text(4.58,.06,3.16,.42,'当前处理与拟研究方法',19,True,BLUE)
    d.text(9.11,.06,2.95,.42,'用什么检验',19,True,BLUE)
    rows=[
      ('链路 SRS/CSI 质量不同','链路条件误差 C → 接收与预编码','同场景误差对照',MID),
      ('边缘 UE 协同受干扰影响','用户中心服务 + WMMSE 更新','体验低分位与速率',GREEN),
      ('273 RB 与跨组功率耦合','集中式 ADMM 联合投影','功率违规与残差',ORANGE),
    ]
    for i,(a,b,c,col) in enumerate(rows):
        y=.68+i*1.25
        card(d,.10,y,3.58,.93,str(i+1).zfill(2),a,col,VERY,15.5,16)
        arrow(d,3.73,y+.46,4.23,y+.46,col)
        card(d,4.29,y,4.10,.93,'对应机制',b,col,PALE,15.2,16)
        arrow(d,8.44,y+.46,8.93,y+.46,col)
        card(d,8.98,y,3.12,.93,'评价口径',c,col,VERY,15.2,15.5)
    d.box(.16,4.62,11.88,.68,'#fff7eb',ORANGE)
    d.text(.37,4.68,11.44,.54,'当前已接入统计误差与集中求解；椭球最坏情况和 TRP 本地求解仍是新方案。',17,True)
    d.save()
    note(slide,'本页沿困难→方法→可验证量讲。前三列对应原始难题、验收场景与系统方案；协方差 C、集中式 WMMSE–ADMM 已在当前 MATLAB 正式入口，最坏情况椭球和分布式仍待实现。当前正式规模停止条件未通过。来源：茶思三张原图、chasi_generate_scene.m、chasi_matrix_wmmse.m、chasi_evaluate.m，db9d7e3。')


def execution(slide):
    clear_body(slide); title(slide, '真实执行链')
    d = Diagram(slide, '01_real_execution_chain', y=1.35, h=5.86)
    d.text(.12,.02,11.95,.43,'正式 MATLAB 入口：一次场景快照生成 → 固定资源 → 求预编码 → 真信道评价',18,True,BLUE)
    stages=[
      (.12,'① 场景/业务','站址、扇区、UE 位置\n生成服务集与业务到达',BLUE),
      (2.60,'② 真信道','几何增益 + 复高斯\nHᵗʳᵘᵉ：4×64 / 链路',MID),
      (5.08,'③ 等效测量','CSI-RS / SRS 质量与年龄\n输出 Ĥ、C：4×64 / 4×4',GREEN),
      (7.56,'④ 资源规则','关联 b、调度 χ、流数 r\n及资源权重 ν 固定',ORANGE),
      (10.04,'⑤ 优化','Ĥ、C 和固定资源输入\n矩阵 WMMSE–ADMM 求 w',RED),
    ]
    for x,h,b,col in stages: card(d,x,.67,2.18,1.63,h,b,col,VERY,15.4,13.7)
    for i in range(4): arrow(d,stages[i][0]+2.20,1.49,stages[i+1][0]-.04,1.49,stages[i][3])
    d.box(1.68,3.25,9.06,1.09,PALE,MID)
    d.text(1.94,3.36,8.54,.82,'⑥ 用同一预编码 w 在 Hᵗʳᵘᵉ 上重算下行速率 → 业务交付量、体验分位与功率',17,True,BLUE,True)
    arrow(d,11.11,2.36,11.11,2.77,RED)
    arrow(d,11.11,2.77,6.23,2.77,RED)
    arrow(d,6.23,2.77,6.23,3.21,RED)
    d.box(.18,4.68,11.88,.67,'#fff7eb',ORANGE)
    d.text(.39,4.73,11.45,.55,'旧 GA / PSO 搜索链独立；当前正式入口没有把历史候选接到矩阵求解器。',16.2,True)
    d.save()
    note(slide,'沿编号讲真实执行顺序。chasi_run.m 调 chasi_generate_scene.m → chasi_generate_traffic.m → chasi_matrix_wmmse.m → chasi_evaluate.m，当前是原生 MATLAB 求解，不再经旧 Python 桥接。Htrue 参与仿真测量生成及最后评价；非理想优化输入 Ĥ、C。b/χ/r/ν 为规则生成，w 为求解量。历史 GA/PSO 与正式链未接通。db9d7e3。')


def swimlane(slide):
    clear_body(slide); title(slide, 'SRS–CSI 测量与估计')
    d = Diagram(slide, '02_srs_csi_swimlane', y=1.37, h=5.82)
    widths=[3.52,3.75,4.42]; xs=[.10,3.82,7.76]
    labels=[('UE / 链路','测量对象',MID),('TRP / 接收侧','采集与上送',GREEN),('CPU / 协调侧','集中建模与求解',ORANGE)]
    for x,w,(h,b,col) in zip(xs,widths,labels):
        d.box(x,.05,w,4.92,'#f7fafc',PALE,.03)
        d.box(x,.05,w,.50,col,col,.03)
        d.text(x+.09,.10,w-.18,.38,h,18,True,'#ffffff',True)
        d.text(x+.14,.66,w-.28,.34,b,14.5,True,BLUE,True)
    # Actual code simulates observations from Htrue; directional arrows are logical information flow.
    card(d,.34,1.17,2.98,.87,'① UE 测量视角','SRS 上行；CSI-RS 下行观测',MID,VERY,15.6,14)
    arrow(d,3.34,1.61,4.01,1.61,MID)
    card(d,4.03,1.17,3.26,.87,'② 等效观测样本','质量、年龄、跳频选择 P',GREEN,VERY,15.6,14)
    arrow(d,7.32,1.61,7.95,1.61,GREEN)
    card(d,8.02,1.17,3.85,.87,'③ 条件估计','先验 + CSI-RS + SRS → Ĥ、C',ORANGE,VERY,15.6,14)
    card(d,8.02,2.44,3.85,.91,'④ 资源与求解','b、χ、r、ν 固定；用 Ĥ、C 求 w',ORANGE,PALE,15.6,14)
    arrow(d,9.94,2.07,9.94,2.40,ORANGE)
    arrow(d,8.00,2.87,7.34,2.87,ORANGE)
    card(d,4.03,2.44,3.26,.91,'⑤ 下行执行','取得各 TRP 预编码块 wₗ',GREEN,PALE,15.6,14)
    arrow(d,4.01,2.87,3.35,2.87,GREEN)
    card(d,.34,2.44,2.98,.91,'⑥ UE 接收','多 TRP 相干叠加 + 干扰',MID,PALE,15.6,14)
    d.box(.29,3.77,11.48,.78,'#fff7eb',ORANGE)
    d.text(.48,3.84,11.12,.62,'当前是仿真的等效观测与集中数值计算；图中的信息流不代表完整上行协议或 TRP 本地 ADMM。',15.5,True)
    d.save()
    note(slide,'按 UE→TRP→逻辑 CPU→TRP→UE 的泳道读。chasi_generate_scene.m 用真实信道模拟 CSI-RS 与 2 行 SRS 观测，measurement SINR、年龄进入等效噪声，后验估计输出 H_est(4×64) 与每列接收侧协方差 C(4×4)；资源规则和集中求解在单进程数值实现。这里的 UE/TRP/CPU 是物理解释，并非已实现上行波形、信令、前传或分布式 ADMM。db9d7e3。')


def resources(slide):
    clear_body(slide); title(slide, '资源变量与方法分工')
    d=Diagram(slide,'03_resources_boundary',y=1.39,h=5.75)
    d.box(.12,.20,5.70,4.36,'#fff7eb',ORANGE)
    d.text(.37,.36,5.16,.45,'历史慢层搜索：独立评价链',19,True,BLUE)
    d.text(.40,1.00,5.08,1.19,'候选编码：PF 指数、连接数、调度阈值、rank 门限及修复参数等；不是正式场景的直接联合决策变量。',16.1)
    d.text(.40,2.33,5.03,1.24,'GA 用选择、交叉、变异产生候选；PSO 用位置和速度更新候选；历史评价器计算目标并筛选。',16.1)
    d.box(6.43,.20,5.66,4.36,VERY,MID)
    d.text(6.67,.36,5.16,.45,'当前正式快层：集中式求解',19,True,BLUE)
    d.text(6.70,1.00,5.08,1.10,'规则固定：关联 b、调度 χ、流数 r、资源权重 ν；输入 Ĥ 与 C。',16.2)
    d.text(6.70,2.25,5.05,1.18,'优化：含发射幅度的预编码 w；跨资源组共享每 TRP 功率预算 Pₗ。',16.2)
    arrow(d,5.82,2.27,6.37,2.27,ORANGE,True)
    d.text(4.90,2.50,2.21,.38,'尚未接通',15.2,True,ORANGE,True)
    d.box(.23,4.77,11.77,.59,PALE,MID)
    d.text(.39,4.82,11.45,.46,'只有经过接入与统一评价，才能把“慢层候选 → 快层求解 → 反馈”称为当前联合链。',15.8,True)
    d.save()
    note(slide,'正式入口 chasi_run.m 当前从资源规则直接进入矩阵 WMMSE–ADMM。历史 GA/PSO 搜索代码在 matlab/core，候选含连接数、调度阈值、rank 门限及修复参数等，评价器与正式物理层目标不同；不能把独立搜索画成已接通。图中虚线是可能的未来接口。正式功率约束 ΣgνgΣj||w_ljg||²≤P_l。db9d7e3。')


def downlink(slide):
    clear_body(slide); title(slide, '下行通信与评价')
    d=Diagram(slide,'04_downlink_evaluation',y=1.37,h=5.84)
    # Three stacked bands mirror the reference communication/evaluation trace.
    rows=[(.16,.17,'发射与传播',BLUE),(.16,1.73,'UE 接收与速率',GREEN),(.16,3.29,'业务与评价',ORANGE)]
    for x,y,h,col in rows:
        d.box(x,y,2.02,1.18,col,col,.08)
        d.text(x+.11,y+.16,1.80,.83,h,18,True,'#ffffff',True)
    card(d,2.48,.20,2.65,1.10,'wₗkg：预编码','TRP l 发送 UE k 的 r 流',MID,VERY,15.5,14)
    card(d,5.48,.20,2.65,1.10,'Hᵗʳᵘᵉ：真实信道','各服务 TRP 在 UE 相干叠加',MID,VERY,15.5,14)
    card(d,8.50,.20,3.31,1.10,'yₖg：接收信号','有用信号 + 同资源干扰 + 噪声',MID,VERY,15.5,14)
    arrow(d,5.14,.75,5.44,.75,MID);arrow(d,8.14,.75,8.46,.75,MID)
    card(d,2.48,1.75,2.65,1.10,'每 TTI 可传比特','RB 带宽 × SE × 有效时长',GREEN,VERY,15.5,14)
    card(d,5.48,1.75,2.65,1.10,'速率 / SE','真实信道下 log-det 差',GREEN,VERY,15.5,14)
    card(d,8.50,1.75,3.31,1.10,'组成分析','分出有用信号、干扰与噪声',GREEN,VERY,15.5,14)
    arrow(d,10.15,1.34,10.15,1.69,GREEN);arrow(d,8.46,2.30,8.17,2.30,GREEN);arrow(d,5.44,2.30,5.17,2.30,GREEN)
    card(d,2.48,3.31,2.65,1.10,'业务交付量','受流量到达和队列限制',ORANGE,VERY,15.5,14)
    card(d,5.48,3.31,2.65,1.10,'用户体验','有效时窗内交付量 / 时间',ORANGE,VERY,15.5,14)
    card(d,8.50,3.31,3.31,1.10,'最终报告','体验分位、功率、停止状态',ORANGE,VERY,15.5,14)
    arrow(d,3.80,2.89,3.80,3.27,ORANGE);arrow(d,5.14,3.86,5.44,3.86,ORANGE);arrow(d,8.14,3.86,8.46,3.86,ORANGE)
    d.text(.28,4.80,11.60,.40,'同一个 w 用于仿真真实信道评价；非理想优化分支的求解输入仍是 Ĥ、C。',16.4,True,BLUE,True)
    d.save()
    note(slide,'按三条横带讲：发射→传播→接收→物理速率→业务交付→用户体验。w_lkg 是 64×r 含幅度预编码，Htrue_klg 是 4×64 真信道，有用部分对同一 UE 的服务 TRP 相干求和；其余同组 UE 数据是干扰，另加单位噪声。chasi_evaluate.m 的 true_rates 在 Htrue 上计算 logdet 总协方差减干扰协方差；再由 RB 带宽和 TTI 得交付容量，与业务到达/队列共同得到体验 Mbps 和分位。不能将优化目标等同最终验收指标。db9d7e3。')


def nested(slide):
    clear_body(slide); title(slide, 'WMMSE–ADMM 嵌套求解')
    d=Diagram(slide,'05_wmmse_admm_nested',y=1.35,h=5.88)
    d.box(.12,.08,12.00,2.02,'#edf4fb',MID,.05)
    d.text(.41,.23,6.08,.43,'WMMSE 外轮：更新接收与权重',18,True,BLUE)
    outer=[(.31,'可行 w','初始化 / 上轮输出'),(3.08,'F 与 Rʸʸ','Ĥw；误差项 pC'),(5.85,'A、E、Ω','MMSE 接收；逆 MSE 加权'),(8.62,'二次子问题','固定 A、Ω、η，求 w')]
    for x,h,b in outer: card(d,x,.82,2.45,1.02,h,b,MID,VERY,15.4,13.7)
    for i in range(3):arrow(d,outer[i][0]+2.48,1.33,outer[i+1][0]-.04,1.33,MID)
    d.box(.12,2.54,12.00,1.99,'#fff5e9',ORANGE,.05)
    d.text(.32,2.61,3.65,.39,'ADMM 内轮：固定 A、Ω、η',18,True,BLUE)
    inner=[(.34,'x：原变量','CG 解线性系统'),(3.27,'z：可行副本','跨组功率投影'),(6.20,'y：缩放对偶','y ← y+x−z'),(9.13,'残差','原始 / 对偶 / CG')]
    for x,h,b in inner: card(d,x,3.17,2.49,1.01,h,b,ORANGE,VERY,15.3,13.8)
    for i in range(3):arrow(d,inner[i][0]+2.52,3.67,inner[i+1][0]-.04,3.67,ORANGE)
    arrow(d,10.38,4.22,10.38,4.49,ORANGE)
    arrow(d,10.38,4.49,1.54,4.49,ORANGE)
    arrow(d,1.54,4.49,1.54,4.22,ORANGE)
    d.text(4.58,4.23,3.10,.28,'内层未停止 → 再更新 x',13.5,True,ORANGE,True)
    d.box(.22,4.91,11.76,.62,PALE,MID)
    d.text(.43,4.98,11.31,.47,'返回可行 z → 重算外层目标 → 接受 / 回溯 / 停止；未停止则返回 F、Rʸʸ。',15.6,True)
    arrow(d,11.07,1.87,11.07,2.48,MID)
    arrow(d,9.99,4.54,9.99,4.86,ORANGE)
    arrow(d,.29,5.12,.08,5.12,MID)
    arrow(d,.08,5.12,.08,1.39,MID)
    arrow(d,.08,1.39,.27,1.39,MID)
    d.save()
    note(slide,'外层：w 初始可行；F_kjg=Σ_l Hhat_klg w_ljg，相干叠加；Ryy_kg=I+Σ_j F_kjg F_kjg^H+Σ_l p_lg C_klg；A=(Ryy)^−1 Fkk；E 为 MSE 矩阵；Ω=E^-1；η 为用户效用权重。固定 A/Ω/η 构建预编码二次子问题。内层 ADMM 以 CG 更新 x，所有组联合投影 z 到每 TRP 功率预算，y+=x-z，并判原始/对偶/CG 残差；未停止闭合回到 x。返回 z 后外层重新计算目标并进行接受/回溯和停止检查；未停止返回状态更新。当前为集中式单进程求解，正式规模停止条件尚未满足。chasi_matrix_wmmse.m，db9d7e3。')


def admm(slide):
    clear_body(slide); title(slide, 'ADMM 功率约束与停止')
    d=Diagram(slide,'06_admm_detail',y=1.42,h=5.65)
    d.text(.18,.16,11.70,.48,'内轮将二次预编码问题拆为原变量 x 与功率可行副本 z，y 记录一致性误差。',17.2,True,BLUE)
    cards=[(.19,'① CG 更新 x','按 νg Qg 与 ρ/2 构成线性系统',MID),
           (4.23,'② 联合投影 z','Σg νg Σj ‖wₗjg‖² ≤ Pₗ',GREEN),
           (8.27,'③ 对偶与残差','y←y+x−z；检查残差',ORANGE)]
    for x,h,b,col in cards:card(d,x,.95,3.74,1.35,h,b,col,VERY,16.8,16)
    arrow(d,3.96,1.62,4.18,1.62,MID);arrow(d,8.00,1.62,8.22,1.62,GREEN)
    d.box(.22,2.79,11.76,1.17,PALE,MID)
    d.text(.44,2.88,11.30,.97,'为什么跨组投影？一个 TRP 在所有资源组共用同一预算 Pₗ；逐组独立限制会改变原问题。',17.2,True)
    d.box(.22,4.35,11.76,.64,'#fff7eb',ORANGE)
    d.text(.44,4.40,11.30,.51,'功率可行 ≠ 数值对拍通过 ≠ ADMM 收敛 ≠ WMMSE 外层停止。',17,True)
    d.save()
    note(slide,'源码 chasi_matrix_wmmse.m ADMM 段。每组 x 的正规方程含 νg Qg + ρ/2 I，与增广目标定义一致。z 是跨全部资源组的联合投影，y 为缩放对偶。检查原始/对偶残差及 CG 精度，ρ 可自适应。返回功率可行的 z 供外层接受/回溯。当前正式规模未满足算法停止条件。db9d7e3。')


def robust(slide):
    clear_body(slide); title(slide, '非均匀误差作用机制')
    d=Diagram(slide,'07_nonuniform_mechanism',y=1.40,h=5.66)
    steps=[(.18,'测量质量与年龄','SINR、CSI 年龄、SRS 行选择',MID),
           (3.22,'条件协方差 C','每链路、资源组的 4×4 统计误差',GREEN),
           (6.26,'接收统计','Rʸʸ 增加 Σₗ pₗg Cₖₗg',ORANGE),
           (9.30,'预编码与评价','二次项 Q(C) → w → 真信道体验',RED)]
    for x,h,b,col in steps:card(d,x,.55,2.68,1.54,h,b,col,VERY,15.8,14.5)
    for i in range(3):arrow(d,steps[i][0]+2.71,1.31,steps[i+1][0]-.04,1.31,steps[i][3])
    d.box(.21,2.57,5.61,1.31,PALE,MID)
    d.text(.42,2.67,5.17,1.08,'当前统计模型：先验、CSI-RS 与 SRS 观测的精度相加；未测 SRS 的组只用其余观测。',16.2)
    d.box(6.34,2.57,5.64,1.31,'#fff7eb',ORANGE)
    d.text(6.57,2.67,5.16,1.08,'待研究：校准椭球、最坏情况内层；尚无可据以宣称体验提升的公平对照。',16.2)
    d.text(.30,4.42,11.50,.52,'公平对照需固定拓扑、业务、预算与初值，仅改变名义／统一／非均匀误差模型。',16.0,True,BLUE,True)
    d.save()
    note(slide,'chasi_generate_scene.m 的 awgn_independent 分支按先验 βRrx、CSI-RS、两行 SRS 等效观测形成每发射列接收侧 4×4 条件协方差 C；测量质量与年龄改变等效噪声。chasi_matrix_wmmse.m 中 C 进入 Ryy=I+ΣFF^H+Σ_l p_lg C_klg，也进入固定接收器后的二次算子，进而改变 w。另有 pilot_reuse_gaussian 分支，不能笼统称同一个后验公式适用于所有分支。最坏情况椭球未接入，效果待验证。db9d7e3。')


def remove_dangling(slide):
    for sh in slide.shapes:
        if not sh.has_text_frame: continue
        for p in sh.text_frame.paragraphs:
            for r in p.runs:
                r.text=re.sub(r'\s*\[(?:\d+)(?:\s*,\s*\d+)*\]','',r.text)


def main():
    assert sha256(SOURCE.read_bytes()).hexdigest()==EXPECTED, 'The hand-edited source changed; inspect before rerunning.'
    p=Presentation(SOURCE)
    assert len(p.slides)==14
    untouched={i:p.slides[i].shapes._spTree.xml for i in (0,1,3,11,12,13)}
    research(p.slides[2]);execution(p.slides[4]);swimlane(p.slides[5]);resources(p.slides[6]);downlink(p.slides[7]);nested(p.slides[8]);admm(p.slides[9]);robust(p.slides[10])
    for i,s in enumerate(p.slides):
        if i not in untouched:remove_dangling(s)
    assert untouched=={i:p.slides[i].shapes._spTree.xml for i in untouched}
    p.save(OUTPUT)
    print(f'{OUTPUT}\n14 slides\nSHA256 {sha256(OUTPUT.read_bytes()).hexdigest()}')


if __name__=='__main__': main()
