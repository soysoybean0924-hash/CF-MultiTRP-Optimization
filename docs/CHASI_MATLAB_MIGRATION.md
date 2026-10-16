# CHASI 原生 MATLAB 迁移状态

> 本页保留 2026-10-16 首次原生迁移的运行证据和当时的 `V/U/W` 命名。当前正式输出的统一 $w/A/E/\Omega$ 记号、v2 字段、物理模型缺口与对拍状态见 [CHASI_NATIVE_V2_AUDIT.md](CHASI_NATIVE_V2_AUDIT.md)，完整公式及旧版差异见 [CHASI_UNIFIED_TRACE.pdf](CHASI_UNIFIED_TRACE.pdf)（[可编辑 TeX](CHASI_UNIFIED_TRACE.tex)）。不要按本页旧字段名读取新的 MAT 文件。

本表以 2026-10-16 当前源码为准。正式目标为 `matlab/chasi/chasi_run.m` 单进程完成配置、场景、估计、资源、矩阵求解、评价和保存；不执行 Python。此文件同时是本轮实施检查表，只有实际验证后才标记完成。

| 正式模块 | 迁移前 Python 实现 | 迁移前 MATLAB 状态 | 本轮原生位置 | 验证 |
|---|---|---|---|---|
| 配置和入口 | `chasi_formal_implementation/run.py`, `config.py`; `.m` 桥接调用 Python | 旧 `cf_default_config.m` 属不同模型 | `matlab/chasi/chasi_run.m`, `chasi_config.m` | 原生入口无 Python 调用，参数快照 |
| 场景和 CSI | `scenario.py`, `pathloss.py`, `srs_reuse.py` | 旧 `cf_generate_scenario.m` 不等价 | `matlab/chasi/chasi_generate_scene.m` | H/CSI 维度和独立生成 |
| 矩阵求解 | `solver.py` | 日期目录 `chasi_matrix_wmmse.m` 已有主体和小例对拍 | `matlab/chasi/chasi_matrix_wmmse.m` | 同输入 U/E/W、二次项、ADMM、功率 |
| 静态及业务评价 | `evaluate.py`, `traffic_model.py`, `second_metrics.py`, `burst_metrics.py` | 旧 CF 指标口径不同 | `matlab/chasi/chasi_evaluate.m`, `chasi_traffic.m`, `chasi_time_evolution.m` | 显式单链路同输入评价对拍；移动回放原生测试 |
| 结果 | `run.py` 的 JSON/NPZ/MAT | `.m` 桥接仅读取 Python 输出 | `matlab/chasi/chasi_run.m` | MAT/JSON/CSV、正式规模运行 |

## 符号与代码名称

| 旧名称 | 新名称 | 数学符号 | 含义和维度 | 影响位置 |
|---|---|---|---|---|
| 旧 `result.W` | `result.legacyBeamformer` | 旧 $W$, 非新 $W$ | 已含幅度的波束 `[Tx,stream,TRP,UE,group]` | 旧 `cf_evaluate_candidate.m` 及消费者；历史 MAT 未批量转换 |
| CHASI `V` | `precoderV` | $V$ | `[TRP,groupUE,Tx,rank]`，复数、含发射幅度 | 原生求解、评价、保存 |
| CHASI `U` | `receiverU` | $U$ | `[groupUE,Rx,rank]`，复数接收器 | 原生求解、保存 |
| CHASI `W` | `mseWeightW` | $W=E^{-1}$ | `[groupUE,rank,rank]` | 原生求解、保存 |
| CHASI `E` | `mseMatrixE` | $E$ | `[groupUE,rank,rank]` | U/W 更新、验证 |
| 旧搜索 `V` | `psoVelocity` | 无通信符号 | `[particle,searchDimension]` | 旧 `cf_search.m` |
| 旧 `U` | `numUEs` | $K$ | 标量用户数 | 旧候选评价器 |
| 旧 `Q` | 仍为局部 `Q` | $Q_{old}$ | `[Rx,UE,group,rank]` | 旧候选评价器；待内部改名 |
| 求解器协方差局部量 | 仍用局部简写 | $R_{yy}$ | `[Rx,Rx]` | 原生 U/E 更新；待内部改名 |
| 求解器等效信道局部量 | 仍用局部简写 | $G_{ki}$ | `[Rx,rank]` | 原生相干合并；待内部改名 |
| CG 残差、方向局部量 | 仍用局部简写 | $r_{CG},p_{CG}$ | 与预编码向量同形 | 原生 ADMM 线性解；待内部改名 |

此处同名不代表同变量：旧波束与新 V 只有物理类别相近，模型、索引和约束不同；PSO 速度 V 与预编码 V 无关。第三方 Python 参考仓库历史源码保留，但不属于正式入口。

## 验证摘要

原生 MATLAB R2026b 已执行配置、场景、矩阵求解、无协作基线、静态评价和移动回放的聚焦测试。`test_chasi_native_entry.m` 在 21 TRP、210 UE、273 RB、零外循环和缩小干扰范围条件下完成文件输出。这是入口连通测试，不是默认求解规模验收。

