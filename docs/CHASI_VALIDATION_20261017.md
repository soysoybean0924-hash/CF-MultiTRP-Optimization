# CHASI 代码修订与验证记录

## 最终导出与重读补记（2026-10-18）

最终字段版 420 UE 的 `matrix_statistical_precoders.mat` 已由 `chasi_load_precoder_result` 重读并确认 schema 3。基于**保存的同一份** `scene.mat` 导出只读探针后，独立 Python 检查得到：588 条建模链路、37632 个复数列样本，最大相对后验协方差误差 `6.8952e-8`，白化误差协方差相对 Frobenius 误差 `0.008503`。这检查保存的 `H_true/H_est/C` 内部统计一致性，不是两语言共用噪声样本的完整场景对拍。

同一运行的保存业务掩码与静态 SE 再计算得到 117140 个有效 UE×TTI；每 UE 体验速率最大差 `9.95e-14` Mbps，均值差 `1.07e-14` Mbps，5% 分位差 `4.44e-16` Mbps。它验证保存字段到当前汇总指标的读取链，不验证在线队列重求。`docs/chasi_native_atlas/` 的 12 张图已由 MATLAB 导出 PNG/矢量 PDF，修正图 07/08 的箭头与物理实体后重新渲染；12 页合并 PDF 与 14 页公式 PDF 已打开抽检。下表先前“保存→读回→绘图”一行的**待完成**状态由本补记更新为“静态保存与读回通过；动态在线及完整同输入场景对拍未通过”。

代码基线 `9527089`；本轮未修改 WMMSE/ADMM 数学、容差、迭代上限、功率口径或业务样本规则。正式 MATLAB 入口 `matlab/chasi/chasi_run.m:1` 直接调用原生 `chasi_generate_scene`、`chasi_traffic`、`chasi_matrix_wmmse` / `chasi_no_cooperation`、`chasi_evaluate` 和保存路径；静态调用链不包含 Python 解释器、Python 模块或预生成场景读取。Python 仅由测试命令单独运行。

静态检索 `matlab/chasi/` 的 `pyrun|py.|python|system(|readmatrix(|load(`：命中仅配置注释中的 Python 参考名称和两个**独立只读工具** `chasi_load_precoder_result.m`、`chasi_plot_topology.m` 的 `load`。正式 `chasi_run` 没有调用这两个读取工具，且从 `chasi_generate_scene` 新生成场景，不读 Python 生成的正式输入。

| 检查对象 | 输入与动作 | 实际结果／容差 | 状态与边界 |
|---|---|---|---|
| SRS 组数、RB和时间 | MATLAB `test_chasi_native_scene`, `test_chasi_srs_timing`, `test_chasi_native_entry`；红阶段原先分别因缺 `srsRbCounts`、缺 `srsHopIntervalTti`、把派生字段当未知选项而失败 | 修订后这三项 MATLAB 批处理退出码0；末组17RB，总273RB，20 TTI/跳 | 通过代码元数据/轻量运行；未生成波形 |
| 正式入口小预算 | 210 UE，`matrix_nominal`，正式 `chasi_run`、缩小求解预算 | 退出码0，真信道 sum SE 12.411529392… bit/s/Hz，最大功率违规0；summary/manifest Python 只读验证脚本退出0 | 通过原生入口连通性；不替代正式求解预算 |
| 同一显式输入求解器对拍 | `tests/chasi_export_canonical_parity.m` 导出 H/C/掩码/初值；独立 `tests/verify_chasi_canonical_parity.py`，5 fixture × 外轮0/2 | 全通过；最大目标绝对差1.776e-15，w 6.663e-16，A 1.671e-16，Ω 8.882e-16，E 3.331e-16，真sum SE 1.804e-16，功率1.11e-16，ADMM原始残差1.087e-16 | 求解器等价迁移通过；不是相同 seed 随机场景对拍 |
| 最终字段版 210 UE | 当前正式参数 `usersPerCell=10, matrix_statistical`；输出 `results/chasi_matlab/formal210_20261017_srs_contract2/` | MATLAB 批处理退出码0；solver 688.68s；真信道 sum SE 68.1866955652 bit/s/Hz，210/210 UE 按程序定义有效，功率违规0 W | **原生规模端到端通过**；`converged=false`，原因 `max_outer_iterations_with_latest_inexact_admm`，不代表物理验收 |
| 最终字段版 420 UE | 当前正式参数 `usersPerCell=20, matrix_statistical`；输出 `results/chasi_matlab/formal420_20261017_srs_contract2/` | MATLAB 批处理退出码0；solver 2252.46s；真信道 sum SE 95.1281554963 bit/s/Hz，420/420 UE 按程序定义有效，功率违规0 W；外轮目标26.84295→76.46299→82.85374 | **原生规模端到端通过**；`converged=false`，原因 `max_outer_iterations_with_latest_inexact_admm`，不代表物理验收 |
| 保存→读回→绘图 | 当前版本 `scene.mat`, `*_precoders.mat`, CSV/JSON，图集源 `build_chasi_atlas.m` | 待420完成后检查，图集未先占用实验MATLAB资源 | **未完成** |
| 完整场景/业务跨语言显式同输入 | 几何随机样本、信道、SRS噪声、估计、调度、固定到达/队列、在线更新 | 只有已有局部场景后验/业务探针和本轮求解器显式输入对拍；不能推出完整同输入场景等价 | **未通过完整要求** |

