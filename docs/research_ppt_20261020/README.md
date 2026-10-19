# 茶思研究汇报（2026-10-20）

本版是 27 页、基于用户指定 `开题报告-示范-有调研.pptx` 的可编辑汇报稿。模板原件未改动。正文围绕“茶思任务 → 实际 MATLAB 拓扑 → 通信变量 → WMMSE–ADMM → 真信道评价 → 新版拟议方案”。材料对应代码提交 `db9d7e3c71a75f8f9724b743fc78023185b5cddf`；未吸收另一会话正在编辑的未提交搜索代码，也未将旧场景数值结果冒充新拓扑性能。

## 建议阅读

1. [PPTX](CHASI_研究汇报_20261020.pptx)：先看第 5–8 页的坐标/服务/数据链，再看第 12–21 页的物理模型与求解，最后看第 23–27 页的证据和新版方案。每页备注提供问题、讲法、符号解释、来源与追问。
2. [PDF](CHASI_研究汇报_20261020.pdf)：直接投影/查阅版本；可检索正文。
3. [证据索引](EVIDENCE_INDEX.md) 与 [完整核心符号表](SYMBOLS.md)：查材料原图、源码、维度、状态与边界。
4. [Archify 源码链](archify/code-chain.html)：交互查看正式 MATLAB 调用与数据依赖；主要 PPT 图形仍为可编辑 PowerPoint 对象。

## 实际拓扑图

`create_topology_assets.m` 调用当前提交的 `chasi_config` 和 `chasi_generate_scene`，只生成场景，不调用求解器。输出 `topology/sites_seed20261011.csv`、`trps_seed20261011.csv`、`ues_seed20261011.csv` 与 `topology_manifest.json`。CSV 依次为：站 ID/x/y；TRP ID/站 ID/扇区 ID/主方向角/x/y；UE ID/home TRP/x/y。`topology_full` 和 `topology_zoom` 均有 MATLAB 矢量 PDF、由 PDF 导出的 SVG 和高清 PNG。SVG 可在 Inkscape 编辑。中心站为 `(450,450)m`，外环半径 300m，三个 TRP 共址；25–150m 环扇区为项目假设。

本次 MATLAB 批处理已写出完整 CSV、manifest 和两份矢量 PDF，选定 UE 7 的服务集合为 T01/T02；但进程在文件写毕后仍未返回批处理退出码，随后只终止了本会话启动的 MATLAB 命令。因此这里把图件标为“MATLAB 实际导出并已视觉检查”，不声称该批处理退出码 0。正式场景生成逻辑另有仓库既存的 210/420 UE 场景级核查记录。

## 生成与检查

- `build_presentation.py` 从指定模板另存，27 页内容由约 400 个原生 PPT 对象构成，仅第 5、6 页的实际 MATLAB 拓扑作为图片嵌入。主要文字、流程、箭头、框架和变量表均可编辑。
- PowerPoint 已实际打开 PPTX 并导出 27 页 PDF；PDF 27 页可检索，27 页均有备注。逐页渲染后检查全部联系图，另以完整分辨率核查封面、拓扑页、代码架构页、方法分工页和复杂公式页，修正了标题换行和 UE–TRP–CPU 信息方向。
- Archify `candidate.json` 由最新提交源码定位更新，`finalize` 的 validate/deliver/check/browser-check 全部通过。HTML 是附加交互图，不等于代码运行验证。
- 210/420 UE 的正式静态运行、功率可行和 MATLAB/Python 对拍来自已有记录；本次未重跑大型求解。两个运行都未达外层/最近 ADMM 停止阈值。新版系统方案第 24–27 页全部标为拟研究。

## Skills 实际使用

- `presentations`：检查指定模板 23 页、母版/版式/字体位置，保留版式并构建/导出 PPTX。
- `archify`：把正式入口至场景、资源、求解、评价、保存的依赖做成有源码证据的交互图并运行内置检查。
- `pdf`：检查原始方案/公式文档，PowerPoint 导出后渲染与逐页视觉检查。
- `verification-before-completion`：核对 27 页、27 份备注、PDF 可检索、MATLAB 坐标行数与 Git 范围。

### 注意

模板中的校徽/学校视觉识别元素依用户指定模板保留。PPT 只供研究汇报；严格协议验收、算法收敛、非均匀误差相对收益、拟议最坏情况椭球及事件触发通信仍待独立验证。
