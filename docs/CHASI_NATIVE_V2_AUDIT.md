# CHASI MATLAB 主线：命名、模型边界和验证（2026-10-16）

本页以 `matlab/chasi/chasi_run.m` 的当前源码为准。历史审计 `full_trace_20261014/` 保留原状，反映当时 Python 主线与 `V/U/W` 记号，不能代表此版入口。公式全集的可编辑源是 [CHASI_UNIFIED_TRACE.tex](CHASI_UNIFIED_TRACE.tex)，PDF 是其导出件。本轮没有把未获物理依据的参数修正混进等价迁移。

## 实际调用与保存

`chasi_run(options)` → `chasi_config` → `chasi_generate_scene`（`geometry`、`schedule`、`link_gain`、独立/复用 SRS 后验）→ `chasi_traffic` → 对各分支调用 `chasi_matrix_wmmse` 或 `chasi_no_cooperation` → `chasi_evaluate` → 可选 `chasi_time_evolution` → JSON/MAT/CSV。此路径不调用 Python。`experiments/chasi_formal/run_chasi_formal.m` 是未接入的旧 Python 桥接；`chasi_formal_implementation/` 是参考与对拍源。

在仓库根目录执行 `run('setup_project_paths.m'); summary=chasi_run(struct('usersPerCell',10,'branches',{{'matrix_statistical'}}));` 可启动原生 210 UE 场景；20 UE/小区对应 420 UE。`setup_project_paths.m` 现已显式加入 `matlab/chasi`。正式运行不读 Python 预生成输入；对拍脚本独立运行。

目前 MATLAB 原生输出的 `resultSchemaVersion=2`；`*_precoders.mat` 保存 `precoder`、`rxCombiner`、`mseMatrix`、`mseWeight`、`userWeight`、`scheduleMask`、`servingMask`、`ueIDs`、`numStreams`。`scene.scheduleMask[u,g]` 是全局 UE 的资源组调度，`resources(g).servingMask[l,k]` 是组内 UE 对 TRP 的服务关联，`resources(g).ue_ids[k]` 明确从组内 `k` 映射到全局 `u`。二者不能合并成一个 `b`；本版用 $b_{ug}$ 表示调度，服务关系另记 $a_{lkg}$。正式结果不以裸 `W` 同时表示波束和 MSE 权重。历史 MAT 原字段仅在历史证据中保留，未批量修改。

历史 CHASI v1 `*_precoders.mat` 仅通过只读 `chasi_load_precoder_result.m` 转为当前内部字段；缺失的 `scheduleMask` 和 `userWeight` 明确为空，不能由历史文件猜测。它拒绝将旧 CF `result.W` 当作同一矩阵预编码；正式求解入口从不调用此读取器。

| 旧名／来源 | 当前数学符号 | 当前代码／保存字段 | 含义、维度 | 变更类别 |
|---|---|---|---|---|
| CF 旧 `W`, `result.W` | $w^{\rm old}_{r u s g}$ | `legacyBeamformer`, `result.legacyBeamformer` | 含实际幅度的 DU 波束，`[Tx,stream,DU,UE,RBG]`；`p=Σ_s‖w‖²` | 仅改名；旧评价模型仍独立 |
| Python/迁移版 `V`, `precoderV` | $w_{l j g}$ | `precoder` | 含实际幅度的联合预编码，`[TRP,groupUE,Tx,stream]`，cell 按组；不再另乘 $\sqrt p$ | 仅改名，矩阵模型与旧链不同 |
| Python/迁移版 `U`, `receiverU` | $A_{kg}$ | `rxCombiner` | 复接收器 `[groupUE,Rx,stream]` | 仅改名 |
| Python/迁移版 `E`, `mseMatrixE` | $E_{kg}$ | `mseMatrix` | Hermitian MSE `[groupUE,stream,stream]` | 仅改名 |
| Python/迁移版 `W`, `mseWeightW` | $\Omega_{kg}=E_{kg}^{-1}$ | `mseWeight` | MSE 权重 `[groupUE,stream,stream]`；绝非旧波束 | 仅改名 |
| Python `userWeights`, `final_user_weights` | $\eta_{ug}$ | `userWeight` | 目标导数/用户标量权重，按组局部 UE cell | 仅改名 |
| Python/迁移版 `serve` | $a_{lkg}$ | `servingMask` | `[TRP,groupUE]`；服务集限制 $w$ 的非零块 | 仅改名 |
| Python 的组内 `ue_ids` | $u(k,g)$ | `ueIDs` / `ue_ids` | 组内到全局 UE 一基索引 | 保持显式映射 |
| 旧 PSO `V` | 非通信量 | `psoVelocity` | 粒子速度；与预编码无关 | 仅改名 |
| 旧 UE 数 `U` | $K$ | `numUEs` | 全局 UE 个数；与接收器无关 | 仅改名 |
| 参考仓库标量 `v_k` | 参考文献接收器 | 无正式字段 | 固定方向单流模型的标量，与本版矩阵 $w$ 不同 | 无源码继承接口 |

