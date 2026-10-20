"""Finish both current 14-page decks without changing their input files.

Each diagram is native PowerPoint shapes and has a separate editable SVG source.
The input hashes protect the manually edited revision from accidental replacement.
"""
from __future__ import annotations

from pathlib import Path
from hashlib import sha256
from html import escape
from base64 import b64encode
from PIL import Image
import re

from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE, MSO_CONNECTOR
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.dml import MSO_LINE_DASH_STYLE

ROOT = Path(__file__).parent
FIG = ROOT / 'six_figure_sources'
FIG.mkdir(exist_ok=True)
SOURCES = [
    ('CHASI_研究汇报_修订版_20261020.pptx',
     '61ae41073d08d4a796332a82ea09ff7006b2a7d3cd8b6a199f1b42a230e49926',
     'CHASI_研究汇报_修订版_六图完善_20261020.pptx'),
    ('CHASI_研究汇报_图示增强版_20261020.pptx',
     'e4bf7211af47a9b72972c31ab737abec27ec205061db7f5ec3ad2f6fb89fb879',
     'CHASI_研究汇报_图示增强版_六图完善_20261020.pptx'),
]
BLUE='#092b56'; MID='#124a8f'; RED='#b12a30'; ORANGE='#df7b27'
PALE='#e0ecf6'; VERY='#f4f9fd'; DARK='#000000'; GREEN='#1c7663'; GRAY='#677587'
FONT='Microsoft YaHei'


def rgb(value):
    return RGBColor.from_string(value.lstrip('#'))


