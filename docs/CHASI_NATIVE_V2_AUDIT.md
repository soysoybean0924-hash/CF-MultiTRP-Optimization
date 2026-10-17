# CHASI MATLAB 主线：命名、模型边界和验证（2026-10-17 v3；含 v2 历史）

> **2026-10-17 v3 字段更新。** 下方原有的 v2 运行数字和字段描述是按
> 2026-10-16 当时源码保存的历史证据，不代表当前输出字段。保留它们用于
> 对照，不改写原始结果。当前公式以 [CHASI_UNIFIED_TRACE.tex](CHASI_UNIFIED_TRACE.tex)
> 为准；本页末尾补记本轮最终规模运行和未完成验证。

当前正式入口仍是 `matlab/chasi/chasi_run.m`，不启动 Python。
`resultSchemaVersion=3` 的 `*_precoders.mat` 保存 `precoder`、
`rxCombiner`、`mseMatrix`、`mseWeight`、`userWeight`、`scheduleMask`、
`servingMask`、`ueIds`、`resourceWeightNu`、`numStreams`。历史 v1/v2 MAT
只由 `chasi_load_precoder_result.m` 显式转换；v2 `ueIDs` 变成 `ueIds`，
没有保存的 `resourceWeightNu` 保持空，不从旧结果猜测。正式求解从不读取
这一转换器。

| 旧记号或字段 | 当前符号 | 当前字段 | 物理含义、轴与单位 | 变更 |
|---|---|---|---|---|
| `a_lkg`, `serve` | $\chi_{lkg}$ | `servingMask[l,localUeIdx]` | TRP 对全局 UE $k$ 的服务关联，布尔；`ueIds(localUeIdx)=k` | 仅命名 |
| `a_g`, `rbweight` | $\nu_g=n_g^{tx}/N_{RB}$ | `resourceWeightNu[g]` | 发射 RB 数占 273 数据 RB 的比例，无量纲；在目标、跨组 TRP 功率与 UE 率各乘一次 | 仅命名和显式保存 |
| `ue_ids`, `ueIDs` | $k$ | `ueIds[localUeIdx]` | 全局 UE 身份，一基索引；资源组数组轴仍为局部位置 | 仅命名 |
| 旧 `W`, 新 `V` | $w_{ljg}$ | `precoder[l,localUeIdx,txPort,stream]` | 含实际幅度的复预编码；$p_l=\sum_g\nu_g\sum_j\|w_{ljg}\|_F^2$ W，不再乘 $\sqrt p$ | 旧链与新链模型不同，无赋值接口 |
| 新 `U`, `E`, `W` | $A,E,\Omega$ | `rxCombiner`, `mseMatrix`, `mseWeight` | 接收器 $[K_g,4,r]$ 与 MSE/权重 $[K_g,r,r]$，均非发射波束 | 仅新链记号统一 |
| 新目标导数权 | $\eta_k$ | `userWeight[localUeIdx]` | PF 导数、固定边缘权或 1，无量纲 | 与 MSE 权重区分 |

### v3 核心变量的生成、更新和最终去向

组内数组轴 `localUeIdx` 经 `ueIds(localUeIdx)=k` 才是全局 UE；下表的
$j$ 为求和 UE，可等于 $k$，仅 $j\ne k$ 才是纯干扰项。当前 MATLAB
没有实例化数据符号 $s_j$、发射波形 $x_l$ 或无线接收样本 $y_k$；C15–C16
是与实际协方差/速率计算等价的教学信号式。