上述旧 `W` 与新 $w$ 只对应“发射线性映射”这个物理类别。旧链按 DU/RBG 作逐流投影并更新波束，新的矩阵链按 TRP 跨资源组功率预算直接优化复矩阵；没有旧波束到新矩阵的正式赋值、导入或等价转换。旧 $Q$ 是流合并方向，新 $A$ 是 MMSE 接收器，也不是直接改名关系。

### 核心变量完整去向

| 量（维度、单位） | 首次产生→更新／形状变化 | 消费者→保存／图表 |
|---|---|---|
| $d_{ul}$ `[UE,TRP]` m、站/UE坐标 `[21,2]/[N,2]` m | `chasi_generate_scene>geometry` 坐标；主循环逐UE/TRP算距离→`link_gain` | 生成大尺度增益、home/最近TRP和750m截断；坐标到 `scene.mat`/`scene_manifest.json`，完整距离阵未保存 |
| $H^{true},\widehat H$ `[K_g,21,4,64]`，归一化幅度 | `chasi_generate_scene` 真H→CSI-RS/SRS观测→后验H；`ideal` 求解分支暂将真H置为优化可见H | `state/trueRates/chasi_evaluate`；每组 `scene.resources` 到 `scene.mat`；非理想分支真H只生成观测与最终评价 |
| $C,C_{stat}$ `[K_g,21,4,4]`，归一化误差协方差 | C11/C12后验→`prepareResources` 依分支取零、原值或统一误差；`C_stat` 原值保留 | `state/quadratic`；`scene.mat`，未生成完整64列交叉协方差 |
| $b_{ug}$ `[N,17]` bool；$a_{lkg}$ `[21,K_g]` bool | `schedule` 选组内 UE→`scene.scheduleMask`；组循环按 home+最近TRP→`servingMask` | 限制 $w$ 非零；`scene.mat`、`scene_manifest.json`、v2 precoders MAT；旧 `b[R,U,G]` 为另一对象 |
| $w_{ljg}$ `[21,K_g,64,r]`，幅度按 $\sqrt{\mathrm W}$ 解释 | `chasi_matrix_wmmse` SVD→功率投影→ADMM 可行 `z`→回溯更新；`no_cooperation` 本地SVD单独产生 | `state/qapply/chasi_evaluate/chasi_time_evolution`；v2 MAT `precoder`；TRP功率、真SE、业务率间接进 JSON/CSV |
| $p_l=\sum_ga_g\sum_j\|w_{ljg}\|^2$ `[21,1]` W | `chasi_power` 每次由当前 $w$ 重算；不是另乘于发射符号的独立因子 | `project`、轨迹、`summary.branches.*.per_trp_power_watt`、评价总辐射功率 |
| $A$ `[K_g,4,r]`；$E,\Omega$ `[K_g,r,r]` | `state` 根据H/C/w算接收协方差→`A=R^{-1}F`→E→`Omega=E^{-1}`；每WMMSE外轮重算 | `quadratic` 固定为子问题系数；v2 MAT 各自保存，不把 Omega 当波束 |
| $\eta$ `[K_g,1]` 无量纲 | `objectiveSnapshot` 由 PF 率导数、固定边缘权重或1生成；按 `ue_ids` 从全局映回局部 | `quadratic`；v2 MAT `userWeight`；决定优化代理，不是无线功率 |
| ADMM $x,z,y$ 各 `[21,K_g,64,r]`、$\rho$ 标量；CG 残差/方向同形 | `precoder_admm` 从当前w初始化；CG→投影→对偶，rho每10轮按残差调节 | 可行 `z` 回WMMSE；轨迹残差和功率到 `summary.json`；内部x/y不单独保存 |
| $R^{SE,true}$ `[K_g,1]` bit/s/Hz；全局UE率 `[N,1]` | `chasi_evaluate>true_rates` 用真H和最终w的两个logdet；按 `ue_ids` 和 RB 权重聚合 | 物理率、体验、分位数；`*_per_ue.csv`、`summary.json`；未生成调制符号或实际接收波形 |

