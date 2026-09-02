# Results Index

This folder contains generated experiment outputs. Most new result files are
ignored by Git to keep the repository manageable. Older result files may still
be tracked because they were committed before the current ignore rules.

Snapshot date: 2026-09-02.

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