class Diagram:
    """One source model drives native PPT objects and independent vector SVG."""
    def __init__(self, slide, stem, x=.55, y=1.35, w=12.23, h=5.55):
        self.slide=slide; self.stem=stem; self.x=x; self.y=y; self.w=w; self.h=h
        self.svg=[]

    def box(self,x,y,w,h,fill=VERY,stroke=PALE,r=.13):
        sh=self.slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE if r else MSO_SHAPE.RECTANGLE,
            Inches(self.x+x),Inches(self.y+y),Inches(w),Inches(h))
        sh.fill.solid(); sh.fill.fore_color.rgb=rgb(fill)
        sh.line.color.rgb=rgb(stroke);sh.line.width=Pt(.8)
        self.svg.append(f'<rect x="{x*100:.1f}" y="{y*100:.1f}" width="{w*100:.1f}" height="{h*100:.1f}" rx="{r*100:.1f}" fill="{fill}" stroke="{stroke}" stroke-width="1.3"/>')
        return sh

    def text(self,x,y,w,h,value,size=16,bold=False,color=DARK,center=False):
        sh=self.slide.shapes.add_textbox(Inches(self.x+x),Inches(self.y+y),Inches(w),Inches(h))
        tf=sh.text_frame;tf.clear();tf.word_wrap=True
        tf.margin_left=tf.margin_right=Inches(.03)
        tf.margin_top=tf.margin_bottom=Inches(.015)
        tf.vertical_anchor=MSO_ANCHOR.MIDDLE
        for i,line in enumerate(value.split('\n')):
            p=tf.paragraphs[0] if i==0 else tf.add_paragraph()
            p.text=line;p.alignment=PP_ALIGN.CENTER if center else PP_ALIGN.LEFT
            for run in p.runs:
                run.font.name=FONT;run.font.size=Pt(size);run.font.bold=bold;run.font.color.rgb=rgb(color)
        lines=value.split('\n'); fs=size*1.3
        for i,line in enumerate(lines):
            anchor='middle' if center else 'start'
            xx=(x+w/2 if center else x+.05)*100
            yy=(y+h/2+(i-(len(lines)-1)/2)*.22)*100+fs*.34
            self.svg.append(f'<text x="{xx:.1f}" y="{yy:.1f}" text-anchor="{anchor}" font-family="Microsoft YaHei, sans-serif" font-size="{fs:.1f}" font-weight="{700 if bold else 400}" fill="{color}">{escape(line)}</text>')
        return sh

    def link(self,x1,y1,x2,y2,label='',color=MID,dash=False,width=2.0):
        sh=self.slide.shapes.add_connector(MSO_CONNECTOR.STRAIGHT,
            Inches(self.x+x1),Inches(self.y+y1),Inches(self.x+x2),Inches(self.y+y2))
        sh.line.color.rgb=rgb(color);sh.line.width=Pt(width)
        if dash:sh.line.dash_style=MSO_LINE_DASH_STYLE.DASH
        self.svg.append(f'<line x1="{x1*100:.1f}" y1="{y1*100:.1f}" x2="{x2*100:.1f}" y2="{y2*100:.1f}" stroke="{color}" stroke-width="2.5" {"stroke-dasharray=\"8 6\"" if dash else ""} marker-end="url(#arr)"/>')
        if label:
            mx=(x1+x2)/2; my=(y1+y2)/2-.18
            self.text(mx-1.05,my,2.1,.35,label,11,False,color,True)

    def band(self,y,label,fill=PALE):
        self.box(0,y,self.w,.40,fill,fill,.03)
        self.text(.16,y,self.w-.25,.40,label,16,True,BLUE)

    def formula(self,name,x,y,w,h):
        """Embed the existing TeX-rendered equation as a crisp vector component."""
        png=ROOT/'revision_equations'/(name+'.png')
        svg=ROOT/'revision_equations'/(name+'.svg')
        with Image.open(png) as im:
            ratio=im.width/im.height
        real_w=min(w,h*ratio);real_h=real_w/ratio
        real_x=x+(w-real_w)/2;real_y=y+(h-real_h)/2
        self.slide.shapes.add_picture(str(png),Inches(self.x+real_x),Inches(self.y+real_y),
                                      width=Inches(real_w),height=Inches(real_h))
        payload=b64encode(svg.read_bytes()).decode('ascii')
        self.svg.append(f'<image x="{real_x*100:.1f}" y="{real_y*100:.1f}" width="{real_w*100:.1f}" height="{real_h*100:.1f}" href="data:image/svg+xml;base64,{payload}" preserveAspectRatio="xMidYMid meet"/>')

    def save(self):
        body='\n'.join(self.svg)
        data=f'''<svg xmlns="http://www.w3.org/2000/svg" width="{self.w*100:.0f}" height="{self.h*100:.0f}" viewBox="0 0 {self.w*100:.0f} {self.h*100:.0f}"><defs><marker id="arr" markerWidth="8" markerHeight="7" refX="7" refY="3.5" orient="auto"><path d="M0 0 L8 3.5 L0 7 Z" fill="{MID}"/></marker></defs><rect width="100%" height="100%" fill="white"/>{body}</svg>'''
        (FIG/(self.stem+'.svg')).write_text(data,encoding='utf-8')


def clear_body(slide):
    title=slide.shapes[0]._element
    for s in list(slide.shapes):
        if s._element is not title: slide.shapes._spTree.remove(s._element)


def title(slide,value):
    # Keep the template placeholder, geometry, font and blue title treatment.
    t=slide.shapes[0]
    if t.has_text_frame:
        t.text=value
        for p in t.text_frame.paragraphs:
            for r in p.runs:
                r.font.name=FONT;r.font.bold=True;r.font.color.rgb=rgb(BLUE)


def note(slide,value):
    slide.notes_slide.notes_text_frame.text=value


