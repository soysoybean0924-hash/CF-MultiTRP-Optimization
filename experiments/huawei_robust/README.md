# Huawei Robust SRS Benchmark

This folder contains the staged robust-vs-nonrobust validation workflow for
the Huawei-style SRS nonideal measurement challenge.

The default run is intentionally a Huawei probe, not the final full-scale
Huawei validation. It keeps the same scene semantics while reducing UE/RBG
and antenna dimensions enough to iterate quickly.

## Run

```matlab
run('experiments/huawei_robust/run_huawei_robust_comparison.m')
```

For the staged probe/medium/full-lite workflow:

```matlab
run('experiments/huawei_robust/run_huawei_robust_scale_suite.m')
```

For the formal Huawei algorithm comparison entry:

```matlab
run('experiments/huawei_robust/run_huawei_final_algorithm_comparison.m')
```

Outputs are written under:

```text
results/huawei_robust/<run_id>/
```

## Default Probe Budget

- UE count: 21
- RBG count: 4
- Tx/Rx antennas: 8x2
- inner iterations: 1
- outer evaluations: 2
- methods: basic, inner, PSO+GA
- variants: nonrobust, robust

The key metrics are computed on both the scheduler-visible estimated channel
and the validation `H_true` channel. The robust challenge should be judged by
the true-channel columns.

## Scale Suite

- `probe`: validates logic and output fields.
- `medium`: tunes soft/default/aggressive robust parameters and screens
  feasible algorithms.
- `full_lite`: keeps 21 sectors and increases UE/RBG/antenna dimensions with
  a low search budget before final full Huawei validation.

## Final Comparison Entry

`run_huawei_final_algorithm_comparison.m` compares:

- basic, inner, GA, PSO, GA+PSO, PSO+GA, and PGSAO;
- robust and nonrobust SRS handling;
- edge-aware and non-edge-aware scheduling.

It exports summary CSV/XLSX/MAT files, per-method search histories, best
candidate tables, experience-rate CDF CSV files, comparison figures, a
Markdown report, and a runtime-per-evaluation complexity trend table.

The default `HUAWEI_FINAL_SCALE=final` uses the full `cf_default_config('huawei')`
scale. Use `probe`, `medium`, or `full_lite` for fast checks, or override
`HUAWEI_FINAL_NUM_UES`, `HUAWEI_FINAL_NUM_RBGS`, `HUAWEI_FINAL_NUM_TX`,
`HUAWEI_FINAL_NUM_RX`, `HUAWEI_FINAL_INNER_ITER`, `HUAWEI_FINAL_MAX_EVAL`,
and `HUAWEI_FINAL_POPULATION` for controlled acceptance runs.
