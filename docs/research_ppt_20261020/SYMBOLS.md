# 核心符号与代码字段

基线 `db9d7e3c71a75f8f9724b743fc78023185b5cddf`。数组维度按资源组 `g` 内的 `K_g` 个活动 UE；MATLAB 索引从 1 起。完整逐式说明另见仓库 `docs/CHASI_UNIFIED_TRACE.tex` 的 C01–C38、L01–L17、Z01–Z03。本表不把旧搜索模型的同名字母等同于正式矩阵模型。

| 分组 | 符号 | 中文含义 | 维度 / 单位 | 正式代码字段或来源 |
|---|---|---|---|---|
| 索引 | `l,k,j,g` | TRP、接收 UE、求和 UE、资源组 | 21、210/420、210/420、17；无量纲 | `chasi_config`; `resources(g).ueIds` |
| 索引 | `N_t,N_r,r` | TRP 发射端口、UE 接收端口、传输流数 | 64、4、2 | `txPorts,ueRxPorts,rank` |
| 几何 | `s_m,q_k` | 站址、UE 位置 | `7×2`, `N_UE×2`；m | `scene.topology.site_xy`, `scene.ue_xy` |
| 几何 | `home(k)` | UE 初始归属 TRP | `N_UE×1`；ID | `scene.home` |
| 信道 | `H^{true}_{klg}` | 真信道 | `4×64`；归一化 | `resources(g).H_true` |
| 信道 | `Ĥ_{klg}` | 估计信道 | `4×64`；归一化 | `resources(g).H` |
| 测量 | `C_{klg}` | 每发射列共享的接收侧条件误差协方差 | `4×4`；归一化 | `resources(g).C / C_stat` |
| 测量 | `P_srs,Y_s,Y_c` | SRS 行选择、SRS 与 CSI-RS 观测 | `2×4`,`2×64`,`4×64` | `chasi_generate_scene` 的局部量 |
| 测量 | `n_s,n_c,t_s,t_c` | SRS/CSI-RS 噪声方差与 CSI 年龄 | 标量归一化；年龄 ms | `chasi_generate_scene` 的局部量；`age_ms` |
| 资源 | `b_{kg}` | UE 组调度掩码 | `N_UE×17`；布尔 | `scene.scheduleMask` |
| 资源 | `χ_{lkg}` | TRP–UE 组服务掩码 | `21×K_g`；布尔 | `resources(g).servingMask` |
| 资源 | `ν_g` | 第 g 组实际发射数据 RB 比例 | 标量；无量纲 | `resourceWeightNu=tx_rb_count/273` |
| 发射 | `w_{ljg}` | 含幅度复预编码块 | `64×r`；模型幅度 | `solution.precoder{g}(l,j,:,:)` |
| 功率 | `p_{lg},p_l` | 组内与跨组 TRP 功率 | 标量；模型 W | `state` 局部功率；`solution.power` |
| 功率 | `P_l` | 每 TRP 跨组功率预算 | 标量；默认 20 W | `powerWattPerTrp` |
| 接收 | `F_{kjg}` | UE k 对数据 UE j 的相干有效信道 | `4×r` | `state` 的 `effectiveChannel` |
| 接收 | `R^{yy}_{kg}` | 接收协方差 | `4×4` | `state` 的 `rxCovariance` |
| WMMSE | `A_{kg}` | MMSE 接收矩阵 | `4×r` | `rxCombiner` |
| WMMSE | `E_{kg}` | MSE 矩阵 | `r×r` | `mseMatrix` |
| WMMSE | `Ω_{kg}` | MSE 权重 | `r×r` | `mseWeight` |
| WMMSE | `η_k` | 用户效用权重 | 标量；无量纲 | `userWeight` |
| 子问题 | `M_{kg},B_{lkg},D_{lg}` | 固定接收器/权重后的二次系数 | `4×4`,`64×r`,标量 | `quadratic` 返回 `parts.M/B/D` |
| 子问题 | `Q_g` | 作用于预编码的隐式二次算子 | 输入/输出同 `w_g` | `qapply` |
| ADMM | `x,z,y` | 原变量、可行副本、缩放对偶 | 均同 `w` | `precoder_admm` 局部量 |
| ADMM | `ρ` | 增广项罚系数 | 标量；默认 0.05 | `cfg.rho` |
| 评价 | `R^{SE}` | 频谱效率 | bit/s/Hz | `true_rates`; `per_ue_physical_bits_per_s_hz` |
| 评价 | `R^{exp}` | 有效忙时体验代理 | Mbit/s | `per_ue_experience_mbps` |

**区别：**`H^{true}` 用于合成模拟观测、理想分支和最终评价；非理想分支求解只见 `Ĥ,C`。`p` 由 `w` 求出，发送信号里不再乘 `√p`。`C` 是统计协方差，尚未被校准成确定性误差椭球。