def research(slide):
    clear_body(slide);title(slide,'研究问题与目标')
    d=Diagram(slide,'05_problem_method')
    d.band(.03,'实际困难 → 当前方法 → 需要核验的结果')
    rows=[
      ('SRS/CSI 精度随链路变化','链路条件协方差 C；测量质量分组','同条件比较边缘体验',MID),
      ('边缘 UE 协同受干扰影响','用户中心服务＋WMMSE 接收更新','真信道体验分位与协议口径',ORANGE),
      ('跨组功率与正式规模','集中式 ADMM 联合功率投影','预算违规、残差及运行规模',GREEN)]
    for i,(a,b,c,col) in enumerate(rows):
        y=.70+i*1.16
        d.box(.10,y,3.24,.83,VERY,col);d.text(.20,y+.06,3.02,.70,a,16,True)
        d.link(3.42,y+.42,3.78,y+.42,color=col)
        d.box(3.84,y,4.03,.83,PALE,col);d.text(3.98,y+.06,3.74,.70,b,15.7)
        d.link(7.94,y+.42,8.30,y+.42,color=col)
        d.box(8.37,y,3.74,.83,VERY,col);d.text(8.50,y+.06,3.45,.70,c,15.5)
    d.box(.12,4.42,11.98,.82,'#fff7eb',ORANGE)
    d.text(.30,4.47,11.64,.72,'当前：统计误差与集中求解已接入；最坏情况椭球、TRP 本地求解仍属研究方案。',17,True)
    d.save()
    note(slide,'本页回答为什么研究、用什么办法、如何证明。原图：难题1、典型验收场景、用户速率协议定义。当前实现：固定服务/调度、链路非均匀条件协方差、集中式矩阵 WMMSE–ADMM。正式规模目前尚未达到停止条件。最坏情况椭球和分布式仍未实现。背景文献：Demir, Björnson, Sanguinetti, Foundations of User-Centric Cell-Free Massive MIMO, 2021, DOI 10.1561/2000000109。')


def system(slide,variant):
    clear_body(slide);title(slide,'系统框架')
    d=Diagram(slide,'02_communication_dataflow',y=1.45,h=2.28)
    stages=[('位置与扇区','站址、UE 坐标','生成 Hᵗʳᵘᵉ'),('SRS / CSI','Hᵗʳᵘᵉ、质量/年龄','输出 Ĥ、C'),('资源规则','Ĥ、归属、业务','固定 b、χ、r、ν'),('WMMSE–ADMM','Ĥ、C、b/χ/r/ν','优化 w'),('真实信道评价','Hᵗʳᵘᵉ、w','速率/体验/功率')]
    cols=[BLUE,MID,GREEN,ORANGE,RED]
    for i,(h,ins,out) in enumerate(stages):
        x=.08+i*2.44
        d.box(x,.23,2.20,1.66,VERY,cols[i])
        d.box(x,.23,2.20,.42,cols[i],cols[i],.06)
        d.text(x+.08,.24,2.04,.39,h,15.2,True,'#ffffff',True)
        d.text(x+.12,.73,1.96,.45,ins,12.9)
        d.text(x+.12,1.24,1.96,.49,out,13.1,True)
        if i<4:d.link(x+2.21,1.05,x+2.42,1.05,color=cols[i])
    d.save()
    e=Diagram(slide,'01_ue_trp_cpu',y=4.02,h=2.58)
    e.band(.03,'UE–TRP–CPU：当前集中式仿真中的测量、计算与下行')
    nodes=[(.16,'UE','上行 SRS / 业务需求'),(4.05,'21 个 TRP','接收测量；执行预编码块'),(8.30,'逻辑 CPU','形成 Ĥ、C；集中求 w')]
    for x,h,b in nodes:
        e.box(x,.74,3.15,.92,VERY,MID)
        e.text(x+.13,.77,2.86,.36,h,18,True,BLUE,True)
        e.text(x+.13,1.15,2.86,.40,b,13.2,False,DARK,True)
    e.link(3.34,1.07,4.04,1.07,'SRS',MID)
    e.link(7.22,1.05,8.27,1.05,'测量/质量',MID)
    e.link(8.28,1.82,7.22,1.82,'业务数据、wₗ',ORANGE)
    e.link(4.03,1.84,3.36,1.84,'下行信号',ORANGE)
    e.text(.25,2.05,11.74,.36,'虚拟协调节点；目前无 TRP 本地 ADMM、前传协议或编解码实现。',14.1,True)
    e.save()
    note(slide,'从上方依次讲输入、处理、输出：几何→真信道→观测→估计信道 Ĥ 与条件协方差 C→固定资源→集中求含幅度预编码 w→真信道评价。Htrue 用于仿真观测和最后评价，不直接给非理想优化分支。下方 UE/TRP/CPU 是当前数值实现的逻辑架构，CPU 无实际坐标；没有模拟完整前传、PUSCH/LLR/解码，也未实现 TRP 本地 ADMM。源码：chasi_run.m、chasi_generate_scene.m、chasi_matrix_wmmse.m、chasi_evaluate.m。参考图片 2.png 仅借鉴节点与带标签信息流。')


