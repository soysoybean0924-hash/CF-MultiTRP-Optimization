# CHASI 原生 MATLAB 变量与参数验收

源码基线：`9527089`（SRS 末跳修订）；正式入口 `matlab/chasi/chasi_run.m:1`。本表只对 `matlab/chasi/` 的正式链下结论；旧 `matlab/core/` 和独立 Python 参考链的同名字段不自动继承此语义。状态“通过”指静态维度/消费者核查及本轮小例运行，不意味着华为物理验收。行号指该基线源码。

## 阅读规则

`g=1..17` 为资源组，`l=1..21` 为 TRP，`k=1..N_UE` 为全局接收 UE，`j` 为求和中的全局数据 UE。组内 `localUeIdx=1..K_g` 通过 `resources(g).ueIds(localUeIdx)` 映射到全局 `k` 或 `j`。MATLAB 数组为一基索引。`H(k,l,:,:)` 表示 `[4 Rx,64 Tx]`；`precoder(l,localUeIdx,:,:)` 表示 `[64 Tx,r]`。`'` 是复共轭转置，`.'` 才是普通转置。

## 正式链通信变量全生命周期

| ID | 物理量／统一符号 | 代码字段，维度轴顺序，单位 | 首次生成与变换 | 更新与最终消费者／保存 | 旧名与验收 |
|---|---|---|---|---|---|
| V01 | 站址 $s_m$ | `scene.trp_xy_m` 来源，7×2，m | `chasi_generate_scene>geometry:142`：中心加半径300m六边形 | 每站复制三扇区为21×2；链路距离；`scene.mat`,`scene_manifest.json` | 旧 DU 不是自动等同 TRP；通过（部署规则为项目实现） |
| V02 | TRP 编号 $l$ | `trp_xy`, 21×2，m | `geometry:146` 重复站址 | `link_gain`, 服务掩码, `precoder` 第一轴；manifest | 站/扇区共址，扇区朝向 `mod(l-1,3)`；通过 |
| V03 | UE 位置 $q_k$ | `ue_xy`, N_UE×2，m | `geometry:149-158` 角均匀、$d=25+125\sqrt\xi$ | 距离/拓扑；`scene.mat`, manifest | **未通过物理验收**：非严格面积均匀环扇区，验收图未给区域边界 |
| V04 | UE 身份 $k$ | `ueIds`, K_g×1，一基 ID | `schedule:159-205` 从 `home` 池选出 | 资源组局部轴→全局率/流量/CSV；manifest、MAT | 旧 `ueIDs` 经只读历史转换；通过 |
| V05 | 小区归属 | `home`, N_UE×1，TRP ID | `geometry:148` 每 TRP `usersPerCell` | 服务候选首项、业务；`scene.mat`, manifest | 并非优化关联；通过 |
| V06 | 链距 $d_{kl}$ | `distances`, K_g×21，m | `chasi_generate_scene:59` 欧氏距离 | 最近 TRP 服务与750m截断；未单独保存，坐标可复算 | 旧 `r` 距离已避开 rank；通过 |
| V07 | 大尺度增益 $\beta_{kl}$ | `gains`, N_UE×21，无量纲归一化 | `link_gain:207`，默认 surrogate 或可选 UMi/UMa 子集 | `H_true`, CSI 先验、遗漏诊断；资源 `prior_gain`, scene MAT | **待定义**：0.025等常数缺外部校准；物理 W 与噪声归一化口径须区分 |
| V08 | 真实下行信道 $H^{true}_{klg}$ | `resources(g).H_true`, K_g×21×4×64，复归一化 | `chasi_generate_scene:74` 由增益、4×4相关及高斯产生 | CSI 合成、`ideal` 优化分支、最终真信道评价；`scene.mat` | **通过代码路径**；不声称完整8×4×2物理阵列 |
| V09 | 估计信道 $\widehat H_{klg}$ | `resources(g).H`, K_g×21×4×64，复归一化 | `chasi_generate_scene:100` 独立后验或 `reuse_update:281` | 非 ideal 初始化、U/E/Ω、V 子问题；`scene.mat` | 旧 `H_est`；通过代码路径 |
| V10 | 接收相关矩阵 $R_{rx}$ | `rxCorrelation`, 4×4，无量纲 | `chasi_generate_scene:11` 的 $0.35^{|m-n|}$ | 真信道与估计先验；间接 scene MAT | **待定义**：0.35无原图校准 |
| V11 | 后验误差协方差 $C_{klg}$ | `C`,`C_stat`, K_g×21×4×4，复归一化 | `chasi_generate_scene:82-102`; pilot reuse 在 `reuse_update` 变更 | `state:392` 与 `quadratic:413`；scene MAT | 完整列协方差假设 $I_{64}\otimes C$；跨 UE 后验块未建 |
| V12 | SRS 测量掩码／年龄 | `measured`,`age_ms`, 17 个布尔/ms | `chasi_generate_scene:47-56`，跳间隔20 TTI | CSI 精度；events/manifest/summary/scene MAT | 末跳17RB元数据已验证；无逐 RB 波形 |
| V13 | SRS SINR | `srs_diagnostic`, 依组/TRP/复用 pilot | `reuse_update:281` pilot reuse 分支诊断 | scene MAT；非正式验收系统级 Presinr | **待定义**：聚合/接收机/功率缺原图定义 |
| V14 | 数据 RB 范围／已发射 RB | `rb_start`,`rb_count`,`tx_rb_count`, 各17标量，RB | `chasi_config:50-52`, `schedule:159-205` | `resourceWeightNu`, manifest/scene MAT | 第17组17RB；`prbUtilization` 与业务负载分开；通过 |
| V15 | 组权重 $\nu_g$ | `resourceWeightNu`, 1×17，无量纲 | `chasi_generate_scene:129`，$n_g^{tx}/273$ | 目标、跨组功率、真实速率/业务容量，MAT/manifest | 旧 `a_g`；通过（每处只乘一次） |
| V16 | 调度 $b_{kg}$ | `scene.scheduleMask`, N_UE×17，布尔 | `chasi_generate_scene:135-139` | 组内 `ueIds`, 保存 MAT | 旧 `b_{lkg}` 语义不同；通过静态映射 |
| V17 | 服务关联 $\chi_{lkg}$ | `resources(g).servingMask`, 21×K_g，布尔 | `chasi_generate_scene:61-64` home+最近可用 TRP | 限制预编码、投影；MAT/manifest | 旧 `a_lkg`；通过；规则生成非优化 |
| V18 | 流数 $r_{kg}$ | `cfg.rank`,`numStreams`, 标量=2，流/UE | `chasi_config:6,57-60` | `precoder`, `rxCombiner`, E/Ω；config/summary/MAT | 上限 min(64 DL Tx,4 DL Rx)，非 UE 上行2Tx；通过 |
| V19 | 发射预编码 $w_{ljg}$ | `solution.precoder{g}`, 21×K_g×64×r，复幅度 | `chasi_matrix_wmmse:15-31` 估计H右奇异向量+投影 | ADMM/回溯更新，真信道评价，`*_precoders.mat` | 旧 MATLAB `W` 与旧模型不同；新 Python `V` 同类物理量，非直接接口；通过代码语义 |
| V20 | TRP 功率 $p_l$ | `solution.power`, 21×1，模型 W | `chasi_matrix_wmmse>chasi_power:526`，$\sum_g\nu_g\sum_j\|w_{ljg}\|_F^2$ | 预算、summary `per_trp_power_watt` | $w$ 已含幅度，发送不再乘 $\sqrt p$；通过模型内部一致性 |
| V21 | 接收协方差 $F_{kg}$ | `rxCovariance`, 4×4，归一化 | `state:381-392`，噪声$I_4$+所有用户+误差项 | U/E/Ω；中间态不保存 | 新旧 `R` 避歧义；通过 |
| V22 | 有效信道 $T_{kjg}$ | `effectiveChannel`, 4×r，归一化 | `state:383-390`，$\sum_l H_{klg}w_{ljg}$ | 有用/干扰、评价 `true_rates`；不单存 | 相干跨TRP先和后平方；通过 |
| V23 | 接收合并 $A_{kg}$ | `rxCombiner{g}`, K_g×4×r，复 | `state:393`，$F^{-1}T_{kkg}$ | E、二次子问题；MAT | Python `U`；通过 |
| V24 | MSE 矩阵 $E_{kg}$ | `mseMatrix{g}`, K_g×r×r，无量纲 | `state:394-397` | Ω 与优化轨迹；MAT | Python `E`；通过 |
| V25 | MSE 权重 $\Omega_{kg}$ | `mseWeight{g}`, K_g×r×r，无量纲 | `state:398`，$E^{-1}$ | 二次系数；MAT | Python `W`；不同于旧波束 W；通过 |
| V26 | 公平权重 $\eta_k$ | `userWeight{g}`, K_g×1，无量纲 | `objectiveSnapshot:301-344`，分支特定 | 二次子问题；MAT | PF 导数/edge固定/1，与 Ω 区分；通过 |
| V27 | 估计 SE $R^{est}_{SE,kg}$ | `rate{g}`, K_g×1，bit/s/Hz | `state:399`，$-\log_2\det E$ | 目标/权重；solution/summary | $r$ 保留流数；通过 |
| V28 | 二次算子 $M,B,D,Q$ | `parts.M` K_g×4×4, `B` 21×K_g×64×r, `D`21×1 | `quadratic:403-418`; `qapply:420-438` | ADMM/CG；可选 probe | 优化系数不是新的物理信号；通过 |
| V29 | ADMM 原变量、副本、缩放对偶 | `x`,`z`,`dual`, 各组21×K_g×64×r | `precoder_admm:440-455` | `z` 投影后返回；残差 history | `rho` 初始0.05，更新时对偶重缩放；通过小例 |
| V30 | CG 残差／方向 | `cgResidual`,`cgDirection`, 同单组 w 形状 | `cg:485-496` | 解 $x$ 子步；不保存单步数组 | 旧短 `r/p` 不再复用；通过 |
| V31 | ADMM 残差 | `history.primal`,`dual`,`eps_primal`,`eps_dual`,`cg_relative`, 标量 | `precoder_admm:456-474` | 停止及 summary trajectory | 达上限不等于收敛；通过记录 |
| V32 | 真信道 SE $R^{true}_{SE,kg}$ | `chasi_evaluate>true_rates`, K_g×1，bit/s/Hz | `chasi_evaluate:137-154` logdet 协方差比 | 全局物理率、业务容量；CSV/summary | 仅模型等效功率统计，没有数据符号/波形；通过代码路径 |
| V33 | UE 平均 SE | `per_ue_physical_bits_per_s_hz`, N_UE×1，bit/s/Hz | `chasi_evaluate:53-55` 组 $\nu_g$ 加权 | 汇总及 `*_per_ue.csv` | 不等于用户体验吞吐；通过 |
| V34 | 业务掩码 | `busy`,`tail`,`terminal`, N_UE×340，布尔 | `chasi_traffic:1-37` | `chasi_evaluate:1-136`、scene MAT | 默认 `legacy_bursts` 不消费30%目标；**未通过30%验收** |
| V35 | 交付量代理 | `volume`, N_UE×1，bit | `chasi_evaluate:75-81` 按忙时、尾部需求、SE、RB、12子载波、SCS、TTI | experience, summary `per_ue_delivered_bits_proxy` | 无真实队列/ACK/BLER；代理口径通过代码路径 |
| V36 | 体验率 $R_{exp,k}$ | `per_ue_experience_mbps`, N_UE×1，Mbit/s/有效TTI | `chasi_evaluate:91-94`；无样本=NaN | 5%分位、valid/zero-included；CSV/summary | TS28.554严格样本边界尚未验收；**待定义** |
| V37 | 省略链路功率诊断 | `omitted_gain`,`omitted_interference_expected_over_noise` | `chasi_generate_scene:68-71`, `chasi_evaluate:60-65` | summary 诊断 | **未通过完整干扰**：750m外真信道未生成/未加到率分母 |

