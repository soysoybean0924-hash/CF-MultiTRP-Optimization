# CHASI 代码修订与验证记录

## 2026-10-18 Ω 绝对门槛失败的定位与修复（提交 `9b591cc`）

**上游同底层输入的已核查范围：**`chasi_export_geometry_common.m` 与 `verify_chasi_geometry_common.py` 使用完全相同的显式角度／径向均匀数组，得到21 TRP位置差0、210 UE位置最大差 `1.1369e-13 m`、home ID完全相同。它验证坐标映射，不验证两语言各自随机发生器或随后的调度、链路增益、H_true、SRS/CSI抽样。Python参考场景/回放原先把 SRS 间隔写死20 TTI；`test_srs_hop_timing.py` 在170 TTI周期先失败，改为 `srs_period_tti/srs_hops` 并校验整数后通过，默认340/20的210 UE冻结波束业务对拍仍通过。

**可选动态在线路径：**`chasi_time_evolution.m` 新增 `beamPolicy='online_wmmse'`，在已更新的估计 H/C 上、按既有 `fastPeriodTti` 调用原生 `chasi_matrix_wmmse`，并以返回的可行预编码计算后续真信道速率及队列。`test_chasi_dynamic_online_wmmse.m` 先因未知策略失败；1 UE确定性零速度轨迹修复后通过，确认更新次数1、新旧预编码不同、真信道时间平均SE与冻结波束不同、功率违规小于 `1e-8 W`。该模式保留固定调度／服务集／rank，沿用项目Gauss--Markov、SRS/CSI与业务代理假设；没有正式210/420 UE移动闭环运行，也没有与Python在线路径对拍，不代表物理或业务验收。

**入口与场景回归：**正式入口现通过 `timeEvolutionBeamPolicy` 显式选择动态策略，默认仍是 `estimated_svd`，静态路径 `timeEvolutionTti=0` 不执行回放。场景抽样按原随机流的 TRP 顺序收集角度、半径均匀数，再交给共用的纯几何映射；重建修复前正式210 UE `scene.mat`，21 TRP位置、210 UE位置、home、调度掩码和第1资源组 `H_true` 均逐元素相等。共同底层均匀数组跨语言几何检查仍仅覆盖拓扑，不扩展为完整输入生成等价结论。

**当前210 UE冻结波束回放对拍：**使用同一修复版210 UE静态输入、最终 w 与新导出的零速度 `busy/tail/terminal` 回放，事件和计数一致；每UE交付量最大差 `5.465e-16 Mbit`，平均体验、真信道时间平均 sum SE、PRB比例与功率违规差均为0，按预设门槛通过。它仅覆盖冻结 w 的业务聚合，不能证明变化 CSI、在线重求或资源反馈跨语言等价。

**最终字段版420 UE静态运行：**MATLAB 原生入口独立生成并保存，`matrix_statistical` 求解耗时 `2559.664 s`，目标 `82.8537421422`、真信道 sum SE `95.1281555163 bit/s/Hz`、最大功率违规 `0 W`；第2外轮目标相对变化 `0.0835797`、预编码变化 `0.219672`，第1外轮的12步 ADMM 末值原始 `0.0389884>0.0210251`、对偶 `0.0263877>0.0126029`、CG相对残差 `1.32717e-5`。停止为 `max_outer_iterations_with_latest_inexact_admm`，`converged=false`。该运行采用新双精度求解字段，但发生在几何纯函数接入及可选动态配置字段加入之前；上述场景逐元素回归说明几何改写保持该冻结输入的结果，不将其称为改写后新运行。420 UE Python 同输入对拍见 `CHASI_PARITY_420_20261019.json`。

**420 UE完整求解同输入对拍：**从该原生运行导出同一 H_est/H_true/C、掩码、全局 UE 映射、初始 w、权重及停止参数，Python 独立重求，预设绝对门槛保持不变。初始 Ω 最大差 `3.553e-15`、最终固定 w 的 Ω 最大差 `1.954e-14`（原门槛 `1e-5`）；二次项最大差 `6.667e-16`，完整目标差0、最终 w 最大差 `3.387e-15`、真信道 sum SE 差 `9.921e-7`，功率违规0，ADMM轨迹残差最大差 `1.332e-15`；停止原因完全一致，`full_scale_pass=true`。显式输入和场景是本地大文件，不入库；`scene.mat` SHA256 `F973ED5F01835E944EB5E04A24E775BF2675590CBFA651AEBBDA862C657DDB6D`。数值等价与停止原因一致不等于已满足收敛停止条件。

在最终几何函数接入后又用保存的420 UE配置原生重建场景，`trp_xy`、`ue_xy`、`home`、`scheduleMask` 及**全部17组** `H_true/H_est` 均逐元素相等，MATLAB 批处理退出码0。该比对确认此次几何代码重构没有改变该冻结场景输入；它不等于把后续完整420 UE优化再运行一次。