def timeline(slide):
    clear_body(slide);title(slide,'资源变量与两时间尺度')
    d=Diagram(slide,'04_timescales_search')
    d.band(.03,'物理时刻 t → 测量更新 → 固定配置下求一个可评价的预编码')
    d.box(.16,.66,3.01,1.44,'#fff5e9',ORANGE)
    d.text(.32,.76,2.70,.38,'历史慢层候选搜索',18,True,BLUE)
    d.text(.32,1.20,2.70,.78,'连接数、调度阈值、rank 与惩罚/修复参数；GA 交叉变异，PSO 位置速度更新。',13.4)
    d.box(4.06,.66,3.38,1.44,VERY,MID)
    d.text(4.22,.76,3.08,.38,'SRS / CSI 测量',18,True,BLUE)
    d.text(4.22,1.20,3.06,.76,'质量与 CSI 年龄 → 估计信道 Ĥ、条件协方差 C。',14.2)
    d.box(8.30,.66,3.68,1.44,VERY,GREEN)
    d.text(8.46,.76,3.36,.38,'当前正式快层求解',18,True,BLUE)
    d.text(8.46,1.20,3.36,.77,'固定 b、χ、r、ν；WMMSE 外迭代中调用 ADMM 求 w。',14.0)
    d.link(3.20,1.37,4.03,1.37,'拟接入',ORANGE,True)
    d.link(7.45,1.37,8.27,1.37,'Ĥ、C',MID)
    d.box(8.31,2.71,3.67,.86,'#eef7f4',GREEN)
    d.text(8.47,2.81,3.36,.61,'真信道评价：体验、功率、停止状态',15.5,True)
    d.link(10.11,2.10,10.11,2.69,'w',GREEN)
    d.link(8.28,3.13,3.27,3.13,'反馈搜索：拟接入',ORANGE,True)
    d.box(.17,3.93,11.82,.97,PALE,MID)
    d.text(.34,4.02,11.46,.80,'四种“循环”不同：物理 TTI／候选迭代／WMMSE 外轮／ADMM 内轮。当前正式入口仅接通测量→固定资源→快层求解→评价。',15.6)
    d.save()
    note(slide,'旧候选的归一化编码含 PF 指数、连接数、调度阈值、链路/功率惩罚、rank 门限、修复功率和修复链接数。GA 对候选做选择/交叉/变异，PSO 用速度位置更新；历史评价器有自己的目标与修复逻辑。旧搜索与当前正式矩阵求解器没有默认实线调用。图中两条橙色虚线是希望将来连接的搜索配置/评价反馈。当前 b、χ、r、ν 按规则给定，只有 w 是正式数值优化量。源码 cf_search.m、cf_decode_candidate.m、cf_evaluate_candidate.m（以 db9d7e3 已提交版本为准）；正式链 chasi_run.m、chasi_matrix_wmmse.m。')