求解器同输入对拍使用显式 H、C、服务掩码、初始 V 与参数：`tests/chasi_export_canonical_parity.m` 读保存的五组输入，`tests/verify_chasi_canonical_parity.py` 对照保存的 Python 输出，外循环分别为 0 和 2。10 个案例均通过；最大绝对差：V `6.67e-16`、U `1.68e-16`、E `3.34e-16`、W `8.89e-16`、目标 `1.78e-15`、ADMM 原残差 `1.09e-16`。二次算子 M/B/D/QV 的各项差小于 `3e-16`。本地明细在 `tmp/chasi_canonical_parity_current/parity_report.json`，不提交大批输出。

静态评价另用显式单链路 H/V、资源权重、busy/tail/terminal 掩码与 Python `evaluate.evaluate` 保存参考对拍：`tests/chasi_export_evaluator_parity.m`、`tests/verify_chasi_evaluator_parity.py`、`tests/fixtures/chasi_eval_reference.json`。15 个速率、功率、PRB、业务和样本字段最大绝对差 `2.67e-15`；这是小例，不证明多用户干扰场景的全指标一致。

MATLAB 使用 MT19937，Python 使用 NumPy PCG64；相同 seed 不构成相同场景或业务样本。场景随机生成和移动轨迹尚无独立的跨语言同输入对拍。移动业务是容量/队列代理，不是已核实的接收端 ACK 计数。旧候选评价器的波束局部变量已改成 `legacyBeamformer` 等明确名称；旧链的 `Q` 等历史记号及新求解器若干局部简写仍待整理。当前旧链波束输出与新链 MSE 权重输出已区分。

建模边界：UE 上行 2Tx SRS 只对应 `srsRxRows=[1 2]` 两个下行接收行的互易性假设；其余下行 4Rx 信息由模型化的 CSI-RS 观测提供，未模拟真实射频端口校准。`matrix_statistical` 等实际估计信道分支用 H_est 求解、H_true 评价；`ideal` 对照分支按定义把 H_true 交给求解器。服务集合和调度由几何/资源规则确定，不把本次随机 H_true 矩阵用于这些决策。

默认 21 TRP、210 UE、273 RB、rank 2、2 次 WMMSE 外循环的 `matrix_statistical` 分支完成正式规模端到端运行：输出位于本地忽略目录 `results/chasi_matlab/formal_20261016_statistical/`。`summary.json` 记录优化目标 `58.5807699273603`、真实信道物理 sum-SE `68.1866955651523 bit/s/Hz`、210 个有效 UE、最大功率超限 `0 W`、运行 `801.04 s`。停止原因为 `max_outer_iterations_with_latest_inexact_admm`，`converged=false`；这是完成默认预算的运行证据，不是收敛或全局最优证明。输出包括 `scene.mat`、`matrix_statistical_precoders.mat`、逐 UE CSV、配置、事件和场景清单；原始本地结果不上传。

业务回放另以 21 TRP、210 UE、340 TTI、无协作基线、零外循环和限制干扰范围完成原生入口测试，输出本地 `results/chasi_matlab/replay_smoke_20261016_b/`，包含 `no_cooperation_time_evolution.mat`。回放有效 TTI 数 58679、完成 burst 2793、最大功率数值超限 `7.11e-15 W`。首次测试暴露零 RB 权重被基线误拒绝；按 Python `_weight` 允许零权重的定义修正后通过。这是语言等价性边界修复，不是调度或算法改动。

默认四分支也已在同一 MATLAB 原生 21 TRP、210 UE、273 RB 场景完整运行，输出位于本地 `results/chasi_matlab/formal_20261016_default/`，MATLAB 退出码为 0。各分支均保存预编码 MAT、逐 UE CSV，`summary.json` 的四个状态均为 `completed`，210 个 UE 均有有效样本：

| 分支 | 真实信道 sum-SE (bit/s/Hz) | 有效 UE 边缘 5% 体验 (Mbps) | 最大功率超限 (W) | 停止原因 |
|---|---:|---:|---:|---|
| `ideal` | 105.376798 | 17.096679 | 0 | 达到 2 次外循环上限，ADMM 未达内层容差 |
| `matrix_nominal` | 66.190224 | 4.316168 | 0 | 同上 |
| `matrix_statistical` | 68.186696 | 3.234964 | 0 | 同上 |
| `no_cooperation` | 65.811449 | 4.759397 | `7.11e-15` | 固定本地 MRT 规则完成 |

这是语言迁移的全链连通证据，不是算法收敛、全局最优、统计显著改善或华为体验验收证明。在该单场景，统计分支的边缘体验代理低于无协作基线，应作为负结果保留。场景随机生成和移动模型跨语言同输入对拍、`fixed_direction_power` 旧桥接可选分支、正式 ACK/RLC 体验口径及更充分的收敛验证仍未完成。

`matlab/chasi/chasi_run.m` 是本轮原生入口，调用 MATLAB 生成场景、CSI、求解、评价与保存。原 `experiments/chasi_formal/run_chasi_formal.m` 是保留在工作区的未跟踪 Python 桥接脚本，不能作为原生验证证据。运行命令：在仓库根目录执行 `addpath('matlab/chasi'); summary=chasi_run();`。