保留下面原始 `1e-5` 门槛和历史失败：保存的210 UE旧状态在**第10组／局部UE18／全局UE208／Ω(1,1)** 的最大绝对差 `1.1981398456644364e-5`，相对该元素 `1.406545e-6`，相对 Ω 矩阵 Frobenius 范数 `1.085138e-6`。原保存结果 A 差 `9.1587e-8`、E 差 `1.6319e-7`；同一保存 E 在 Python 求逆与保存 Ω 的差 `1.7776e-7`，说明主要误差先出现在计算 E 以前。E 条件数 `1.18074`、最小特征值 `0.11695`、Hermitian 缺陷0，Ω Hermitian 缺陷 `2.1074e-8`、线性残差 `||EΩ-I||_F=3.1062e-8`；并无病态矩阵或截断导致的证据。

追到存储与乘法边界：保存 `H` 为 `complex64`、`C_stat` 为 `float32`，预编码 `w` 为 `complex128`。旧 MATLAB `state` 将单精度 H/C 直接参加矩阵乘法，Python 对照在加载时将二者转换为双精度。`tests/test_chasi_solver_mixed_precision.m` 在修复前相同数值的 single/double 存储得到 Ω 差 `1.52e-7`（测试按 `1e-12` 断言失败）；`chasi_matrix_wmmse>prepareResources` 在数值计算前显式转换 H、C、H_true 为 double 后，该差为0。使用**同一份历史 w** 重新计算第10组，当前 MATLAB 与 Python 的 Ω 差 `6.2173e-15`、E 差 `2.1089e-16`；保存旧 Ω 与重算 Ω 差仍是 `1.1981398456644364e-5`。故历史 `fixed_input_pass=false` 不改判，新 `current_fixed_input_pass=true` 是另一次计算。完整旧初始状态因精度修复而不再严格等于重建初态，不能用它冒充同初值完整轨迹对拍。

按**修复后正式 MATLAB 入口新生成**的同配置210 UE场景、求解和保存，静态全链退出码0，solver `671.073 s`、真信道 sum SE `68.1866940127 bit/s/Hz`、功率违规0；同显式输入固定状态 Python 对拍：初始 A/E/Ω 最大差 `5.3291e-15`，最终 A/E/Ω 最大差 `2.3093e-14`，原绝对门槛下通过。历史输出 `68.1866955652` 与新输出之差是语言精度修订后的运行差，不是目标或模型改动。新运行仍以 `max_outer_iterations_with_latest_inexact_admm` 停止，`converged=false`；不能从对拍通过推断算法收敛。

固定 A/Ω 的独立小例用 SciPy SLSQP 验证复二次目标与跨组功率约束：ADMM 与参考目标绝对差 `6.1996e-10`、功率可行，但极严格 `1e-9/1e-8` 测试容差下600步仍未满足残差停止。它验证小例子问题目标，**不证明正式规模12步足够**。正式210新运行末轮仍有原始残差 `0.0369995>0.0172353`、对偶残差 `0.0367336>0.0089010`，CG残差 `1.4409e-5` 小于 `1e-3`；代码中的 `inexact` 精确定义为内层在12步内未同时满足原始残差、对偶残差和CG三个条件。外层在第2轮上限前相对目标变化 `0.161877`、预编码变化 `0.271840`，均远高于原停止门槛，两个迭代预算先耗尽。

随后在**同一显式210 UE初始 H/C/w、固定 A/Ω** 上，`tests/diagnose_chasi_admm_budget.py` 只改变单个子问题的最大内步数，原阈值、目标和预算不变：上限12步时对偶 `0.0917273>0.0088897`，固定二次目标 `-35.28483`；24步对偶 `0.0271693>0.0088946`、目标 `-36.45040`；48步对偶 `0.00996265>0.00889509`、目标 `-36.60062`；允许96步时实际第52步满足原始／对偶／CG条件，对偶 `0.00873410<0.00889512`、目标 `-36.60748`，各次功率违规0。**这是固定子问题的预算诊断，非正式算法参数修订，更不能推出两轮外层已经收敛。** 因而已定位该状态下12步不够，未排除后续外轮所需更多迭代、其他资源状态的尺度问题及正式理论收敛条件。

## 2026-10-18 同显式输入正式规模复核与停止诊断

`tests/chasi_export_formal_shared_input.m` 从已保存的**原生 MATLAB** 210/420 UE 场景、业务掩码和最终解导出 H_est/H_true、4×4 误差协方差、全局 UE 映射、服务掩码、RB 权重、功率预算、初始/最终预编码、初始 A/E/Ω/η 及二次项。它重建初值并断言与原运行轨迹首点一致。`tests/verify_chasi_formal_shared_input.py` 独立读取**同一份显式输入**，以预先写定的绝对容差比较；Python 只在离线测试运行，正式入口不调用它。下表记录实际逐层误差与判断；大型共享 MAT 仅留本地 `tmp/`，不入库。

