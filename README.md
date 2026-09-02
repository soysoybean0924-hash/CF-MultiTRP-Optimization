# CF-MultiTRP-Optimization

Cell-Free / Multi-TRP cooperative scheduling research code for studying
inner iterative optimization plus outer search over scheduling parameters.

## Research Question

This repository studies whether a Multi-TRP scheduler can improve the true
system objective by combining:

- an inner iterative beam / power / link update; and
- an outer search over mixed scheduling parameters.

The current first-stage paper track is not trying to prove full Huawei-scale
dominance yet. The active claim to test is:

```text
Hybrid Outer Search + Inner optimization
  > Inner-only
  > matched Outer-only ablations
  > single outer search + Inner, if supported by multi-seed data
```

Huawei-style runs are treated as engineering stress tests.

## Current Directory Map

```text
CF-MultiTRP-Optimization/
|-- matlab/core/                 Core MATLAB model, objective, inner loop, search
|-- experiments/local_sensitivity/
|                                Historical local sensitivity experiments
|-- experiments/m3_scale_comparison/
|                                M3 profile comparison and reduced search scripts
|-- experiments/m3_testbed/       Full 9-D M3 staging testbed
|-- experiments/m3_efficiency/    Runtime / complexity probe workflow
|-- experiments/huawei_robust/    Huawei-inspired robust / edge-aware workflows
|-- experiments/paper_ablation/   Current paper ablation workflow
|-- docs/                         Research notes, status, experiment index
|-- results/                      Experiment outputs and result index
|-- tests/                        Smoke checks for paths and core pipeline
|-- paper_edit/                   Untracked paper-building artifacts
|-- setup_project_paths.m         MATLAB path setup
```

## Core Algorithms

- Basic baseline: `cf_evaluate_candidate(..., false)` on `cfg.defaultX`.
- Inner-only: `cf_evaluate_candidate(..., true)` on `cfg.defaultX`.
- Outer search: `cf_search(method, cfg, scenario, options)`.
- Implemented search methods: `GA`, `PSO`, `GA+PSO`, `PSO+GA`, `PGSAO`.
- Matched outer-only ablation: set `options.enableInnerOptimization = false`.
- Outer + Inner: default search behavior, or set `options.enableInnerOptimization = true`.

The objective used by the outer search is `J_true`, implemented as scheduled
sum rate: `sum log2(1 + SINR)` over scheduled streams. Engineering score,
fairness, active links, total power, and runtime are reported as diagnostics.

## Config Profiles

Defined in `matlab/core/cf_default_config.m`:

| Profile | TRP / DU | UE | RBG | Tx/TRP | Rx/UE | Use |
|---|---:|---:|---:|---:|---:|---|
| `quick` | 4 | 6 | 3 | 4 | 2 | Fast code sanity checks |
| `standard` | 8 | 16 | 4 | 8 | 2 | Small / medium algorithm checks |
| `paper` | 16 | 30 | 5 | 8 | 2 | Earlier paper-scale single-seed profile |
| `m3` | 7 | 100 | 100 | 12 | 2 | M3 C-RAN stress profile |
| `huawei` | 21 | 315 | 273 | 64 | 4 | Full Huawei-inspired acceptance scale |

The current controlled paper ablation defines S1-S4 inside
`experiments/paper_ablation/run_controlled_outer_ablation.m`:

| Scale | TRP / DU | UE |
|---|---:|---:|
| S1 | 4 | 8 |
| S2 | 8 | 16 |
| S3 | 12 | 24 |
| S4 | 16 | 32 |

Default controlled settings are 8 Tx/TRP, 2 Rx/UE, 4 RBGs, seeds `1:10`,
32 outer evaluations, population size 8, and 12 inner iterations.

## How To Run

From the repository root:

```matlab
run('setup_project_paths.m')
run('tests/run_smoke_tests.m')
```

Current paper ablation smoke:

```matlab
setenv('PAPER_ABLATION_RUN_ID','smoke_manual')
setenv('PAPER_ABLATION_SCALES','S1')
setenv('PAPER_ABLATION_SEEDS','1')
setenv('PAPER_ABLATION_MAX_EVAL','2')
setenv('PAPER_ABLATION_POPULATION','2')
setenv('PAPER_ABLATION_INNER_ITER','1')
setenv('PAPER_ABLATION_NUM_RBGS','2')
run('experiments/paper_ablation/run_controlled_outer_ablation.m')
```

Current first-stage paper run:

```matlab
run('experiments/paper_ablation/run_controlled_outer_ablation.m')
```

M3 testbed:

```matlab
run('experiments/m3_testbed/run_m3_full9_testbed.m')
```

Huawei stress workflow:

```matlab
run('experiments/huawei_robust/run_huawei_final_algorithm_comparison.m')
```

## Result Locations

- Current controlled ablation smoke:
  `results/paper_ablation/smoke_codex/`
- Earlier quick / standard / paper / M3 comparison:
  `results/M3_scale_comparison/`
- M3 full 9-D testbed:
  `results/m3_testbed/`
- M3 runtime probes:
  `results/m3_efficiency/`
- Huawei robust / edge-aware / full-lite / full probes:
  `results/huawei_robust/`

See `results/README.md` for the result trust labels. Most generated result
files are intentionally ignored by Git unless explicitly tracked from older
commits.

## Current Evidence Snapshot

- Outer-only ablation is implemented and smoke-tested.
- `GA-only`, `PSO-only`, and `PGSAO-only` now run without inner iterations.
- `GA+Inner`, `PSO+Inner`, and `PGSAO+Inner` already exist.
- The existing `smoke_codex` run only proves the wiring on a tiny S1 case.
- The formal S1-S4 x seeds `1:10` x 32-evaluation run is still not complete.
- Existing M3 results show `basic` can exceed inner/search in `J_true`, so
  M3 is currently evidence of stress behavior, not a clean paper win.
- Existing Huawei full-scale results are incomplete for the full algorithm
  matrix; Huawei remains an engineering stress-test track.

## Key Documentation

- `docs/CURRENT_RESEARCH_STATUS.md`: quickest way to recover the project.
- `docs/EXPERIMENT_INDEX.md`: experiment entry points and status labels.
- `docs/RESEARCH_ASSET_INVENTORY.md`: file and result inventory.
- `docs/REPOSITORY_REORGANIZATION_PLAN.md`: safe reorganization plan.
- `docs/目标函数与评价指标说明.md`: objective and metric discussion.
