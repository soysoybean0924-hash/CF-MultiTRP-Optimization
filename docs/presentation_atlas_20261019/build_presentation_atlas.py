"""Build six 16:9 research briefing figures from source-traced facts.

Static slide 06 reads the verified Archify candidate for its execution graph.
This script draws no solver output and runs no experiments.
"""
from __future__ import annotations

import json
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch, Circle, Wedge
from matplotlib.font_manager import FontProperties

ROOT = Path(__file__).resolve().parent
ARCH = ROOT / "archify" / "architecture-code-chain-20261019" / "candidate.json"
FIG = ROOT / "figures"
FIG.mkdir(exist_ok=True)
FONT = FontProperties(family="Microsoft YaHei")
plt.rcParams.update({
    "font.family": "Microsoft YaHei",
    "svg.fonttype": "none",
    "pdf.fonttype": 42,
    "axes.unicode_minus": False,
})

RED = "#A81E22"
NAVY = "#17324D"
BLUE = "#246C9C"
TEAL = "#117A70"
AMBER = "#B97911"
PURPLE = "#7154A0"
MUTED = "#53677A"
PALE = "#F5F8FA"
LINE = "#D8E1E8"
GOOD = "#E6F4F0"
WARN = "#FFF2DA"
PLAN = "#F1ECF8"
WHITE = "#FFFFFF"

def txt(ax, x, y, s, size=15, color=NAVY, weight="normal", ha="left", va="center", **kw):
    return ax.text(x, y, s, fontsize=size, color=color, fontproperties=FONT,
                   fontweight=weight, ha=ha, va=va, zorder=5, **kw)

def rect(ax, x, y, w, h, fc=WHITE, ec=LINE, lw=1.2, r=.14, z=1):
    p = FancyBboxPatch((x,y),w,h,boxstyle=f"round,pad=0,rounding_size={r}",
                       facecolor=fc,edgecolor=ec,linewidth=lw,zorder=z)
    ax.add_patch(p)
    return p

def arrow(ax, x1,y1,x2,y2, color=BLUE, lw=2.2, style="-|>", ls="-", rad=0):
    p=FancyArrowPatch((x1,y1),(x2,y2),arrowstyle=style,mutation_scale=16,
                      color=color,linewidth=lw,linestyle=ls,
                      connectionstyle=f"arc3,rad={rad}",zorder=4)
    ax.add_patch(p)
    return p

def chip(ax,x,y,w,label,fc=GOOD,tc=TEAL):
    rect(ax,x,y,w,.35,fc=fc,ec="none",r=.16)
    txt(ax,x+w/2,y+.175,label,10.5,tc,"bold",ha="center")

def base(num,title,subtitle,claim):
    fig,ax=plt.subplots(figsize=(16,9),dpi=200)
    fig.patch.set_facecolor(WHITE); ax.set_facecolor(WHITE)
    ax.set_xlim(0,16);ax.set_ylim(0,9);ax.axis("off")
    txt(ax,.6,8.53,f"{num:02d}  {title}",29,RED,"bold")
    txt(ax,.62,8.05,subtitle,13,MUTED)
    ax.plot([.6,15.4],[7.82,7.82],color=LINE,lw=1.3)
    rect(ax,.58,.27,14.84,.56,fc=PALE,ec="none",r=.12)
    txt(ax,.83,.55,claim,14,NAVY,"bold")
    txt(ax,15.23,.55,f"{num:02d} / 06",10,MUTED,ha="right")
    return fig,ax

def save(fig,stem,pdf):
    fig.savefig(FIG/f"{stem}.svg",bbox_inches=None,facecolor=WHITE)
    fig.savefig(FIG/f"{stem}.png",dpi=220,bbox_inches=None,facecolor=WHITE)
    pdf.savefig(fig,facecolor=WHITE)
    plt.close(fig)

