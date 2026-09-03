# Agent Progress And Paper Plan

Snapshot date: 2026-09-03.

This note records the current research progress, the intended small-paper
storyline, the implemented code paths, and the next experiments an agent
should run or implement. It is written for future agents resuming this project.

## 1. Current Research Direction

The current first-stage paper should not claim full Huawei challenge
acceptance yet. The better near-term direction is:

```text
Use controlled Massive MIMO / Multi-TRP scales to prove that a two-layer
optimization framework plus a chosen hybrid outer-search algorithm improves
Multi-TRP scheduling, reduces search cost through sensitivity-based dimension
reduction, and can reduce normalized transmit power while satisfying an
experience-loss constraint.
```

Huawei challenge material should be used as the engineering motivation and
future validation target. Full Huawei-scale validation and detailed nonideal
SRS handling can be kept for a later extended paper.

## 2. One-Sentence Paper Argument

In large-scale Multi-TRP cooperative scheduling, direct optimization over
`b/p/r/W` is difficult; this project tests whether an inner beam/power/link
optimization loop combined with a hybrid outer search over a compact scheduling
parameter vector can improve the true scheduling objective, reduce search
dimension, and lower transmit-power cost under controlled experience-loss
constraints.

## 3. Canonical Terms

| Term | Meaning |
|---|---|
| `J_true` | Main max objective, recomputed from final `b` and `SLINR` |
| `Objective` | Current candidate objective used by outer search; currently `SumRate` |
| `Score` | Weighted engineering score for diagnostics and tie-breaking |
| `SumRate` | Total scheduled sum rate, currently aligned with `Objective` |
| `ExperienceRate` | 3GPP-style throughput proxy based on `ThpVolDl / ThpTimeDl` |
| `EdgeExperienceRate5` | Bottom-5% user experience-rate point |
| `Rate5` / `Rate10` | Bottom-5% / bottom-10% ordinary user-rate proxies |
| `TotalPower` | Normalized total transmit power, `sum(p(:))` |
| `ActiveLinks` | Number of active TRP-UE-RBG links |
| `Inner-only` | Default candidate with inner optimization enabled |
| `Outer-only` | GA/PSO/PGSAO search with inner optimization disabled |
| `Outer+Inner` | Outer search where each candidate runs inner optimization |
| `PGSAO` | Current hybrid outer-search candidate |

## 4. Current Implemented Code Map

Core MATLAB code:

| File | Role |
|---|---|
| `matlab/core/cf_default_config.m` | System profiles, search ranges, score weights |
| `matlab/core/cf_generate_scenario.m` | DU/UE geometry, channels, edge metadata, Huawei-style channel metadata |
| `matlab/core/cf_decode_candidate.m` | Maps normalized 9-D outer vector to scheduling parameters |
| `matlab/core/cf_evaluate_candidate.m` | Builds `b/p/r/W`, runs optional inner loop, computes all metrics |
| `matlab/core/cf_search.m` | GA, PSO, GA+PSO, PSO+GA, PGSAO outer search |
| `matlab/core/cf_compute_true_objective.m` | Recomputes `J_true` from final schedule and SINR |
| `matlab/core/cf_compute_experience_rate.m` | 3GPP-style experience-rate proxy |
| `matlab/core/cf_apply_srs_measurement_model.m` | Initial nonideal SRS channel-estimation model |
| `matlab/core/cf_classify_edge_users.m` | Edge-user classification for M3/Huawei-style scenarios |
| `matlab/core/cf_generate_burst_traffic.m` | Burst traffic trace generation |

Experiment entrypoints:

| File | Current use |
|---|---|
| `experiments/paper_ablation/run_controlled_outer_ablation.m` | Main small-paper controlled ablation |
| `experiments/local_sensitivity/*.m` | Existing local sensitivity workflow |
| `experiments/m3_scale_comparison/run_m3_local_sensitivity.m` | M3 sensitivity run |
| `experiments/m3_scale_comparison/run_m3_reduced_algorithm_comparison.m` | Reduced-dimension search comparison |
| `experiments/m3_testbed/run_m3_full9_testbed.m` | M3 stress-scale algorithm comparison |
| `experiments/m3_efficiency/run_m3_efficiency_benchmark.m` | Runtime / complexity probes |
| `experiments/huawei_robust/*.m` | Huawei-inspired stress and SRS robustness workflows |

Documentation to read before editing:

