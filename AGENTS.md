# Agent Project Guide

This repository is a MATLAB research prototype for Cell-Free / Multi-TRP
cooperative scheduling. Read this file first when resuming work as an agent.

## Read First

1. `README.md`
   - Project overview, current directory map, core algorithms, run commands.
2. `docs/CURRENT_RESEARCH_STATUS.md`
   - Current research claim, what is proven, what is not proven.
3. `docs/RESEARCH_ASSET_INVENTORY.md`
   - Full code/result/document inventory and trust labels.
4. `docs/EXPERIMENT_INDEX.md`
   - Experiment entrypoints, scales, seeds, budgets, and output directories.
5. `docs/AGENT_PROGRESS_AND_PAPER_PLAN.md`
   - Current small-paper storyline, implemented progress, and next experiments.
6. `docs/目标函数与评价指标说明.md`
   - Objective/score/metric definitions. Essential for avoiding confusion.

## Core Code

The core implementation is in `matlab/core/`.

| File | Purpose |
|---|---|
| `cf_default_config.m` | Profiles, system scale, search ranges, score weights |
| `cf_generate_scenario.m` | DU/UE topology, channel, Huawei true/estimated channel metadata |
| `cf_decode_candidate.m` | Maps normalized 9-D search vector into scheduling parameters |
| `cf_evaluate_candidate.m` | Builds `b/p/r/W`, runs optional inner loop, computes metrics |
| `cf_search.m` | GA, PSO, GA+PSO, PSO+GA, PGSAO outer search |
| `cf_compute_true_objective.m` | Recomputes `J_true` from final `b` and `SLINR` |
| `cf_compute_experience_rate.m` | 3GPP-style experience-rate proxy |
| `cf_apply_srs_measurement_model.m` | Huawei-style nonideal SRS channel estimate model |

## Current Objective

The active outer-search objective is:

```text
J_true = scheduled sum log2(1 + SINR)
```

In code, `result.Objective = proposed.SumRate`, and `J_true` is recomputed
from `result.b` and `result.SLINR` as a validation value.

`result.Score` is an engineering evaluation score for fairness, power, link
cost, and weak-user tradeoffs. It is not the primary objective unless code is
changed explicitly.

## Huawei Challenge Mapping

| Huawei item | Current status |
|---|---|
| Max objective over `b/p/r/W` | Implemented as `J_true` / scheduled sum rate |
| Power reduction | Implemented as `TotalPower=sum(p(:))` diagnostic and score cost |
| Edge experience | Implemented through `Rate5`, `Rate10`, `EdgeExperienceRate5` |
| Average experience loss | Partially implemented through `MeanExperienceRate`; formal validation incomplete |
| SRS nonideal measurement | Initial model implemented via `H_est`, `H_true`, Presinr, error variance |
| Robust true-channel evaluation | Implemented in `result.TrueChannel` |
| Distributed parallel architecture | Not actually deployed; only algorithmic/search prototype |
| Full Huawei-scale proof | Not complete; Huawei runs are stress tests for now |

## Important Baseline Warning

Current `basic` is not a strict "no inter-cell cooperation + independent power
control" baseline. It is a raw Multi-TRP/MRT baseline:

```text
top-K TRP association + MRT beamforming + per-DU/RBG power normalization
```

Use it as a high-link/high-power baseline unless a new no-cooperation baseline
is implemented.

## Main Experiment Track

The current formal paper track is:

```text
experiments/paper_ablation/run_controlled_outer_ablation.m
```

It compares:

```text
basic
inner
GA-only
PSO-only
PGSAO-only
GA+Inner
PSO+Inner
PGSAO+Inner
```

Expected formal outputs go to `results/paper_ablation/<run_id>/`.
Check `results/README.md` before treating any result as paper-quality evidence.

## Quick Sanity Commands

From MATLAB at the repository root:

```matlab
run('setup_project_paths.m')
run('tests/run_smoke_tests.m')
```

For a tiny ablation smoke run, use the environment-variable recipe in
`README.md`.

## Do Not Assume

- Do not claim Huawei full-scale acceptance is proven.
- Do not treat `SumRate` as Huawei user-experience KPI.
- Do not treat current `basic` as no-cooperation independent-power baseline.
- Do not delete or move `results/` or `paper_edit/` assets without confirming
  the generating script and manuscript references.