## 同名异义与历史读取边界

| 旧路径与名称 | 当前数学符号／代码字段 | 物理量及维度 | 转换及接通状态 |
|---|---|---|---|
| `matlab/core/cf_evaluate_candidate.m` 更早历史 `W`；当前已提交 `legacyBeamformer` | 旧 $w^{old}$，旧链波束 | `[Tx,stream,DU,UE,RBG]`；先单位方向，旧功率归一后含幅度 | `9527089` 已是语义名；本轮不纳入该文件既存的其他未提交改动；没有赋值给正式 `solution.precoder` |
| 旧链 `p` | 旧 $p^{old}=\|w^{old}\|^2$ | DU/RBG功率，旧约束按 DU/RBG | 与当前 $p_l=\sum_g\nu_g\sum_j\|w_{ljg}\|_F^2$ 的跨组TRP口径不同 |
| Python 求解器 `V` | $w$／MATLAB `precoder` | `[TRP,K_g,64,r]` 复矩阵，含发射幅度 | 数学同类，显式同输入可对拍；正式入口没有 Python→MATLAB 运行接口 |
| Python 求解器 `U` | $A$／`rxCombiner` | `[K_g,4,r]` 复接收矩阵 | 只用于 MSE/二次系数，不是 UE 数 |
| Python 求解器 `W` | $\Omega$／`mseWeight` | `[K_g,r,r]` 复 Hermitian MSE 权重 | 与旧 MATLAB 波束 W 不同物理量；v3 MAT 字段分开保存 |
| 旧 CF MAT `result.W` | **无转换** | 旧模型波束，与新 CHASI 轴/约束不同 | `chasi_load_precoder_result.m` 明确拒绝；正式 `chasi_run` 不读取历史结果 |
| CHASI v1 `precoderV`, v2 `precoder`/`ueIDs` | v3 `precoder`/`ueIds` | 同一 CHASI 求解结果的历史字段 | `chasi_load_precoder_result.m` 只读显式版本转换；缺失的权重不推测 |
| 参考论文代码小写 `v_k` | 无直接当前字段 | 单流标量接收器 | 不是当前预编码 w；只在 Z02 保留来源差异 |
| 旧 PSO 速度 `V`、旧 UE 数 `U` | `psoVelocity`、`numUEs` | 搜索状态／计数 | 与预编码和接收矩阵不是同一量；旧链不参与正式运行 |

