# M3 Efficiency Benchmark

This folder contains the staged validation workflow for the mandatory
high-efficiency computing target.

The benchmark measures runtime scaling before changing the production
optimization logic. It runs fixed-size scenarios, records per-method timing,
and exports plots plus a short interpretation report.

## Run

```matlab
run('experiments/m3_efficiency/run_m3_efficiency_benchmark.m')
```

Outputs are written under:

```text
results/m3_efficiency/<run_id>/
```

## Environment Controls

- `M3_EFFICIENCY_RUN_ID`: result folder name.
- `M3_EFFICIENCY_PROFILES`: comma-separated profiles. Default:
  `tiny,small,m3_probe`.
- `M3_EFFICIENCY_METHODS`: comma-separated methods. Default:
  `basic,inner,PSO+GA`.
- `M3_EFFICIENCY_INNER_ITER_CAP`: inner-loop cap. Default `1`.
- `M3_EFFICIENCY_MAX_EVAL_CAP`: outer-search evaluation cap. Default `2`.
- `M3_EFFICIENCY_POPULATION_SIZE`: outer-search population size. Default `2`.

## Interpretation

The first target is measurement, not a final claim. A successful run produces:

- `efficiency_summary.csv`
- `efficiency_scaling_fit.csv`
- `fig_runtime_vs_links.png`
- `fig_runtime_per_eval.png`
- `M3_efficiency_explanation.md`

These files show whether the current implementation behaves close to a
low-linear scaling target and identify which method/scale is the bottleneck.