def s01(pdf):
    fig,ax=base(1,"研究框架｜把测量不准转化为可检验的资源优化问题",
       "茶思原始任务 → 正式场景 → 方法分工 → 非均匀鲁棒机制 → 协议评价",
       "核心判断：场景与指标来自原始验收材料；方法方案和当前实现的边界需要分别陈述。")
    # Distinct visual bands, not a row of generic boxes.
    for x,n,lab,col in [(0.65,"01","困难",RED),(3.68,"02","目标",AMBER),
                        (7.25,"03","方法",BLUE),(10.70,"04","创新",PURPLE),
                        (13.43,"05","验证",TEAL)]:
        txt(ax,x,7.32,n,13,col,"bold");txt(ax,x+.48,7.32,lab,18,NAVY,"bold")
    rect(ax,.64,2.05,2.74,4.76,fc="#FFF5F3",ec="#E9C4C1")
    txt(ax,.92,6.38,"非理想 SRS / CSI",18,RED,"bold")
    for j,(a,b) in enumerate([("链路质量不同","协同权重难可信"),
                              ("边缘 UE 易受扰","体验与能耗冲突"),
                              ("21 TRP、海量变量","低时延实现困难")]):
        y=5.56-j*1.1;txt(ax,.95,y,a,15,NAVY,"bold");txt(ax,.95,y-.36,b,12,MUTED)
    arrow(ax,3.43,4.42,3.78,4.42)
    rect(ax,3.79,2.05,3.05,4.76,fc=WARN,ec="#E9D7AA")
    txt(ax,4.1,6.35,"验收目标 ≠ 研究困难",17,AMBER,"bold")
    for y,a,b in [(5.56,"边缘体验","50% PRB 下达到理想参考 80%"),
                  (4.35,"平均体验","损失 < 10%（原图目标）"),
                  (3.15,"辐射功率","相对独立功控降低 > 30%")]:
        txt(ax,4.12,y,a,15,NAVY,"bold");txt(ax,4.12,y-.37,b,11.5,MUTED)
    arrow(ax,6.88,4.42,7.22,4.42)
    rect(ax,7.24,4.0,3.05,2.8,fc="#EAF3F9",ec="#C5DCEB")
    txt(ax,7.54,6.3,"快层｜WMMSE",17,BLUE,"bold")
    txt(ax,7.54,5.7,"ADMM 优化复矩阵 w",12.5,NAVY)
    txt(ax,7.54,5.25,"当前集中式实现",12.5,BLUE,"bold")
    rect(ax,7.24,2.05,3.05,1.68,fc=PALE,ec=LINE)
    txt(ax,7.54,3.34,"慢层｜GA / PSO",15,NAVY,"bold")
    txt(ax,7.54,2.92,"SRACOS；正式入口未调用",11.5,MUTED)
    chip(ax,7.53,2.30,2.32,"独立链 / 拟议接入",PLAN,PURPLE)
    arrow(ax,10.33,5.34,10.69,5.34)
    rect(ax,10.71,2.05,2.35,4.76,fc=PLAN,ec="#D8CCE8")
    txt(ax,10.99,6.38,"质量感知",18,PURPLE,"bold")
    for y,a,b in [(5.55,"SRS 质量","决定链路可信度"),
                  (4.43,"非均匀误差","C_stat 进入计算"),
                  (3.31,"鲁棒对照","椭球 / 最坏情形待研")]:
        txt(ax,10.99,y,a,14,NAVY,"bold");txt(ax,10.99,y-.34,b,11.5,MUTED)
    arrow(ax,13.08,4.42,13.41,4.42)
    rect(ax,13.43,2.05,1.98,4.76,fc=GOOD,ec="#BBDCD5")
    txt(ax,13.69,6.38,"验证",18,TEAL,"bold")
    for y,a,b in [(5.52,"协议 5%","边缘体验"),
                  (4.38,"平均体验","与功率"),
                  (3.23,"规模 / 时延","收敛 / 对拍")]:
        txt(ax,13.68,y,a,13.5,NAVY,"bold");txt(ax,13.68,y-.32,b,11,MUTED)
    chip(ax,13.68,2.35,1.45,"尚未验收",WARN,AMBER)
    save(fig,"01_research_framework",pdf)

