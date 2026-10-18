# CHASI 独立 Python 对照的复现入口

正式入口是 `matlab/chasi/chasi_run.m`，不导入或运行 Python。本目录只为离线数值对拍保留项目内 Python 参考实现的必要模块：`chasi_formal_implementation/{config,scenario,pathloss,srs_reuse,solver,evaluate,traffic_model,time_evolution,second_metrics,burst_metrics,uniform_error,initializers}.py`、已有的 `protocol_contract.py` 及包入口。没有将外部 2023 论文仓库整份复制进来；所选文件没有外部版权或许可证头，项目原始创作和再分发权的法律归属仍以仓库所有者记录为准。

Python 3.9 离线环境按 `tests/requirements_chasi_reference.txt` 安装 NumPy、SciPy、h5py。MATLAB 路径无需这些依赖。所有命令从仓库根目录执行；输出目录必须是新的空目录。

## 可在干净检出中直接运行的小例

```powershell
py -3.9 -m pip install -r tests/requirements_chasi_reference.txt
matlab -batch "addpath('tests'); chasi_export_canonical_parity('tmp/chasi_clean_canonical')"
py -3.9 tests/verify_chasi_canonical_parity.py tmp/chasi_clean_canonical
py -3.9 -m chasi_formal_implementation.test_v_reference
```

前两条读取已跟踪的五组显式 MAT 夹具，比较 MATLAB 与保存的 Python 原参考输出；第三条用独立 SciPy SLSQP 检查小型固定 A/Ω 的预编码子问题。保存的参考输出并非一次新的现场 Python 求解。运行记录应注明这一证据边界。

## 210／420 UE 静态同输入对拍

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