组内 `k` 通过 `ue_ids` 映射到全局 `u`，预编码的四维 cell 不存在额外的全局UE轴。`H(k,l,:,:)` reshape 为 `[4,64]`，`precoder(l,j,:,:)` reshape 为 `[64,r]`，两者相乘为 `[4,r]`；MATLAB `'` 是共轭转置，`reshape` 不改变天线/流轴的定义。计算 $\sum_lH_{kl}w_{lj}$ 时先跨TRP做复幅度相加，随后取协方差。当前没有64端口与8×4×2物理阵列的映射或真实前传数组。

## 物理模型核查与状态

| 疑点 | 源码事实及位置 | 状态／影响 |
|---|---|---|
| 7站×3扇区、300 m | `chasi_generate_scene>geometry`：中心 `(450,450)`，6站在半径300 m 的正六角顶点；每站3个 TRP 同坐标，扇区主方向 $0,120,240^\circ$；21小区各有10/15/20 UE。300 m 是中心到六邻站的站址间距，不是小区半径或覆盖保证。 | 已核实。扇区方向仅进简化方向增益。 |
| UE 区域 | $r=25+125\sqrt{U}$、角度在对应120°扇区均匀。$r$ 在25–150 m，但环形区域面积均匀应使用 $r=\sqrt{25^2+(150^2-25^2)U}$。 | 已核实为非面积均匀。验收图片没有给可核实的精确小区几何/边界坐标；修改会改变场景，当前不把它混进迁移等价对拍。 |
| 0.08、0.92、方向图指数4、0.025、100 m、3.2、相关0.35、750 m | 分别在 `link_gain`、`geometry`、`rx=0.35^|i-j|` 和距离截断处。Python `config.py`/`scenario.py` 已先使用相同值；未在本轮找到对应原图、标准条文或论文的逐值来源。 | 项目建模假设，不能称标准校准。750 m 外非服务链路 H 为零，`omitted_gain` 只做诊断，实际真信道评价遗漏该干扰。 |
| 路损与单位 | 默认 `geometry_correlated_surrogate` 为无量纲归一化增益；另有 UMi/UMa 路损子集，以3.5 GHz、10/25 m 站高、1.5 m UE 高、LOS/NLOS 阴影并除 `noiseWattPerRb*rbTotal`。`noiseWattPerRb=1e-10`，273 RB ×12×30kHz=98.28 MHz。 | 已核实；默认不能宣传为标准 UMa/UMi 或真实 W→SNR 标定。两个模式不同口径，不可混合比较。 |
| 阵列、端口与rank | `H[UE,TRP,4,64]` 的64列由独立高斯抽样产生，只加4×4接收相关；没有8×4×2的阵列流形、极化耦合或端口映射。rank 当前2，上限由下行4Rx与64Tx决定，UE上行2Tx只限制 SRS 可探测端口。 | 64优化维度已实现，二维双极化物理阵列尚未实现。 |
| 2Tx/4Rx 与 SRS | `srsRxRows=[1,2]` 把两个上行端口视为下行4接收行中的两行；4行 CSI-RS 观测另以合成高斯噪声产生。没有波形、TDD 校准或真实端口映射。C11 是独立观测后验；C12 复用导频为条件高斯边际更新，丢弃共导频 UE 交叉后验块。 | 模型假设，不能称完整实测下行 CSI。`C[4,4]` 是每发射列共享的接收协方差，完整误差假设为 $I_{64}\otimes C$。 |
| SRS 时间和273 RB | `srsPeriodTti=340`，每20 TTI 一跳17组；数据组16×16+17=273。`measured` 当前按整组布尔值，末组17个数据RB都使用同一测量后验。17×16=272，原图“每跳16RB”不能推出末跳测17RB。 | 已核实语义冲突，末组第273 RB的独立测量状态尚未实现；不可宣称 SRS 全273RB覆盖。当前 `summary.scenario.srs_coverage_rb` 是代码覆盖计数，需理解为模型组覆盖，非实际SRS 16RB覆盖。 |
| 功率和负载 | `chasi_matrix_wmmse>chasi_power/project` 用 $\sum_g n_g/273\sum_j\|w_{ljg}\|_F^2\le20$，按 TRP 跨组；20 W 是 Python 参考配置假设，不能由64端口反推。`prbUtilization=.40` 控制激活 RB，`trafficLoad=.30` 控制独立 burst 生成，不等于30% RB激活或正式 offered load。 | 已核实，功率物理口径与业务负载验收定义尚无原图依据。 |
| DU 与 TRP | 旧 `cf_generate_scenario` 的 DU 是旧配置中的站点/发射对象；旧波束以 DU 轴和每 DU/RBG 限额组织。新链是每站3共址扇区 TRP、每 TRP 跨组限额。 | 模型对象不同；不能把旧 DU 索引机械映射成新 TRP。 |