这不是全局字符串替换。当前正式 MAT 输出只有 `precoder`, `rxCombiner`, `mseMatrix`, `mseWeight`, `userWeight` 等语义字段；`resultSchemaVersion=3`。旧 MATLAB 函数仍可有自己的内部符号，需按 L01–L17 旧模型阅读，不能把它声称已合并到新链。旧 CF `result.W` **不被 CHASI 历史读取器转换**。`matlab/core/` 当前工作区有既存未提交修改；本表旧链现状取工作区静态核查，正式 MATLAB 结论则固定在已提交 `9527089`。

## 参数传递与口径验收

| 参数族／字段 | 定义与单位 | 传到何处 | 判断 |
|---|---|---|---|
| `sites=7,sectorsPerSite=3,trps=21,usersPerCell=10/15/20` | 站/扇区/UE数 | `geometry`, `schedule`, scene dimensions | 通过规模维度；小区边界待定义 |
| `txPorts=64,ueRxPorts=4,ueTxPorts=2,rank=2` | DL 发射/接收、UL SRS端口、流数 | H轴、`srsRxRows`、solver | 通过维度；8×4×2物理阵列未实现 |
| `rbTotal=273,srsHops=17,srsPeriodTti=340` | RB/跳/TTI | `rbGroups`, `srsRbCounts=[16×16,17]`, `srsHopIntervalTti=20` | 通过组级元数据，逐RB波形未实现 |
| `summary.scenario.srs_nominal_hop_rb` | 兼容摘要字段，当前值273 RB | `chasi_run.m:77-85`，与 `srs_total_measured_rb` 同值 | **命名仍待清理**：不能读成“每一跳273RB”；本轮保留以便核对历史验证器，优先读显式 `srs_hop_rb_counts` |
| `prbUtilization=.40,scheduleMode,usersPerActiveCellRb` | 目标占用比例/调度规则 | `schedule` → `tx_rb_count`/`ueIds` | 通过规则路径；正式30–50%范围核验另需全分支统计 |
| `trafficLoad=.30,trafficModel=legacy_bursts` | 业务忙时目标，名义值 | legacy 模式不使用30%；target模式决定平均空闲 gap | **未通过30%业务验收**；分母/到达定义需材料补足 |
| `powerWattPerTrp=20` | 每TRP跨组模型预算 W | solver `budget` → `project`，评价 power | 模型内部通过；20W来源待定义，设备能耗未实现 |
| `noiseWattPerRb=1e-10` | 每RB热噪声代理 W | 仅可选 pathloss 子集的归一化 | 默认 surrogate 分支不使用；标准噪声口径待定义 |
| `frequencyGhz=3.5,channelMode` | 载频 GHz，信道模式 | 可选 UMi/UMa pathloss 子集；默认 surrogate 不用载频 | 默认配置的载频**未生效**，非完整TR38.901/阵列 |
| `maxInterferenceDistanceM=750` | 信道计算截断，m | `chasi_generate_scene:68` | 生效；遗漏干扰只诊断，未补偿 |
| `pilotSnrDb=-10,csiRsSnrDb=-3,srsRxRows=[1,2]` | dB/端口映射 | 观测噪声、后验 | 生效；2Tx→4Rx端口映射为项目假设，未证明互易校准 |
| `srsPilotSequences=8,srsMode` | 复用序列数/估计分支 | pilot reuse 分支；独立分支不使用序列数 | 条件生效，C11/C12不能混称同一后验 |
| `ageCoherenceMs=120,decisionTti=340,csiRsPeriodTti=40` | ms/TTI | 逐组测量年龄、CSI-RS年龄 | 生效于统计噪声；不是连续时域信道估计 |
| `seed,initializationSeed,initializationMode` | 随机控制/方式 | 分离 RandStream、SVD/偏home/扰动初值 | 通过；跨语言相同 seed 不构成显式同输入 |
| `outerIterations=2,admmIterations=12,cgIterations=8` | 上限 | solver 外/内/CG | 生效；上限退出不称收敛 |
| `outerRelTol,outerPrecoderRelTol,epsAbs,epsRel,pfRateFloorBitsPerSHz` | 无量纲阈值 | 目标变化、预编码变化、ADMM残差、PF | 生效；PF仅相应分支使用 |
| `timeEvolutionTti=0,fastPeriodTti,slowPeriodTti,offeredMbps` | 回放时长/周期/目标Mbps | 仅启用可选 `chasi_time_evolution` 时 | 默认静态正式链不消费后三者；回放非在线矩阵WMMSE重求 |
| `bandwidthHz=100e6,scsHz=30e3` | Hz | `scsHz` 进入业务容量 `12×scsHz×RB`；`bandwidthHz` 只保存在配置 | `bandwidthHz` **未进入速率运算**；273×12×30kHz=98.28MHz，与名义100MHz分别记录 |
| `speedKmh=3` | km/h | 可选 `chasi_time_evolution`；静态 `chasi_generate_scene` 不消费 | 默认静态链未生效；速度要求只在可选动态回放近似体现 |
| `durationTti=340,ttiMs=1` | TTI/ms | `chasi_generate_scene` events、`chasi_traffic`、`chasi_evaluate` | 生效；样本窗口半开 `[0,340)` |
| `serviceTrps=2` | 每UE目标服务TRP上限 | `chasi_generate_scene:63` | 生效；实际可少于2，取决于可用 TRP |
| `branches`, `solver`, `outputDir` | 运行分支/旧选项/输出路径 | `chasi_run:13-36,90-142` | `branches`、`outputDir` 生效；`solver` 字段未决定正式运行分支，视为未生效的遗留配置 |
| `slowPeriodTti=340,fastPeriodTti=40,offeredMbps=5` | TTI/Mbps | `chasi_run:130-139` 传可选回放 | 正式默认0 TTI回放，不影响静态结果 |

