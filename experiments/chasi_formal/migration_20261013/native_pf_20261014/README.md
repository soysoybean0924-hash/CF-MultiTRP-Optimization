# MATLAB 原生 PF 迁移与小例对拍（2026-10-14）

这五组 **2 TRP × 2 UE × 2 资源组 × 4Rx × 4Tx** 显式复数输入，覆盖 rank1、rank2，以及名义、统一矩阵误差、统一相对误差、异质误差。它们是数学/语言等价小例，**不是 210 UE 茶思正式场景验证**。所有输入、Python 与 MATLAB 输出保存在本目录，均为轻量测试产物；没有覆盖历史实验。`comparison.json` 核查初态和两个外轮后的 PF、真信道总率、功率、V/U/W、ADMM 末残差、回溯步长和停止原因，五组最大 V 元素差 `6.67e-16`。`operator_comparison.json` 核查固定 U/W 的 M、B、误差对角项及 Q(V)，最大元素差 `2.60e-16`。容限分别为目标/真率/功率 `1e-6`、V/U `1e-5`、W/ADMM残差 `1e-4`、固定算子 `1e-8`，结果均通过。

运行记录：`prepare_compare.py` → `run_matlab_compare.m` → `verify_compare.py`；固定算子单独为 `prepare_operator.py` → `run_operator_probe.m` → `verify_operator.py`。生成脚本拒绝覆盖已有同名小例；比较数据保留原样。MATLAB 原生模块是上级目录 `chasi_matrix_wmmse.m`，正式 MATLAB 运行不调用 Python。Python 仅用于产生一次性同输入夹具和对拍。

| Python 正式函数 | MATLAB 对应实现 | 当前验证 |
|---|---|---|
| `_state`, `_effective` | `chasi_matrix_wmmse>state` | 复数 U/W、rank2 与相干和，小例对拍 |
| `_objective_snapshot`, `_pf_derivatives` | `objectiveSnapshot` | 跨组 UE PF 与导数权重，小例对拍 |
| `_quadratic_parts`, `_q_apply` | `quadratic`, `qapply` | 固定 U/W 的 M/B/误差项/Q(V) 逐数组对拍 |
| `_cg`, `_solve_v_admm`, `_project` | `cg`, `v_admm`, `project` | 跨组预算、双残差、末态 V 小例对拍 |
| `solve` 外轮与回溯 | `chasi_matrix_wmmse` 主函数 | 五支小例目标、步长、停止原因对拍 |
| `rates` | `trueRates` | 小例同一 H_true 总率对拍 |
| `uniform_*_covariances` | `uniformCovariance` | 统一与统一相对两支小例对拍 |

## 已接通的 MATLAB 入口与限制

`matlab/core/cf_evaluate_candidate.m` 在 `cfg.chasiNative.enabled=true` 时转入 `cf_evaluate_chasi_native_candidate.m`；该函数用 `cf_chasi_native_resources.m` **消费现有 MATLAB 场景的 H_est/H_true**、显式 U×G 调度和每组 RB 数，按候选 `numConnections` 选择已估计增益最高的服务 TRP，并用候选 `maxRank` 设流数，再执行纯 MATLAB PF 求解与真信道评价。旧后端默认路径保留。`tests/run_chasi_native_smoke.m` 已实际运行：4 TRP、2 个被调度 UE、3 组轻量场景中，候选连接数 1→2 使首组服务链路 2→4，PF 目标 `13.235514317→13.298414618`，两次预算可行；`cf_search('GA')` 两次评价完成并返回 PF 目标名。该烟测用旧 MATLAB 合成网络，**不是正式茶思 7站/21TRP/210UE 的等价运行**。

旧 MATLAB 场景只有标量 `srs.ErrorVariance`，没有 Python 正式场景逐链路 4×4 后验协方差。适配器要求显式 `cfg.chasiNative.covarianceRule`：`explicit_rx_covariance` 需要调用方提供完整 Nr×Nr×L×U×G 协方差；`srs_scalar_isotropic_est_gain` 则明确使用旧标量误差乘估计增益的各向同性代理。H 与 C 统一按旧 `noisePower` 归一到单位噪声。调度掩码、RB 数（合计 273）、预算、PF floor 均必须显式提供；缺失时报错，不生成替代网络。旧 9 维候选仅支持 `numConnections` 和 `maxRank` 进入本求解器，其余维度若偏离默认候选则直接报错。搜索示例应把 `activeDimensions=[2 6]`，不可把旧 9 维搜索结果与 PF 档案混为同一目标。

`export_scene_to_matlab.py` 已扩展导出 H_est/H_true、C_stat、服务掩码、UE ID、RB 数与 prior_gain；PF 分支还导出 `users`、`pf_floor`、`branch`。这只是一次性 Python 冻结场景测试工具，**现有 MATLAB 原生入口不依赖它**。其完整 210 UE 数据导入、64Tx/rank2/17组状态与算子核查，以及 210 UE 原生端到端对拍尚未执行；不能从这里的小例机器精度外推。时间演化、SRS 生成、业务协议 UE 秒感知率、共同基线和理想参照仍未原生迁移。原生目标是估计 PF 对数效用，真信道静态速率是诊断，尚不能返回正式验收判定。

## 轻量运行命令

从仓库根目录：

```powershell
& 'F:\bin\matlab.exe' -batch "run('tests/run_chasi_native_smoke.m')"
& 'C:\Users\sypxx\py\python.exe' -B experiments/chasi_formal/migration_20261013/native_pf_20261014/verify_compare.py
& 'C:\Users\sypxx\py\python.exe' -B experiments/chasi_formal/migration_20261013/native_pf_20261014/verify_operator.py
```
