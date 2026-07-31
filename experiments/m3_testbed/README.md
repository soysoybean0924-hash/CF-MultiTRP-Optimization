# M3 Testbed

This folder is the staging area for M3-scale changes that are not yet
confirmed as final results.

The workflow here always runs the full M3 scale and the full 9-D outer
search vector before a change is promoted to the formal M3 scripts:

- M3 scale: 7 DUs, 100 UEs, 100 RBGs, 2x12 MIMO.
- Methods: basic, inner, GA, PSO, GA+PSO, PSO+GA, PGSAO.
- Search space: all 9 normalized candidate parameters.
- Objective: maximize J_true, the scheduled sum log2(1+SINR).
- Other metrics such as Jain, ActiveLinks, TotalPower, and Runtime are
  evaluation metrics only.
- The first outer-search candidate is always `cfg.defaultX`, so every
  search algorithm is compared against the default inner candidate.

Run from the repository root:

```matlab
run('experiments/m3_testbed/run_m3_full9_testbed.m')
```

Useful environment variables:

- `M3_TESTBED_RUN_ID`: result folder name under `results/m3_testbed`.
- `M3_TESTBED_MAX_EVAL_CAP`: outer-search evaluations, default `16`.
- `M3_TESTBED_POPULATION_SIZE`: outer-search population size, default `8`.
- `M3_TESTBED_INNER_ITER_CAP`: inner-loop iterations, default `2`.

The script is resumable: if a method already has `search_result.mat` in the
selected run folder, it is loaded instead of recomputed.