| 数学量／代码字段 | 首次产生；轴／单位 | 更新、索引或归一化 | 消费与保存 |
|---|---|---|---|
| $N_{\rm RB}$、$\sigma_{\rm RB}^2$；`rbTotal`,`noiseWattPerRb` | `chasi_config`；273 RB、$10^{-10}$ W/RB 默认 | 可选物理路损模式用二者把增益噪声归一化；默认 surrogate 已归一化 | `chasi_generate_scene`、资源组权重；`config.json` |
| $d_{kl}$、$\beta_{kl}$；距离、`prior_gain` | `chasi_generate_scene>geometry,link_gain`；米、默认无量纲 | 方位增益、距离律；可选 UMi/UMa 路损是另一口径 | 关联排序、真信道和后验先验；`scene.mat` 的坐标/增益、`scene_manifest.json` 坐标 |
| $H^{\rm true},\widehat H,C$；`H_true`,`H`,`C` | `chasi_generate_scene`；各组 `[K_g,21,4,64]`、`[K_g,21,4,4]` | 真 H 生成合成 CSI-RS/SRS 观测；后验估计 H/C 按资源组与时间戳保存。完整误差仅假设 $I_{64}\otimes C$ | 非理想求解只读估计 H/C；真 H 用于观测和最终评价，`ideal` 分支例外；`scene.mat` |
| $b_{kg}$、$\chi_{lkg}$；`scheduleMask`,`servingMask` | `chasi_generate_scene>schedule` 和组循环；`[N_{\rm UE},17]`、每组 `[21,K_g]` 布尔 | `ueIds` 连接全局身份与组内轴；服务外预编码强制零 | 初始化、ADMM、评价、拓扑图；`scene.mat`、v3 预编码 MAT 和场景清单 |
| $\nu_g$；`resourceWeightNu` | 组循环；`tx_rb_count/273`，无量纲 | 不等于业务负载或 SRS 覆盖；每个目标、功率、率的对应组贡献各乘一次 | `chasi_matrix_wmmse>resourceWeight`、`chasi_evaluate>resource_weight`；场景清单和 v3 MAT |
| $r_{kg}$；`numStreams` | `chasi_config.rank=2`；流／UE／组 | 下行上限受 4Rx 与 64Tx 限制，2Tx 是上行 SRS 端口数；本分支不动态改 rank | 预编码/接收器形状；v3 MAT 的 `numStreams` |
| $w_{ljg},p_l$；`precoder`,`per_trp_power_watt` | `chasi_matrix_wmmse` SVD 初始化；`[21,K_g,64,r]`、`[21,1]` W | 功率投影与 WMMSE/ADMM 更新复矩阵；$p_l=\sum_g\nu_g\sum_j\|w_{ljg}\|_F^2$，发送式不再乘 $\sqrt p$ | 接收统计、真信道 logdet、功率预算；v3 MAT、`summary.json` |
| $A,E,\Omega$；`rxCombiner`,`mseMatrix`,`mseWeight` | `chasi_matrix_wmmse>state:374`；每组 `[K_g,4,r]`、`[K_g,r,r]`、`[K_g,r,r]` | 每次外轮由当前估计 H/C/w 重算；$A=R_{yy}^{-1}F$、$\Omega=E^{-1}$ | `quadratic:403` 生成子问题系数；v3 MAT |
| $\eta_k$；`userWeight` | `objectiveSnapshot:301`；每组 `[K_g,1]` 无量纲 | PF 导数按全局 UE 率计算后经 `ueIds` 回映，或为固定边缘权/1 | 乘入 MSE 二次系数；v3 MAT |
| $M,B,D,\mathcal Q$；`parts.M/B/D`,`qapply` | `quadratic:403`、`qapply:420`；`M[K_g,4,4]`,`B[21,K_g,64,r]`,`D[21,1]` | 固定 A/Ω/η 构造优化系数，不是额外无线信号 | CG/ADMM 线性系统；仅诊断轨迹，不单独作为物理量保存 |
| $x,z,y,\rho$、CG 残差／方向 | `precoder_admm:440`、`cg:485`；前三者与 w 同形，$\rho$ 标量 | CG 更新 x、跨组投影得可行 z、缩放对偶 y 更新；`cgResidual/cgDirection` 仅数值迭代 | 返回 z 给 WMMSE 外轮；残差/功率写 `summary.json` 的轨迹，x/y 不单存 |
| $R_{\rm SE},R_{\rm exp}$、有效样本 | `chasi_evaluate>true_rates:137`；bit/s/Hz、Mbps、UE×TTI计数 | 真 H 与最终 w 的 logdet → $\nu$ 聚合 → 忙时/尾段代理；无有效样本为 NaN | `summary.json`、`*_per_ue.csv`；并非真实 ACK/RLC 交付速率 |

`scene_manifest.json` 也保存 `ueIds` 和 `resourceWeightNu`；
`chasi_plot_topology.m` 对旧 `ue_ids` 仅作图时显式读取转换。
`chasi_evaluate.m`、`chasi_no_cooperation.m` 和 `chasi_time_evolution.m`
都优先读取 `resourceWeightNu`；旧显式小例缺该字段时，才按
`tx_rb_count/273` 计算相同权重。`nu` 是数据资源占比，既不是业务负载，
也不是 SRS 测量覆盖比例。当前 `srs_nominal_hop_rb=272` 与
`srs_modeled_group_rb=273` 分别报告，不把第 273 个数据 RB 称为已独立测量。

