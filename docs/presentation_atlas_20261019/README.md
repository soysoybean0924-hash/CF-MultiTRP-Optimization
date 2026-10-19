# 茶思研究汇报图集（16:9）

本图集是适合直接插入 PPT 的六张静态图；[合并 PDF](PRESENTATION_ATLAS.pdf) 可用于顺序讲解，[figures](figures/) 内每张均有可编辑文本 SVG 和 3520×1980 PNG。静态源为 [build_presentation_atlas.py](build_presentation_atlas.py)。第 6 图的执行链节点从经过 Archify 仓库证据校验的 [candidate.json](archify/architecture-code-chain-20261019/candidate.json) 读取；[交互附图](archify/architecture-code-chain-20261019/code-chain.html) 可逐节点查源码。静态图为重新设计的汇报版，不是旧图换色，也不是 Archify 交互画面的截图。

## 汇报顺序

| 图 | 一句话结论 | 边界 |
|---|---|---|
| 01 研究框架 | 困难、验收目标、方法和创新须分别说明 | 原始指标是目标，尚非结果 |
| 02 场景协同 | 同一 UE 的服务链路有不同 SRS 可信度 | 拓扑为教学示意；不是实际坐标 |
| 03 方法分工 | 旧搜索和正式矩阵求解当前是两条链 | 紫色虚线是拟议接口 |
| 04 WMMSE—ADMM | 外层更新 A/E/Ω，内层求满足功率约束的 w | ADMM 集中运行，正式规模未收敛 |
| 05 非均匀鲁棒 | 当前条件协方差入算，椭球与效果仍待证明 | 不能把 C_stat 称作已校准椭球 |
| 06 代码与证据 | 正式入口已运行，对拍与收敛是不同证据 | 210/420 UE 均达到迭代上限 |

逐图 1 分钟讲解及追问见 [SPEAKER_NOTES.md](SPEAKER_NOTES.md)。

## 版本、资料与视觉

- 固定的**已提交代码**：`3efa44cb92a27562b05076d9c49a3c7d5fb352ba`（2026-10-19 11:23:33 +08）。另一会话当前主工作区有大量未提交修改；本图不把这些改动当作已实现或已验证。
- 原始任务依据：`难题1.png`、`典型验收场景.png`、`用户速率协议定义.png`；方法依据：`202609-系统方案.pdf`；搜索定位依据：`研究主题分析.pdf`。原件位置均为 `C:\Users\sypxx\Desktop\AAAa研一\AAAa研二\MIMO huawei\`，未复制进仓库。
- 视觉取自原图的白底、红色结论标题、浅黄条件区和清晰分栏，改为投影可读的大字与少量高对比箭头；6 张图分别采用证据分栏、物理拓扑、双泳道、嵌套算法、机制＋对照、执行链＋证据等级，避免同一种模板重复。
- `Archify` v3.1：完整读取 `SKILL.md` 与仓库作图、作者默认和交付说明；其代码链候选的 `finalize` 已通过 validate、deliver、strict check、browser-check；`visual-check` 的 1440×900 与 2048×1320 明暗截图已生成且实际查看样图。Archify 的交互图作为可追溯附图；主图为按同一核实关系手工编排的静态矢量图。
- `pdf` 与 `verification-before-completion`：用于逐页图像、可检索 PDF、图件尺寸和 Git 范围检查；未运行大型实验。

## 溯源定位

| 关系 | 代码 / 证据 |
|---|---|
| 正式执行与保存 | `matlab/chasi/chasi_run.m:1-146` |
| 场景、信道、SRS 后验 | `matlab/chasi/chasi_generate_scene.m:1-112,249-305`；`matlab/chasi/chasi_config.m` |
| A/E/Ω、二次项、ADMM | `matlab/chasi/chasi_matrix_wmmse.m:380-540` |
| 历史搜索与变量 | `matlab/core/cf_search.m:1-119,133-260`；`matlab/core/cf_decode_candidate.m:1-29`；`matlab/core/cf_evaluate_candidate.m:1-102` |
| 正式运行与对拍状态 | `docs/CHASI_VALIDATION_20261017.md`；`docs/CHASI_PARITY_420_20261019.json`；`docs/study_materials_20261019/EVIDENCE_AND_STATUS.md` |
| 公式细节 | `docs/study_materials_20261019/FORMULA_TRACE.tex` |

## 重建与检查

在仓库根目录运行 `py -3.9 -X utf8 docs/presentation_atlas_20261019/build_presentation_atlas.py`，只绘图，不调用正式求解器。完整性检查见 `verify_atlas.py`。SVG 保留文本和矢量图元，可在 Inkscape/Illustrator 中修改；PNG 用于 PPT 直接插入。
