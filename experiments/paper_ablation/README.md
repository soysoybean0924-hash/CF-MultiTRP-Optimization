# Paper Ablation Experiments

This folder contains the controlled first-stage paper workflow for separating
outer-only search from outer search with the inner iterative optimizer.

## Methods

The default matrix is:

| Method | Outer search | Inner optimization |
|---|---|---|
| `basic` | no | no |
| `inner` | no | yes |
| `GA-only` | GA | no |
| `PSO-only` | PSO | no |
| `PGSAO-only` | PGSAO | no |
| `GA+Inner` | GA | yes |
| `PSO+Inner` | PSO | yes |
| `PGSAO+Inner` | PGSAO | yes |

`PGSAO` is used as the current hybrid outer-search method because it is already
implemented in the repository and avoids introducing a new algorithm just for
the ablation.

## Controlled Scales

The default scale set isolates TRP growth while keeping antennas and RBGs fixed:

| Scale | TRP / DU | UE |
|---|---:|---:|
| `S1` | 4 | 8 |
| `S2` | 8 | 16 |
| `S3` | 12 | 24 |
| `S4` | 16 | 32 |

Default shared settings are 8 Tx/TRP, 2 Rx/UE, 4 RBGs, 10 seeds, 32 outer
objective evaluations, population size 8, and 12 inner iterations.

## Outputs

`run_controlled_outer_ablation.m` writes:

- `ablation_comparison.csv`
- `scale_comparison.csv`
- `multiseed_statistics.csv`
- `convergence_comparison.csv`
- `runtime_comparison.csv`
- `controlled_outer_ablation_results.mat`
- `fig1_algorithm_jtrue.png`
- `fig2_jtrue_vs_trp.png`
- `fig3_multiseed_mean_std.png`
- `fig4_convergence_curve.png`
- `fig5_performance_vs_runtime.png`
- `paper_ablation_report.md`

## Quick Validation

Use a tiny run to validate wiring without claiming paper evidence:

```matlab
setenv('PAPER_ABLATION_RUN_ID','smoke');
setenv('PAPER_ABLATION_SCALES','S1');
setenv('PAPER_ABLATION_SEEDS','1');
setenv('PAPER_ABLATION_MAX_EVAL','2');
setenv('PAPER_ABLATION_POPULATION','2');
setenv('PAPER_ABLATION_INNER_ITER','1');
run('experiments/paper_ablation/run_controlled_outer_ablation.m');
```

The full first-stage paper run should keep the same budget for every outer
method and report both objective evaluations and runtime.
