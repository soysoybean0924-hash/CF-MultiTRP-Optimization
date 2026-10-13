# 茶思正式分支当前状态

> **2026-10-13 本轮实物更新（优先于下方历史记录）**：已按用户明确口径把原图“50%PRB下，边缘体验提升达成集中式协同（理想信道估计）的80%”记为相对提升分数 `(候选边缘率－共同基线边缘率)/(理想集中协同边缘率－共同基线边缘率)≥0.80`；原图并未明确该条的共同基线、有效UE细则，因此正式判定仍为空值，绝不可把候选率/理想率≥0.8当成结论。此解释与原句没有直接冲突。保存证据绘成七张独立PNG/PDF，见 `migration_20261013/README.md`。新增独立 MATLAB 复矩阵求解模块 `migration_20261013/chasi_matrix_wmmse.m`，显式接收 H/C/服务掩码/RB/预算，同一两TRP小例与 Python V 的最大元素绝对差 `6.11e-16`，仅证明该小例的数值语言等价；未接入旧 `cf_evaluate_candidate` 或主 Python 场景导出。三TRP sharing-ADMM 仅串行本地节点原型，目标对集中式 SLSQP 差 `9.81e-6`，1200轮后原/对偶残差 `2.00e-6/7.43e-5`，**未达所设停止阈值**，不是正式分布式运行。图与新代码的证据见 `migration_20261013/ROUND_AUDIT.md`。下方原有运行、负结果和版本边界继续保留。

> 2026-10-13 现场汇报证据整理：新增 `PRESENTATION_EVIDENCE_PACK_20261013.md` 与只读 `show_presentation_evidence.py`。已核对实际 MATLAB→Python正式入口、旧 MATLAB 搜索/评价器未贯通、U/W/V复数MAT桥接、固定U/W小例对拍、seed27完整轨迹及seed22业务筛选偏差。小例对拍当前代码复测通过但严苛ADMM残差600轮未停；210 UE仅展示保存证据，未重跑。seed27当前 `config/scenario/solver/srs_reuse` SHA仍匹配历史运行，而 `evaluate/run/time_evolution` 已变，不能声称整个运行可逐字节重现。未修改算法、默认值或评价口径，未push。下方开发历史原样保留。

> 2026-10-13 11:39 增量：本轮已进入“测量与评价契约接入＋异质误差机制离线核查”。以下是最新状态；后文全部历史记录原样保留。尚未新增算法优化分支，也未重跑 WMMSE 性能实验。

## 2026-10-13 测量/评价契约与 seed27 机制进展

- **研究判断**：已有 210 UE 合成 SRS 导频复用的 B3b 配对显示，名义/统一相对/异质误差三分支均满足数值三重局部停止（18/28/28轮）；尾部静态代理分别 `0.791579/0.749215/0.747725 Mbps`。这证明合成统计误差可进入决策，但不证明异质误差改善边缘。seed27 已查看，只可用于机制诊断；所有结果仍非正式协议或全局最优。来源：`results/chasi_formal/b3b_uniform_relative210_seed20261027_20261013/{summary.json,paired_error_ablation_audit.json}`。
- **协议接入**：三张原图和引用标准的来源/假设/未定义项见 `MEASUREMENT_AND_PROTOCOL_CONTRACT_20261013.md`。新增 `protocol_contract.py`，`run.py` 输出显式 `acceptance_contract`，`evaluate.py` 在旧 0.34 秒线性分位代理旁另报经验逆 CDF、尾部均值和无有效样本置零候选；`time_evolution.py` 新增仅计本秒内**队列已完成**突发、排除末 TTI 的 UE 秒级候选和删失/未完成计数。旧字段、默认值和历史结果未改。系统 SRS SINR、官方30%负载、正式体验值、80%验收判断保持 `null`，因接收/统计/协议细则未定；新候选只有容量-队列仿真计数，不含 ACKed RLC/BLER。`tests/test_chasi_protocol_contract.py` 5 个手核测试通过，`test_formal` 回归在本轮执行。
- **seed27 离线机制证据**：新脚本 `diagnose_seed27_error_mechanism.py` 先核对场景/求解器/误差源码哈希及场景清单，再读取保存的统计 V，不重新优化。`results/chasi_formal/seed27_error_mechanism_20261013/diagnostic.json`：7938 条模型链路中756条服务、7182条非服务；服务链路归一化后验迹/(4×先验增益)中位 `0.707948`，统一相对/异质迹比中位 `0.986413`，756条服务链路均已测；固定同一 U/W 的 V 误差 Hessian 对角项相对差异中位 `1.12%`、95分位 `20.34%`。因此多数服务链路的相对模型差异小，但差异并未在 U/W/V 接口完全丢失；尾部无收益属于本合成场景的负结果，不能推广。`solver._state` 使用完整 4×4 RX 协方差，`_quadratic_parts` 使用 `tr(M_k C_kl)`，在 TX 各列独立同分布假设下 V 误差块退化为 TRP 标量，不是误把矩阵只取迹；更丰富的发射方向相关性尚未建模。
- **质量/年龄分组补查**：同一 seed27 离线诊断的新增独立输出为 `results/chasi_formal/seed27_error_mechanism_by_quality_20261013/diagnostic.json`。9个已测资源组各84条服务链路，20ms与280ms龄期的归一化误差中位分别约`0.70615/0.70841`；合成SRS SINR低于−30dB的107条服务链路中位`0.70846`，至少−10dB的237条中位`0.69878`。年龄范围很宽但相对后验误差普遍接近饱和，质量较好组才略有下降。0条未测服务链路，故**不能**从该场景验证缺测决策响应。初次按质量分组脚本因空档位二维索引报 `IndexError` 且无输出，已修复空档位返回 `null` 并另目录成功运行；失败没有覆盖旧诊断。
- **CDL 隔离副本**：已复核 `C:\Users\sypxx\Documents\CF mMIMO TRP\chasi_tr38901_staging` 的审计、MIT许可、`tr38901_cdl.py`、测试和补丁基线哈希。主项目 `config.py/scenario.py/run.py` 已与补丁基线不同，不能盲贴；现有测试仅覆盖链路形状/种子/功率缩放/频时变化和210 UE场景形状，缺独立 PDP/角/时频统计对拍及匹配 CDL 的矩阵 SRS 后验。故**未合并**，原路径损耗子集继续作回归，不把隔离代码算主项目能力。
- **1秒接口回放与重大限制**：保存的 seed22、21 TRP/210 UE 名义 PF 冻结决策，仅重放业务/移动而不重跑 WMMSE，输出 `results/chasi_formal/protocol_candidate_replay_seed22_completion_20261013/summary.json`。旧忙时代理底部5% `0.088942 Mbps`；3107个到达突发中仅1518个末 TTI 队列清空，新候选排除1589个未完成、另1个仅有末 TTI，计1517个突发，138/210个UE秒有样本。**仅有效样本**经验CDF底部5% `2.789116 Mbps`，**无样本置零**则为 `0`。这是严重的选择偏差/完成条件依赖，绝不是新指标下的性能提升或正式验收；旧代理与新候选不可互换。因队列模型未区分重叠到达突发的逐包完成，新计数仍只属协议结构代理。第一次未过滤队列完成状态的候选回放保留于 `protocol_candidate_replay_seed22_20261013/`，不覆盖失败设计证据。实测busy UE×TTI `29.42%`、实际PRB `35.05%`，仍不是确认的原图30%负载。
- **下一工作及依赖**：先向任务方确认未完成业务/零样本/跨秒burst的正式口径，并给队列增加逐突发ID和交付完成事件，避免“到达结束”与“业务完成”混淆；并行补导频观测固定噪声/复用/年龄的受控机制试验及独立条件误差统计；然后推导与合格边缘样本一致的可解代理，做小例梯度/子问题对拍，才允许新评估 seed 的210 UE 同目标名义/统一/异质配对。315/420 UE仅在定义与数值稳定后；不继续搜索 PF floor。失衡的绝对均值统一基线及全部负结果仍见 `DEVELOPMENT_RUN_20261013.md` 和原结果目录。

> 2026-10-13 上午持续开发更新（A2 六项已全部结束；下方历史审计与旧记录原样保留）。本轮优先级为定义→场景/业务接口→误差统计→求解配对→正式计数，不把扩大规模当作默认下一步。预登记见 `EXECUTION_QUEUE_20261012_LATE.md`，新增结果均在独立目录，旧日志未覆盖。