| File | Why it matters |
|---|---|
| `AGENTS.md` | Agent entrypoint and warnings |
| `README.md` | Project overview and run commands |
| `docs/CURRENT_RESEARCH_STATUS.md` | What is proven and not proven |
| `docs/RESEARCH_ASSET_INVENTORY.md` | Full code/result inventory |
| `docs/EXPERIMENT_INDEX.md` | Experiment matrix and output locations |
| `docs/目标函数与评价指标说明.md` | Objective and metric definitions |
| `docs/代码递进说明.md` | Algorithm progression from basic to PGSAO |
| `docs/HUAWEI_VALIDATION_SCENE.md` | Huawei-inspired scenario scope and limitations |

## 5. What Is Already Implemented

- Main objective bookkeeping:
  - `result.Objective = proposed.SumRate`.
  - `J_true` is recomputed as scheduled `sum log2(1+SLINR)`.
  - `Score` is separated from the main objective.
- Basic, inner-only, outer-only, and outer+inner flows:
  - `basic`: `cf_evaluate_candidate(..., false)` on the default candidate.
  - `inner`: `cf_evaluate_candidate(..., true)` on the default candidate.
  - `GA-only`, `PSO-only`, `PGSAO-only`: outer search with inner disabled.
  - `GA+Inner`, `PSO+Inner`, `PGSAO+Inner`: outer search with inner enabled.
- The 9-D outer search space:
  - `betaPF`, `numConnections`, `scheduleThreshold`, `rhoLink`,
    `rhoPower`, `maxRank`, `rankThreshold`, `repairPower`,
    `maxRepairLinks`.
- Normalized transmit-power accounting:
  - `p(r,u,g)=sum_s ||W(:,s,r,u,g)||^2`.
  - `TotalPower=sum(p(:))`.
  - Per-DU/RBG normalization enforces `cfg.maxDUPower`.
- Experience diagnostics:
  - `MeanExperienceRate`.
  - `EdgeExperienceRate5`.
  - `Rate5` and `Rate10` as ordinary edge-rate proxies.
- SRS and robust diagnostics:
  - `H_true`, `H_est`, error variance, measured-mask metadata.
  - `TrueChannel` metrics recomputed on validation channel.

## 6. Important Current Limitations

- Current `basic` is not a strict no-cooperation independent-power-control
  baseline. It is a high-link Multi-TRP/MRT baseline with top-K TRP association
  and per-DU/RBG power normalization.
- Energy reduction is implemented as `TotalPower` reduction and score cost,
  not yet as a hard outer-search constraint.
- The Huawei acceptance scene is not fully validated. Huawei runs should be
  treated as stress tests, not paper-level proof.
- Existing smoke runs prove wiring, not final algorithm superiority.
- Existing M3/Huawei results are mostly single-seed or low-budget stress
  evidence.
- `rhoLink` and `rhoPower` are part of the candidate vector, but agents should
  verify whether they are actively used in the current inner update before
  making claims about their effect.

## 7. Proposed Small-Paper Experiment Plan

### Experiment A: Two-Layer Ablation

Goal: prove the contribution of inner optimization, outer search, and their
combination under matched budgets.

Compare:

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

Primary metrics:

```text
J_true / Objective
SumRate
Rate5 / Rate10
Jain
TotalPower
ActiveLinks
RuntimeSeconds
RuntimePerEvaluation
```

Main entrypoint:

```text
experiments/paper_ablation/run_controlled_outer_ablation.m
```

### Experiment B: Multi-Seed Stability

Goal: show that the chosen method is stable rather than seed-lucky.

Recommended setup:

```text
scales: S1-S4
seeds: 1:10 or higher if runtime permits
outer evaluations: fixed across methods
inner iterations: fixed across methods
population size: fixed across methods
```

Report:

```text
mean
standard deviation
confidence interval
win rate
convergence curves
runtime distribution
```

### Experiment C: Sensitivity-Based Dimension Reduction

Goal: use existing sensitivity tests to identify key outer parameters and
reduce outer-search cost.

Workflow:

```text
1. Run or reuse local sensitivity ranking.
2. Select top-K sensitive outer-search dimensions.
3. Run full 9-D search and reduced-K-D search under matched seeds/budgets.
4. Compare performance loss and runtime reduction.
```

Claims to support:

```text
Reduced search lowers cost.
Reduced search keeps J_true close to full search.
Reduced search does not badly degrade edge metrics or power metrics.
```