def s02(pdf):
    fig,ax=base(2,"茶思场景｜同一用户的协同链路，测量可信度不同",
      "物理链路示意；TRP 和 UE 位置仅用于解释，不代表配置生成的实际坐标或面积均匀性",
      "关键机制：较弱或较旧的 SRS 观测会改变 CSI 误差，从而影响协同权重的可信程度。")
    rect(ax,.65,1.48,10.13,5.95,fc="#F8FBFD",ec=LINE)
    # Soft coverage circles and distinct station sectors
    sites=[(2.05,5.83),(5.02,6.07),(8.05,5.61),(2.36,3.12),(7.94,2.83)]
    for i,(x,y) in enumerate(sites):
        ax.add_patch(Circle((x,y),.69,fc="#DCECF4",ec="none",alpha=.75,zorder=1))
        ax.add_patch(Circle((x,y),.11,fc=NAVY,ec=WHITE,lw=1,zorder=4))
        for ang in (0,120,240):
            ax.add_patch(Wedge((x,y),.38,ang-21,ang+21,width=.18,fc=BLUE,ec=WHITE,lw=.7,zorder=3))
        txt(ax,x,y+.86,f"站点 {i+1}" if i<3 else "站点（示意）",10.5,MUTED,ha="center")
    ux,uy=5.30,3.55
    ax.add_patch(Circle((ux,uy),.22,fc=RED,ec=WHITE,lw=2,zorder=6))
    txt(ax,ux,uy-.48,"边缘 UE k",16,RED,"bold",ha="center")
    arrow(ax,5.02,5.71,ux,uy+.32,TEAL,3.0)
    arrow(ax,7.68,5.42,ux+.23,uy+.15,TEAL,3.0)
    txt(ax,5.68,5.10,"下行相干叠加",12,TEAL,"bold")
    arrow(ax,ux+.33,uy+.31,7.86,5.56,AMBER,2.0,ls="--")
    txt(ax,6.55,4.84,"SRS：质量低 / CSI 老",11.5,AMBER,"bold",rotation=30)
    arrow(ax,ux+.11,uy+.24,5.03,5.66,BLUE,2.0,ls="--")
    txt(ax,5.26,4.60,"SRS：质量高",11.5,BLUE,"bold")
    txt(ax,1.04,2.09,"绿实线 = 下行协同     蓝/橙虚线 = 上行 SRS 测量",12,MUTED)
    rect(ax,11.10,5.12,4.3,2.3,fc=WARN,ec="#E7D5AC")
    txt(ax,11.43,6.93,"正式场景（原始材料）",18,AMBER,"bold")
    txt(ax,11.43,6.39,"7 站 × 3 小区 = 21 TRP",15,NAVY,"bold")
    txt(ax,11.43,5.91,"10–20 UE/小区；64 TRX；UE 4 Rx",13,NAVY)
    txt(ax,11.43,5.47,"273 RB；30% 负载；3 km/h",13,NAVY)
    rect(ax,11.10,1.48,4.3,3.32,fc=WHITE,ec=LINE)
    txt(ax,11.43,4.37,"测量与资源的时间结构",17,BLUE,"bold")
    txt(ax,11.43,3.86,"17 次 SRS 跳频覆盖 273 RB",13,NAVY)
    txt(ax,11.43,3.44,"前 16 跳 × 16 RB；末跳 17 RB",12,MUTED)
    txt(ax,11.43,3.02,"20 ms/跳 → 340 ms 全带周期",13,NAVY)
    txt(ax,11.43,2.60,"CSI-RS 40 TTI；PRB 30–50%",12,MUTED)
    chip(ax,11.43,1.88,3.02,"当前传播：surrogate",WARN,AMBER)
    save(fig,"02_scene_cooperation",pdf)