## 2026-10-12 晚间至 10-13 上午已完成

- **参考复现/方法迁移**：2023 固定方向单流功率参考仍是独立受限基准；本轮没有重写已与 SLSQP 对拍的固定 U/W 的 V 子问题。21 TRP/210 UE 已知 `seed=20261013` 的 `floor=0.001` 名义/统计 PF 同场景配对：名义分支 17 轮局部停止，统计分支首段 24 轮达上限后保留原目录，再独立新目录续算 3 轮（累计27）满足目标变化、V变化、最近 ADMM 精度三重局部停止。两者底部5% 静态**代理** 0.491901/0.502428 Mbps，物理总频谱效率 49.761876/52.663359 bit/s/Hz，总辐射功率均约420W；仅一已查看样本、模型自定，差异很小，**不是鲁棒创新稳定收益**。证据：`results/chasi_formal/holdout210_pf_floor1e3_seed20261013_20261012/`、`b1_known210_pfstat_floor1e3_seed20261013_20261012/`（非收敛首段）、`b1_known210_pfstat_floor1e3_seed20261013_continued_20261012/`。
- **PF 机制**：已保存同输入两底座的离线诊断发现各自底部11人重叠10人；共同尾部平均体验代理 0.02882→0.22252 Mbps，平均逐UE加权功率 0.19867→2.26796W，发射有用能量也上升；只有45/210人体验改善、165人下降。这支持“弱用户获更多功率”的机制，而非简单排名替换；并非最低速率保证。证据：`results/chasi_formal/a1_pf_tail_mechanism_seed20261013_20261012/{mechanism.json,per_ue.csv}`。代码：`diagnose_pf_tail.py`；`floor` 在 `solver._objective_snapshot/_pf_derivatives`，单位 bit/s/Hz。
- **场景/业务构建**：新增可选 `traffic_model=target_busy_fraction`，明确定义为UE×TTI buffer-nonempty 忙时占比目标；旧 `legacy_bursts` 默认保留且逐UE计数与旧结果完全相同。已保存决策的 210 UE 业务独立回放（`traffic_seed=20261021`）目标30%、实际28.23%，tail TTI/busy 61.89%、tail需求占31.69%，分配PRB49.82%，home-only MRT实际PRB24.07%、双TRP PF约34.77%；1人无有效样本。此处的30%分母是**实现假设**，不是已确认的华为“负载”定义。证据：`results/chasi_formal/d3_traffic_replay_known210_seed20261021_20261012/summary.json`、`test_traffic_model`；接口：`config.py/evaluate.py/traffic_model.py/run.py/time_evolution.py`。
- **测量/误差校准**：新增合成独立测试 `validate_error_statistics.py`，10个SRS质量/年龄/未测分组的后验协方差最大相对偏差1.95%，95% 单列高斯椭球覆盖94.85%–95.19%；受限单接收行64维固定波束椭球独立校准/测试覆盖94.47%–95.67%，支持函数误差<2e-15。证据：`experiments/chasi_formal/c1_error_statistics_20261012.json`、`c3_restricted_ellipsoid_20261012.json`。只验证自定高斯模型，不是实际SRS校准或多用户最坏情形鲁棒解。旧AWGN模式的-12dB为观测SNR；新增合成复用SINR口径见下条，官方系统SRS SINR仍未确认。
- **动态/正式计数代理**：已保存210 UE/1秒同场景移动配对，名义/统计 PF 在冻结初始决策时底部5% UE秒级代理0.05949/0.06426Mbps；每40TTI按估计CSI刷新SVD方向后0.51573/0.52076Mbps，24次刷新、功率违反约1e-7W。该收益归因于方向更新，不能归因误差鲁棒化；功率仍冻结、关联仅复核不切换。证据：`results/chasi_formal/d1_d4_mobile_replay_known210_20261012/summary.json`。另按原图“每burst一条样本”新增 `burst_metrics.py` 和手核例，1秒210 UE回放保存3260条有效burst样本及210条UE秒级代理样本，两种CDF分存，不称正式TS28.554仪表口径：`results/chasi_formal/d4_burst_protocol_proxy_known210_20261012/summary.json`。
- **新独立评估**：预登记固定 `floor=0.001`、21TRP/210UE、显式忙时30%、此前未查看的场景/业务 `seed=20261022`，同一运行 home-only MRT、名义/统计PF。名义/统计分别第20/29轮满足三重局部停止；底部5%静态代理 MRT/名义/统计 `0.071160/0.569360/0.571339 Mbps`，物理总频谱效率 `49.6727/55.0907/57.7345 bit/s/Hz`，辐射功率均约420W，实际忙时29.40%，三者实际PRB约24.77%/34.90%/34.90%。统计对名义尾部仅高0.00198 Mbps，一样本不支持稳定创新或节能；此场景仍只有AWGN观测SNR，没有导频干扰。结果：`results/chasi_formal/b1_independent210_pf001_seed20261022_busy30_20261012/summary.json`，逐用户、完整轨迹、源码哈希与内存均在目录中；名义/统计运行约565/450s，进程峰值工作集记录约306MB。
- **合成SRS复用/年龄接口**：新增可选 `srs_mode=pilot_reuse_gaussian`（默认旧AWGN保持不变），8条序列/等功率是明确仿真假设；同时同导频干扰+固定参考噪声形成观测，指数相关的当前/过去联合高斯模型形成匹配的边际后验，未建模远链路仍作导频干扰。小模型即时/160ms/裁剪干扰的后验协方差对拍相对误差均约1.3–1.4%；210 UE 场景契约确保旧/新 `H_true`、UE/RB/服务相同，后验Hermitian且最小特征值约2.73e-10。证据：`test_srs_reuse.py`、`test_srs_scene.py`、`SRS_REUSE_MODEL_CONTRACT_20261012.md`。`seed=20261023` 三档参考SNR -12/-10/-6 dB 测量-only 配对，**服务链路**合成SINR中位约 -15.34/-13.57/-10.17 dB，<-10dB比例约64.95%/60.98%/50.79%；远近全部建模链路的中位显著更低，不能混称。准确口径版：`results/chasi_formal/b2_srs_reuse_quality210_seed20261023_scopefixed_20261012/summary.json`；原先未区分“系统聚合”的输出目录保留。官方系统SRS SINR因功率/序列/聚合规则未给仍为null；并非完整38.901或真实测量校准。
- **合成复用性能负结果**：新 `seed=20261024`、21TRP/210UE、固定floor与业务/资源、home-only MRT+名义/统计PF均已结束；名义/统计分别19/29轮满足三重局部停止。底部5%静态代理 MRT/名义/统计 `0.086170/0.591557/0.557527 Mbps`；物理总频谱效率 `40.7995/45.6544/47.8812 bit/s/Hz`，辐射功率均约420W。统计项使 V 相对变化24.49%、逐UE功率绝对变化和47.24W，122人改善/88人下降，但**尾部降低**约0.0340Mbps；两分支底部11人交集10人。即统计项确实改变决策，但期望MSE代理未稳定改善尾部，不能称测量质量鲁棒创新已证实。结果与源哈希：`results/chasi_formal/b1_b2_pilotreuse210_pf001_seed20261024_busy30_20261012/{summary.json,paired_decision_audit.json}`。场景实际忙时30.51%、服务链路合成SINR中位-16.83dB，约67.59%低于-10dB；官方系统聚合仍未定义。主场景若请求移动回放会明确拒绝此模式，因为1秒移动接收器尚未接入导频碰撞。
- **质量×年龄合成校准补充**：两条同导频链路，参考 SNR -12/-10/-6 dB × 年龄0/160/320ms，9组×各1万独立测试列，18个边际后验协方差最大相对差2.60%，95%单列覆盖94.59%–95.40%，无特征值裁剪。证据 `experiments/chasi_formal/c1_srs_reuse_quality_age_20261012.json`；此为模型内蒙卡，不是实际SRS或CDL校准。
- **A2 初始化配对已结束（2026-10-12 23:31 至 2026-10-13 00:11 北京时间）**：同一新开发场景/业务 `seed=20261025`，3初始 V（SVD/home偏置/15%方向扰动）×两个既有floor；六项启动源码哈希集合只有1种、场景清单哈希只有1种、实际忙时均28.4048%。六项均满足目标相对变化≤1e-4、V相对变化≤0.005、最近 ADMM 原/对偶残差各低于各自阈值的**局部数值停止**，各用18–19外层轮、371–439秒、峰值工作集约261–271 MiB；原命令、源码哈希、控制台、逐轮轨迹、逐UE统计见 `results/chasi_formal/a2_init_floor_pairs_seed20261025_20261012/queue.json` 及各子目录。`floor=0.001` 三初始化底部5%静态体验代理为0.514397–0.514629 Mbps，总SE47.4880–47.6860 bit/s/Hz；`floor=0.01` 为0.271257–0.273181 Mbps、50.2979–50.6011 bit/s/Hz；均约420W。同初始政策两个floor的各自尾部11人重叠10人，仅46/210人体验代理提高、164人降低，尾部增量0.241–0.243 Mbps，是明确的尾部/总率权衡。这个场景中初始化影响小于floor权衡，但不能据此证明无局部极小/跨场景稳定，亦不能把不同floor的优化目标绝对值直接比较。未挑选最佳初始化。初始V的210UE零迭代测试证明不同策略可行、两个floor共享完全相同的扰动初始V；`test_formal`、`test_pf_gradient`、`test_v_reference`复测通过（后者严格残差到600次仍未停，按旧事实保留）。
- **B3 绝对均值误差消融已完成，但公平基线判为不充分（2026-10-13）**：可选 `matrix_pf_uniform` 把每资源组非零模型链路后验4×4 `C_rx` 全部换成算术均值，组内**绝对总量**不变，旧默认不变。`test_uniform_error`、210UE `test_uniform_error_formal`（含真信道隔离/功率可行）、`test_pf_gradient`、`test_formal` 通过。预登记 `seed=20261026`、21TRP/210UE 合成复用SRS三分支名义/绝对统一/异质在20/18/30轮均达到三重**局部**停止。静态底部5%代理0.772300/0.431611/0.726144Mbps；真值总SE64.9763/69.9214/69.6354bit/s/Hz；辐射功率420.0/406.58/420.0W。逐UE RB/业务条件一致，异质比绝对统一尾部高0.294534Mbps，却仍比名义低0.046155Mbps；V和功率确有变化。**关键后诊断：绝对均值把三支共同7名弱用户所见协方差迹平均放大至原异质后验约318倍，统一分支给这7人的平均加权功率仅0.971W（名义3.142W、异质3.091W），体验代理0.093/0.321/0.324Mbps。尽管组总量相等，这不是一个足够公平的“统一相对误差”基线，不能以异质优于它宣称创新优势。**同场景原结果、`paired_error_ablation_audit.json`、`tail_error_diagnostic_covratio.{json,csv}` 保留在 `results/chasi_formal/b3_uniform_heterogeneous210_seed20261026_20261013/`；首次默认沙箱拒绝创建新目录但未开始计算，随后批准唯一串行进程。此为单一合成模型样本，不是真实SRS校准或正式尾部保障。
- **B3b 公平基线修正及配对已完成（2026-10-13）**：新增可选 `matrix_pf_uniform_relative`：`C_kl = prior_gain_kl × [Σ_model C_kl / Σ_model prior_gain_kl]`，组内统一**相对**协方差形状且保持绝对总协方差，不用H_true或评估结果设权重。小矩阵与210UE测试通过Hermitian/PSD、总量、统一相对形状、真信道隔离、功率可行；`test_pf_gradient`、`test_formal` 再次通过。新未查看 `seed=20261027` 的21TRP/210UE同场景合成SRS名义/统一相对/异质三方分别在18/28/28轮达到三重局部停止；静态底部5%代理0.791579/0.749215/0.747725Mbps，真值总SE52.2856/54.7448/54.7501bit/s/Hz，三者辐射功率均约420W。统一相对vs异质尾部仅差0.00149Mbps且异质略低；两者尾部11人完全相同、V相对Fro差0.03044、逐UE加权功率L1变化2.102W；共同9名三方尾部用户的模型协方差迹比（统一相对/异质）均值0.9355，不再是B3的318倍病态。两种统计保护都低于名义静态尾部约0.042–0.044Mbps。`paired_error_ablation_audit.json`验证逐UE资源与业务样本三支一致；`tail_error_diagnostic_relative.{json,csv}`验证场景源码/清单重建、共同尾部测量/误差/功率；全部结果、配置、轨迹、内层残差、源码哈希、命令/停止/耗时见 `results/chasi_formal/b3b_uniform_relative210_seed20261027_20261013/`。seed27是在B3发现基线问题后预登记的**新样本**，不与seed26冒充事前冻结的双样本统计；合成模型下无异质创新收益证据。

