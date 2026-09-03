# Results Index

This folder contains generated experiment outputs. Most new result files are
ignored by Git to keep the repository manageable. Older result files may still
be tracked because they were committed before the current ignore rules.

Snapshot date: 2026-09-02.

## 中文速览

这个目录里不是所有结果都能直接写进论文。当前分类原则是：

- `SMOKE`：只证明代码能跑通，例如 `paper_ablation/smoke_codex/`。
- `COMPLETE historical`：历史单 seed 或旧配置结果，可以帮助恢复研究脉络。
- `COMPLETE stress`：M3/Huawei 压力测试结果，能说明大规模行为，但不是当前第一阶段论文主证据。
- `PLANNED`：计划中的正式论文结果，主要是未来的 `paper_ablation/<run_id>/`。

目前真正缺的是 `paper_ablation` 下的正式 S1-S4、多 seed、统一搜索预算结果。

## Current Paper Track

| Directory | Status | Use |
|---|---|---|
| `paper_ablation/smoke_codex/` | SMOKE | Confirms controlled outer-only ablation wiring. Not paper-level evidence. |
| `paper_ablation/<future_run>/` | PLANNED | Formal S1-S4, seeds 1:10, eval 32 paper ablation outputs. |

The formal paper run should produce:

- `ablation_comparison.csv`
- `scale_comparison.csv`
- `multiseed_statistics.csv`
- `convergence_comparison.csv`
- `runtime_comparison.csv`
- `fig1_algorithm_jtrue.png`
- `fig2_jtrue_vs_trp.png`
- `fig3_multiseed_mean_std.png`
- `fig4_convergence_curve.png`
- `fig5_performance_vs_runtime.png`
- `paper_ablation_report.md`

## Smoke / Debug Results

| Directory | Reason |
|---|---|
| `paper_ablation/smoke_codex/` | S1, seed 1, eval 2, inner iter 1; code-path validation only |
| `M3_scale_comparison_capped_eval1_iter1/` | Very low-budget capped debug result |
| `huawei_robust/final_smoke_codex/` | Huawei smoke output |
| `m3_testbed/m3_outer_probe_20260809/` | M3 outer probe with eval 2 |

## M3 Results

中文说明：M3 结果很重要，但更像压力测试。已有结果显示在当前 `J_true` 定义下，
`basic` 因为保留更多链路和功率，在 M3 上可能非常强，不能简单当作 proposed
方法已经失败或成功的最终论文结论。

| Directory | Status | Notes |
|---|---|---|
| `M3_scale_comparison/` | COMPLETE historical | quick/standard/paper/m3 single-seed profile comparison |
| `M3_true_objective_comparison/` | ARCHIVED | older or duplicate-looking true-objective comparison root |
| `m3_testbed/jtrue_full9_default_seeded_eval16/` | COMPLETE stress | 7 TRP, 100 UE, 100 RBG, 12 Tx, eval 16 |
| `m3_testbed/m3_basic_inner_converged_20260809/` | COMPLETE partial | basic vs inner at M3 scale |
| `m3_efficiency/initial_efficiency_benchmark/` | COMPLETE support | runtime / per-evaluation scaling probe |

Key M3 fact: `basic` remains very strong under the current `J_true` objective
because it keeps many links and high power. M3 is therefore a stress-test
track, not the first-stage paper proof.

## Huawei Results

中文说明：Huawei 目录是工程启发式 stress test。full config 已经存在，
但完整 21 TRP / 315 UE / 64 Tx / 273 RBG 的全算法矩阵还没完成。

| Directory | Status | Notes |
|---|---|---|
| `huawei_robust/probe_robust_vs_nonrobust/` | SMOKE | 21 TRP probe, low budget |
| `huawei_robust/probe_medium_full_lite_suite/` | COMPLETE stress | staged probe/medium/full-lite robust comparison |
| `huawei_robust/full_lite_algorithm_matrix/` | COMPLETE stress | full-lite algorithm matrix, low default budget |
| `huawei_robust/full_lite_algorithm_matrix_eval16/` | COMPLETE stress | 21 TRP, 63 UE, 12 RBG, 12 Tx, eval 16 |
| `huawei_robust/huawei_full_ue_tx_rank1_rbg16_basic_inner/` | COMPLETE partial | 21 TRP, 315 UE, 64 Tx, 16 RBG, basic/inner only |

Huawei full profile exists in code, but the full 21 TRP / 315 UE / 64 Tx /
273 RBG algorithm matrix is not complete.

## Sensitivity Results

| Directory | Status | Notes |
|---|---|---|
| `local_sensitivity/` | ARCHIVED | local parameter sensitivity outputs |
| `local_sensitivity_profiles/` | ARCHIVED | quick/standard/paper sensitivity profile comparison |

## Which Results Are Paper-Usable Now?

Current paper-quality evidence is not complete. The most useful current files
are for orientation and stress analysis:

- `M3_scale_comparison/algorithm_profile_comparison.csv`
- `m3_testbed/jtrue_full9_default_seeded_eval16/algorithm_comparison.csv`
- `huawei_robust/full_lite_algorithm_matrix_eval16/huawei_final_algorithm_comparison.csv`
- `paper_ablation/smoke_codex/scale_comparison.csv` for smoke only

The next paper-usable result should be generated under
`paper_ablation/<run_id>/` by running the default controlled ablation.