def wmmse(slide):
    clear_body(slide);title(slide,'WMMSE 更新')
    d=Diagram(slide,'03_wmmse_admm_nested')
    d.band(.03,'外层 WMMSE：当前可行 w → 接收统计 → 固定量 → 内层 ADMM → 接受 / 停止')
    nodes=[(.13,.81,2.25,'① 当前 w','服务集外为零；满足功率'),(2.85,.81,2.55,'② F、Rʸʸ','Ĥw 相干叠加；叠加 C'),(5.87,.81,2.55,'③ A、E、Ω','MMSE 接收与误差权重'),(8.90,.81,3.10,'④ 二次子问题','固定 A、Ω、η；更新 w')]
    for x,y,w,h,b in nodes:
        d.box(x,y,w,1.25,VERY,MID)
        d.text(x+.13,y+.11,w-.25,.37,h,17,True,BLUE)
        d.text(x+.13,y+.57,w-.25,.57,b,13.2)
    for a,b in [(2.38,2.82),(5.41,5.84),(8.43,8.87)]:d.link(a,1.43,b,1.43)
    d.box(4.52,2.75,4.00,1.03,'#fff5e9',ORANGE)
    d.text(4.71,2.83,3.63,.79,'内层 ADMM：x → z → y\nCG 求解 · 跨组功率投影 · 残差',16,True)
    d.link(10.43,2.08,8.50,2.75,'进入',ORANGE)
    d.box(.49,4.23,11.29,.67,PALE,MID)
    d.text(.68,4.28,10.90,.56,'返回可行副本 z；重算目标并按接受、回溯和外层停止条件判断。',16,True)
    d.link(4.55,3.84,3.60,4.23,'返回 z',ORANGE)
    d.save()
    note(slide,'外层固定当前 w 后，用估计信道和误差统计形成 F 与 Ryy，再更新 A=(Ryy)^−1 Fkk、E、Ω=E^−1，按当前效用更新 η。固定 A/Ω/η 后的 w 子问题由内层 ADMM 解。ADMM 中 A/Ω/η 不更新。返回跨组功率可行的 z 后，实际代码重算目标并可能回溯，内层残差判停与外层停止分开。源码 chasi_matrix_wmmse.m：外层约 41–100；状态更新约 380；ADMM 约 446。正式规模停止条件目前未满足。理论参考：Christensen et al., Weighted Sum-Rate Maximization Using Weighted MMSE for MIMO-BC Beamforming Design, IEEE TWC 2008, DOI 10.1109/TWC.2008.070851；Boyd et al., Distributed Optimization and Statistical Learning via ADMM, 2011, DOI 10.1561/2200000016。')


def admm(slide):
    clear_body(slide);title(slide,'ADMM 求解')
    d=Diagram(slide,'03b_admm_detail')
    d.band(.03,'固定 A、Ω、η 和资源掩码；内层联合更新全部资源组的预编码副本')
    for i,(h,b,col) in enumerate([
        ('x：原变量','CG 近似解二次线性系统',MID),
        ('z：可行副本','跨全部 g 投影到每 TRP 预算',GREEN),
        ('y：缩放对偶','y ← y + x − z',ORANGE),
        ('残差判断','原始/对偶残差＋CG 阈值',RED)]):
        x=.15+i*3.05
        d.box(x,.83,2.78,1.37,VERY,col)
        d.text(x+.14,.95,2.47,.43,h,18,True,BLUE)
        d.text(x+.14,1.47,2.47,.60,b,14)
        if i<3:d.link(x+2.79,1.51,x+3.02,1.51,color=col)
    d.box(.38,2.77,5.48,1.20,PALE,MID)
    d.text(.57,2.83,5.10,.28,'CG 所解的线性系统',14.3,True)
    d.formula('admm_linear',.57,3.18,5.00,.53)
    d.box(6.35,2.77,5.48,1.20,'#eef7f4',GREEN)
    d.text(6.53,2.83,5.09,.28,'所有资源组共享同一 TRP 预算',14.3,True)
    d.formula('power',6.57,3.16,4.98,.52)
    d.box(.38,4.48,11.44,.59,'#fff7eb',ORANGE)
    d.text(.56,4.52,11.10,.49,'返回 z 给外层；功率可行、数值对拍、内层收敛、外层停止须分别判断。',15.8,True)
    d.save()
    note(slide,'源码固定 A、Ω、η，构造隐式二次算子 Q 与线性项 B；每组 CG 更新原变量 x。ρ/2 项在增广目标中，因此正规方程出现 ρI；νg 是该组跨 RB 发射权重。z 对同一 TRP 的所有资源组共同投影，使 ΣgνgΣj||w_ljg||²≤P_l；不能逐组独立投影。随后 y+=x−z 并检查原始/对偶残差与 CG 精度。输出可行 z。当前是单进程集中式实现，尚未 TRP 并行化。正式规模有触及停止上限的记录。源码 chasi_matrix_wmmse.m ADMM 段约 446–560。')