## 物理来源与尚不能宣称的结果

原始 `典型验收场景.png` 已读：7站、三扇区、64TRX（8水平×4垂直×2极化）、UE 2Tx/4Rx、273数据RB、SRS 16×16+17 RB、20ms/跳、340ms周期、30%业务负载、3km/h、30–50% PRB使用率。`难题1.png` 指定理想集中参考、无协作独立功控基线、80%边缘改进和30%辐射功率降低等比较。`用户速率协议定义.png` 规定按突发及UE秒统计；系统方案 PDF 中的分布式 ADMM 是研究方案，不是目前已部署代码。当前实现与要求的缺口：严格小区面积均匀区域、物理双极化阵列、链路互易校准、系统级SRS SINR、750m外完整干扰、协议级体验样本和共同基线均未通过。0.08/0.92、方向图4次、0.025、100m、路径指数3.2、相关0.35、750m、20W只标项目假设或当前配置，不能归给原图或标准。

## 本轮数值证据和未完成项

`tests/chasi_export_canonical_parity.m` 与 `tests/verify_chasi_canonical_parity.py` 使用显式公共复数 H/C/服务掩码/初始 w；五套 fixture、外层0/2全部通过：最大目标绝对差 `1.776e-15`，w `6.663e-16`，A `1.671e-16`，Ω `8.882e-16`，E `3.331e-16`，真sum SE `1.804e-16`，功率 `1.11e-16`，ADMM原始残差 `1.087e-16`。这是**求解器显式同输入**证据；拓扑随机样本、估计后验、业务到达的跨语言显式同输入对拍尚未完成。静态正式运行的停止原因必须以各自 `summary.json` 为准。

代码路径中 `H_true` 参与模拟观测，也进入 `ideal` 分支及最终评价；普通非理想分支的初始化、U/E/Ω及子问题只见 `H`/`C`。不能简单说真实信道仅用于最终评价。没有真实调制符号、SRS/PDSCH波形或物理前传；发射/接收式为协方差等效模型。