**下项依赖**：A2 的一个210UE场景支持暂将 `floor=0.001` 作为**研究对照配置**冻结，不是正式公平性保证。B3绝对均值基线已诊断为对弱链路病态，B3b合理统一相对误差与异质误差在一个新合成样本几乎同决策、同尾部，均未胜过名义；**当前最关键阻塞是模型异质性/质量敏感性不足或期望MSE与正式边缘目标不对齐**，需先用独立校准/测试检查按质量与年龄的 `Cov(vec(E))` 和弱链路覆盖，再定义可解释的边缘约束/尾部目标，不继续靠调floor或扩大规模寻找正收益。315/420UE小底座压力对照仍未运行，420UE默认底座严重边缘退化保留；在模型/口径可解释后同新版场景配对复核。TR38.901 CDL适配仍在隔离副本，未合并主项目；30%业务负载官方分母、系统SRS SINR、BLER/MCS/正式秒级协议、独立功控基线和分布式V更新仍未解决。

> 以下为 2026-10-12 较早的四问题只读核查历史记录；其“现优先级/本轮”只表示当时，不覆盖文件顶部的晚间持续开发状态。
> 用途：供只读研究会话快速了解最新代码、证据边界和下一步。详细历史结果仍保留在 `results/chasi_formal/` 与 `IMPLEMENTATION.md`，不写入 `AGENTS.md`。

## 历史：四问题只读核查时的优先级与证据分层（已由文件顶部晚间更新取代）

**现优先级是研究问题—验收场景—方法迁移—创新落地的定义与证据核查，不是直接扩大规模实验。** 完整逐项表、函数/行号、原图/论文/隔离副本来源、未解决事项和按依赖排序的修改清单见 [`FOUR_QUESTION_EVIDENCE_AUDIT_20261012.md`](FOUR_QUESTION_EVIDENCE_AUDIT_20261012.md)。本轮只读核查后仅编辑此报告与本状态文件；没有启动性能实验，没有修改算法/默认参数/评价口径，没有碰运行进程、用户改动、历史结果或失败日志，没有 push。

| 证据层 | 当前状态 | 能说什么／不能说什么 |
|---|---|---|
| 参考复现 | 部分完成 | 已核对 2023 Zaher 等论文和公开 Python 求解器：固定 MR/RZF 方向、单天线UE、单流、全AP服务的统计 SE/PF **功率**内核。当前矩阵 V 求解器是重建迁移，不是论文逐行复现；原论文已有导频复用与异质误差，不能据此宣称“首次考虑链路误差差异”。 |
| 方法迁移 | 部分完成 | 固定服务集/流数的矩阵 WMMSE + **集中式** ADMM、跨RB加权预算和小例固定U/W V对拍已有证据。新 210 UE 名义/统计 PF 以及 315/420 UE 默认名义 PF均满足各自局部三重停止，旧求和与理想分支则按目录保留未收敛事实；不能笼统说“210 UE未收敛”或“全局最优”。 |
| 场景构建 | 部分完成 | 21TRP、210/315/420 UE、273RB、路径损耗/LOS子集、SRS/CSI-RS高斯观测和业务代理可运行。TR38.901 CDL 隔离副本**未合并**：主项目没有 `tr38901_cdl.py`，`config.py` 不接受 CDL 模式；隔离210 UE仅形状/场景生成测试，不是完整性能实验。30%负载、系统SRS SINR、真实双极化与正式秒级体验均未对齐。 |
| 创新验证 | 证据不足 | `matrix_pf_statistical` 在自设 `I_64⊗C_rx` 高斯后验下把误差协方差进入U/W/V，是期望MSE代理；非实测/校准的质量条件模型，非最坏情形或概率保障。210 UE同场景统计PF底部5%低于名义PF；改变PF floor只是效用权衡，不是测量质量感知鲁棒创新。 |
| 验收验证 | 未完成 | 原图80%分母未有明确公式；理想CSI局部解未收敛且非严格上界；当前home-only满功率MRT不是“无协同独立功控”完整基线；约420W无30%辐射降幅，更不能等同系统能耗。协议秒级CDF、30%负载、Presinr<-10dB系统SINR、实际分布式通信均缺证据。 |