### 本轮物理核查状态

| 问题 | 当前源码事实 | 处理状态与仍缺定义 |
|---|---|---|
| 7站、21 TRP | `chasi_generate_scene>geometry` 将中心站与半径300 m 的6站各复制3个共址扇区；`home` 每TRP分10/15/20 UE | 已核实代码映射；原验收图的300 m定义仍需原件逐页确认 |
| UE 分布 | 120°扇区、25–150 m，`25+125*sqrt(U)`；并非面积均匀环扇采样 | 已核实缺口；原材料没有可核查的小区边界和最小站距定义，不能擅改正式等价配置 |
| 阵列 | `[K_g,21,4,64]` 独立发射列，仅4×4接收相关 | 8×4×2半波长双极化阵列流形、端口映射尚未实现；不把64列当作已验证的物理阵列 |
| SRS | 17跳×16 RB名义测量为272 RB；数据为16×16+17=273 RB，末组共用一个后验；事件记录20/340 TTI | 已区分输出语义；第273数据RB的独立测量掩码/后验尚未实现；旧转述文件称末跳17RB，与用户原图的16RB说法冲突，缺原件核对 |
| 750 m 截断 | 超距非服务 `H_true/H` 置零；`omitted_gain` 进入诊断，不进入真实干扰 logdet | 代码的条件性遗漏已核实；但当前静态七站几何满足最远站距 600 m + UE 最大偏移 150 m，210/420 保存场景实际超界链路均为 0，静态评价此项影响为 0。改变部署或移动回放仍需复核；没有校准补偿模型。 |
| 功率 | $\sum_g\nu_g\sum_j\|w_{ljg}\|_F^2\le20$ W，按TRP跨组辐射预算；`p` 由 `w` 范数得到 | 已核实代码口径；20 W 来源为参考实现配置，设备功耗/每通道官方约束未证实 |
| 业务和边缘 | `trafficLoad=.30` 独立于40%默认 PRB；但默认 `legacy_bursts` 不按目标忙时占比生成，已保存210/420运行的实际 UE×TTI 忙时比例分别为86.64%/86.50%。有效UE秒、线性5%分位、最低5%均值候选分开。 | 已核实默认口径与“30%负载”不能等同；`target_busy_fraction` 只是可选 UE×TTI 代理，正式验收分母、未完成业务与零样本、80%共同基线仍缺定义。 |
| 0.08/0.92、4、0.025、100m、3.2、0.35 | `link_gain` 和接收相关的默认 surrogate 常数 | 仅能追到 Python 参考实现及当前 MATLAB；`git log -S` 在受跟踪的当前路径追到 `c6cd623` 的 MATLAB 引入提交，不是物理来源；未找到原图/标准逐值依据，记未校准项目假设 |

当前仓库可读的 [HUAWEI_VALIDATION_SCENE.md](HUAWEI_VALIDATION_SCENE.md)
是配置转述，并非原始三张任务图；本轮检索未取得含页码的验收原件、
系统方案和研究主题分析原文件。因此上表不给伪造的页码，涉及官方定义的
修正保持待确认；对等价迁移使用的默认模型和评价口径没有偷偷改值。

`tests/verify_chasi_scene_manifest.py` 读取本轮 420 UE MATLAB 输出的
`config.json`/`scene_manifest.json`，从显式坐标和身份独立复核站址复制、
120°扇区半径范围、home、服务集合、组 RB、$\nu_g$ 和测量年龄；
得到 21 TRP、420 UE、17组、588次组内UE调度、1176条服务连接、
站址坐标最大误差0 m，名义 SRS 272 RB 与数据273 RB差1。
此检查没有复现随机抽样、$H_{\rm est}$ 或动态队列，不是完整跨语言
场景对拍；同输入矩阵求解与单链路评价对拍另见下文。

### 相比上一版公式与溯源

| 类别 | 本轮变化 | 数值含义 |
|---|---|---|
| 仅符号/字段 | $a_{lkg}\to\chi_{lkg}$、$a_g\to\nu_g$；全局 UE 用 $k$，组内下标用 `localUeIdx`/`ueIds`；时间相关、回溯步长、旧稀疏权各自命名；结果 MAT 为 v3 | 同输入求解和评价公式未变 |
| MATLAB 迁移 | 沿用已接通的原生 `chasi_run` 全链；本轮把 v3 字段传到求解、评价、回放、绘图与历史读取转换器 | 没有新增 Python 正式调用 |
| 模型变化 | 默认几何、阵列 surrogate、SRS 后验、截断和业务代理均未改；新增 272/273 RB 的分开报告 | 不把模型差异算作迁移误差 |
| 评价口径变化 | 无；$\nu_g$ 只把既有 `tx_rb_count/273` 显式保存 | 旧 v2 输出保留原样 |
| 仍未完成 | 原图页码、严格面积均匀区域定义、阵列端口校准、第273 RB独立CSI、改变部署时的超距干扰处理、官方30%业务口径及动态跨语言同输入对拍 | 不能宣称物理验收完成 |

