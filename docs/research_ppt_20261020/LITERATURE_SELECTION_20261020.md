# 汇报文献筛选与引用边界

本表在阅读用户提供的《参考文献.pdf》后，按当前代码与研究问题重新筛选。编号用于图示增强版 PPT 的备注。文献提供理论或研究背景；引用不表示对应方法已在本项目实现。

| 编号 | 文献与来源 | 本次用途 | 与当前代码的关系 |
|---|---|---|---|
| [1] | Demir, Björnson, Sanguinetti, *Foundations of User-Centric Cell-Free Massive MIMO*, 2021. DOI [10.1561/2000000109](https://doi.org/10.1561/2000000109)，[作者公开稿](https://arxiv.org/abs/2108.02541)，[作者代码](https://github.com/emilbjornson/cell-free-book)。 | 用户中心服务集合与可扩展性背景。 | 未发现当前实现直接调用作者代码。 |
| [2] | Ammar et al., *Distributed Resource Allocation Optimization for User-Centric Cell-Free MIMO Networks*, **IEEE TWC 2022**, 21(5), 3099–3115. DOI [10.1109/TWC.2021.3118303](https://doi.org/10.1109/TWC.2021.3118303)，[作者公开稿](https://arxiv.org/abs/2110.08154)。 | 非理想 CSI 下的用户中心资源分配背景。 | 论文研究分布式算法；本项目当前 ADMM 是集中式数值实现。DOI 中的 2021 为在线登记时间，期刊卷期年份为 2022，不称“2023 参考论文”。 |
| [3] | Bu et al., *Joint User Scheduling and Resource Allocation in Distributed MIMO Systems with Multi-Carriers*, **Electronics 2022**, 11(12), 1836. DOI [10.3390/electronics11121836](https://doi.org/10.3390/electronics11121836)，[期刊全文](https://www.mdpi.com/2079-9292/11/12/1836)。 | 多载波多点协同、调度与资源分配背景。 | 不作为当前正式入口直接迁移的算法证据。 |
| [4] | Shi et al., *An Iteratively Weighted MMSE Approach to Distributed Sum-Utility Maximization for a MIMO Interfering Broadcast Channel*, **IEEE TSP 2011**. DOI [10.1109/TSP.2011.2147784](https://doi.org/10.1109/TSP.2011.2147784)，[IEEE 页面](https://ieeexplore.ieee.org/document/5756489/)。 | WMMSE 交替更新与加权效用关系的理论依据。 | 当前矩阵实现和 PF 权重、误差项以本项目源码为准，不声称复用论文代码。 |
| [5] | Boyd et al., *Distributed Optimization and Statistical Learning via the Alternating Direction Method of Multipliers*, **Foundations and Trends in Machine Learning 2011**，[作者主页](https://stanford.edu/~boyd/papers/admm_distr_stats.html)。 | ADMM 共识分裂、原始/对偶残差的理论依据。 | 当前实现位于单个 MATLAB 进程，不能据 ADMM 名称推断 TRP 已分布式。 |
| [6] | Zheng, Wong, Ng, *Robust Linear MIMO in the Downlink: A Worst-Case Optimization with Ellipsoidal Uncertainty Regions*, **EURASIP JASP 2008**. DOI [10.1155/2008/609028](https://doi.org/10.1155/2008/609028)，[期刊全文](https://link.springer.com/article/10.1155/2008/609028)。 | 拟议确定性误差椭球与最坏情况问题的背景。 | 当前条件误差协方差不是已校准椭球，最坏情况内层未实现。 |
| [7] | Shi, Zhang, Letaief, *Group Sparse Beamforming for Green Cloud-RAN*, **IEEE TWC 2014**. DOI [10.1109/TWC.2014.040214.131770](https://doi.org/10.1109/TWC.2014.040214.131770)，[作者公开稿](https://arxiv.org/abs/1310.0234)。 | 新版方案中服务链路组稀疏的研究背景。 | 当前正式求解无该罚项；关闭链路与 TRP 休眠分别定义。 |
| [8] | Björnson and Sanguinetti, *Scalable Cell-Free Massive MIMO Systems*, **IEEE TCOM 2020**. DOI [10.1109/TCOMM.2020.2987311](https://doi.org/10.1109/TCOMM.2020.2987311)，[作者代码](https://github.com/emilbjornson/scalable-cell-free)。 | 可扩展用户中心协同的背景及后续对照。 | 未发现当前代码调用该仓库。 |

## 未采用为当前实现证据的旧条目

《参考文献.pdf》中与 UWB 误差、交通流 PSO 或其他无关任务相关的条目，不用于证明本项目非均匀 CSI 建模或算法创新。新版系统方案中的事件触发通信目前也没有可直接归属于当前代码的文献或运行结果，因此只在备注中列为待定义机制。

## 原始指标来源

用户提供的《用户速率协议定义.png》援引 3GPP TS 28.554。可核对 [ETSI TS 128 554 官方版本](https://www.etsi.org/deliver/etsi_ts/128500_128599/128554/19.06.00_60/ts_128554v190600p.pdf)。当前源码中的体验率代理与正式协议口径应分别检查，不能因术语相同而认定已满足验收。
