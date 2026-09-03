# Current Research Status

Snapshot date: 2026-09-02.

## 中文摘要

当前项目已经完成了真正的 Outer-only 消融接口：`GA-only`、`PSO-only`、
`PGSAO-only` 可以在不运行 inner 的情况下评价同一个 `J_true`。同时，
`GA+Inner`、`PSO+Inner`、`PGSAO+Inner` 也已经存在。

但现在还没有完成正式论文级实验。已有 `smoke_codex` 只是一个极小 S1 单 seed、
2 次外层评价、1 次 inner 迭代的连通性验证，不能证明 PGSAO+Inner 稳定优于
GA+Inner 或 PSO+Inner。下一步最重要的是跑 S1-S4、seed 1:10、统一 eval 32
的 controlled ablation。

## Current Research Goal

Show, on controlled small/medium Multi-TRP scales, whether inner iterative
optimization and hybrid outer search are complementary under the same
objective, same scenario seeds, and matched outer evaluation budgets.

## Current Core Algorithms

- Basic: default candidate without inner optimization.
- Inner-only: default candidate with inner optimization.
- Single outer + inner: GA+Inner and PSO+Inner.
- Hybrid outer + inner: PGSAO+Inner is the current proposed track.
- Matched outer-only ablations: GA-only, PSO-only, PGSAO-only.

## What Is Already Proven

- The core pipeline runs through MATLAB smoke tests.
- Outer-only ablation is implemented through
  `options.enableInnerOptimization=false` in `cf_search`.
- A tiny S1 smoke run confirms that GA-only, PSO-only, and PGSAO-only skip
  inner iterations.
- The smoke run shows `PGSAO+Inner > Inner-only > PGSAO-only` for one tiny
  case, but this is not paper-level evidence.

## What Is Not Yet Proven

- PGSAO+Inner is not yet proven better than GA+Inner or PSO+Inner.
- No formal S1-S4 x 10-seed x 32-evaluation controlled result exists yet.
- No statistical significance has been established for the proposed method.
- Huawei full-scale dominance has not been shown and is not the current
  first-stage claim.

## Most Trustworthy Current Experiments

- For code wiring: `results/paper_ablation/smoke_codex/`.
- For historical profile behavior: `results/M3_scale_comparison/algorithm_profile_comparison.csv`.
- For M3 stress behavior: `results/m3_testbed/jtrue_full9_default_seeded_eval16/algorithm_comparison.csv`.
- For Huawei full-lite stress behavior:
  `results/huawei_robust/full_lite_algorithm_matrix_eval16/huawei_final_algorithm_comparison.csv`.

## Current Largest Scales

- Configured maximum: Huawei full profile, 21 TRP, 315 UE, 64 Tx/TRP,
  273 RBG, 4 Rx/UE.
- Actually completed broad algorithm matrix near Huawei: 21 TRP, 63 UE,
  12 Tx/TRP, 12 RBG, eval 16.
- Actually completed full UE/Tx partial: 21 TRP, 315 UE, 64 Tx/TRP,
  16 RBG, basic/inner only.

## Huawei Status

Huawei is currently an engineering-inspired stress-test branch:

- Full config exists.
- Probe, medium, full-lite workflows exist.
- Full Huawei algorithm matrix is not complete.
- Full Huawei results should not be used as the main paper proof yet.

## Current Paper Gaps

1. Run the controlled S1-S4 ablation with seeds `1:10`, eval 32, fixed 8 Tx.
2. Add statistical comparison and confidence intervals from the generated
   `multiseed_statistics.csv`.
3. Compare convergence curves for GA+Inner, PSO+Inner, and PGSAO+Inner.
4. Report runtime and evaluations to separate performance gain from budget.
5. Decide whether PGSAO is truly the hybrid method after multi-seed data.

## Next Three Things

1. Run `experiments/paper_ablation/run_controlled_outer_ablation.m` with the
   default controlled paper settings.
2. Inspect `results/paper_ablation/<run_id>/paper_ablation_report.md` and
   `multiseed_statistics.csv`.
3. If PGSAO+Inner does not beat GA+Inner/PSO+Inner, analyze convergence and
   budget before changing algorithms.
