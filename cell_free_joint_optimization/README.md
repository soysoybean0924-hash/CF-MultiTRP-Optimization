# Cell-Free / 多 TRP b/p/r/W 联合优化 MATLAB 套件

## 运行入口

| 文件 | 内容 |
|---|---|
| `run_01_basic.m` | 基础多 DU、多 UE、top-K 服务、MRT、功率约束 |
| `run_02_inner_wps.m` | `H → W → SLINR → WPS → W` 内层迭代 |
| `run_03_ga.m` | 外层 GA |
| `run_04_pso.m` | 外层 PSO |
| `run_05_ga_pso.m` | GA 后接 PSO |
| `run_06_pso_ga.m` | PSO 后接 GA |
| `run_07_pgsao.m` | PGSAO 混合搜索 |

在 MATLAB 中进入本目录后直接运行，例如：

```matlab
run_01_basic
run_02_inner_wps
run_03_ga
```

默认是快速验证配置。正式实验可将入口中的：

```matlab
cfg=cf_default_config('quick');
```

改为 `standard` 或 `paper`。

## 联合变量

| 变量 | 维度 | 含义 |
|---|---:|---|
| `H` | `Nr×M×R×U×G` | 固定 MIMO 信道 |
| `W` | `M×S×R×U×G` | 每流预编码 |
| `b` | `R×U×G` | 二值 DU–UE–RBG 服务关系 |
| `p` | `R×U×G` | 每链路连续功率 |
| `r` | `U×G` | 每 UE/RBG 的整数数据流数 |

外层统一搜索 9 个参数：PF 指数、候选 DU 数、调度门限、链路惩罚、功率惩罚、最大 rank、rank 门限、修复功率、修复链路数。

## 资源图的离散/连续口径

- **b 图**显示跨所有 RBG 的服务次数，只可能为 `0,1,...,numRBGs`。使用一整数一颜色的离散色块，colorbar 只保留整数刻度。
- **r 图**显示数据流数，只可能为整数（当前 1 或 2）。同样使用离散色块和整数刻度。
- **p 图**是连续功率分配，`0.5` 功率可能真实存在，因此保留连续色阶。

三张资源图都关闭了落在整数刻度中心的默认网格，避免色块内部出现“十字”。分界线改画在 `0.5、1.5、2.5…` 的单元边缘：内部边界为浅灰色，外围边框稍深。离散图在不超过 200 个单元格时还会直接标注整数。实现集中在 `cf_plot_result.m` 的 `plotDiscreteIntegerHeatmap`、`plotContinuousHeatmap` 和 `drawCellBoundaries`。

## 模型边界

当前假设完美 CSI、同步相干联合传输、每 RBG 窄带平坦衰落、最多 2 流，以及每 DU/RBG 独立功率上限。内层属于 WMMSE/二次变换/SCA-like 研究原型。
