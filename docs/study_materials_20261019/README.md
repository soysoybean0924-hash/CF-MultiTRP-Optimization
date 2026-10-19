# 茶思公式、代码图与研究关系学习包

本目录基于提交 `3efa44cb92a27562b05076d9c49a3c7d5fb352ba` 的独立稀疏检出制作。它是研究学习材料，不是茶思验收结论；另一会话后续修复须重新核对。原始三图及两份研究 PDF 只读使用，未复制进仓库。

## 建议顺序

1. 看 [13 研究关系](atlas/13_research_map.pdf)、[03 物理拓扑](atlas/03_network.pdf)、[04 端口与维度](atlas/04_ports.pdf)、[16 RB与时间](atlas/16_resource_time.pdf)、[05 SRS/CSI](atlas/05_srs_csi.pdf)，再读 `matlab/chasi/chasi_config.m`、`chasi_generate_scene.m` 和公式 C01–C13。
2. 看 [01 调用图](atlas/01_calls.pdf)、[06 决策和功率](atlas/06_resources.pdf)、[08 下行链](atlas/08_signal.pdf)，读 `chasi_run.m`、`chasi_matrix_wmmse.m` 中 `state`、`quadratic`，对照 C14–C26。
3. 看 [07 外层与内层](atlas/07_wmmse_admm.pdf)、[09 评价](atlas/09_metrics.pdf)、[10 保存](atlas/10_lifecycle.pdf)，读 `precoder_admm`、`project`、`chasi_evaluate`，对照 C27–C38。
4. 最后看 [14 旧搜索](atlas/14_legacy_search.pdf)、[15 鲁棒边界](atlas/15_nonuniform_boundary.pdf)、[11 语言关系](atlas/11_languages.pdf)、[12 动态边界](atlas/12_dynamic.pdf)，读 L01–L17、Z01–Z03、R01–R04。

## 文件

- [公式合集 PDF](FORMULA_TRACE.pdf) / [TeX](FORMULA_TRACE.tex)：保留历史编号 C01–C38、L01–L17、Z01–Z03；新增 R01–R04。每式给出量纲、物理解释、输入输出、函数定位和状态。
- [合并图集](atlas/STUDY_ATLAS.pdf)：逐图 PDF、SVG、PNG 与可编辑 [MATLAB 绘图源](atlas/build_study_atlas.m) 同目录。
- [变量字典和交叉索引](VARIABLE_INDEX.md)：数学符号、MATLAB 字段、轴序、生产者、消费者。
- [证据状态](EVIDENCE_AND_STATUS.md)：原始要求、代码实现、保存验证和拟研究四栏。
- [研究关系说明](RESEARCH_RELATIONSHIP.md)：主线、独立旧搜索、鲁棒方向及验收缺口。

## 图例与图的边界

蓝实线为函数/控制，绿虚线为数据或服务，灰线为逻辑传递，红虚线提示需区分的干扰、可选或未接入关系；具体含义看箭头标注和各图脚注。物理拓扑图 03 是教学示意：部分服务边身份取先前保存的 `scene_manifest.json`，布点位置并非实际坐标；不能据图判断面积均匀或干扰覆盖。实际坐标须用本次运行的 manifest 和 seed。公式中的发送符号是二阶统计等效模型，代码没有产生真实 IQ/OFDM 波形。

原图视觉依据：16:9 白底、红色主标题、浅黄色信息块、黑色细表格线，以及 SRS 红色跳频柱；本图集在程序图中用统一的浅黄模块和红色标题继承该层级，没有把原图截图改作代码图。旧图集 01–12 的几何与节点构造是本次图源的起点，新版新增 13–16，并重新导出所有页。可编辑源和图像均在新目录，未覆盖旧交付。

## 实际使用的 skills

- `using-git-worktrees`：按隔离原则建立独立稀疏检出与材料分支，随后只在本分支快进新提交。
- `domain-modeling`：把正式调度/服务、矩阵预编码/MSE 权重、旧搜索目标/正式目标以及误差协方差/椭球分别命名，形成变量索引。
- `pdf`：编译可检索公式 PDF，合并逐图矢量 PDF，并渲染逐页查看。
- `verification-before-completion`：核查公式编号、图件三格式、可检索文本、TeX 字形与溢出日志及 Git 差异。

评估过 `archify`，但本项目已有可编辑 MATLAB 矢量图源，本轮实际图件由该图源产生，没有把 Archify 候选件算作交付图。

## 重建与自检

在仓库根目录，运行 `matlab -batch "addpath('docs/study_materials_20261019/atlas'); build_study_atlas"` 导出逐图 PNG/PDF/SVG；再用 Python 运行 `atlas/normalize_svg.py` 和 `atlas/merge_atlas.py`（路径从本目录计算）。在本目录运行 `xelatex -interaction=nonstopmode -halt-on-error FORMULA_TRACE.tex` 两次，生成可检索 PDF；最后运行 `verify_materials.py`。图和公式重建不调用正式求解器或大型实验。