### Experiment D: Energy-Constrained Scheduling

Goal: connect the work to the Huawei challenge energy requirement without
claiming full Huawei acceptance.

Recommended definitions:

```text
PowerReductionPct =
    100 * (Power_baseline - Power_method) / Power_baseline

ExperienceLossPct =
    100 * (Experience_baseline - Experience_method) / Experience_baseline

EnergyEfficiency =
    J_true / TotalPower
```

Recommended target:

```text
PowerReductionPct >= 30%
ExperienceLossPct <= 10%
```

The baseline must be defined carefully. Current `basic` is not enough for a
strict no-cooperation baseline. Add or explicitly name at least:

```text
No-CoMP baseline: one serving TRP per UE/RBG, no joint transmission.
Raw Multi-TRP baseline: current top-K MRT baseline.
Proposed: chosen hybrid outer search + inner optimization, optionally reduced.
```

### Experiment E: TRP Scalability

Goal: prove the method scales with the number of TRPs before moving to full
Huawei scale.

Recommended scales:

```text
4 TRP
8 TRP
12 TRP
16 TRP
21 TRP if runtime permits
```

Report:

```text
J_true vs TRP count
TotalPower vs TRP count
ActiveLinks vs TRP count
RuntimePerEvaluation vs TRP count
PowerReductionPct vs TRP count
```

### Experiment F: Optional SRS Robustness Extension

Goal: keep a bridge to Huawei challenge 2 without making it the main paper
claim.

Use:

```text
ideal SRS
nonideal SRS
robust update
nonrobust update
```

Report:

```text
TrueChannel.SumRate
TrueChannel.ExperienceRate.EdgeExperienceRate5
TrueChannel.Jain
TotalPower
```

This can be a secondary experiment or discussion section, not the central
proof of the small paper.

## 8. Suggested Paper Contribution Statements

Use bounded claims until formal multi-seed evidence is available:

1. A two-layer optimization framework for Multi-TRP scheduling that separates
   inner beam/power/link updates from outer strategy-parameter search.
2. A controlled comparison of GA, PSO, and a selected hybrid outer-search
   strategy under matched evaluation budgets.
3. A sensitivity-guided dimension-reduction workflow that reduces search
   cost while preserving most of the scheduling performance.
4. An energy-aware evaluation protocol that measures normalized transmit-power
   reduction under an explicit experience-loss constraint.
5. A TRP scalability study that prepares the method for later Huawei-scale
   validation.

## 9. Recommended Next Implementation Tasks

1. Add a strict no-cooperation baseline:
   - one serving TRP per UE/RBG;
   - no joint transmission;
   - clear independent-power-control or fixed-power policy.
2. Add energy-constrained summary metrics to experiment outputs:
   - `PowerReductionPct`;
   - `ExperienceLossPct`;
   - `EnergyEfficiency`;
   - pass/fail for `PowerReductionPct >= 30%` and `ExperienceLossPct <= 10%`.
3. Run formal `paper_ablation`:
   - S1-S4;
   - seeds `1:10`;
   - matched evaluation budget.
4. Convert sensitivity ranking into a fixed reduced-search setting.
5. Run full 9-D vs reduced-D comparisons.
6. Add TRP scalability figures and tables.
7. Keep SRS experiments optional until the main story is stable.

## 10. Recommended Agent Reading Order

```text
AGENTS.md
README.md
docs/AGENT_PROGRESS_AND_PAPER_PLAN.md
docs/CURRENT_RESEARCH_STATUS.md
docs/RESEARCH_ASSET_INVENTORY.md
docs/EXPERIMENT_INDEX.md
docs/目标函数与评价指标说明.md
docs/代码递进说明.md
```

## 11. Claim Boundaries

Safe to claim after current code review:

```text
The framework can run basic, inner-only, outer-only, and outer+inner
comparisons under a shared objective and matched search budget.
```

Safe to claim only after formal runs:

```text
The chosen hybrid outer search is consistently better than GA/PSO.
Dimension reduction reduces cost without substantial performance loss.
The method meets the 30% power-reduction and 10% experience-loss targets.
```

Not safe to claim yet:

```text
Full Huawei acceptance has been achieved.
Challenge 2 is fully solved.
Current basic is a no-cooperation independent-power-control baseline.
The method has proven linear complexity at Huawei scale.
```