站/TRP/小区映射固定为 `siteId=ceil(l/3)`、`sectorId=mod(l-1,3)+1`、`cellId=l`，其中 $l=1,\ldots,21$。所以站1→TRP1–3、小区1–3；站2→TRP4–6；依次至站7→TRP19–21。每小区10 UE时全局210，20 UE时420，`home` 按 TRP 顺序重复相应次数。实际抽样坐标见 [210 UE 保存场景拓扑 PNG](CHASI_TOPOLOGY_210_SAVED.png)（[矢量PDF](CHASI_TOPOLOGY_210_SAVED.pdf)，由 `matlab/chasi/chasi_plot_topology.m` 读取已有 `scene.mat` 生成）；图只显示第1资源组服务连线，其他 UE 为灰点，CPU 是计算概念而非无线坐标。图没有将未画的非服务干扰误标为不存在。

## 与上一版的实质差异

| 类别 | 此版变化 | 数学/评价数值是否应改变 |
|---|---|---|
| 仅符号变化 | 旧输出 `precoderV/receiverU/mseWeightW/mseMatrixE` 改语义字段；显式调度/服务掩码；`V/U/W` 改 $w/A/\Omega$。 | 不应改变；同输入对拍负责检查。 |
| MATLAB 迁移 | 相对于 `full_trace_20261014` 的 Python正式链，`chasi_run` 已本地生成/求解/评价/保存。 | MATLAB 与 Python RNG 不同，同seed结果不能直接比较。 |
| 模型变化 | 本轮未修改部署、信道、SRS、调度或速率算法；上表列出所需的未来单独模型版本。 | 无。 |
| 口径变化 | 本轮未改变负载/噪声/功率/评价口径。 | 无。 |
| 尚未完成 | 第273 RB测量粒度、严格面积均匀区、真实阵列/端口、原图功率与业务口径、跨语言同输入场景与动态业务对拍。 | 不能据当前运行声称物理模型验收。 |

## 验证记录与边界

### C24 起实际函数接口