本地独立 Python 参考目录 `chasi_formal_implementation/` 当前为工作区既存未跟踪源码，不在本轮改名/提交范围。上述对拍确实在本地执行，但远端只含测试脚本时无法在新克隆中原样重跑 Python 对照；这是**证据可复现性缺口**，不是数值误差。提交前仅暂存本轮自建材料，不擅自纳入整套既存未跟踪实现。

来源类型：SRS 跳频定义来自原始 `典型验收场景.png`；3张原图与 `202609-系统方案.pdf` 属研究要求/方案；上述测试数值来自本轮实际运行；数学表达见 [公式 TeX](CHASI_UNIFIED_TRACE.tex)；未核实的物理常数归为项目假设，不把方案建议当已实现事实。

**停止理由的读法：** `status=completed` 只说明函数完成并保存可行输出；`reason=max_outer_iterations_with_latest_inexact_admm` 表示外轮达到上限且最近ADMM未满足内停；只有 `reason=relative_objective_precoder_and_admm_tolerance` 才表示代码定义的局部停止。两者都不构成全局最优证明。
`no_cooperation` 固定构造分支在 `chasi_no_cooperation.m:67-75` 设置 `converged=true`，它没有运行 WMMSE 迭代，此字段只能读作基线构造完成，不能解读为数值收敛。

## 文件覆盖与仍缺的证据

| 代码文件 | 本轮核查问题 | 结论 |
|---|---|---|
| `matlab/chasi/chasi_config.m`, `chasi_run.m` | 派生字段、正式入口、分支、保存 schema | 已修改 SRS 合同并实测小例；正式规模见上表 |
| `chasi_generate_scene.m` | 部署、真实/估计 H、误差 C、服务、调度、SRS末跳与年龄 | 已修改元数据及20TTI间隔；随机场景跨语言同输入未完成 |
| `chasi_matrix_wmmse.m`, `chasi_no_cooperation.m` | 初始化、A/E/Ω、Q/B/D、CG/ADMM/投影与基线 | 五组显式输入对拍；正式分支尚需完成本轮规模记录 |
| `chasi_evaluate.m`, `chasi_traffic.m` | 真信道SE、业务掩码、体验和输出字段 | 静态公式核查；严格协议样本与30%负载未通过 |
| `chasi_time_evolution.m`, `chasi_burst_metrics.m`, `chasi_second_metrics.m` | 可选动态与完成业务代理 | 与正式静态路径区分；完整在线WMMSE重求和动态同输入对拍未完成 |
| `chasi_load_precoder_result.m`, `chasi_plot_topology.m` | 历史字段只读转换、保存坐标可视化 | 转换隔离；图集示意坐标不冒充保存坐标 |
| `matlab/core/cf_evaluate_candidate.m`, `cf_search.m`, `cf_generate_scenario.m` | 旧 W/DU/GA/PSO 模型边界 | 只追调用和符号；未将旧链改造成正式 CHASI 链 |
| `chasi_formal_implementation/config.py,scenario.py,solver.py,evaluate.py,time_evolution.py` | 独立数值参考与对拍 | Python 不参与正式入口；未对其全部随机场景和动态回放建立共同显式随机输入 |

210/420 UE 的 `verify_chasi_saved_run.py` 和 `verify_chasi_scene_manifest.py` 均退出码0：两者皆21 TRP、17组、273数据/SRS测量RB；组内UE出现294/588次、服务边588/1176条、最大UE-TRP距离744.53/743.92m（两样本皆无超过750m的几何链路）。与旧 `formal210_20261017_schema3_named_final` / `formal420_20261017_schema3_named_final` 对照，目标、真信道sum SE、每TRP功率、停止原因逐项完全相同；420体验均值/5%分位及实际PRB比例也完全相同。只有 SRS 元数据合同发生变化。420实际忙UE×TTI比例0.865014，实际PRB比例0.409978，说明名义 `trafficLoad=.30` 尚未兑现为正式负载定义。

代码中仍缺源码支持的物理过程：8×4×2双极化阵列、校准后的上/下行互易映射、逐 RB SRS/CSI-RS 波形、真正前传数据/消息、分布式 TRP 求解、协议级 ACK/RLC/BLER 和严格业务验收分母。不能因公式源给出理论信号式，就把这些标为已实现。
