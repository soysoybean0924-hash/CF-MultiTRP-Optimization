# 变量字典与公式—源码—图索引

默认轴：全局 UE `k`；资源组 `g=1..17`；TRP `l=1..21`；组内局部 UE `i` 经 `resources(g).ueIds(i)` 映到 `k`。发送端口 64、下行接收端口 4，默认 rank 2。复数共轭转置记 `H` 上标；代码中的 `'` 是 MATLAB 共轭转置。

| 符号 / 单位与维度 | MATLAB 字段或局部量 | 产生 → 消费 | 公式 / 图 / 状态 |
|---|---|---|---|
| 站址 `s`、UE 位置 `q` / m，二维 | `scene.trp_xy`, `scene.ue_xy` | `chasi_generate_scene>geometry` → `scene_manifest.json`, `link_gain` | C01–C02 / 03；位置抽样为项目假设 |
| TRP–UE 距离 `d` / m、链路增益 `beta` / 无量纲 | `prior_gain` | `link_gain` → H 与观测 | C03–C05 / 03–05；默认 surrogate |
| `H_true` / 复 `4×64` 每 `k,l,g` | `resources(g).H_true` | `chasi_generate_scene` → 真信道评价、理想分支 | C06,C16,C32 / 05,08,09；非波形 |
| `H_est` / 复 `4×64` 每 `k,l,g` | `resources(g).H` | SRS/CSI 后验 → `state`, `quadratic` | C10–C12,R01 / 05,07；统计观测模型 |
| `C` / `4×4` 接收边际协方差 | `C_stat`, 求解器局部 `C` | 场景后验 → `state`, `quadratic` | C11–C12,C17,C24,R01–R02 / 05,15；非校准椭球 |
| `P_srs` / `2×4` 行选择矩阵 | `srsRxRows` | 配置 → 后验 | C11 / 04–05；未建互易校准 |
| 质量 `gamma_s` / dB、年龄 `t_s` / ms | `pilotSnrDb`, `age_ms` | 配置、SRS 事件 → 观测噪声和 C | C10–C12,R01 / 05,15；默认 -10 dB |
| RB 数 `n_g` / RB，权重 `nu_g` / 无量纲 | `rb_count`, `srs_rb_count`, `tx_rb_count`, `resourceWeightNu` | 配置/调度 → 目标、功率与评价 | C07–C08 / 05–06；16×16+17=273 |
| 调度 `b_kg` / 二值 | `scheduleMask` | `schedule` → 求解资源、体验口径 | C09 / 06；固定规则 |
| 服务 `chi_lkg` / 二值 | `servingMask` | `schedule` → 波束掩码 | C09,C26 / 03,06,07；固定规则 |
| 流数 `r_kg` / 流，默认 2 | `rank`, `numStreams` | 配置 → 预编码/接收轴 | C14–C21 / 04,06；尚非自适应 |
| 数据符号 `s_j` / 复 `r×1` | 无显式数组 | 理论信号式 → 二阶协方差 | C15 / 08；未产生 IQ/OFDM |
| 预编码 `w_ljg` / 复 `64×r`，含幅度 | `precoder` | SVD 初始化、ADMM → 评价和 MAT | C14–C16,C26–C31 / 06–10；当前优化量 |
| 有效信道 `F_kjg` / 复 `4×r` | `effectiveChannel` | H 与 w 相干叠加 → 协方差/SE | C16–C17,C32 / 08–09；TRP 幅度先相加 |
| 组功率 `p_lg` / W | 局部 `p`, `chasi_power` | w 范数 → 误差项、跨组预算、摘要 | C17,C26,C29 / 06–09；不是独立优化变量 |
| 接收器 `A_kg` / 复 `4×r` | `rxCombiner` | `state` → E、M/B/D、MAT | C18–C19,C24 / 07–08；MMSE 矩阵 |
| MSE `E_kg`、权重 `Omega_kg` / 复 `r×r` | `mseMatrix`, `mseWeight` | `state` → 速率、二次项、MAT | C19–C20,C24 / 07–08；与预编码 w 不同 |
| 用户权重 `eta_k` / 无量纲 | `userWeight` | `objectiveSnapshot` → `quadratic` | C22–C24 / 07；仅相应分支按 PF 更新 |
| 二次系数 `M[4,4]`,`B[64,r]`,`D` | `parts.M/B/D` | `quadratic` → `qapply`, CG | C24–C26 / 07；局部临时量 |
| ADMM `x,z,y` / 与 w 同形，`rho` / 罚参数 | `new`, `z`, `dual`, `rho` | `precoder_admm` → 投影、残差、回溯 | C27–C31 / 07；集中式变量 |
| 真信道 SE / bit/s/Hz | `true_rates`, `per_ue_physical_bits_per_s_hz` | `chasi_evaluate` → CSV/JSON | C32–C33 / 09–10；不能等同体验 |
| 体验代理 / Mbps | `per_ue_experience_mbps` | 业务掩码、容量代理 → CSV/JSON | C34–C36 / 09–10；协议验收未核实 |
| 旧候选 `x_old` / 9维归一化 | `BestX`, `cf_decode_candidate` | `cf_search` → `cf_evaluate_candidate` | L03,L17 / 14；独立旧链 |
| 旧搜索目标 `J_old`、可选适配目标 `J_adapter` | `Objective`, `ObjectiveName` | 旧评价器/适配器 → 搜索排序 | L07,L15,L17 / 14；与正式目标分开 |
| 候选误差椭球 `U(alpha)` | 无 | 待测量标定 → 待设计求解器 | R03–R04 / 15；拟研究 |

保存路径：`chasi_run` 写 `scene.mat`、`scene_manifest.json`，再写每分支 `*_precoders.mat`、`*_per_ue.csv`、`summary.json`。图 10 展示流转；离线 Python 对拍仅在测试命令另行调用。详细原有 V01–V37 字典仍在 `docs/CHASI_VARIABLE_ACCEPTANCE_20261017.md`，本表按阅读顺序补齐生产者和消费者。