最新 210 UE 保留样本 `seed=20261013` 两组 `summary.json` 复核：场景清单 SHA-256 同为 `704aba...6d71f47`，仅 PF `floor` 配置不同；六个启动源码哈希逐项相同且与当前文件一致，逐UE RB、busy/tail/terminal/valid TTI逐项相等。`floor=0.001/0.01` 分别在17/19轮满足目标相对变化 `<=1e-4`、最近V相对变化 `<=0.005` 和最近ADMM原始/对偶/CG容差；底部5%体验**代理** `0.491901/0.176256 Mbps`，物理总频谱效率 `49.761876/53.157118 bit/s/Hz`，辐射功率均约420W。其公式是 `Σ_已调度u ln(1+R_u/floor)`，floor单位bit/s/Hz，导数权重与 `1/(R_u+floor)` 成比例，**不是最低速率保障**。上一轮三项测试的通过见当时控制台与下文记录；仓库无独立测试归档日志，本轮未重跑。420 UE 默认floor底部5% `0.000721900 Mbps` 对同场景MRT `0.029804121 Mbps` 的负结果保留，较小floor在315/420仍**未验证**。

原图三张、老师两份PDF均已读取；老师材料的WMMSE/PF、ADMM分布式及质量感知鲁棒路线是研究建议，不是华为硬验收或现有能力。可核查的最新源码链为 `run.main:33-290`→`scenario.generate:153-235`→`solver.solve:286-423`→`evaluate.evaluate:66-145`；MATLAB旧 `cf_search`/SRACOS 仍调用 `cf_evaluate_candidate`，未与该 Python 求解链形成实际候选评估闭环。原图、论文及隔离副本的详细来源/哈希见新报告。

## 当前代码状态

