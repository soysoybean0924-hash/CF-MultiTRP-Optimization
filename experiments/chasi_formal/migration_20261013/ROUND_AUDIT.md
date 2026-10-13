# 茶思代码迁移、原始指标与本轮实物核查（2026-10-13）

## 证据范围与不干扰记录

先读取仓库 `AGENTS.md`、Git状态和正在运行进程；本轮没有启动210/315/420 UE求解，也未更改旧正式结果。三张原始图片位于 `C:\Users\sypxx\Desktop\AAAa研一\AAAa研二\MIMO huawei\`：`难题1.png`、`典型验收场景.png`、`用户速率协议定义.png`，已逐张视觉检查。老师的《202609-系统方案.pdf》《研究主题分析.pdf》已以 `pdftotext -layout` 读取，它们是慢/快层、椭球和分布式建议，不是原图验收硬条件。旧审计 `../READ_ONLY_SOURCE_AND_RUN_AUDIT_20261013.md` 用于定位文件，以下新增结论以源码、原图、存档为准。Git树存在其他会话未提交改动；本轮仅隔离新增文件及明确的状态/契约改动。

## 1. 原图、方案与可计算字段

| 原图位置和原句/参数 | 正确口径及公式 | 源码/存档及状态 |
|---|---|---|
| `难题1.png` 性能条款：“50%PRB下，边缘体验提升达成集中式协同（理想信道估计）的80%” | 用户已明确按**相对提升80%**：`(E_candidate-E_baseline)/(E_ideal_central-E_baseline)≥0.80`，要求共同边缘率定义、共同资源与正的理想增益。原句没有写“候选率达到理想率的80%”，也未明确本条共同基线。 | `run.py:299-311` 的 `bottom5_gain_fraction_if_positive_reference_gap` 是候选代理；`bottom5_stat_over_ideal` 是另一比值，**不用于所确认的80%口径**。`protocol_contract.acceptance_contract` 明写公式，正式pass仍null，因RLC样本和理想参考未闭环。 |
| `难题1.png` 与 `典型验收场景.png`：7站×3小区、每小区10–20 UE、每TRP64发、UE2发4收、100MHz/30kHz/273RB、UMi/UMa、3km/h | 21TRP、210–420UE；2个上行SRS发射口、4个下行接收口与数据流数`d`是不同轴。 | `config.py`、`scenario.generate` 有规模/子集场景；`pathloss.py` 是UMi/UMa大尺度子集，主分支不等于完整38.901 CDL。旧315/420输出不能与seed27同条件拼图。 |
| 原图SRS 17跳×20ms、前16组16RB末组17RB；CSI-RS40TTI；系统SRS条件 `Presinr<-10dB` | 17组覆盖273RB，SRS2口与CSI-RS4口映射需单独假设；系统级SINR需上行发送功率、复用/干扰域和聚合定义。 | `config.rb_groups`、`scenario.py`、`srs_reuse.py`、`time_evolution.py`有事件/合成协方差；`evaluate.py` 的 `system_srs_sinr_db=null`，现有按服务链路统计不能代替系统指标。 |
| 原图30%负载、尾部数据约30%/尾部TTI约60%、30–50%PRB | 到达流量、buffer非空的UE×TTI占比、分配PRB占比、真实占用PRB占比是不同分母；不可自动互换。 | `traffic_model.generate_traffic` 的 `target_busy_fraction` 是自定忙时目标；`evaluate.py`另报 `allocated_prb_fraction_mean`/`actual_prb_fraction_mean`。没有已确认的原图30%负载正式通过判据。 |
| `用户速率协议定义.png`：剔除burst前空闲/末TTI，在每个1秒窗汇聚合格业务，按UE秒样本CDF取尾部 | 必须保留每burst到达、完成、末TTI、跨窗、未完成、无样本UE的原事件；不能删失后只报幸存者均值。 | `protocol_contract.py`/`time_evolution.py`仅容量+队列代理，缺ACKed RLC SDU/BLER，seed22有效138/210、缺72；`2.789116Mbps`是有样本者的候选分位，不是收益。 |
| 原图挑战2：以小区间无协同、独立功控为基线，功耗下降30%且体验损失<10% | 必须有严格的无协同独立功控基线、相同流量/时窗与系统能耗（发射、电路、休眠、前传）定义。 | `solver._solve_local_mrt`是home-only MRT参考；`power_by_trp`只算辐射功率。旧MATLAB `basic`也非严格无协同独立功控。尚不能判断。 |

老师方案提出慢层关联/组簇/预算，快层接收、波束、功率，测量质量/年龄驱动椭球或统计误差，TRP本地更新；本项目只完成规则服务集/调度、固定rank、统计期望MSE和集中式快层的若干部分。原图没有要求使用特定WMMSE、ADMM或椭球公式。可交付的研究问题是：在多TRP相干发送、非理想CSI与受限资源下，同时决定/评估边缘业务体验和能耗；现在实际优化主要为固定资源分配下的复矩阵V，其他决策尚未形成联合闭环。

## 2. 三种“迁移”和真实调用链

旧MATLAB：`cf_search.m` 的GA/PSO/SRACOS候选 → `cf_decode_candidate.m` 的9维参数 → `cf_evaluate_candidate.m` 构造`b/p/r/W`并作旧内层更新 → `cf_compute_true_objective.m` 重算`J_true`，`cf_compute_experience_rate.m`仅旧代理。新分支没有替换`cf_evaluate_candidate`的内层，旧外层不调用新矩阵求解器。`cf_run_chasi_candidate.m` 是有限候选适配器，也没有把9维旧候选无损送入矩阵问题。

正式Python：`cf_run_chasi_formal.m`/`run_chasi_formal.m` 拼CLI → `chasi_formal_implementation.run.main` 调 `scenario.generate`（Python重新建网络、真/估H、资源调度/几何服务掩码）→ `solver.solve`：`_initial`/`_state`/`_quadratic_parts`/`_solve_v_admm` → `evaluate.py` 真信道/业务代理 → 可选 `time_evolution.py` 回放 → `summary.json`、逐UE项、`*_precoders.npz/.mat`。MATLAB CLI传seed、UE/小区、rank、服务TRP数、PRB比例、SRS/CSI模式、迭代容差等**标量配置**；不传复数`H_est/H_true`、逐组serve/schedule或显式功率预算。Python回传JSON和保存的复数`V/U/W`，MATLAB能读回复数V。桥接原因没有完整开发日志；作为工程推断，是为了先隔离验证Python复矩阵原型并保持旧MATLAB入口可调用。不能将CLI读回复数与“MATLAB向Python传实际复数信道”等同。

现在的三个层次：①原2023固定方向实数标量功率 → 本项目多流复矩阵数学**重推**，实际借鉴WMMSE/ADMM思想而非照搬其`WMMSE_ADMM_Func.py`；②Python复矩阵公式 → 本轮独立MATLAB语言实现（小例对拍）；③旧/正式场景数据 → MATLAB求解器显式输入接口及Python场景对象导出器 `export_scene_to_matlab.export_scene` 已有，同一小场景的H/C/serve/UE ID/RB/V MAT字段验证通过；正式210UE场景自动调用、PF/回溯和旧候选路径仍未接通。新求解器不能直接充当旧候选评价器。

## 3. 数组、seed与初始化

每资源组 `H_est/H_true[K_g,L,4,64]`、误差协方差`C[K_g,L,4,4]`、`V[L,K_g,64,d]`、`U[K_g,4,d]`、MSE权重`W[K_g,d,d]`、`serve[L,K_g]`。seed27样本`V_03=[21,42,64,2]`、`U_03=[42,4,2]`、`W_03=[42,2,2]`。42人是此组在各home-cell规则选择的活动UE，其他组可重复出现同一UE；不代表全网仅42人。17组宽度16×16+17=273，`tx_rb_count`可小于组宽，`a_g=txRB_g/273`用于功率与目标。服务掩码将禁用的`V[l,i]`强制零。rank由配置指定（seed27为2），可跑单流/多流但未做rank自适应优化。旧MATLAB波束变量`W`、此处矩阵MSE权重`W`、PF导数标量`1/(R_u+floor)`是三件不同东西。

seed27整数为`20261027`。`scenario.generate`主RNG用`cfg.seed`生成拓扑/调度；真H、CSI误差、SRS噪声、导频复用分别用`+201/+202/+203/+204`，校准`+101`；`traffic_model.generate_traffic`在所给交通seed上再`+303`，移动回放`+90817`。`solver._initial`对允许链路做H的SVD并投影至跨组每TRP预算，默认无随机抽样；其他初始化的扰动可用`cfg.seed+cfg.initialization_seed`。每一轮`_state(H,C,V)`**由当前V计算**U与W；固定它们后内层ADMM更新V，再进入下一轮，绝非每轮重新随机抽UVW。

`G_ki=Σ_l H_kl V_li`先按服务TRP相干相加；`Ryy_k=I+Σ_i G_kiG_kiᴴ+Σ_l ||V_l||² C_kl`，`U_k=Ryy_k⁻¹G_kk`，`E_k=I-UᴴG-GᴴU+UᴴRyyU`，`W_k=E_k⁻¹`。固定U/W后`min_V Σ_g a_g(VᴴQ_gV−2Re B_gᴴV)`，约束每TRP`Σ_g a_g||V_gl||²≤P_l`。本轮MATLAB `chasi_matrix_wmmse.m`以这些真实数组为输入，含状态、Q作用、复CG、集中式`X=Z` ADMM、跨组投影和外层停止；未在函数内生成随机网络。它当前实现**总估计率目标**，尚不含Python正式PF跨组全局导数、回溯、不同误差分支及正式场景导出，因此不可宣称完整正式等价。

## 4. 小例实测与分布式边界

运行命令（只需小例）：

```powershell
& 'F:\bin\matlab.exe' -batch "run('experiments/chasi_formal/migration_20261013/test_chasi_matrix_fixture.m')"
& 'C:\Users\sypxx\py\python.exe' experiments/chasi_formal/migration_20261013/compare_matlab_python.py
& 'C:\Users\sypxx\py\python.exe' experiments/chasi_formal/migration_20261013/trp_sharing_admm_demo.py
```

`matlab_fixture_input.mat`是相同的2TRP×2UE×2资源组×4Rx×4Tx×1流、16/17RB、0.11W输入；`matlab_fixture_output.mat`为MATLAB输出。`matlab_python_comparison.json`：三快照目标绝对差`1.39e-17/0/1.67e-16`，最大V元素差`6.11e-16`，功率差`8.33e-17W`，两次Python ADMM在29/17轮停。证明该小例状态、V更新、投影和外循环数值相同。`test_scene_export.py`用**调用方供应**的小场景验证MAT文件逐组保持H/C/serve/UE ID/RB/初始V；导出器不重生随机网络。**未验证**64Tx/4Rx/rank2、PF、正式210UE场景导出后MATLAB求解或工程性能。另 `test_v_reference.py` 的独立SLSQP（Sequential Least Squares Programming）固定U/W小例：ADMM目标`-0.248503145836`与SLSQP`-0.248503146456`差`6.20e-10`，两TRP功率约0.11W，但严苛容差下600轮残差未达阈值；目标接近/约束可行与残差收敛必须分开。

当前正式Python `_solve_v_admm` 是集中式：X需要全H的相干Q作用，Z按TRP预算可分，dual按X=Z；`local.py`只是消息模拟。新`trp_sharing_admm_demo.py`提出**sharing分裂**：每TRP保留不同的物理`V_l`及本地`A_l V_l`（`A_l`由本地H列构造）；协调节点持有副本`z_l`和`Σ_l z_l`，求`min Σ_l [a d_l||V_l||²−2aRe⟨b_l,V_l⟩+I_{P_l}] + (Σ_l z_l)ᴴM(Σ_l z_l)`，约束`A_l V_l=z_l`。本地x更新只需本地H、b、误差对角及协调节点发回的z/对偶；U/W的接收端统计、M汇总仍需协调或可信汇聚。**不设置物理V_l相等**。本轮在单进程串行模拟3TRP/2UE，单TRP单向消息16个complex128=256字节/轮（未含M/U/W/控制），与集中式SLSQP目标差`9.81e-6`、功率均约0.11W；1200轮原/对偶残差`2.00e-6/7.43e-5`，未达到演示阈值`1e-7`，不叫收敛，不叫并行部署。结果见`trp_sharing_admm_result.json`。

## 5. 运行证据与七张图

逐图解读和30秒话术在`README.md`，CSV/PNG/PDF/SVG在本目录，`plot_saved_seed27.py`可只读重画；`plot_manifest.json`保存输入与源码哈希。图1 PF目标`753.603→1067.412`；图2最后相对V变化`0.004742<0.005`；图3**各WMMSE轮结束时**ADMM最后原/对偶`0.012165/0.002988`分别低于`0.018833/0.010123`，加上目标相对变化`5.08e-5<1e-4`才是三重局部停止；图4 21TRP加权辐射功率各近20W；图5/6同条件名义/统一相对/异质各210个UE的静态底5%代理`0.791579/0.749215/0.747725Mbps`，异质未胜。`seed27_error_mechanism_20261013/diagnostic.json`显示服务链路归一误差中位约0.708、统一/异质比中位约0.986及V Hessian误差项差，证明机制进入U/W/V且多数近饱和，不证明收益。图7单独是seed22秒级候选，138/210 UE有效，72无样本，`terminal_bursts_not_queue_completed=1589`，幸存者底5%`2.789116Mbps`不能与静态代理比收益。seed27当前 `evaluate/run/time_evolution`哈希与当时不同；旧315/420用不同floor、旧源码/场景条件，不能拼接。210/315/420跑过、seed27局部停、代理可算、正式验收通过是四个不同命题；最后一个目前没有证据。

## 6. 38.901/CDL 与后续依赖

参考源码真实位置见 `../source_manifest_20261012.json`：2023功率仓库 `D:\GitHubProjects\power-allocation-cell-free-main\WMMSE_ADMM_Func.py`（GPLv2）；隔离CDL适配 `C:\Users\sypxx\Documents\CF mMIMO TRP\chasi_tr38901_staging\chasi_formal_implementation\tr38901_cdl.py`，上游MIT，审计见同处`TR38901_ADAPTER_AUDIT.md`。隔离适配已有CDL-A/D链路形状、极化阵列、频时响应和seed测试；可复用链路级PDP、角度/极化/XPR/相关响应构件。独立PDP/角度/XPR统计对拍、全场景主分支接入、2口SRS到4口DL后验误差均未完成；不得判参考仓库不可用，也不得称标准一致性通过。因主项目 `config/scenario/run` 已变化，本轮未直接覆盖隔离副本或运行中的正式场景。

下一步依赖顺序：①保留原始burst事件并固定无样本/跨秒规则及ACKed RLC计数；②明确30%到达负载、系统SRS分母和50%PRB政策；③CDL链路统计对拍和2SRS/4DL端口条件后验；④在已有场景导出器上接正式210UE场景与MATLAB同场景对拍，加入PF与回溯；⑤调度/关联/rank候选和快慢层更新形成闭环；⑥sharing原型残差/交换数据/并行节点完善；⑦构造同口径理想集中与严格无协同基线，多seed检验相对提升80%、节能30%且体验损失<10%。

## 5分钟看图汇报

1. **0–1分钟**：开原图三张和本报告第1节。说“研究的是21TRP、多UE、2口SRS观测与4口下行接收；80%按相对提升，当前正式口径还缺同基线及协议计数”。老师问“是否已达标”，答“没有正式判定”。
2. **1–2分钟**：开`fig01`和`fig02`。说“210UE固定调度/服务下，PF代理753→1067，末次V变化0.004742，配合第三项才局部停”；问“全局最优吗”，答“不能证明”。
3. **2–3分钟**：开`fig03`和`fig04`。说“ADMM图每点是一个WMMSE轮末值，21TRP加权跨RB功率符合20W”；问“节能30%吗”，答“只验证辐射预算，非系统能耗”。
4. **3–4分钟**：开`fig05`和`fig06`。说“同样210人三支，误差模型确实进入V，但静态尾部代理异质支低于名义”；问“鲁棒失败吗”，答“仅此seed/模型/代理负结果，不能推广”。
5. **4–5分钟**：开`fig07`、本报告第4节和`matlab_python_comparison.json`。说“秒级完成筛选只剩138人，2.789不是提升；数学矩阵算法已小例同输入改写到MATLAB，旧外层/正式场景未接，三TRP本地sharing仍串行且残差未停”；问“代码在哪里”，展示三个新脚本和JSON即可，无需重跑210UE。
