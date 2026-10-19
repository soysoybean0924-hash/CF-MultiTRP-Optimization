# 依据、验证与待同步状态

## 固定代码版本

- 初始研究代码检出：`9b591cc9cf46b22dc6031aad8b57b476bd4772ed`，提交时间 `2026-10-18T21:13:32+08:00`。交付前发现三个新提交，独立材料分支安全快进至 `3efa44cb92a27562b05076d9c49a3c7d5fb352ba`，提交时间 `2026-10-19T11:23:33+08:00`，主题 `Record final 420 UE native scene identity check`；本材料最终对应后者。
- 本材料位于独立本地分支 `codex/chasi-study-materials-20261019`，不读取另一会话未提交的求解器作为已实现事实，不重跑大型实验。
- 源码核对：`chasi_run.m:1-155` 的调用和保存；`chasi_config.m:1-90` 的正式配置；`chasi_generate_scene.m` 的 `geometry/schedule/reuse_update`；`chasi_matrix_wmmse.m:380-540` 的 `state/quadratic/qapply/precoder_admm/cg/project`；`cf_search.m:1-70` 的搜索入口和可选适配开关。

## 原始文件与历史跟踪

本轮实际打开三张原图，并以 PDF 文本层检查两份研究材料。原件在 `C:\Users\sypxx\Desktop\AAAa研一\AAAa研二\MIMO huawei\`，未复制入本目录。

| 原件 | SHA256 | 用途 |
|---|---|---|
| `难题1.png` | `FBC313683B3C537CC0E2F54960FFF8DEB7DB941B0946E949E53BD848D1B85878` | 问题、目标、三类指标和对照基线 |
| `典型验收场景.png` | `977AD2FB99BB6A3778598A36FC3DD1AFF15BAD7ABCC0E1AC67724B1FCE2312E9` | 7站/21TRP、64TRX、273RB、SRS跳频、负载 |
| `用户速率协议定义.png` | `2E428E8771DD86CE86F1E641B421AEAB331199F947738BF3A3DD3CBDC641FACD` | 突发及 UE 秒体验样本、首尾排除、5% 分位 |
| `202609-系统方案.pdf` | `22189D4FBE36C8D5A7A47F523D281C9DA3B07DFE9B46F594C04B229BAC9B6992` | WMMSE、分布式 ADMM 和鲁棒方向；方案不是实现证据 |
| `研究主题分析.pdf` | `C9CD3E6880DF2F15E048DCC702F9E4C8AFD11991378FB3F661A8E8670245F384` | 搜索方法的研究定位与分层设想 |

旧版 `docs/CHASI_UNIFIED_TRACE.tex/pdf`、`docs/chasi_native_atlas/`、`docs/CHASI_RESEARCH_SOURCE_MAP_20261017.md`、`docs/CHASI_CROSS_INDEX_20261017.md`、`docs/CHASI_VARIABLE_ACCEPTANCE_20261017.md`、`docs/CHASI_VALIDATION_20261017.md` 已核查。原先另给的独立“公式排版参考文件”未从已知资料目录和仓库文件名找到；版式以实际读取的旧版 `CHASI_UNIFIED_TRACE.tex/pdf` 为可核查参考。若后续找到独立参考，需复核版式。

源仓库另一会话正在写的报告可能变动。本轮先只读打开 `D:\GitHubProjects\CF-MultiTRP-Optimization\docs\CHASI_PARITY_420_20261019.json`，当时 SHA256 为 `B23D95BA3A58F18631D3E9619418D2D3C831F96EBB18AE6E619739A02A5445F8`；后来它进入了 `3efa44c` 的提交，材料分支已快进并按已提交文件核对。`CHASI_VALIDATION_20261017.md` 曾在本轮两次读取间哈希变化；最终以 `3efa44c` 中的已提交文本为准，之后再变更须重核。

## 要求 / 实现 / 保存验证 / 待研究

| 主题 | 原始任务要求 | 当前代码（固定提交） | 已有验证与缺口 |
|---|---|---|---|
| 场景 | 7站×3小区、10–20 UE/小区、真实阵列及标准传播 | 21 TRP、210/420 UE 维度；默认相关高斯 surrogate 和示意方位模型；纯几何映射函数可用同底层均匀数组比较 | 420 UE 已保存场景重建的全部17组 H 与几何/调度逐元素一致；严格面积均匀、双极化阵列、标准信道未证 |
| SRS/CSI | 非理想测量，17跳覆盖273RB，20ms/跳 | 组级 SRS/CSI 后验、4×4 每链误差统计；末跳17RB元数据 | 组级合同与保存后验有轻量核查；无波形/校准/完整随机场景同输入对拍 |
| 资源优化 | 联合 `b,p,r,W`、边缘与功率 | `b,chi,r` 固定规则；复矩阵 `w` 优化，`p` 由范数派生；集中式 ADMM | 保存 210/420 轨迹功率可行，外轮/ADMM 达迭代上限；不称收敛 |
| 评价 | 协议体验、共同理想和独立功控基线，80%/10%/30% | 真信道 SE、容量/业务体验代理、分位数和功率摘要 | 部分保存字段/同输入对拍；协议样本和共同基线达标尚无证据 |
| 旧搜索 | 可扩展资源搜索 | 独立 `cf_search` 的 GA/PSO/PGSAO；旧评价器，条件适配 | 历史搜索结果独立；正式 `chasi_run` 不调用 |
| 非均匀鲁棒 | 测量质量与可信赋形 | `C_stat` 进入接收协方差及二次项；可选 `online_wmmse` 在快周期用更新的 H/C 重求 w | 后验一致性与显式输入对拍支持统计模型；在线重求仅1 UE小例通过；完整误差椭球、最坏情况及正式移动闭环拟研究 |

本材料中的“已验证”仅表示对应日志/脚本的既有证据范围，不把保存运行推广为系统验收。最新提交和报告仍需在集成前重新读取；若主线更新触及上述函数、配置或验证门槛，则重做对应公式、图及状态表的差异核对。

本轮只重跑一个轻量核查：在 `3efa44c` 检出执行 `matlab -batch "addpath('tests'); test_chasi_dynamic_online_wmmse"`，退出码 0，输出 `PASS miniature online WMMSE update, stop=max_outer_iterations_with_latest_inexact_admm`。它检查 1 UE 确定性回放的更新次数、波束变化、SE变化和功率界；停止原因仍为预算上限，不是收敛证明。