def s03(pdf):
    fig,ax=base(3,"方法分工｜历史搜索与正式求解运行在两条链上",
      "慢尺度候选探索与快尺度复矩阵赋形是研究分层设想；当前正式入口只调用下方链路",
      "实线表示已发生的调用；紫色虚线只表示未来接口设想，不能解读为当前联合闭环。")
    txt(ax,.78,7.28,"慢尺度 / 历史实现",17,PURPLE,"bold")
    rect(ax,.72,4.77,14.56,2.12,fc="#F7F3FA",ec="#DCCFE9")
    for x,w,h,t in [(1.02,2.73,"9 维候选配置","cf_decode_candidate"),
                    (4.44,2.68,"GA / PSO","PGSAO / SRACOS"),
                    (7.82,3.25,"旧候选评价器","cf_evaluate_candidate"),
                    (11.88,2.75,"旧目标 J_old","历史搜索结果")]:
        rect(ax,x,5.32,w,1.05,fc=WHITE,ec="#C7B5DC")
        txt(ax,x+.18,5.99,h,15,NAVY,"bold");txt(ax,x+.18,5.59,t,10.5,MUTED)
    for a,b in [(3.76,4.42),(7.13,7.8),(11.1,11.85)]:
        arrow(ax,a,5.84,b,5.84,PURPLE,2.1)
    txt(ax,.78,4.23,"快尺度 / 当前正式入口",17,BLUE,"bold")
    rect(ax,.72,1.54,14.56,2.25,fc="#ECF5FA",ec="#C5DCEB")
    for x,w,h,t in [(1.02,2.84,"固定 b / χ / rank","场景规则"),
                    (4.70,3.13,"矩阵 WMMSE","更新 A、E、Ω"),
                    (8.64,2.77,"集中式 ADMM","优化复预编码 w"),
                    (12.18,2.45,"真信道评价","SE / 体验代理")]:
        rect(ax,x,2.10,w,1.14,fc=WHITE,ec="#B5D5E6")
        txt(ax,x+.16,2.83,h,15,NAVY,"bold");txt(ax,x+.16,2.38,t,10.5,MUTED)
    for a,b in [(3.88,4.67),(7.86,8.61),(11.43,12.15)]:
        arrow(ax,a,2.67,b,2.67,BLUE,2.1)
    arrow(ax,6.25,4.74,6.25,3.80,PURPLE,1.9,ls="--")
    rect(ax,6.48,3.86,4.28,.53,fc=WHITE,ec="#DCCFE9")
    txt(ax,6.68,4.12,"拟议：候选规则 → 正式快层评价",11,PURPLE,"bold")
    chip(ax,11.18,3.96,3.78,"当前无实际调用边",PLAN,PURPLE)
    save(fig,"03_method_timescales",pdf)

