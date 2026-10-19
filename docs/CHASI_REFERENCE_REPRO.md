# CHASI 独立 Python 对照的复现入口

正式入口是 `matlab/chasi/chasi_run.m`，不导入或运行 Python。本目录只为离线数值对拍保留项目内 Python 参考实现的必要模块：`chasi_formal_implementation/{config,scenario,pathloss,srs_reuse,solver,evaluate,traffic_model,time_evolution,second_metrics,burst_metrics,uniform_error,initializers}.py`、已有的 `protocol_contract.py` 及包入口。没有将外部 2023 论文仓库整份复制进来；所选文件没有外部版权或许可证头，项目原始创作和再分发权的法律归属仍以仓库所有者记录为准。

Python 3.9 离线环境按 `tests/requirements_chasi_reference.txt` 安装 NumPy、SciPy、h5py。MATLAB 路径无需这些依赖。所有命令从仓库根目录执行；输出目录必须是新的空目录。

2026-10-18 在提交 `9b591cc` 的**独立稀疏 Git 工作树**实际检出上述源文件、测试和小夹具，使用 Python 3.9.13、NumPy 1.26.4、SciPy 1.13.1、h5py 3.13.0（环境已安装，未测试现场安装），执行以下小例命令。五组、外轮0/2的检查退出码0，最大 $w$ 元素差 `6.663e-16`、Ω差 `8.882e-16`；独立 SLSQP 子问题差 `6.200e-10`，其严格 ADMM 残差停止条件仍未满足。该临时工作树不是正式 MATLAB 的输入来源。**未在此干净检出中重建和求解 210/420 UE 大场景**；正式规模命令是可执行复现步骤而非已完成证据。

## 可在干净检出中直接运行的小例

2026-10-19 在提交 `a550537` 的**独立稀疏 Git 工作树**实际检出 `chasi_formal_implementation`、`matlab/chasi` 与 `tests`，重跑 `py -3.9 -m chasi_formal_implementation.test_srs_hop_timing`、`py -3.9 -m chasi_formal_implementation.test_v_reference`、`matlab -batch "addpath('matlab/chasi','tests'); chasi_export_geometry_common('clean_geometry.mat')"` 与 `py -3.9 tests/verify_chasi_geometry_common.py clean_geometry.mat`，均退出0；独立 SLSQP 固定子问题目标差 `6.200e-10`，严格 ADMM 残差未过，显式几何坐标差 `1.137e-13 m`。该检出只证明小例和参考模块可从已提交源重建，**没有在干净检出中重跑210/420 UE大场景**，其结果以主工作区原生运行和同显式输入报告为准。临时工作树检查后移除，不保留仓库副本。

```powershell
py -3.9 -m pip install -r tests/requirements_chasi_reference.txt
matlab -batch "addpath('tests'); chasi_export_canonical_parity('tmp/chasi_clean_canonical')"
py -3.9 tests/verify_chasi_canonical_parity.py tmp/chasi_clean_canonical
py -3.9 -m chasi_formal_implementation.test_v_reference
```

前两条读取已跟踪的五组显式 MAT 夹具，比较 MATLAB 与保存的 Python 原参考输出；第三条用独立 SciPy SLSQP 检查小型固定 A/Ω 的预编码子问题。保存的参考输出并非一次新的现场 Python 求解。运行记录应注明这一证据边界。

拓扑的**共同底层随机输入**另用确定性均匀数组（不靠相同 seed）验证：

```powershell
matlab -batch "addpath('matlab/chasi','tests'); chasi_export_geometry_common('tmp/chasi_geometry_common.mat')"
py -3.9 tests/verify_chasi_geometry_common.py tmp/chasi_geometry_common.mat
```

实际小例输出：21个 TRP 坐标最大差0，210个 UE 坐标最大差 `1.137e-13 m`，home TRP ID完全一致。此只覆盖**几何映射**；调度抽样、链路增益/阴影、信道高斯样本及 SRS 噪声尚未提供全链共同原始随机输入，不能据此宣称生成器全部等价。