本页以 `matlab/chasi/chasi_run.m` 的当前源码为准。历史审计 `full_trace_20261014/` 保留原状，反映当时 Python 主线与 `V/U/W` 记号，不能代表此版入口。公式全集的可编辑源是 [CHASI_UNIFIED_TRACE.tex](CHASI_UNIFIED_TRACE.tex)，PDF 是其导出件。本轮没有把未获物理依据的参数修正混进等价迁移。

## 历史 v2 审计快照：实际调用与保存

以下旧字段、旧变量轴和当时运行数字保留作版本对照；当前 v3 定义以上方
命名表和 [公式溯源 PDF](CHASI_UNIFIED_TRACE.pdf) 为准。

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
| 0.08、0.92、方向图指数4、0.025、100 m、3.2、相关0.35、750 m | 分别在 `link_gain`、`geometry`、`rx=0.35^|i-j|` 和距离截断处。Python `config.py`/`scenario.py` 已先使用相同值；未在本轮找到对应原图、标准条文或论文的逐值来源。 | 项目建模假设，不能称标准校准。超750 m非服务链路若出现会被省略；当前210/420静态场景超界数为0，故本次真信道评价没有这一项遗漏。 |
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
| C24 | `quadratic(H,C,rxCombiner,mseWeight,userWeights)`，`chasi_matrix_wmmse.m:403` | 估计信道、误差统计、固定 $A,\Omega,\eta$；$H[K_g,L,4,64]$、$C[K_g,L,4,4]$ | `parts.M/B/D` → `qapply`、`precoder_admm`；仅优化系数 |
| C25 | `qapply(H,parts,x,mask)`，`:420` | 估计信道、二次系数、试探矩阵 `[L,K_g,64,r]`、服务掩码 | 同形 $Q(x)$ → CG 线性算子及固定二次目标 |
| C26–C27 | `precoder_admm(resources,parts,initial,cfg)`，`:440` | 每组资源、二次系数、当前可行预编码、预算和停止阈值 | 可行副本 `z`、逐步 `history`、内层 `converged` → WMMSE 回溯 |
| C28 | `cg(apply,b,x,maxiter,tol)`，`:485` | 算子、右端、初值、迭代上限/相对阈值 | 近似原变量 `x` → 功率投影 |
| C29 | `project(resources,x,budget)` 与 `projectedpower(resources,x,l,lambda)`，`:499,:518` | 每组 RB 权重、服务掩码、每 TRP 总预算 | 可行副本 `z` → 对偶更新及返回外轮 |
| C30 | `precoder_admm` 内部 `history`，`:440` | $x,z,y,\rho$ 与 CG 残差 | 原/对偶残差及阈值 → 内层停止和 `summary.trajectory` |
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

## 2026-10-17 最终命名版运行与完成边界

以上 v2 段落保留其历史时点；下面是当前源码 `9b5bf9f7e2943d7d22d71c8661c354d144e2de46` 的证据。两次均从 `setup_project_paths.m` 后直接调用 `chasi_run`，由 MATLAB R2026b 原生生成场景、CSI、业务掩码、求解、真信道评价与保存；正式调用链静态检索无 Python。配置均为 7 站、21 TRP、64 Tx/TRP、4 Rx/UE、UE 上行 2 Tx、273 数据 RB、17 组、rank 2、种子 20261011、`matrix_statistical`、外轮上限 2、ADMM 上限 12、CG 上限 8、每 TRP 跨组预算 20 W。场景及原始 MAT 留在本地；Git 仅保存轻量配置、摘要、场景清单和逐 UE CSV。