| 公式 | 真实函数签名与位置 | 输入字段/数学作用 | 输出与下一消费者 |
|---|---|---|---|
| C24 | `quadratic(H,C,rxCombiner,mseWeight,userWeights)`，`chasi_matrix_wmmse.m:399` | 估计信道、误差统计、固定 $A,\Omega,\eta$；$H[K_g,L,4,64]$、$C[K_g,L,4,4]$ | `parts.M/B/D` → `qapply`、`precoder_admm`；仅优化系数 |
| C25 | `qapply(H,parts,x,mask)`，`:416` | 估计信道、二次系数、试探矩阵 `[L,K_g,64,r]`、服务掩码 | 同形 $Q(x)$ → CG 线性算子及固定二次目标 |
| C26–C27 | `precoder_admm(resources,parts,initial,cfg)`，`:436` | 每组资源、二次系数、当前可行预编码、预算和停止阈值 | 可行副本 `z`、逐步 `history`、内层 `converged` → WMMSE 回溯 |
| C28 | `cg(apply,b,x,maxiter,tol)`，`:481` | 算子、右端、初值、迭代上限/相对阈值 | 近似原变量 `x` → 功率投影 |
| C29 | `project(resources,x,budget)` 与 `projectedpower(resources,x,l,lambda)`，`:495,:514` | 每组 RB 权重、服务掩码、每 TRP 总预算 | 可行副本 `z` → 对偶更新及返回外轮 |
| C30 | `precoder_admm` 内部 `history`，`:436` | $x,z,y,\rho$ 与 CG 残差 | 原/对偶残差及阈值 → 内层停止和 `summary.trajectory` |
| C31 | `chasi_matrix_wmmse(resources,cfg,initialPrecoder)`，`:1` | 组资源与初始预编码；先 `state` 得 $A,E,\Omega$ | `solution.precoder` → `chasi_evaluate(scene,solution,traffic)` → `chasi_run` 保存 |

上述局部函数的上一调用者均为 `chasi_matrix_wmmse`；`cg` 由 `precoder_admm` 调用，`qapply` 被 CG 算子及诊断调用。函数未作为独立物理发送模块使用。

`tests/chasi_export_canonical_parity.m` 读取五组显式复数 H、C、服务掩码、初始预编码，经**历史输入字段转换**喂给当前 MATLAB 求解器；`tests/verify_chasi_canonical_parity.py` 只做离线对照。对拍检查预编码、接收器、MSE/权重、二次算子、功率、ADMM残差、目标、真实信道率与停止原因。`tests/chasi_export_evaluator_parity.m` 对显式一链路 H、w 和业务掩码作评价对拍。两者都不是完整场景生成的跨语言逐数组对拍。

本版服务掩码字段转换后，5组×外轮上限0/2均通过：最大目标绝对差 `1.78e-15`，预编码元素差 `6.67e-16`，接收器 `1.68e-16`，MSE `3.33e-16`，权重 `8.88e-16`，功率 `1.11e-16 W`，ADMM原残差 `1.09e-16`；停止原因完全一致。显式单链路评价对拍的各数值字段最大绝对差 `2.67e-15`。这些是等价迁移证据，不是新物理模型验收。

本轮 MATLAB R2026b 跑过 `test_chasi_native_solver`、`test_chasi_no_cooperation`、`test_chasi_native_evaluate`、`test_chasi_native_time_evolution`、`test_chasi_native_entry`；前次已完成的210 UE 四分支全链证据在 `results/chasi_matlab/formal_20261016_default/`，该目录本地保留。420 UE 本轮原生 MATLAB 运行 `results/chasi_matlab/formal420_20261016_v2/` 已以退出码0完成：`matrix_statistical` 用时4318.29 s，真实信道 sum SE 为95.1282 bit/s/Hz、420/420 UE有有效样本、最大功率违规0 W，停止原因 `max_outer_iterations_with_latest_inexact_admm`。这次运行开始于最终 `servingMask/scheduleMask` 保存字段改名之前，求解数学不变，但其 MAT 文件仍保存旧字段。随后当前字段版 `results/chasi_matlab/formal420_20261016_schema2/` 的420 UE `no_cooperation` 基线退出码0，用时33.76 s，真实 sum SE 80.3447 bit/s/Hz、420/420有效、最大功率违规1.07e-14 W，MAT 输出是 v2 字段。默认2次WMMSE外轮、12次ADMM内轮常到上限，`completed` 只表示运行完成和可行输出，不表示数值收敛。两目录为本地原始证据，未加入 Git。

