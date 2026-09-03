# Experiment Index

Status values: `PLANNED`, `SMOKE`, `RUNNING`, `COMPLETE`, `ARCHIVED`, `FAILED`.

Snapshot date: 2026-09-02.

## 中文说明

这个文件是“实验地图”。以后找实验时优先看这里：入口脚本在哪、用了什么规模、
seed 和 evaluation budget 是多少、结果目录在哪里、当前能不能当论文结果。

状态含义：

- `PLANNED`：计划要跑，但还没有正式结果。
- `SMOKE`：只验证代码链路，不作为论文结论。
- `RUNNING`：正在跑或预期可续跑。
- `COMPLETE`：已有完整结果，但仍需看是否单 seed 或是否仅压力测试。
- `ARCHIVED`：历史结果，保留参考，不作为当前主线证据。
- `FAILED`：运行失败或结果不可用。

| Experiment | Entry | Config / scale | TRP | UE | Tx | RBG | Seeds | Eval | Result directory | Status |
|---|---|---|---:|---:|---:|---:|---|---:|---|---|
| Controlled outer ablation smoke | `experiments/paper_ablation/run_controlled_outer_ablation.m` | S1 smoke overrides | 4 | 8 | 8 | 2 | 1 | 2 | `results/paper_ablation/smoke_codex/` | SMOKE |
| Controlled paper ablation full | `experiments/paper_ablation/run_controlled_outer_ablation.m` | S1/S2/S3/S4 | 4/8/12/16 | 8/16/24/32 | 8 | 4 | 1:10 | 32 | `results/paper_ablation/<run_id>/` | PLANNED |
| Quick core examples | `matlab/core/run_01_basic.m` to `run_07_pgsao.m` | `quick` | 4 | 6 | 4 | 3 | 11/23/37 | 32 | manual figures/tables | SMOKE |
| Legacy profile comparison | `experiments/m3_scale_comparison/run_m3_algorithm_comparison.m` | quick/standard/paper/m3 | 4/8/16/7 | 6/16/30/100 | 4/8/8/12 | 3/4/5/100 | default single seed | 32/72/200/capped | `results/M3_scale_comparison/` | COMPLETE |
| Legacy true-objective comparison | `experiments/m3_scale_comparison/run_m3_algorithm_comparison.m` | quick/standard/paper/m3 | 4/8/16/7 | 6/16/30/100 | 4/8/8/12 | 3/4/5/100 | default single seed | mixed | `results/M3_true_objective_comparison/` | ARCHIVED |
| Capped comparison debug | `experiments/m3_scale_comparison/run_m3_algorithm_comparison.m` | quick/standard/paper/m3 with caps | mixed | mixed | mixed | mixed | default single seed | 1 | `results/M3_scale_comparison_capped_eval1_iter1/` | SMOKE |
| M3 full 9-D default seeded eval16 | `experiments/m3_testbed/run_m3_full9_testbed.m` | `m3`, full 9-D search | 7 | 100 | 12 | 100 | default single seed | 16 | `results/m3_testbed/jtrue_full9_default_seeded_eval16/` | COMPLETE |
| M3 basic/inner converged check | `experiments/m3_testbed/run_m3_full9_testbed.m` | `m3`, basic/inner | 7 | 100 | 12 | 100 | default single seed | 1 | `results/m3_testbed/m3_basic_inner_converged_20260809/` | COMPLETE |
| M3 outer probe | `experiments/m3_testbed/run_m3_full9_testbed.m` | `m3`, outer methods | 7 | 100 | 12 | 100 | default single seed | 2 | `results/m3_testbed/m3_outer_probe_20260809/` | SMOKE |
| M3 efficiency benchmark | `experiments/m3_efficiency/run_m3_efficiency_benchmark.m` | tiny/small/m3_probe | mixed | mixed | mixed | mixed | default single seed | 2 | `results/m3_efficiency/initial_efficiency_benchmark/` | COMPLETE |
| Local sensitivity | `experiments/local_sensitivity/run_local_sensitivity_9params.m` | default / quick-like | mixed | mixed | mixed | mixed | default | none | `results/local_sensitivity/` | ARCHIVED |
| Local sensitivity profiles | `experiments/local_sensitivity/run_local_sensitivity_profile_comparison.m` | quick/standard/paper | 4/8/16 | 6/16/30 | 4/8/8 | 3/4/5 | 1:5 | none | `results/local_sensitivity_profiles/` | ARCHIVED |
| Huawei robust probe | `experiments/huawei_robust/run_huawei_robust_comparison.m` | Huawei probe overrides | 21 | 21 | 8 | 4 | default single seed | 2 | `results/huawei_robust/probe_robust_vs_nonrobust/` | SMOKE |
| Huawei staged robust suite | `experiments/huawei_robust/run_huawei_robust_scale_suite.m` | probe/medium/full_lite | 21 | 21/42/63 | 8/8/12 | 4/8/12 | default single seed | 2 | `results/huawei_robust/probe_medium_full_lite_suite/` | COMPLETE |
| Huawei final full-lite matrix eval16 | `experiments/huawei_robust/run_huawei_final_algorithm_comparison.m` | `HUAWEI_FINAL_SCALE=full_lite` | 21 | 63 | 12 | 12 | default single seed | 16 | `results/huawei_robust/full_lite_algorithm_matrix_eval16/` | COMPLETE |
| Huawei full basic/inner partial | `experiments/huawei_robust/run_huawei_final_algorithm_comparison.m` | final overrides rank1/RBG16, basic+inner | 21 | 315 | 64 | 16 | default single seed | 1 | `results/huawei_robust/huawei_full_ue_tx_rank1_rbg16_basic_inner/` | COMPLETE |
| Huawei full algorithm matrix | `experiments/huawei_robust/run_huawei_final_algorithm_comparison.m` | full Huawei | 21 | 315 | 64 | 273 | default single seed | 48 | `results/huawei_robust/<future_run>/` | PLANNED |

## Current Paper Matrix

中文说明：当前论文主线的消融矩阵就是下面这 8 个方法。注意 `GA-only`、
`PSO-only`、`PGSAO-only` 是不跑 inner 的真正 outer-only baseline；
`GA+Inner`、`PSO+Inner`、`PGSAO+Inner` 是外层搜索每个 candidate 都调用 inner。

The paper-focused experiment matrix is:

- `basic`
- `inner`
- `GA-only`
- `PSO-only`
- `PGSAO-only`
- `GA+Inner`
- `PSO+Inner`
- `PGSAO+Inner`

The first formal result should be produced by the default
`run_controlled_outer_ablation.m` settings, not by the tiny `smoke_codex`
validation.
