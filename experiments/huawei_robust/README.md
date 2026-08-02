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