| 输出目录 | MATLAB 批处理 | 求解耗时 | 估计信道优化目标 | 真信道 sum SE | 有效 UE；UE×TTI | 最大功率违规 | 停止原因 |
|---|---|---:|---:|---:|---:|---:|---|
| `results/chasi_matlab/formal210_20261017_schema3_named_final/` | 退出码 0 | 763.24 s | 58.5807699274 | 68.1866955652 bit/s/Hz | 210/210；58679 | 0 W | `max_outer_iterations_with_latest_inexact_admm` |
| `results/chasi_matlab/formal420_20261017_schema3_named_final/` | 退出码 0 | 2537.24 s | 82.8537424043 | 95.1281554963 bit/s/Hz | 420/420；117140 | 0 W | 同上 |

`tests/verify_chasi_saved_run.py` 检查两次摘要、功率、逐 UE CSV、结果文件与 v3 schema 声明；`tests/verify_chasi_scene_manifest.py` 检查 21 TRP 身份、17 组、扇区和坐标、273 数据 RB 与名义 272 SRS RB。保存场景的最大 UE–TRP 距离分别为 744.53/743.92 m，超过 750 m 的几何链路都是 0。420 UE 运行期间观测到峰值工作集 1.220 GB，210 UE 运行期间观测到 0.997 GB；这是进程采样值，不是完整内存剖析。最终两次运行的优化目标、真实评价、各 TRP 功率、停止原因、轨迹及逐 UE CSV 均与局部变量改名前的 v3 运行完全相同；420 UE 场景的 H、H_true、C、增益、身份、服务掩码也逐数组相同。求解到上限且最近 ADMM 未收敛：`completed` 只表示全链执行和返回满足功率预算的预编码，不是理论收敛或全局最优。420 UE 外轮目标 26.84295→76.46299→82.85374，末轮相对目标变化 0.08358，尚大于停止阈值；没有为制造收敛而放宽阈值。

MATLAB 批处理重新读取两次最终 `*_precoders.mat`，验证 v3、17 组、全局调度行数及组权重，并以最终 420 UE `scene_manifest.json` 实际导出拓扑 PNG/PDF（本地 `tmp/chasi_final_named420_topology.*`），批处理退出码 0；已查看 PNG。该图仅画第 1 资源组的真实抽样坐标和服务线，部分密集 UE 标签贴近，不能替代原始网络示意或全部组干扰图。

静态业务代理仍是 `legacy_bursts`：配置的 `trafficLoad=0.30` 不是实际忙 UE×TTI 比例。两次实际忙比例为 0.86636/0.86501，实际 PRB 使用比例为 0.40877/0.40998。两次“全部 UE 有效”仅按当前忙时容量代理的有效样本定义成立，不能等同正式业务交付口径或 30% offered load 验收。`tests/chasi_export_business_probe.m` 从保存场景导出显式忙/尾掩码，`tests/verify_chasi_business_probe.py` 离线对拍静态业务代理，210/420 UE 最大逐 UE 体验率差分别为 `1.07e-13`/`9.95e-14` Mbps；这不是在线队列或信道更新对拍。保存场景的真信道/后验协方差探针在 420 UE 第 1 组检了 588 条模型链路，最大后验协方差相对差 `6.90e-8`，未证明相同随机输入下的 Python/MATLAB 场景逐数组等价。

### 本轮状态分类

- **A 已实现且验证通过：** 原生 MATLAB 正式静态入口、v3 保存字段、210/420 UE 全链执行、功率可行性、两规模场景清单和逐 UE CSV 检查；显式同输入的求解器/单链路评价数值对拍；命名修订前后的同场景结果一致。
- **B 已实现但验证尚不完整：** 可选 `chasi_time_evolution` 是估计信道 SVD 快速重置或冻结预编码回放，并非逐时隙在线 WMMSE；SRS 统计观测和第 17 数据组共用后验已有代码，但与真实 16RB 跳频波形的同输入跨语言对拍未完成；XeLaTeX 公式 PDF 已编译为 14 页并检查修改页，原 PDF 证据保留。
- **C 原材料定义不足：** 原三张任务图及其可定位页码不在本仓库，因而严格小区边界/面积均匀抽样、20W 物理口径、30% 负载分母、SRS 最后一跳和正式业务验收口径不能据二手转述定案；0.08、0.025、100m、3.2、0.35 等继续标为未校准项目假设。
- **D 尚未实现：** 8×4×2 双极化阵列/端口映射、末第 273 数据 RB 的独立 SRS 测量状态、真实波形与 CPU 前传、完整在线重求与动态业务跨语言同输入对拍，以及无依据场景外的 750m 超距干扰补偿。旧 MATLAB 外搜索模型与本正式 CHASI 主线仍是不同模型，不能把旧 `W` 波束作为新 `w` 的直接输出接口。