def robust(slide):
    clear_body(slide);title(slide,'非均匀误差机制')
    d=Diagram(slide,'06_nonuniform_error')
    d.band(.03,'链路测量质量 → 条件误差统计 → 接收器与预编码二次项 → 真信道评价')
    blocks=[(.10,2.25,'SRS SINR、CSI 年龄','有效观测噪声'),(2.70,2.36,'条件协方差 C','4×4；链路/组不同'),(5.43,2.72,'接收器 A、MSE E','Ryy 增加误差干扰'),(8.52,3.50,'Q(C) → w → 评价','误差惩罚改变预编码')]
    for i,(x,w,h,b) in enumerate(blocks):
        col=[MID,ORANGE,GREEN,RED][i]
        d.box(x,.91,w,1.34,VERY,col)
        d.text(x+.13,1.01,w-.25,.47,h,16.4,True,BLUE)
        d.text(x+.13,1.55,w-.25,.54,b,13.9)
        if i<3:d.link(x+w,1.58,blocks[i+1][0]-.04,1.58,color=col)
    d.box(.25,2.96,7.22,1.08,PALE,MID)
    d.text(.43,3.00,6.85,.29,'后验精度由先验、CSI-RS 与 SRS 相加',14.0,True)
    d.formula('posterior',.43,3.37,6.82,.47)
    d.box(7.83,2.96,4.15,1.08,'#fff7eb',ORANGE)
    d.text(8.00,3.05,3.82,.87,'公平对照：固定场景、预算和初值\n仅改变误差模型',14.7,True)
    d.text(.28,4.39,11.57,.55,'当前是统计误差模型；拟议椭球最坏情况内层尚未实现，性能改善尚无有效对照结论。',16.2,True)
    d.save()
    note(slide,'输入是链路增益、SRS/CSI-RS 测量 SINR、测量年龄、行选择矩阵 P 和先验 C0=βRrx。当前等效噪声 ns,nc 已包含测量质量/年龄影响；每发射列使用同一接收侧 4×4 条件协方差 C。若无该组 SRS，省略 PᴴP/ns。求解器以 Σ_l p_lg C_klg 加入接收协方差，改变 A、E、Ω；固定这些量后的二次算子还含误差惩罚，改变 w。最后以 Htrue 独立评价。名义 C=0、统一 C、链路非均匀 C 的公平对照需固定拓扑、业务、预算、初值；尚无正向结论。确定性误差椭球需校准半径/形状，最坏情况内层未接入。源码 chasi_generate_scene.m、chasi_matrix_wmmse.m、chasi_evaluate.m。')


def clean_dangling(slide):
    # Existing enhanced slides contain footnote labels without a reference list.
    for sh in slide.shapes:
        if not sh.has_text_frame:continue
        for p in sh.text_frame.paragraphs:
            for r in p.runs:
                s=r.text
                s=re.sub(r'\s*\[(?:\d+)(?:\s*,\s*\d+)*\]','',s)
                s=re.sub(r'^(?:理论依据|方法依据|相关方法|用户中心协同研究背景)\s*$','',s)
                r.text=s
        if sh.text_frame.text.strip() in {'理论依据','方法依据','相关方法','用户中心协同研究背景'}:
            sh.text_frame.clear()


for src_name,expected,out_name in SOURCES:
    src=ROOT/src_name
    actual=sha256(src.read_bytes()).hexdigest()
    if actual!=expected:raise RuntimeError(f'Input was modified; inspect before editing: {src} {actual}')
    p=Presentation(src)
    assert len(p.slides)==14
    # Cover, contents and the hand-positioned topology retain exact shape trees.
    untouched=[p.slides[i].shapes._spTree.xml for i in (0,1,3)]
    research(p.slides[2])
    system(p.slides[4],src_name)
    timeline(p.slides[6])
    wmmse(p.slides[8])
    admm(p.slides[9])
    robust(p.slides[10])
    for s in p.slides:clean_dangling(s)
    assert untouched==[p.slides[i].shapes._spTree.xml for i in (0,1,3)]
    p.save(ROOT/out_name)
    print(out_name,len(p.slides),sha256((ROOT/out_name).read_bytes()).hexdigest())
