# 10 MathWorks 示例独立字典与公式

## 版本与可见性

指定的 [R2025a 中国站页面](https://ww2.mathworks.cn/help/releases/R2025a/5g/ug/evaluate-performance-of-cell-free-mmimo-networks.html) 和英文 release URL 在本轮网页工具均不可读；实际能逐段核对的是 [MathWorks 当前在线页面](https://www.mathworks.com/help/5g/ug/evaluate-performance-of-cell-free-mmimo-networks.html)，页眉为 `R2026b`、`Since R2024b`。下面 **O** 仅表示当前页主脚本、局部函数及文字公式可见；**O?** 表示页面描述了 helper 行为而 helper 实现未取得；**T** 是为了说明维度的理论式，非官方示例显示的计算。不能据此推断 R2025a 的默认参数或 helper 源码逐行完全相同。三张用户图片是概念图与页面截屏；第一张画约 10 AP，**当前可见主脚本设置 20 AP**，本审计以代码数字为准。

## 独立于 CF 项目的符号字典

页面行号指网页工具可见文本行，位于上述当前 URL，不是可下载 `.m` 文件行号。

| 符号/代码别名 | 含义 | 轴、类型、单位 | 首次生成／公式 | 更新／传递 | 最终去向／证据 |
|---|---|---|---|---|---|
| `CPU` | 中央处理节点，非无线 AP | 单个 `hPre6GCPU` 对象；位置 `[500,1100,10]m` | 页面 83-107；1.9GHz/20MHz/15kHz、4 Tx/4 Rx、SRS 周期5 | `connectAP(CPU,APs)`；连接/调度/PHY 分工受 `Split` 控制 | `CPU.statistics()`、KPI；页面 29,103-120,207-228，helper 内部 ? |
| `APs,m` | 20 个分布式无线接入点，`m` 为 AP 索引 | 对象数组 `[20]`；各 4 Tx/4 Rx、23dBm、9dB NF | `generateAPPositions`、`hPre6GAP`，页面 94-120,304-376 | `connectAP`；对各 UE 建双向 CDL | SRS/PDSCH/PUSCH 物理端；内部 PHY helper ? |
| `UEs,k` | 4 个用户，`k` 为 UE 索引 | 对象 `[4]`；各 1 Tx/1 Rx、20dBm、9dB NF | `generateUEPositions`、`hPre6GUE`，页面 123-150,377-399 | 各 UE 最近 2 AP `connectUE(...,FullBufferTraffic="on")` | UE 统计、BLER/速率；页面 207-228 |
| `apPositions,uePositions` | AP/UE 三维坐标 | `[20,3]`,`[4,3]` m | 页面局部函数 306-399；AP 网格分段＋随机扰动，高30m；UE 四象限随机，高3m | 欧氏二维距离→服务集；CDL AoA/AoD | 场景、示意可视化；随机实现按当前页面，不可从图片恢复实际样本 |
| `distance,closestAPIdx,M_k` | UE 到 AP 的距离、升序排列、两 AP 服务集 | `[20]` m／索引；`|M_k|=2` | 页面 128-149；`d_{mk}=sqrt((x_m-x_k)^2+(y_m-y_k)^2)` | `connectUE`；集合可重叠 | SRS 拼接、W 分块及 AP 叠加；集合内部存储方式 ? |
| `channels,dlChannel,ulChannel` | 节点间信道实例 | `channels[Nnode,Nnode]` cell；DL/UL CDL 对象 | 页面 156-167,232-303；`Nnode=1+20+4`，延迟扩展 300ns；DL 复制/设几何，UL `swapTransmitAndReceive` | `hNRCustomChannelModel.applyChannelModel` 作用于在途包 | 全 PHY 接收；CDL 核心内部 ? |
| `SRSPeriodicityUE,SRS configuration` | 上行探测配置 | 周期 5；资源/序列/功率的具体内部字段 ? | CPU 构造页面 105-107；官方文字 49-52 CPU 配置 UE | UE→AP SRS；集中 AP 上送 path gains/filter，分布 AP 上送局部 CSI | CPU 形成联合估计；helper 内部 ? |
| `H_{mk}^{ul},Ĥ_k^{ul}` | AP m 与 UE k 上行估计信道、CPU 合并信道 | 在当前 4Rx AP/1Tx UE 配置下，每 AP 约 `[4,1]`，拼接约 `[8,1]`；一般按页面的转置堆叠，具体内部轴 ? | 页面 49-58；O01 | AP→CPU 或 CPU 从 path gains/filter 估计，再按 AP 天线轴拼接 | 计算 DL `W_k`；真值 path gains/filter 给“完美估计”假设 |
| `W_k,W_{mk}` | CPU 计算的 DL ZF 预编码及按服务 AP 的块 | 若 `Ĥ_k∈C^{8×1}` 则 `W_k∈C^{8×1}`，块各约 `[4,1]`；功率尺度/归一化 ? | 页面 54-70，O02/O04 | 集中模式 CPU 应用到波形；分布模式 CPU 下发块，AP 应用 | PDSCH；不能当成 CF 旧 `W` 的源代码继承或新 MSE 权重 |
| `TPMI` | UL 码本预编码指示 | 码本索引/矩阵，具体尺寸依上行层数；本页 UE 1Tx | CPU 选取，页面 60,71-76 | UL grant→UE，UE 对 PUSCH 应用 | AP/CPU 上行译码；与 `W_k` **方向不同** |
| `X_k^dl,X_{mk}^dl,X_m^dl` | 已预编码的 UE 下行波形/其中的 AP 块/单 AP 叠加波形 | 时域样本块，具体样本轴 helper ? | 页面 61-70，O03/O04 | CPU→AP（集中波形）或 AP 本地从 TB＋W 块生成（分布） | AP→UE PDSCH；与 CF 项目未生成波形不同 |
| `PUSCH waveform,LLR_{mk}` | UE 上行数据波形、AP 对 UE 的软信息 | 样本/LLR 向量；长度由 TB/编码决定，helper ? | 页面 71-78，O05 | 集中 AP→CPU 原始波形，CPU 完整 PHY；分布 AP→CPU LLR，CPU 相加 | TB 解码/BLER；不是 CF 模型中的 `U^Hy` 数据数组 |
| `cpuStats,ueStats,metricsVisualizer` | 节点统计与可视化 | 对象/结构体，具体字段 ? | 页面 168-228 | `statistics()`、`displayPerformanceIndicators()` | 吞吐、SE、BLER；不同于 CF 的静态容量与业务代理 |
| `split,phyModelType,simulationTime` | 集中/分布处理，PHY 级别和时长 | 字符串、字符串、秒 | 页面 83-92,188-194；当前默认 `Centralized`,`full-phy`,0.1s | 决定 CPU/AP 职责和 run | 指标；页面样例数不能外推到 R2025a |

循环 `i` 在主脚本分别枚举 UE/AP，局部 `ueIdx` 是 CDL 构造内 UE 索引；它们不是可优化的用户权重。`apRadius` 是绘图/覆盖尺度 `max(subX,subY)/2`，页面并未说它对 `connectUE` 的最近两 AP 判定设硬覆盖门槛。CPU 的坐标用于布局，CPU 本身**不是** PDSCH 无线发射端。

## 可见公式全集与输入输出

| 编号 | 公式/成立条件，符号逐一解释 | 页面/代码位置 | 输入→输出、轴检查 | 来源/调用状态/最终影响 |
|---|---|---|---|---|
| O01 | `d_{mk}=√[(x_m−x_k)²+(y_m−y_k)²]`；`M_k=arg top2_m(-d_mk)`。`m` AP、`k` UE；高度未入这段选择距离。 | 当前页 128-149 | AP/UE 坐标→每 UE 20 距离、2 连接 | O 可见主脚本；决定 SRS/数据服务连接 |
| O02 | `Ĥ_k^{ul}=[(H_{m1k}^{ul})^T ... (H_{mnk}^{ul})^T]^T`；`m_i∈M_k`。转置再整体转置即按 AP 天线**行**堆叠；没有共轭。 | 当前页 49-53 | 两个 4×1 AP 估计→8×1（本配置的维度解释） | O 公式；局部估计 helper ?；CPU 的 CSI |
| O03 | `W_k=[((Ĥ_k^HĤ_k)^{-1}Ĥ_k^H)]^H`。`H` 为共轭转置，逆矩阵维度为流/UE 维；若 `Ĥ_k` 8×1，输出 W 8×1。 | 当前页 54-58 | `Ĥ_k`→DL ZF `W_k` | O 原式；内部奇异矩阵保护、总功率缩放 ?；下行 PHY。页面称 ZF，单 `k` 写法未展示跨用户零干扰矩阵的完整构造，不能替 helper 补式。 |
| O04 | `W_k=[(W_{m1k})^T ... (W_{mnk})^T]^T`；按服务 AP 发射端口块拆 W。`X_k^dl=[(X_{m1}^dl)^T ...]^T` 同理拆波形。 | 当前页 61-70 | 8×d→两个 4×d 块（本配置若 d=1）；集中/分布应用位置不同 | O 明示；单个 AP 的块进入 PDSCH。符号 `W_{m_i^k k}` 是第 i 个服务 AP 对 UE k 的块，绝非 MSE 权重。 |
| O05 | `X_m^dl=Σ_{k:m∈M_k}X_{mk}^dl`；一个 AP 对它服务的多个 UE 叠加。 | 当前页 63-67 | 各 UE 的 AP 块→AP 单个发送波形 | O 明示；共用无线时频产生多用户叠加。页面索引排版简略，集合按文字定义。 |
| O06 | `LLR_k=Σ_{m∈M_k}LLR_{mk}`；只有**分布式上行 PUSCH** AP 上送 LLR 时适用。 | 当前页 71-78 | 各 AP 同一 UE 的等长软信息→CPU 软信息 | O 明示；CPU 最终 TB 检测。不是下行信号相干合并式。 |
| O07 | `ulChannel=swapTransmitAndReceive(clone(dlChannel))`；TDD 下行/上行模型共享几何并交换端。 | 当前页 262-301 | DL CDL 对象→UL CDL 对象 | O 可见局部函数；真实 RF 校准误差不见。 |
| O08 | `a≈round√(numAPs·lengthX/lengthY)` 后找整除 `b=numAPs/a`，按子区域随机扰动 AP；UE 按四象限 `mod(i,4)` 放置，AP 高30m/UE 高3m。 | 当前页 304-399 | 参数+RNG→`apPositions[20,3]`,`uePositions[4,3]` | O 局部函数可见；图02仅布局示意，不是假装重现随机坐标。 |
| O09 | `run(networkSimulator,numFrameSimulation·0.01)`，之后 `statistics` 与 `displayPerformanceIndicators`。 | 当前页 188-228 | 仿真状态→吞吐/SE/BLER | O 主脚本；KPI 算法在 helper 中 ?，不能补成 CF 的 rate logdet 式。 |

**仅供通信模型教学，不当作官方源码公式：** `y_k(t)=Σ_m H_{km}(t)x_m(t)+n_k(t)`（T01）解释 AP→UE 无线方向；`x_m=Σ_{k:m∈M_k}W_{mk}s_k`（T02）解释 W 分块和数据叠加。官方当前页明确 `X_m^dl` 的叠加与 W 分块，**没有展示** helper 内部具体时域矩阵乘法、层映射、功率标定，也没有给各 AP 波形尺寸。T01/T02 的所有 `H,x,s,n` 是教学抽象，不用来推断数值 KPI。当前页完整 PHY 与 path gains/filter 完美估计、未模拟 CSI-RS、理想前传、TDD 互易均为明示假设；图中的“SRS无线信号”不能被误解为从噪声 SRS 样本求统计后验。

## 三方对照的边界

MathWorks `W_k` 是 CPU 从服务 AP 的联合 CSI 算出的 DL 预编码，在集中模式 CPU 应用，在分布模式按 AP 块下发后 AP 应用。CF 旧 `W[M,S,R,U,G]` 是**包含幅相/功率的波束向量**，其初始化为估计信道上的匹配滤波样式，后续更新另有 WPS/二次变换；CF Python `V[L,K_g,64,d]` 是自由复矩阵 WMMSE 的预编码；CF Python `W[K_g,d,d]` 又是 MSE 权重。它们可对应到“下行线性映射”这个物理概念，但没有 MathWorks→CF 的已核实源码赋值、导入、修改链。参考论文的标量 `v_k` 是接收器，`μ_lk=√p_lk` 才是固定 MR 方向的功率系数。详见[预编码专项](04_预编码全程.md)和[来源对照](06_三方来源对照.md)。
