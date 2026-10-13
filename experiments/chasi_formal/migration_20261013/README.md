# 2026-10-13 茶思迁移与汇报输出

本目录只放本轮新代码、轻量对拍与从既有结果生成的图。旧结果不覆盖。图的核心结论是：seed27 的名义矩阵PF达到**局部数值停止**，而同条件误差分支的静态尾部代理没有优势；另一个 seed22 的秒级候选展示完成业务筛选的强烈影响。图型为定量曲线/比较图，Python/matplotlib绘制，白底；所有逐UE观测保留。每图有PNG、可编辑PDF/SVG及相同源数据CSV。大TIFF是可重生成的本地衍生物，不进入Git。

运行：在项目根执行 `& 'C:\Users\sypxx\py\python.exe' -B experiments/chasi_formal/migration_20261013/plot_saved_seed27.py`。只读存档，写入本目录；`plot_manifest.json`记录摘要哈希、场景清单哈希、运行时源码哈希及样本数。脚本检查 `paired_error_ablation_audit.json` 的相同资源/业务结论及210个逐UE值，不生成新信道或求解。中文字体选本机 Microsoft YaHei，图面已人工查看。nature-figure源码预检13项通过、1项log警告；代码在两处log轴前检查全部数据与阈值严格为正，该静态扫描未识别此检查。

| 图 | 怎样读、支持什么 | 不支持什么；30秒讲法 |
|---|---|---|
| [01 PF目标](fig01_pf_objective.png) | 横轴WMMSE快照0–18；目标从753.603到1067.412。说“估计目标在此固定问题中提高并局部停机”。 | 不是真信道总率或全局最优；不能只凭目标曲线判验收。 |
| [02 V变化](fig02_v_change.png) | 每次实际V更新的相对范数与0.005阈值；末次0.004742。说“最近波束更新足够小，但还有另两项停止门槛”。 | 没有给最后只读目标快照编造V更新。 |
| [03 ADMM末残差](fig03_admm_end_residuals.png) | 每个WMMSE轮末的原/对偶残差及**各自随问题尺度计算的阈值**；最后一次两项过线。说“一点是一轮内层的末值”。 | 不是把不同U/W的内层序列拼成连续收敛；单看双残差还不含CG门槛。 |
| [04 TRP功率](fig04_trp_power.png) | 21项 `P_l=Σ_g(txRB_g/273)||V_g[l]||²` 与每TRP 20W线。说“此定义下跨RB预算可行”。 | 辐射功率不是系统能耗，也没有30%节能收益。 |
| [05 逐UE静态CDF](fig05_static_ue_cdf.png) | 同seed、同场景、同逐UE资源/业务，三支各210个样本；实心点是经验逆CDF第5%（第11人），图例是历史NumPy线性第5百分位。说“异质与统一相对非常接近”。 | 0.34秒静态容量/业务代理，非正式UE秒级RLC感知速率；单seed不能推广。尾部数较小，详细值见`fig05_static_quantiles.csv`。 |
| [06 底部5%](fig06_static_bottom5.png) | 线性分位名义/统一相对/异质为0.791579/0.749215/0.747725Mbps。说“本样本统计保护未胜过名义”。 | 不声称统计模型永远无效，也不作为80%验收。 |
| [07 秒级候选CDF](fig07_seed22_second_candidate_cdf.png) | **另一样本seed22、冻结决策**；138个有效UE秒与72个无有效样本UE分开展示，未完成burst 1589个。说“样本资格可改变尾部数值”。 | 容量/队列代理无ACKed RLC；不能与seed27三支同图作算法收益比较。 |

图01–06的源为 `results/chasi_formal/b3b_uniform_relative210_seed20261027_20261013/`，图07源为 `results/chasi_formal/protocol_candidate_replay_seed22_completion_20261013/summary.json`。图05/06使用历史线性第5百分位，以保持与summary一致；经验逆CDF第5%的三数另存 `fig05_static_quantiles.csv`，绝不混名。源码`evaluate.py/run.py/time_evolution.py`如今已与seed27启动时哈希不同，图仅表示旧存档。