def s04(pdf):
    fig,ax=base(4,"WMMSE—ADMM｜外层更新统计量，内层求满足功率约束的 w",
      "矩阵 WMMSE 外轮与集中式 ADMM 内轮；以下为当前代码中的变量和停止判断",
      "功率投影可行 ≠ ADMM 收敛；保存的正式规模轨迹仍达到外轮与内轮次数上限。")
    rect(ax,.67,4.48,14.67,2.65,fc="#EDF5FA",ec="#B8D5E8")
    txt(ax,.98,6.70,"外层｜给定 H_est 与误差统计 C",17,BLUE,"bold")
    steps=[(1.05,2.30,"当前 w","初值 / 上轮结果"),
           (3.73,2.52,"接收器 A","MMSE 更新"),
           (6.70,2.88,"MSE E 与权重 Ω","由当前 A、w 得到"),
           (10.08,3.00,"预编码子问题","固定 A、Ω；更新 w")]
    for x,w,a,b in steps:
        rect(ax,x,5.22,w,.98,fc=WHITE,ec="#B7D1E1")
        txt(ax,x+.16,5.86,a,15,NAVY,"bold");txt(ax,x+.16,5.48,b,11,MUTED)
    for a,b in [(3.39,3.68),(6.30,6.65),(9.61,10.03)]:
        arrow(ax,a,5.70,b,5.70,BLUE,2.1)
    rect(ax,13.55,5.22,1.34,.98,fc=WARN,ec="#E7D5AC")
    txt(ax,14.22,5.87,"停止?",14,AMBER,"bold",ha="center")
    txt(ax,14.22,5.47,"目标 / w / 残差",9.0,MUTED,ha="center")
    arrow(ax,13.13,5.70,13.50,5.70,BLUE,2.1)
    arrow(ax,14.26,5.20,14.26,4.65,AMBER,1.5,ls="--")
    txt(ax,10.37,4.83,"未满足则回到外层；满足并需 ADMM 收敛",11,MUTED)
    arrow(ax,11.63,5.16,11.63,4.17,TEAL,2.1)
    rect(ax,.67,1.41,14.67,2.67,fc=GOOD,ec="#B7D9D2")
    txt(ax,.98,3.63,"内层 ADMM｜仅优化复预编码 w，A / Ω 保持固定",17,TEAL,"bold")
    inner=[(1.02,2.75,"CG 线性系统","更新 x"),
           (4.31,2.75,"跨资源功率投影",r"$z=\Pi_{\mathcal{P}}(x+u)$"),
           (7.59,2.42,"缩放对偶",r"$u\leftarrow u+x-z$"),
           (10.58,3.89,"残差判断","原始 / 对偶 / CG；或达到上限")]
    for x,w,a,b in inner:
        rect(ax,x,2.02,w,.99,fc=WHITE,ec="#B7D9D2")
        txt(ax,x+.16,2.67,a,14.5,NAVY,"bold");txt(ax,x+.16,2.29,b,10.5,MUTED)
    for a,b in [(3.81,4.26),(7.12,7.54),(10.05,10.54)]:
        arrow(ax,a,2.52,b,2.52,TEAL,2.0)
    txt(ax,1.05,1.68,"功率预算按 TRP 跨资源组累计；ADMM 变量均在同一 MATLAB 进程内。",11.5,MUTED)
    save(fig,"04_wmmse_admm",pdf)

def s05(pdf):
    fig,ax=base(5,"非均匀鲁棒机制｜从链路测量质量，到可信赋形",
      "当前已实现的是链路条件误差协方差参与计算；校准椭球与最坏情况保证仍待研究",
      "要证明创新效果，需同场景、同业务、同功率约束、同随机种子比较名义/统一/非均匀三种设定。")
    txt(ax,.78,7.30,"当前可追溯的统计链",17,TEAL,"bold")
    stages=[(.82,2.47,"SRS 质量","SINR / CSI 年龄"),
            (3.88,2.75,"链路条件后验","每 UE–TRP–组"),
            (7.23,2.87,"C_stat","4×4 接收协方差"),
            (10.72,3.85,"A、E、Ω 与二次项","改变预编码 w 的计算")]
    for i,(x,w,a,b) in enumerate(stages):
        rect(ax,x,5.23,w,1.10,fc=GOOD if i>0 else "#EAF3F9",ec="#B8DCD4")
        txt(ax,x+.18,5.95,a,16,NAVY,"bold")
        txt(ax,x+.18,5.54,b,11.5,MUTED)
    for a,b in [(3.32,3.83),(6.67,7.18),(10.13,10.68)]:
        arrow(ax,a,5.78,b,5.78,TEAL,2.2)
    chip(ax,12.73,6.68,2.00,"已实现机制",GOOD,TEAL)
    rect(ax,.83,3.57,6.65,1.04,fc=PLAN,ec="#D8CCE8")
    txt(ax,1.08,4.24,"拟研究：误差椭球的覆盖率标定与最坏情况优化",14,PURPLE,"bold")
    txt(ax,1.08,3.84,"C_stat 本身不等于已校准的 256×256 全信道椭球",11.5,MUTED)
    arrow(ax,4.20,5.18,4.20,4.65,PURPLE,1.8,ls="--")
    txt(ax,8.13,4.37,"公平对照设计",16,BLUE,"bold")
    for x,w,a,b,c in [(8.12,2.18,"名义","忽略误差",BLUE),
                      (10.53,2.18,"统一误差","同一协方差",AMBER),
                      (12.94,2.18,"非均匀误差","链路条件统计",TEAL)]:
        rect(ax,x,2.88,w,1.12,fc=WHITE,ec=LINE)
        txt(ax,x+.18,3.59,a,14.5,c,"bold");txt(ax,x+.18,3.18,b,11,MUTED)
    txt(ax,8.14,2.39,"观察：底部 5% 体验、平均体验、功率、收敛与时延",12,NAVY)
    rect(ax,8.12,1.52,7.03,.58,fc=WARN,ec="none")
    txt(ax,8.40,1.82,"尚无正式对照证据证明“非均匀方案提升”",13,AMBER,"bold")
    save(fig,"05_nonuniform_robustness",pdf)

