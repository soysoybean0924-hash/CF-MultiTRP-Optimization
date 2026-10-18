# CHASI 数学符号—代码—图—证据索引

基线：`9527089`；总图 [02](chasi_native_atlas/02_formal_flow.pdf)，变量逐项 [V01–V37](CHASI_VARIABLE_ACCEPTANCE_20261017.md)，公式 [HTML](chasi_native_atlas/formula_reader.html)／[PDF](CHASI_UNIFIED_TRACE.pdf)／[TeX](CHASI_UNIFIED_TRACE.tex)。C 是当前 MATLAB 模型，L 是独立旧 MATLAB 搜索链，Z 是2023参考仓库公式类别；不能把 L/Z 当正式入口执行。

| 入口符号与变量 ID | 公式入口 | 源码函数（9527089 行） | 图节点 | 实际证据与去向 |
|---|---|---|---|---|
| $s_m,q_k,d_{kl},\beta_{kl}$ V01–V07 | C01–C05 | `chasi_generate_scene>geometry:142`, `link_gain:207` | 03站/TRP/UE，04轴 | `scene.mat`,`scene_manifest.json`；坐标真实样本，不采用图03示意坐标 |
| $H^{true}_{klg},R_{rx}$ V08,V10 | C06 | `chasi_generate_scene:11,74-80` | 04、05 | `scene.mat`; 图04明示双极化阵列缺口 |
| $n_g^{data},n_g^{SRS},\nu_g$ V14,V15 | C07,C08 | `chasi_config:50-52`, `chasi_generate_scene:129`, `chasi_matrix_wmmse>resourceWeight:534` | 05、06 | 17组，末组17RB；config/manifest/MAT |
| $b_{kg},\chi_{lkg},r_{kg}$ V16–V18 | C09 | `chasi_generate_scene:61-64,135-139,159-205` | 03、06 | `scene.scheduleMask`, group `servingMask`, `numStreams`；服务不是优化变量 |
| $\widehat H,C,P_{SRS},t_{age}$ V09,V11–V13 | C10–C12 | `chasi_generate_scene:47-130,281` | 04、05 | `scene.mat`, `events.json`, summary；非理想分支求解输入 |
| 截断与遗漏 $d_{max}$ V37 | C13 | `chasi_generate_scene:68-71`, `chasi_evaluate:60-65` | 03、09 | summary 只诊断，未补偿干扰 |
| $w_{ljg},p_l$ V19,V20 | C14–C16,C26–C29 | `chasi_matrix_wmmse:15-31,440-541` | 06–08、10 | `*_precoders.mat:precoder`, summary per-TRP power；w已含功率幅度 |
| $T_{kjg},F_{kg}$ V21,V22 | C16,C17,C32 | `chasi_matrix_wmmse>state:374-400`, `chasi_evaluate>true_rates:137` | 08、09 | 模型等效，未生成发射符号 |
| $A_{kg},E_{kg},\Omega_{kg}$ V23–V25 | C18–C20 | `chasi_matrix_wmmse>state:393-399` | 07、08、10 | `*_precoders.mat:rxCombiner,mseMatrix,mseWeight` |
| $\eta_k,R^{est}_{SE,kg}$ V26,V27 | C21–C23 | `chasi_matrix_wmmse>objectiveSnapshot:301-344` | 07、09 | summary objective，MAT `userWeight`; PF只在PF分支 |
| $M,B,D,Q$ V28 | C24,C25 | `chasi_matrix_wmmse>quadratic:403`, `qapply:420` | 07 | CG输入系数；不是物理信号，常规输出未单存 |
| $x,z,u,\rho$ 与CG方向 V29–V31 | C26–C31 | `chasi_matrix_wmmse>precoder_admm:440`, `cg:485`, `project:499` | 07 | `solution.trajectory`→`summary.json`; z是可行返回量 |
| $R^{true}_{SE},R_{exp}$ V32–V36 | C32–C36 | `chasi_evaluate:43-136,137-205`, `chasi_traffic:1-37` | 09、10 | `*_per_ue.csv`, summary；体验仅代理 |
| 动态 $\varphi_{Doppler}$ | C37,C38 | `chasi_time_evolution:1-425` | 12 | 默认不执行；`test_chasi_dynamic_srs_timing` 核对非默认跳间隔；SVD重置不是在线WMMSE |
| 旧波束 $W^{old}$、旧速度 V | L01–L17 | `matlab/core/cf_evaluate_candidate.m`, `cf_search.m` | 11 | 不流入正式 `chasi_run`，历史结果独立 |
| 参考标量接收器 $v_k$ | Z01–Z03 | 2023参考 `WMMSE_ADMM_Func.py` | 11 | 与当前矩阵预编码 w / 接收 A 不同模型，论文原式编号待核实 |

**验证入口：** `tests/test_chasi_native_scene.m`、`test_chasi_srs_timing.m`、`test_chasi_native_entry.m` 核查原生组级模型；`tests/chasi_export_canonical_parity.m` 与 `tests/verify_chasi_canonical_parity.py` 对显式 H/C/初值五组 fixture 做求解器对拍。正式规模进一步用 `tests/chasi_export_formal_shared_input.m` 和 `tests/verify_chasi_formal_shared_input.py`，从已保存的同一 210/420 场景对初始二次项、固定状态、ADMM 轨迹、完整求解及真信道评价逐层比较；具体误差和一项210 UE Ω门槛未通过见 [验证记录](CHASI_VALIDATION_20261017.md)。图与公式只解释代码；数值对拍不证明协议体验或物理阵列验收。正式运行日志及摘要以 `results/chasi_matlab/formal210_20261017_srs_contract2/` 和 `formal420_20261017_srs_contract2/` 为准。
