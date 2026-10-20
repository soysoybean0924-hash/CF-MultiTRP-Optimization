# 图示重绘版说明

- 演示文件：`CHASI_研究汇报_执行链重绘_20261020.pptx`，14 页；同名 PDF 由该 PPTX 在 WPS 中导出。
- 修改基准：用户手动保存的 `CHASI_研究汇报_图示增强版_六图完善_20261020.pptx`，输入 SHA256 `42DB3CEA…127A9B7`。原文件未覆盖。第 1、2、4 页的形状、位置、文本与图片内容逐项比对一致；第 4 页真实拓扑未替换。
- 源码依据：`D:\GitHubProjects\CF-MultiTRP-Optimization` 已提交版本 `db9d7e3c71a75f8f9724b743fc78023185b5cddf`。另一个会话的未提交修复未纳入本图集。
- 视觉结构参照：`C:\Users\sypxx\Documents\蒸发波导\analysis_readonly\code_explanation_20261016_1210\figures` 内 `01真实执行链`、`02CPU-TRP-UE`、`03SRS-CSI泳道`、`04下行通信与评价`、`05WMMSE-ADMM` 的 PNG、SVG、JSON。参照图所属内容是先前茶思代码讲解；其旧 MATLAB→Python 桥接与旧变量名已按当前原生 MATLAB 源码改正，`02` 未替换实际拓扑。
- 本轮实际使用：Archify 对 MATLAB 调用与数据依赖生成源码关联图并通过 finalize 校验；Presentations 用于保留模板和可编辑 PPT 形状；PDF 渲染工具用于逐页复核。

| PPT 页 | 主图 | SVG/PNG 源名 | 核心阅读顺序 |
|---:|---|---|---|
| 5 | 真实执行链 | `execution_chain_figures/01_real_execution_chain` | 场景、测量、固定资源、集中求解、真实信道评价 |
| 6 | SRS–CSI 泳道 | `execution_chain_figures/02_srs_csi_swimlane` | UE 观测对象 → TRP 等效测量 → 协调侧条件估计与预编码 → 下行 |
| 8 | 下行通信与评价 | `execution_chain_figures/04_downlink_evaluation` | 预编码 → 真信道接收 → 干扰分解 → SE → 交付量 → 体验 |
| 9 | WMMSE–ADMM | `execution_chain_figures/05_wmmse_admm_nested` | 外轮 A/E/Ω → 固定量二次问题 → 内轮 x/z/y → 残差 → 外轮接受或回溯 |

其余重绘源：第 3、7、10、11 页在同一目录。`rebuild_reference_figures.py` 是可重复生成的绘图源；每张 SVG 也能直接编辑，PNG 为最终 PDF 渲染裁取的高清版本。PPT 中图形为原生可编辑形状，演讲者备注保存源码定位与讲解边界。

边界：当前正式求解为集中式 MATLAB WMMSE–ADMM，历史 GA/PSO 搜索未与正式矩阵求解器连成闭环；SRS/CSI 为等效仿真观测，未实现完整上行协议；非均匀条件协方差已进入优化，最坏情况椭球与 TRP 本地并行仍属新方案。功率可行或数值对拍不等于正式规模算法收敛。