- 工作树包含用户已有的未提交/未跟踪修改；本轮保留全部历史结果、失败日志和用户改动，不清理、不移动、不 push。
- 正式 Python 入口：`python -m chasi_formal_implementation.run`；MATLAB 桥接：`matlab/core/cf_run_chasi_formal.m`。
- 21 TRP、273 RB、210/315/420 UE 场景生成已实现。当前精确资源模式 `precise_shared_rb` 在 50% 目标下激活 136/273 RB（49.8168%）。
- 矩阵分支采用固定服务集下的 U→W→V WMMSE 交替；V 子问题为集中式 ADMM。固定 U/W 的 V 子问题已与独立显式二次式及 SciPy SLSQP 对拍，暂不改写该数学子问题。
- `ideal` 是理想 CSI 下的局部 WMMSE 参考解，不是全局上界；当前理想 CSI 运行也未达到外层收敛条件。
- `no_cooperation` 当前定义为仅本地 CSI 的 home-TRP MRT，并在策略生成阶段按每 TRP 跨 RB 预算分配满功率。它是清楚的无协同局部基线，**仍非原图“无小区间协同 + 独立功控”完整基线**；旧结果中的同名分支还存在定义差异，必须按目录/版本解释。
- 当前 `matrix_edge_weighted` 是基于 home 链路大尺度先验的固定逆潜在速率权重，只是 PF 启发代理；它不使用测试真信道，但也不等于历史吞吐驱动的在线 PF，尚未解决公平性验收问题。
- 新增 `matrix_pf_nominal` 与 `matrix_pf_statistical`：对已调度 UE 的优化器可见聚合速率代理最大化 `sum log(1+R_u/floor)`，默认 `floor=0.01 bit/s/Hz`。名义版先验证，统计版使用后验误差协方差；两者均不读取 held-out `H_true`。这只是**单次决策快照的平滑对数效用**，不是由历史平均吞吐驱动的在线 PF，也不是原图正式的底部 5% 约束。210 UE 同场景的名义/统计版均已续算满足局部数值三重停止条件，但统计版底部 5% 代理较低，且两者均无节能收益。
- 矩阵 WMMSE 现在逐轮保存优化目标、估计速率代理、相对目标变化、预编码器相对变化、ADMM 原始/对偶残差、CG 残差和接受步长；收敛须同时满足目标、预编码器和最近一次内层精度条件。SRS 诊断明确标为观测 SNR，`system_srs_sinr_db=null`，因为未建模导频干扰。
- **2026-10-12 测量口径新发现：** 旧 210 UE 比较使用 `decision_tti=0`，本 seed 的唯一已测 SRS 组（g0）没有调度 UE，所以真正参与优化的已测 SRS 链路数为 **0**。以前的约 −12 dB 诊断扫描了未测资源组，只能当假设性观测信号/AWGN 比，不能证明当前决策有 −12 dB SRS。独立复核在 `results/chasi_formal/measurement_audit_20261012/srs_observation_quality.json`。这些运行可用于 WMMSE/CSI-RS 诊断，不能用于 SRS 非理想测量结论；需以 `decision_tti=340` 新建正式结果。
- 以同 seed、`decision_tti=340` 只读重建核查：9 个已激活且测量的资源组，7938 条实际观测链路；观测信号/AWGN 的 5/50/95 分位约 `−12.715/−12.014/−11.374 dB`。这是 SNR，仍无导频干扰 SINR。`scenario.py` 已补录边界 TTI 340 的 SRS 决策事件，业务窗口保持 `[0,340)`。
- 场景随机流已改为真信道、CSI-RS 噪声、SRS 噪声各自独立，并为未测链路也消耗对应的 SRS 噪声抽样。`test_formal` 验证同 seed 仅改变决策时点时 `H_true` 逐组完全一致、`H_est` 如预期改变。此修改会使新版场景不同于旧版同 seed 的具体真信道实现；旧结果与新结果不得作严格同样本差值，比较应只在新版同输入分支内部进行。新版主入口在 `summary.json` 记录关键源码 SHA-256。
- 已逐张核对用户提供的 `难题1.png`、`典型验收场景.png`、`用户速率协议定义.png`，并核对 `202609-系统方案.pdf` / `研究主题分析.pdf` 的建议；原始文件位于 `C:\Users\sypxx\Desktop\AAAa研一\AAAa研二\MIMO huawei\`，未拷贝或改动。原图的正式边缘指标是按 3GPP TS 28.554 口径获得每 UE 秒级体验速率，再取 CDF 底部 5%；50% PRB 条件下的 80% 参照是“集中式协同（理想信道估计）”，但原图未消除 80% 比例分母歧义。PF 或最小速率约束只是研究方案 PDF 给出的候选策略，不能代替正式指标。当前 340 TTI（0.34 s）窗口及交付比特均为协议代理：虽排除 buffer-empty 与 burst 最后时隙，却未覆盖正式秒级观测，不能宣称验收达标。
- **2026-10-12 业务口径新审计：** `traffic_samples` 当前以每突发 10–30 TTI、突发间 1–5 TTI 的实现假设生成忙时；配置中的 `traffic_load=0.3` 仅作为 `offered_load_target` 报告，未控制业务生成。210 UE 新样本实际 busy TTI 占总 UE×TTI 的 `86.44%`，tail 占 busy 的 `61.96%`，可用非末时隙占 `82.01%`；分配 PRB 为 `49.82%`、实际占用约 `49.33%`。所有分支共享同一业务数组，故算法内部比较仍受控，但不能声称已经复现原图的典型 30% 业务负载。后续需先定义“30%负载”的正式分母，再让配置驱动业务并重验。

## 各规模最后验证状态

| 规模 | 最后验证 | 代码/口径 | 状态与证据 |
|---|---|---|---|
| 210 UE | 2026-10-12 | 新旧两版随机流须分开；新口径 `decision_tti=340`、`precise_shared_rb`、UMi pathloss subset、SRS 2 端口 + CSI-RS 4 行联合 LMMSE | 旧随机流统计求和 32 轮仍未收敛。新随机流同场景 MRT 与两种 PF 首段及续算均完成；名义 PF 累计 18 轮、统计 PF 累计 26 轮，均满足目标/预编码器/最近 ADMM 三重停止条件。跨目录受控审计在 `audit_pf_converged210_20261012/`，含 210 人逐用户 CSV。独立开发 seed `20261012` 及预设保留 seed `20261013` 的 `floor=0.001/0.01` 名义 PF 对照均已结束、均局部数值停止；两 seed 较小底座均改善尾部但降低物理总率，不能推出 420 UE 泛化。完整目录有目标轨迹、双残差、逐 UE 功率/RB/服务/业务统计与停止状态。 |
| 315 UE | 2026-10-12 | 旧结果仅作历史；新代码 `decision_tti=340`、50% PRB、UMi 子集 | 新 `srs340_315_mrt_pf_nominal_20261012/` 已完整结束：名义 PF 19 轮满足三重局部停止条件，逐用户/残差/功率/边缘输出齐全；本地 MRT 同场景。旧目录 `final315_umi_2t4r_20261012/` 与 `formal315_20261012/` 保留。 |
| 420 UE | 2026-10-12 | 旧结果仅作历史；新代码 `decision_tti=340`、50% PRB、UMi 子集 | 新限定复核 `srs340_420_mrt_pf_nominal_20261012/` 已结束：名义 PF 19 轮满足局部数值三重停止，但静态底部 5% 代理 `0.000722 Mbps`，显著低于同场景本地 MRT `0.029804 Mbps`；功率均约 420 W。旧 `final420_umi_2t4r_20261012/` 与 `formal420_20261012/` 原样保留。 |

当前上述 210/315/420 UE 限定运行均已结束；旧随机流与新随机流不得混成同一次严格对照。210 UE 的跨目录受控审计已核对场景、非预算配置、场景/评价源哈希、逐 UE RB 和业务样本。315/420 UE 均只重跑已在 210 UE 数值验证的名义 PF 与本地 MRT，没有重复运行统计 PF 或四分支大规模组。

独立 `seed=20261012` 的 PF 底座开发对照已完成，目录 `dev210_pf_floor1e3_seed20261012_20261012/` 与 `dev210_pf_floor1e2_seed20261012_20261012/`。两者场景清单 SHA-256 均为 `18b4db9be2df4dff7a5fd6953f8cf33cf07dde6cdbf8d62751619d65ccd4903f`，全部 6 个启动源码哈希、逐 UE RB、busy/valid TTI 相同，配置仅 `pf_rate_floor_bits_per_s_hz=0.001/0.01` 不同；同场景 MRT 底部 5% 为 `0.083824 Mbps`。较小/默认底座 PF 都满足目标、V 变化及 ADMM 三重局部停止，分别在第 19/18 轮；底部 5% 体验代理 `0.574934/0.316394 Mbps`，最小单 UE `0.120819/1.51e-8 Mbps`，最小逐 UE 加权功率 `0.311184/2.67e-7 W`。默认底座 UE 202 近零功率 `2.67e-7 W`，较小底座为 `2.048 W`；物理总频谱效率较小/默认底座 `47.2849/49.8383 bit/s/Hz`，总辐射功率均约 `420 W`。较小底座只让 56 人体验代理提高、154 人降低，是尾部与总率的真实权衡，**不能视作已经稳定解决 420 UE 公平性**。底座选择受到先前 `seed=20261011` 的 420 UE 负结果启发，故该 seed 已是探索样本；当前 `seed=20261012` 也仅为开发敏感性样本。若要作结论，须事先固定候选配置，再用未看过的保留 seed 重验。

## 主要复现命令

210 UE 新随机流、真实已测 SRS 覆盖、名义 PF 与本地 MRT 的受控命令：

```powershell
& 'C:\Users\sypxx\py\python.exe' -m chasi_formal_implementation.run --users-per-cell 10 --rank 2 --seed 20261011 --service-trps 2 --prb-utilization 0.50 --schedule-mode precise_shared_rb --pilot-snr-db -12 --csi-rs-snr-db -3 --channel-mode umi_pathloss_subset --decision-tti 340 --branches no_cooperation,matrix_pf_nominal --outer-iterations 12 --admm-iterations 80 --cg-iterations 12 --output results/chasi_formal/srs340_210_pf_nominal_20261012
```

同场景统计 PF（已完成）：

```powershell
& 'C:\Users\sypxx\py\python.exe' -m chasi_formal_implementation.run --users-per-cell 10 --rank 2 --seed 20261011 --service-trps 2 --prb-utilization 0.50 --schedule-mode precise_shared_rb --pilot-snr-db -12 --csi-rs-snr-db -3 --channel-mode umi_pathloss_subset --decision-tti 340 --branches matrix_pf_statistical --outer-iterations 12 --admm-iterations 80 --cg-iterations 12 --time-evolution-tti 1000 --output results/chasi_formal/srs340_210_pf_statistical_20261012
```

名义 PF 独立目录续算（已按三重判据收敛）：

```powershell
& 'C:\Users\sypxx\py\python.exe' -B -m chasi_formal_implementation.run --users-per-cell 10 --rank 2 --seed 20261011 --service-trps 2 --prb-utilization 0.50 --schedule-mode precise_shared_rb --pilot-snr-db -12 --csi-rs-snr-db -3 --channel-mode umi_pathloss_subset --decision-tti 340 --branches matrix_pf_nominal --outer-iterations 20 --admm-iterations 80 --cg-iterations 12 --time-evolution-tti 1000 --resume-from results/chasi_formal/srs340_210_pf_nominal_20261012 --output results/chasi_formal/srs340_210_pf_nominal_continued_20261012
```

统计 PF 独立目录续算（已按三重判据收敛）：

```powershell
& 'C:\Users\sypxx\py\python.exe' -B -m chasi_formal_implementation.run --users-per-cell 10 --rank 2 --seed 20261011 --service-trps 2 --prb-utilization 0.50 --schedule-mode precise_shared_rb --pilot-snr-db -12 --csi-rs-snr-db -3 --channel-mode umi_pathloss_subset --decision-tti 340 --branches matrix_pf_statistical --outer-iterations 20 --admm-iterations 80 --cg-iterations 12 --time-evolution-tti 1000 --resume-from results/chasi_formal/srs340_210_pf_statistical_20261012 --output results/chasi_formal/srs340_210_pf_statistical_continued_20261012
```

315 UE 限定复核（已完成，数值压力测试而非验收）：

```powershell
& 'C:\Users\sypxx\py\python.exe' -B -m chasi_formal_implementation.run --users-per-cell 15 --rank 2 --seed 20261011 --service-trps 2 --prb-utilization 0.50 --schedule-mode precise_shared_rb --pilot-snr-db -12 --csi-rs-snr-db -3 --channel-mode umi_pathloss_subset --decision-tti 340 --branches no_cooperation,matrix_pf_nominal --outer-iterations 24 --admm-iterations 80 --cg-iterations 12 --time-evolution-tti 1000 --output results/chasi_formal/srs340_315_mrt_pf_nominal_20261012
```

420 UE 限定复核（已完成，边缘体验负结果）：

```powershell
& 'C:\Users\sypxx\py\python.exe' -B -m chasi_formal_implementation.run --users-per-cell 20 --rank 2 --seed 20261011 --service-trps 2 --prb-utilization 0.50 --schedule-mode precise_shared_rb --pilot-snr-db -12 --csi-rs-snr-db -3 --channel-mode umi_pathloss_subset --decision-tti 340 --branches no_cooperation,matrix_pf_nominal --outer-iterations 24 --admm-iterations 80 --cg-iterations 12 --time-evolution-tti 1000 --output results/chasi_formal/srs340_420_mrt_pf_nominal_20261012
```

独立 seed 的底座敏感性开发实验（已完成，暂非结论）：

```powershell
& 'C:\Users\sypxx\py\python.exe' -B -m chasi_formal_implementation.run --users-per-cell 10 --rank 2 --seed 20261012 --service-trps 2 --prb-utilization 0.50 --schedule-mode precise_shared_rb --pilot-snr-db -12 --csi-rs-snr-db -3 --channel-mode umi_pathloss_subset --decision-tti 340 --branches no_cooperation,matrix_pf_nominal --pf-rate-floor 0.001 --outer-iterations 24 --admm-iterations 80 --cg-iterations 12 --output results/chasi_formal/dev210_pf_floor1e3_seed20261012_20261012
```

同 seed 默认底座对照（已完成，独立目录）：

```powershell
& 'C:\Users\sypxx\py\python.exe' -B -m chasi_formal_implementation.run --users-per-cell 10 --rank 2 --seed 20261012 --service-trps 2 --prb-utilization 0.50 --schedule-mode precise_shared_rb --pilot-snr-db -12 --csi-rs-snr-db -3 --channel-mode umi_pathloss_subset --decision-tti 340 --branches matrix_pf_nominal --pf-rate-floor 0.01 --outer-iterations 24 --admm-iterations 80 --cg-iterations 12 --output results/chasi_formal/dev210_pf_floor1e2_seed20261012_20261012
```

预先冻结的 210 UE 保留 seed `20261013` 复核（两个目录均已完成，命令只改 seed、分支组合、底座和新输出目录）：

```powershell
& 'C:\Users\sypxx\py\python.exe' -B -m chasi_formal_implementation.run --users-per-cell 10 --rank 2 --seed 20261013 --service-trps 2 --prb-utilization 0.50 --schedule-mode precise_shared_rb --pilot-snr-db -12 --csi-rs-snr-db -3 --channel-mode umi_pathloss_subset --decision-tti 340 --branches no_cooperation,matrix_pf_nominal --pf-rate-floor 0.001 --outer-iterations 24 --admm-iterations 80 --cg-iterations 12 --output results/chasi_formal/holdout210_pf_floor1e3_seed20261013_20261012
& 'C:\Users\sypxx\py\python.exe' -B -m chasi_formal_implementation.run --users-per-cell 10 --rank 2 --seed 20261013 --service-trps 2 --prb-utilization 0.50 --schedule-mode precise_shared_rb --pilot-snr-db -12 --csi-rs-snr-db -3 --channel-mode umi_pathloss_subset --decision-tti 340 --branches matrix_pf_nominal --pf-rate-floor 0.01 --outer-iterations 24 --admm-iterations 80 --cg-iterations 12 --output results/chasi_formal/holdout210_pf_floor1e2_seed20261013_20261012
```

单元/数值验证：

```powershell
& 'C:\Users\sypxx\py\python.exe' -m chasi_formal_implementation.test_formal
& 'C:\Users\sypxx\py\python.exe' -m chasi_formal_implementation.test_v_reference
& 'C:\Users\sypxx\py\python.exe' -m chasi_formal_implementation.test_pf_gradient
```

MATLAB 桥接：

```matlab
run('setup_project_paths.m')
run('experiments/chasi_formal/run_chasi_formal.m')
```

## 已验证能力

- 场景/业务/事件清单可落盘；同 seed 的受控分支可核对网络清单哈希和业务随机种子。
- 理想、名义矩阵、统计误差矩阵、本地无协同 MRT、固定方向功率、先验边缘加权分支均可执行并保存预编码器。
- 测试真信道与在线优化器隔离；测试真信道用于最终评价和理想 CSI 参考，不回流统计/名义分支权重。
- 固定 U/W 的 V 子问题目标与独立参考解数值一致；功率投影与功率违反量已检查。
- 2026-10-12 `test_v_reference` 对拍通过：目标绝对差约 `6.20e-10`。`test_formal` 通过结构、功率、理想/统计隔离及名义/统计 PF 的 `H_true` 隔离测试。新增 `test_pf_gradient` 的 PF 目标与固定导数加权代理方向导数差 `6.66e-11`，验证逐 UE 跨资源聚合权重的一阶关系；同测试还确认当某 UE 全部 V 恰为 0 时，该 UE 的 MMSE 接收器 U 与固定 U/W 的 V 子问题线性驱动均为 0，即零流对纯 U/W/V 交替是吸收态。
- 210 UE、相同场景的 12 轮统计分支诊断：目标从 `24.3916` 单调增至 `63.0058`，全部 12 次 V 内层满足原始/对偶残差和 CG 条件；末轮相对增长约 `0.278%`，尚高于 `1e-4` 停止阈值。证据：`results/chasi_formal/diagnostic210_wmmse_outer12_20261012/summary.json`。
- 旧随机流 `decision_tti=0` 的统计求和 32 轮完整运行：目标终值 `63.838879`，末次相对增长 `1.45085e-4`，倒数第二轮预编码器相对更新 `0.00404`，最近一次 ADMM 原始/对偶残差 `0.017136/0.002544`，分别低于阈值 `0.018862/0.010101`。内层合格，外层目标仍高于 `1e-4`，`reason=max_outer_iterations`，不能标为收敛；held-out 物理总频谱效率 `80.5257 bit/s/Hz`，底部 5% 体验代理 `0 Mbps`，总辐射功率 `420 W`。完整证据：`results/chasi_formal/controlled210_wmmse_verified_20261012/summary.json` 与 `matrix_statistical_progress.json`。末个轨迹点是更新后的只读终值快照，因此该点没有新的 ADMM 字段，最近一次更新的残差在前一点及分支汇总中。
- 旧随机流名义 PF 的 12 轮运行也到上限、未收敛：末次目标相对增长 `2.69659e-4`，最近 ADMM 双残差均合格，底部 5% 代理 `0.4519 Mbps`。它和旧求和运行共享场景，但与新的 `decision_tti=340` 运行不共享具体真信道，不可直接求严格增益。
- 新随机流 `decision_tti=340`、210 UE 同场景的名义 PF 与本地 MRT：场景 SHA-256 为 `0f9721a771b7701431ebff24d0c86ebfaa61400634658384620a5237ee7b8880`；本地 MRT 底部 5% 代理 `0.100129 Mbps`、物理总频谱效率 `45.8540 bit/s/Hz`；名义 PF 分别 `0.418483 Mbps`、`54.2779 bit/s/Hz`，两者辐射功率均约 `420 W`。这是同条件样本上的候选改善，不是已收敛、已满足原图 80% 或节能 30% 的证据。名义 PF 12 轮到上限，末次相对目标增长 `2.49813e-4`，最近 ADMM 原始/对偶残差 `0.015145/0.004077` 低于阈值 `0.018832/0.010121`。证据：`results/chasi_formal/srs340_210_pf_nominal_20261012/summary.json` 与 `matrix_pf_nominal_progress.json`。
- 同一新场景统计误差 PF 在 `srs340_210_pf_statistical_20261012/` 完成，场景 SHA-256、6 个关键源文件启动哈希完全相同，逐 UE 分配 RB 相同；12 轮到上限，`converged=false`，末次目标相对增长 `2.05517e-4`、前一轮 V 相对更新 `0.01149`，最近 ADMM 原始/对偶残差 `0.017482/0.009158` 低于阈值 `0.018832/0.010104`。held-out 底部 5% 代理 `0.227949 Mbps`，低于名义 PF `0.418483`；物理总频谱效率 `59.1824 bit/s/Hz`，高于名义 `54.2779`。210 人中统计版体验代理比名义版提高 121 人、降低 89 人，两者约 420 W。不同 CSI 假设的优化目标数值不可直接互比；此样本下“统计误差感知必然改善边缘体验”不成立，且两分支均未收敛。统计 PF 的独立 1 秒移动代理底部 5% 为 `0.279046 Mbps`，但名义原目录没有对应移动运行，暂不比较动态结果。
- 同一新场景的逐 UE 核查：名义 PF 对 210 名 UE 中 158 人的体验代理高于本地 MRT、52 人下降；每 UE 分配 RB 完全相同、210 人均有有效样本。名义 PF 的最小单 UE 体验代理仍约 `2.70e-6 Mbps`，说明 PF 提高了 5% 分位但并未保证所有极弱 UE 的最低速率。两分支的逐 UE 加权发射功率和均与 420 W 的 TRP 总辐射功率一致。
- 新增 `--resume-from` 对矩阵 WMMSE 的保存预编码器续算，要求新输出目录、场景清单 SHA-256、全部非预算配置、场景源码、逐组 UE ID/服务掩码、预编码器形状/有限性/预算相同。零轮 210 UE 名义 PF 续算核查于 `srs340_210_pf_nominal_resume_smoke_retry_20261012/` 通过：重启目标 `624.437186658` 与原终值 `624.437186694` 相差 `3.59e-8`，场景清单完全一致。首次 smoke 因 JSON 中列表与 Python tuple 直接比较而提前报错，目录 `srs340_210_pf_nominal_resume_smoke_20261012/` 保留，比较现已标准化。smoke 本身不作为收敛证据，正式续算另见下一条。
- 名义 PF 正式续算从原 12 轮终值到累计第 18 轮（续算段第 6 轮）达到 `relative_objective_precoder_and_admm_tolerance`：末次相对目标变化 `9.23682e-5 < 1e-4`，最近 V 相对变化 `0.004673 < 0.005`，最近 ADMM 已收敛，原始/对偶残差 `0.014620/0.003059` 分别低于阈值 `0.018834/0.010121`。完整证据在 `results/chasi_formal/srs340_210_pf_nominal_continued_20261012/{summary.json,matrix_pf_nominal_progress.json}`；终值 `624.965621`。held-out 静态底部 5% 体验代理 `0.415868 Mbps`、物理总频谱效率 `55.2226 bit/s/Hz`、辐射功率约 `420 W`。与同场景本地 MRT 相比，逐 UE RB 与有效业务 TTI 完全相同、159 人体验提升/51 人下降，底部 5% 比值约 `4.1533`，功率变化近 0；这不是原图对理想 CSI 的 80% 比率，也未达到 30% 节能。独立 1 秒移动代理底部 5% 为 `0.373136 Mbps`，但模型仍将 412 次关联变化延后，不能算真实动态关联验证。这是数值局部停止，不是全局最优或原图正式验收。
- 统计 PF 从原 12 轮终值续算到累计第 26 轮（续算段第 14 轮）达到同一停止原因：末次目标相对变化 `4.06721e-5`，最近 V 相对变化 `0.004960`，最近 ADMM 原始/对偶残差 `0.013090/0.007666` 低于阈值 `0.018843/0.010104`。证据：`results/chasi_formal/srs340_210_pf_statistical_continued_20261012/{summary.json,matrix_pf_statistical_progress.json}`；静态底部 5% 代理 `0.245948 Mbps`、物理总频谱效率 `59.4173 bit/s/Hz`、总辐射功率约 `420 W`，1 秒移动代理底部 5% `0.310613 Mbps`，同样延后 412 次关联变化。名义版静态/动态边缘代理分别 `0.415868/0.373136`，但物理总频谱效率较低。统计误差感知在此样本中没有改善边缘指标，不能拿不同 CSI 的优化目标数值互比。
- 新脚本 `audit_pf.py` 对三个已完成分支作跨目录只读审计并导出 `results/chasi_formal/audit_pf_converged210_20261012/{comparison_pf.json,per_ue_pf.csv}`：共同场景 SHA-256 `0f9721a771b7701431ebff24d0c86ebfaa61400634658384620a5237ee7b8880`；21 项共同配置、`config.py/scenario.py/evaluate.py` 源码启动哈希、逐 UE 分配 RB/业务采样完全相同。MRT 为 home-only 满功率，不与双 TRP PF 共享服务/优化定义；PF 两版共享两 TRP 服务和 `H_est` 初值，仅统计版纳入后验协方差。名义/统计对 MRT 的静态底部 5% 比值约 `4.1533/2.4563`；两版功率相对变化均近 0，不具备 30% 节能证据。
- 边缘下降不是全 UE 同向：已收敛统计 PF 对名义 PF 有 121 人体验代理提高、89 人下降，两个分支的最低 11 名 UE 有 8 人重叠。例：UE 196 在相同 16 RB 下，名义/统计加权功率约 `2.994/1.42e-5 W`、held-out 体验约 `0.460/2.07e-6 Mbps`；优化器可见速率代理约 `0.02893/2.07e-8 bit/s/Hz`。这提示统计协方差处理与当前带 `0.01` 底座的 PF 目标仍允许极弱用户被放弃；只能归因于该模型和局部解样本，不能推成普遍规律。
- 另核对两个已收敛 PF 的 1 秒移动结果：逐 UE 有效 TTI、分配 RB×TTI、提供业务量完全一致，50 个事件块数相同，功率违反均为 0。断言已加入 `audit_pf.py`，修订审计另存 `results/chasi_formal/audit_pf_converged210_mobile_checked_20261012/`，旧审计原样保留。移动代理仍用冻结初始 WMMSE 功率与后续估计 SVD 刷新，关联变化只记录不执行，不能称动态关联算法已通过。
- 315 UE 最新代码限定复核 `results/chasi_formal/srs340_315_mrt_pf_nominal_20261012/`：名义 PF 第 19 轮达到目标相对变化 `4.71214e-5 < 1e-4`、V 相对变化 `0.004792 < 0.005`、最近 ADMM 已收敛；原始/对偶残差 `0.016610/0.003934` 低于阈值 `0.021079/0.012385`，功率违反 0。静态底部 5% 体验代理为 MRT `0.035549`、名义 PF `0.058451 Mbps`（比值 `1.644`）；物理总频谱效率 `45.5505/59.3621 bit/s/Hz`，两者辐射功率约 `420 W`。逐 UE RB 与有效业务 TTI 完全一致、315 人均有效，PF 改善 245 人/降低 70 人。名义 PF 的独立 1 秒移动代理边缘 `0.075750 Mbps`，604 次关联变化仍被延后。9 个已测且调度 SRS 组、11907 条观测链路，中位观测 SNR `−12.007 dB`，仍无系统导频 SINR。与 210 UE 续算的 6 个关键源码启动哈希完全相同；逐 UE 字段见 `summary.json`。
- 420 UE 最新代码限定复核 `results/chasi_formal/srs340_420_mrt_pf_nominal_20261012/`：名义 PF 第 19 轮达到目标相对变化 `4.06720e-5`、V 相对变化 `0.004700`，最近 ADMM 原始/对偶残差 `0.015190/0.003828` 低于阈值 `0.023294/0.014296`，功率违反 0；`reason=relative_objective_precoder_and_admm_tolerance`。静态底部 5% 体验代理 MRT `0.029804`、名义 PF **`0.0007219 Mbps`**（PF/MRT `0.02422`），1 秒移动 PF 底部 5% `0.001206 Mbps`；物理总频谱效率 MRT/PF `50.4564/67.2136 bit/s/Hz`，功率均约 `420 W`。逐 UE RB 与有效业务 TTI 完全一致、420 人均有效，PF 改善 338 人/降低 82 人；PF 自身底部 22 人的平均加权功率仅 `0.000481 W`，MRT 给同一批 UE 平均 `0.8957 W`。这说明该 PF 底座/当前 CSI 样本在更高拥塞下仍会饿死尾部，**不能宣称公平性问题已解决或尺度泛化**。9 个已测且调度 SRS 组、15876 条观测链路，中位观测 SNR `−12.008 dB`；与 315 UE 的 6 个关键源码启动哈希一致，仍无系统导频 SINR。动态模型延后 800 次关联变化。
- 420 UE 尾部机制的第一步核查：例如 UE 222/364/120 的优化器可见最终速率代理仅约 `1.86e-15/2.60e-15/1.25e-14 bit/s/Hz`，远小于 PF 底座 `0.01`；其归一化边际权重均饱和在约 `12.18×` 全体中位权重。只读重建同场景的 `H_est` SVD 初值，这三个 UE 初始加权功率均约 `0.468864 W`，最终却降至 `2.35e-12/4.58e-12/1.27e-11 W`，而 MRT 给这些 UE 各约 `1.176 W`。说明功率是在 PF 交替优化中塌缩，并非未被初始化或未获 RB。这不是 held-out 真信道驱动的在线权重。`test_pf_gradient` 已证实**恰为零流**时 U 和固定 U/W 的线性 V 驱动为零；最终**近零流**是否由同一机制主导，还需独立初始化/底座敏感性实验，不把该机制当唯一已证实原因。后续参数选择须用开发样本，不能把原探索 seed 继续当无偏测试。
- 210 UE 独立开发 seed 的 PF 底座受控对照证实**底座数值会实质改变局部解和尾部**：`floor=0.001` 与 `0.01` 的场景、资源、业务、代码完全相同且均局部数值停止；底部 5% 代理 `0.574934` 对 `0.316394 Mbps`，物理总频谱效率反向为 `47.2849` 对 `49.8383 bit/s/Hz`。默认底座 1 人逐 UE 功率低于 `1 mW`，较小底座 0 人；UE 202 由 `2.67e-7 W / 1.51e-8 Mbps` 变为 `2.048 W / 0.120819 Mbps`。较小底座的目标并非在所有 UE 上占优（56 人升、154 人降），且两者都约 `420 W`。证据为两个独立目录的 `summary.json` 与 `matrix_pf_nominal_progress.json`；这只证明开发样本的敏感性，尚不是 420 UE 或未见 seed 的可靠公平性修复。
- 上述 12 轮诊断的 held-out 物理总频谱效率为 `77.6941 bit/s/Hz`，但 340 TTI 代理窗口底部 5% 体验速率仅约 `3.93e-12 Mbps`，发射功率约 `420 W`。这是求和目标继续提高、边缘用户进一步饥饿的负结果，不能作为公平性达标证据。
- 四分支已保存结果审计：`results/chasi_formal/audit_four_branch_conditions_20261012/comparison_four.json`，场景 SHA-256 为 `80f34748758addeef1af68c33262f12fbaaebf5c6c3ec9bd2d0b95c6be7e2c49`；15 项共同配置及逐 UE RB 完全相同。理想 CSI 与本地 MRT 的初始化/可见 CSI/服务定义不同，已在审计报告逐项写明。
- 1 秒移动/业务代理能记录 SRS、CSI-RS、快层刷新、慢层复核、有效 TTI、交付量和边缘体验；动态关联实际切换和每时点重新 WMMSE 尚未实现。

## 未收敛与未解决问题

1. 210 UE 的旧理想、名义、统计求和矩阵 WMMSE 均到外层上限。现已排除固定 U/W 的 V 数学目标不匹配；旧 2–3 轮预算过早截断。32 轮统计求和诊断已完成，所有末段 V 更新均以步长 1 接受、最近内层合格，末次目标仍增长 `1.45e-4 > 1e-4`，属外层缓慢继续变化，而非仅因旧内层失败被误标。新 PF 首段 12 轮也不够，经过有清单校验的续算才分别在累计 18/26 轮达到三重停止条件。理想分支仍没有可当作严格上界的收敛证据。
2. 四分支虽可共享网络、业务、RB 清单、功率预算和随机种子，但服务集与 CSI 可见性按算法定义不同：矩阵三分支使用两 TRP 服务集，本地 MRT 为 home-only；初始化和是否迭代也需要逐项审计后才能称“受控公平”。
3. 求和目标明显饿死边缘用户。先验大尺度增益加权虽提升边缘值，仍远低于本地 MRT，且分支未收敛。可解释的名义 PF 在 210/315 UE 改善 5% 分位，但 420 UE 虽局部数值收敛，5% 分位反而比 MRT 低约 97.6%，底部用户功率近零；这否定了当前 `floor=0.01` 的 PF 代理可稳定解决边缘公平性的结论。统计误差感知 PF 只在 210 UE 验证，在同样本下边缘分位比名义版低。下一步先从尾部用户可见速率/功率查清机制，再考虑更强的 α-fair 或显式最低速率/底部 5% 约束，须先在 210 UE 检验再上规模。
4. 当前约 −12 dB 的旧诊断既不含导频复用干扰，也包含未测资源组，不能称系统 SRS SINR 或实际决策的 SRS SNR。最新 `evaluate.py` 已限制为实际已测组；`decision_tti=0` 的本 seed 结果为 0 个已测且调度的 SRS 组/0 条观测链路，SNR 分位数为 `null`。`test_formal` 另验证 100 TTI 时仅 6 组已测。导频干扰尚未建模，协议代理与原图正式秒级/验收指标仍未对齐。
   进一步源码审计发现当前 `scenario.py` 的 SRS/CSI-RS 观测噪声方差均与该链路 `gain` 成正比：`n_s=gain/SNR_target·exp(2·age/Tc)`。因此同年龄链路的**相对**后验误差几乎不随大尺度增益变化，当前约 −12 dB 分布很窄是配置构造结果，尚非真实链路质量差异建模。年龄只是有效噪声膨胀，静态场景并未生成采样时旧信道与决策时真信道的时域联合实现。后续质量/年龄模型需显式声明接收噪声标定、导频干扰与时变联合分布，再在 210 UE 重验；不可直接给当前结果贴“质量感知鲁棒”标签。
   业务/协议代理还存在负载分母和抽样时长问题：`traffic_load=0.3` 不驱动当前突发过程，实测 busy TTI 约 86.44%；体验代理先在 0.34 s 内汇总，再跨 UE 取 5% 分位，尚未形成协议所述的逐 UE 秒级样本 CDF。尾段 2/7 需求系数、无 BLER/MCS 和真实包级调度也都是实现假设。
5. 315/420 UE 不能直接沿用旧结果；新 210 UE 两种 PF 已保存完整轨迹并通过局部数值停止条件及同场景受控审计。315/420 UE 的名义 PF + MRT 限定数值压力复核现均完成、均局部收敛，但 420 UE 边缘指标严重退步；协议代理/CSI 模型与原图正式验收仍有差距。不能把局部收敛等同于公平性或原图验收通过。
6. 第一次增量进度运行因初始 `inf` 残差无法序列化为严格 JSON，在 `controlled210_wmmse_fixed_20261012/summary.json` 留下失败证据；修复后的一次运行又在环境切换时停于第 0 轮，仅留下 `controlled210_wmmse_fixed_retry_20261012/` 的进度文件。两个目录均保留。

## 已预设并执行的保留样本验证、此前下一项工作（历史记录）

运行前记录（原文保留）：下一项保留样本对照预先冻结于此，尚未查看 `seed=20261013` 结果：210 UE、`decision_tti=340`、50% precise_shared_rb、两 TRP 服务、`outer=24`、`ADMM=80`、`CG=12`、其余参数与上述开发实验相同；独立目录中比较名义 PF `floor=0.001` 与默认 `0.01`，第一个目录同时运行本地 MRT。只接受场景/资源/业务/源哈希相同且各 PF 达到三重停止的受控比较；主观察量为 held-out 静态体验底部 5%、最低单 UE 体验/功率，副观察量为物理总频谱效率和总辐射功率。不能根据此 seed 再调底座并声称无偏，不能用 held-out 真信道制定在线权重。即使单个保留 seed 改善，也不证明跨 seed 稳定、420 UE 可靠或正式验收。

执行结果（预设未因结果调整）：`floor=0.001` + 本地 MRT 在 `results/chasi_formal/holdout210_pf_floor1e3_seed20261013_20261012/`，默认 `floor=0.01` 在 `results/chasi_formal/holdout210_pf_floor1e2_seed20261013_20261012/`。场景清单 SHA-256 均为 `704aba06987187afcc159503508df028194a245b4afefab752b7bf00c6d71f47`，全部启动源码哈希、逐 UE RB、busy/valid TTI 一致，配置只差底座。较小/默认底座分别在第 17/19 轮满足三重局部停止；最后目标相对变化 `6.00e-5/9.76e-5`，V 相对变化 `0.004676/0.004576`，最近 ADMM 双残差均低于各自阈值，功率违反 0。静态底部 5% 体验代理 `0.491901/0.176256 Mbps`，本地 MRT `0.068413 Mbps`；最低单 UE `0.046930/4.10e-13 Mbps`，最低逐 UE 加权功率 `0.298501/1.63e-11 W`，低于 `1 mW` 的 UE 数 `0/5`。物理总频谱效率 `49.7619/53.1571 bit/s/Hz`，总辐射功率均约 `420 W`；较小底座仅 45 人体验代理上升、165 人下降。上一段“尚未查看”是运行前预注册原文，保留以示顺序。两个 210 UE seed 支持底座—尾部—总率权衡，但**单个预设保留 seed 也不证明跨 seed/420 UE 稳定或正式验收**。

此前下一项工作（现已被文首证据核查优先级取代，保留以便追溯）：先核查极弱 UE 的可见速率、逐轮功率轨迹与初始化依赖；再把已经在 210 UE 两个 seed 数值验证的较小 PF 底座作为**受限候选**，在预先设定的 315/420 UE 压力场景验证，不能覆盖既有默认底座负结果，也不能用已见 420 UE 真信道调参。进一步检验更强但可解释的 α-fair 或显式速率约束，并校准统计误差协方差/年龄、SRS 链路质量、30% 业务负载及秒级协议口径。上述关键正确性问题未解决前，不贸然把动态关联或鲁棒分支堆到当前结果上；之后再推进实际关联更新与适用条件明确的鲁棒实现。

保留样本对照结束后重新运行 `test_formal`、`test_v_reference`、`test_pf_gradient`，三者均以 `status=passed` 退出。独立 V 对拍的目标绝对差仍约 `6.20e-10`；其刻意更严格的 ADMM 测试阈值在 600 轮内尚未触发，但目标对拍通过，不能把该测试结果误称为严格 ADMM 残差收敛。