def s06(pdf):
    graph=json.loads(ARCH.read_text(encoding="utf-8"))
    labels={c["id"]:c["label"] for c in graph["components"]}
    assert [labels[i] for i in ("entry","scene","rule","solver","evaluation","store")] == [
        "chasi_run","场景与测量","资源固定规则","矩阵 WMMSE + ADMM","真信道评价","结果保存"]
    fig,ax=base(6,"代码与证据｜正式入口可以运行，但正式收敛尚未通过",
      "本页执行链从经 Archify 仓库证据校验的语义图派生；详细函数和行号见交互附图",
      "证据分层：函数接通与功率可行已观察；数值对拍通过不等于外层和 ADMM 收敛。")
    xs=[.84,3.32,5.82,8.39,11.04,13.42]
    ws=[2.1,2.14,2.14,2.28,2.10,1.75]
    ids=["entry","scene","rule","solver","evaluation","store"]
    subs=["正式入口","H_est / C_stat","b / χ / rank 固定","优化复矩阵 w","真信道 SE / 体验代理","MAT / JSON"]
    for i,(x,w,k,sub) in enumerate(zip(xs,ws,ids,subs)):
        col=BLUE if i<3 else TEAL
        rect(ax,x,5.07,w,1.43,fc=WHITE,ec=col,lw=1.8)
        rect(ax,x,6.22,w,.28,fc=col,ec="none",r=.06)
        display="WMMSE—ADMM" if k=="solver" else labels[k]
        txt(ax,x+.15,5.91,display,13.3,NAVY,"bold")
        txt(ax,x+.15,5.43,sub,10.3,MUTED)
        txt(ax,x+.13,6.75,f"{i+1:02d}",13,col,"bold")
        if i<5: arrow(ax,x+w+.03,5.77,xs[i+1]-.08,5.77,BLUE,2.1)
    txt(ax,.87,4.57,"程序调用",12,BLUE,"bold")
    txt(ax,.87,4.15,"数据：场景与 CSI",12,MUTED)
    txt(ax,5.84,4.15,"规则：服务 / 调度 / rank",12,MUTED)
    txt(ax,9.05,4.15,"循环：A / E / Ω / w",12,MUTED)
    txt(ax,12.42,4.15,"评价与保存",12,MUTED)
    ax.plot([.82,15.2],[3.79,3.79],color=LINE,lw=1.2)
    txt(ax,.84,3.39,"当前证据的三层含义",18,NAVY,"bold")
    for x,w,num,head,body,fc,tc in [
        (.84,4.41,"01","已实现 / 已运行","固定资源规则、集中式求解、真信道评价",GOOD,TEAL),
        (5.77,4.41,"02","已有对拍与功率检查","210/420 UE 保存结果；部分同输入一致", "#EAF3F9",BLUE),
        (10.70,4.48,"03","仍未通过正式收敛","外轮 2 次、ADMM 12 次达到上限",WARN,AMBER)]:
        rect(ax,x,1.52,w,1.43,fc=fc,ec="none")
        txt(ax,x+.22,2.56,num,12,tc,"bold")
        txt(ax,x+.71,2.56,head,16,tc,"bold")
        txt(ax,x+.22,1.98,body,11.2,NAVY)
    save(fig,"06_execution_evidence",pdf)

def main():
    with PdfPages(ROOT/"PRESENTATION_ATLAS.pdf") as pdf:
        for fn in (s01,s02,s03,s04,s05,s06): fn(pdf)
    print("Built six SVG, PNG and PDF pages in",ROOT)

if __name__=="__main__": main()