## 210／420 UE 静态同输入对拍

2026-10-19 新420 UE本地证据：`results/chasi_matlab/formal420_20261018_double_precision/scene.mat` SHA256 `F973ED5F01835E944EB5E04A24E775BF2675590CBFA651AEBBDA862C657DDB6D`；显式导出 `tmp/chasi_formal_shared_420_current.mat`，独立 Python 完整求解及各层比较的轻量报告为 `docs/CHASI_PARITY_420_20261019.json`。原 Ω 绝对门槛 `1e-5` 下最大差 `1.954e-14`，完整 w 最大差 `3.387e-15`；两侧同为内层未达阈值且外层达到上限。大文件只作本地输入，不能从仓库直接下载。

使用同一份已保存的 MATLAB 原生 `scene.mat`、`matrix_statistical_precoders.mat`、`summary.json`、`scene_manifest.json`。大 MAT 由下列命令重建，不入库。`chasi_run` 默认配置为 21 TRP、每小区 10 UE、seed 20261011、rank 2、17 组 273 RB、外轮 2、ADMM 12；420 UE 只将 `usersPerCell` 改为 20。按需要选择**新的**输出路径；求解可能耗时数十分钟。

```powershell
matlab -batch "addpath('matlab/chasi'); chasi_run(struct('usersPerCell',10,'branches',{{'matrix_statistical'}},'outputDir','results/chasi_matlab/repro210'))"
matlab -batch "addpath('matlab/chasi'); chasi_run(struct('usersPerCell',20,'branches',{{'matrix_statistical'}},'outputDir','results/chasi_matlab/repro420'))"
matlab -batch "addpath('matlab/chasi','tests'); chasi_export_formal_shared_input('results/chasi_matlab/repro210','tmp/repro210_explicit.mat')"
matlab -batch "addpath('matlab/chasi','tests'); chasi_export_formal_shared_input('results/chasi_matlab/repro420','tmp/repro420_explicit.mat')"
py -3.9 tests/verify_chasi_formal_shared_input.py results/chasi_matlab/repro210 tmp/repro210_explicit.mat --solve-full
py -3.9 tests/verify_chasi_formal_shared_input.py results/chasi_matlab/repro420 tmp/repro420_explicit.mat --solve-full
```

对于**历史** 2026-10-17 输出，210 UE 保存的 Ω 仍超过原 `1e-5` 绝对门槛；当前脚本额外输出 `current_fixed_input_pass`，指当前 MATLAB 代码用相同旧 `w` 重新计算状态的结果，绝不覆盖 `fixed_input_pass=false`。历史保存的初始预编码也不可被新的双精度初始化默认为相同；当 `historical_initial_matches_regenerated=false` 时，禁止把对旧轨迹的 `--solve-full` 比较称为迁移对拍。新生成正式运行的完整对拍以独立运行记录为准。

复现输入身份应记录 `Get-FileHash ... -Algorithm SHA256`，并核对组数、`H` 轴序 `[本地UE,TRP,下行Rx,TRP Tx]`、全局 `ueIds`、服务掩码、`C_stat`、`resourceWeightNu`、预算、rank、初始 `w` 与停止参数。相同 seed 不等于相同随机输入。`tests/verify_chasi_dynamic_shared_replay.py` 只核查零速度、冻结预编码的业务回放；移动 CSI 与在线重求不在其通过范围。

本次修复版210 UE本地输入标识：`results/chasi_matlab/formal210_20261018_double_precision/scene.mat` SHA256 `FCB75A9B626D3B9D847DB0EFFAB42C2DCD97EE10908075DE22E46532FDBE444F`；由此导出的 `tmp/chasi_formal_shared_210_current.mat` SHA256 `0031B98446F6D939A08669EAB3F343FE30C6596CCF2C037DB0065BD88E691B2C`。哈希标识**本地这一份字节文件**，MAT 文件头及生成时间可能使重建文件的字节哈希不同；复现时还需核对数组和配置。完整求解对拍的轻量结果见 `docs/CHASI_PARITY_210_20261018.json`。