| 层次（绝对误差） | 预设阈值 | 210 UE | 420 UE |
|---|---:|---:|---:|
| 初始目标 | 1e-6 | 2.3002e-7 | 6.7110e-8 |
| 初始 A/E/Ω 最大值 | 1e-5 | 4.4079e-6 | 1.2896e-6 |
| 初始二次项 M/B/D/Qw 最大值 | 1e-4 | 5.6069e-7 | 2.3274e-7 |
| 固定最终 w 的 A/E/Ω 最大值 | 1e-5 | **1.1982e-5（Ω，未通过）** | 5.2035e-6 |
| 固定 w 的目标与真实信道/业务评价最大值 | 1e-4 | 5.1983e-7 | 9.8324e-7 |
| 完整求解：目标／w／真信道 sum SE | 1e-4／2e-3／1e-4 | 5.3419e-7／4.3141e-6／4.4601e-7 | 2.4353e-7／7.9411e-7／1.0907e-6 |
| 外轮与 ADMM 残差轨迹最大值（CG单列） | 1e-4（CG 1e-3） | 5.9597e-6（CG 1.1329e-7） | 9.4604e-7（CG 1.3500e-8） |
| 功率超预算 | 1e-6 W | 0 W | 0 W |

210 的 Ω 最大绝对差相对该矩阵最大幅值为 `1.215e-6`；其 A、E、二次项、完整 w、目标和真信道指标均过阈值，但**固定状态严格门槛仍判未通过**，不能把相对差替换原先阈值。420 全部通过。两侧完整求解的停止原因完全一致，均为 `max_outer_iterations_with_latest_inexact_admm`。这里比较的是已生成正式场景的求解及评价，不证明两语言用同随机样本生成拓扑、SRS 噪声及后验，也不证明在线动态闭环。

两份已保存轨迹表明：210 UE 外层目标 `14.93946→50.41909→58.58077`，末次相对变化 `0.16188`、预编码变化 `0.27184`；420 UE 为 `26.84295→76.46299→82.85374`，末次相对变化 `0.08358`、预编码变化 `0.21967`。最后一次内层在各自 12 次上限停下：210 原始残差 `0.0369995 > 0.0172353`，对偶残差 `0.0367336 > 0.008901`；420 为 `0.038988 > 0.021025`、`0.026388 > 0.012603`。CG 相对残差约 `1.44e-5`／`1.33e-5`，功率违规0；现有证据指向**外轮与内层迭代预算先耗尽、并非 CG 精度或功率不可行**，不等于证明只增加次数即可收敛。此处未改容差、目标和上限。当前 SRS 摘要删去了误导性的 `srs_nominal_hop_rb=273` 别名；原始 210/420 数值运行发生在该纯元数据修订之前，小入口回归已对现行输出字段通过，不能称其为新字段版完整重跑。

可选动态回放的独立一致性缺陷另行修正：此前 `chasi_time_evolution` 将步长、SRS组编号、RB×TTI统计和 Doppler 时间增量写死为20 TTI/17组，而 `chasi_config` 已允许合法的 `srsPeriodTti=170`、每跳10 TTI。`tests/test_chasi_dynamic_srs_timing.m` 在旧实现先因窗口校验失败；修订后同一显式业务掩码运行退出码0，17个事件的前三个时刻为0/10/20 TTI、组号1/2/3，新增 `srs_hop_interval_tti` 与 `fading_correlation_per_srs_hop` 清楚标注含义。正式默认仍是340/20；这是**非默认配置的实现修复**，不是改变正式求解器或证明动态跨语言等价。可选回放仍无随新 CSI 调用矩阵 WMMSE 的在线闭环，随机信道演化与队列跨语言同显式输入对拍仍待完成。

业务回放的**受限同输入对拍已通过**：`tests/chasi_export_dynamic_shared_replay.m` 用保存的210 UE场景、最终 `precoder` 和同一340 TTI `busy/tail/terminal`，将速度设为0、波束设为 `frozen`；`tests/verify_chasi_dynamic_shared_replay.py` 把该显式业务掩码送入独立 Python 回放。判断前固定的容差为每UE交付量/体验速率/真信道SE各 `1e-4`、PRB比例 `1e-8`、功率违规 `1e-6 W`。17个事件的时刻/SRS组/CSI事件相同，有效TTI、完成及总burst计数相同；复查时每UE交付 Mbit 最大绝对差 `7.1055e-15`，平均体验、时间平均真信道 sum SE、PRB比例及功率违规差均为0。两侧估计 CSI 更新仍使用各自随机数，但在零速度及冻结波束设置下不影响发射容量；**不构成随机 CSI 轨迹或在线 WMMSE 重优化的跨语言等价证明**。共享大 MAT 只保留本地 `tmp/`，不入库。

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
| 完整场景/业务跨语言显式同输入 | 几何随机样本、信道、SRS噪声、估计、调度、固定到达/队列、在线更新 | 已对**保存的正式场景及业务掩码**完成210/420求解与固定输入评价；另在210 UE零速度、冻结波束条件下完成固定到达/队列回放对拍。两语言从同一原始随机样本逐层生成拓扑/测量、移动CSI轨迹及在线重求仍无同输入证据 | **部分通过，完整要求未通过** |

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