最终字段版的210 UE `matrix_statistical` 也已从 `setup_project_paths.m` 后的 `chasi_run` 原生入口完成，保存在 `results/chasi_matlab/formal210_20261016_schema2/`：MATLAB 退出码0，求解用时779.90 s，真实信道 sum SE 68.1866955652 bit/s/Hz，210/210 UE有有效样本，最大功率违规0 W；停止原因仍是 `max_outer_iterations_with_latest_inexact_admm`。HDF5/MAT 顶层字段实查包含 `precoder/rxCombiner/mseMatrix/mseWeight/userWeight/scheduleMask/servingMask/ueIDs/numStreams/resultSchemaVersion`。与先前210 UE目录的结果相同只支持字段/语言等价性，不能据此声称收敛或验收物理模型。后续只做局部变量改名，并再次运行轻量测试；此正式输出按运行当时源码记录。

本版字段再运行 `test_chasi_native_scene` 与上述测试，MATLAB 退出码0；`test_chasi_native_entry` 用21 TRP/210 UE、缩小求解预算和链路范围验证新 MAT 字段，属于入口测试而非正式默认预算实验。历史v1 CHASI MAT 经过只读转换器成功读取。拓扑 PNG 与矢量 PDF 均由 MATLAB 实际导出，PDF 再栅格化检查无裁切；统一公式 PDF 由 XeLaTeX 实际编译为11页，日志无 `Overfull`，已逐页查看渲染图。

### 文件/公式覆盖与仍缺的证据

| 对象 | 本轮核查范围 | 仍待核实 |
|---|---|---|
| `chasi_run/config/generate_scene` | 入口到保存、全部配置字段、几何/组/SRS后验和掩码；对应 C01–C13 | 原任务图片的精确 UE 区域和功率定义、末 RB 测量粒度 |
| `chasi_matrix_wmmse/no_cooperation` | 初始化、A/E/Omega、目标权重、二次算子、CG/ADMM/投影及停止；C14–C31 | 420 UE已实测运行完成，但严格收敛/全局最优不成立；矩阵分支保存字段是最后改名前版本 |
| `chasi_evaluate/traffic/time_evolution/burst_metrics/second_metrics` | 真信道SE、容量/队列代理、样本及保存；C32–C38 | 协议 ACK/RLC/BLER 完整计数无波形/栈源码；动态回放跨语言同输入未完成 |
| `cf_generate_scenario/cf_apply_srs_measurement_model/cf_evaluate_candidate/cf_search` | 旧链变量关系与 L01–L17；保留旧模型，未接入新正式入口 | 旧搜索算子每个局部超参数未在统一PDF逐行推导 |
| `WMMSE_ADMM_Func.py` 参考 | Z01–Z03 数学类别与源代码对象 | 论文原式编号与每个统计量出处未逐页核查，不称直接迁移 |

`CHASI_UNIFIED_TRACE.tex` 含 38+17+3=58 个逐条公式，当前没有为真实OFDM/SRS/PDSCH波形、8×4×2端口流形、CPU前传和正式ACK体验伪造公式。数学位置 C24–C31 已逐函数列在上表；一般循环下标、文件句柄等非通信量未加入字母字典。上一版旧 Python `V/U/W` 和旧MATLAB `W` 分别在本页映射，旧证据未覆盖。完整场景生成的**跨语言同输入数组**及420矩阵分支最终 v2 字段版运行仍是覆盖缺口，不能以求解器小例对拍代替。
