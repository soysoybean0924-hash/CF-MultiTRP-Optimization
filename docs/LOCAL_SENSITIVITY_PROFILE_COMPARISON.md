# Local Sensitivity Profile Comparison

This note compares the nine-parameter one-at-a-time local sensitivity
experiment across the `quick`, `standard`, and `paper` profiles.

Experiment settings:

| Profile | DUs | UEs | RBGs | Tx antennas | Inner max iter | Seeds |
|---|---:|---:|---:|---:|---:|---|
| `quick` | 4 | 6 | 3 | 4 | 12 | `1:5` |
| `standard` | 8 | 16 | 4 | 8 | 25 | `1:5` |
| `paper` | 16 | 30 | 5 | 8 | 35 | `1:5` |

Result files are generated under `results/local_sensitivity_profiles/`.
That directory is intentionally ignored by Git.

The cross-profile summary heatmap is generated as
`results/local_sensitivity_profiles/fig08_profile_true_sensitivity_heatmap.png`.

## Objective Definitions

| Objective | Meaning |
|---|---|
| `J_inner` | Final recorded inner WPS/sparse-beam objective. |
| `J_outer` | Existing outer-search fitness, `result.Score`. |
| `J_true` | True scheduled utility recomputed from `b` and `SLINR`: `sum log2(1+SINR)` over scheduled links. |

Ranks are based on absolute normalized local sensitivity. The sign of
`S_*_norm` shows whether increasing the parameter locally increases or
decreases that objective.

## Quick

Top sensitivities:

| Objective | Rank 1 | Rank 2 | Rank 3 |
|---|---|---|---|
| `J_inner` | `betaPF` (-4.114) | `numTransmitAntennas` (-2.510) | `rhoFronthaul` (-1.266) |
| `J_outer` | `numUEConnections` (-36.850) | `rhoFronthaul` (-19.937) | `betaPF` (-19.140) |
| `J_true` | `numUEConnections` (-1.370) | `numTransmitAntennas` (1.246) | `betaPF` (-0.582) |

Full ranking:

| Parameter | Inner rank | Outer rank | True rank | Composite rank | `S_true_norm` | Class |
|---|---:|---:|---:|---:|---:|---|
| `numUEConnections` | 4 | 1 | 1 | 1 | -1.370 | High |
| `betaPF` | 1 | 3 | 3 | 2 | -0.582 | Medium |
| `numTransmitAntennas` | 2 | 5 | 2 | 3 | 1.246 | High |
| `rhoFronthaul` | 3 | 2 | 5 | 4 | -0.248 | Low |
| `rankThreshold` | 5 | 4 | 4 | 5 | -0.287 | Medium |
| `repairWeight` | 9 | 6 | 6 | 6 | -0.183 | Low |
| `scheduleThreshold` | 7 | 8 | 7 | 7 | -0.121 | Low |
| `rhoPower` | 6 | 9 | 8 | 8 | 0.009 | Low |
| `duHeight` | 8 | 7 | 9 | 9 | -0.004 | Low |

## Standard

Top sensitivities:

| Objective | Rank 1 | Rank 2 | Rank 3 |
|---|---|---|---|
| `J_inner` | `betaPF` (-4.470) | `numTransmitAntennas` (-0.952) | `rhoFronthaul` (-0.269) |
| `J_outer` | `numUEConnections` (-7.937) | `numTransmitAntennas` (-2.054) | `rhoFronthaul` (-1.370) |
| `J_true` | `numUEConnections` (-1.967) | `numTransmitAntennas` (0.528) | `rhoFronthaul` (-0.472) |

Full ranking:

| Parameter | Inner rank | Outer rank | True rank | Composite rank | `S_true_norm` | Class |
|---|---:|---:|---:|---:|---:|---|
| `numUEConnections` | 4 | 1 | 1 | 1 | -1.967 | High |
| `betaPF` | 1 | 4 | 4 | 2 | -0.313 | Medium |
| `numTransmitAntennas` | 2 | 2 | 2 | 3 | 0.528 | High |
| `rhoFronthaul` | 3 | 3 | 3 | 4 | -0.472 | Medium |
| `duHeight` | 8 | 5 | 5 | 5 | -0.308 | Low |
| `rankThreshold` | 7 | 6 | 7 | 6 | 0.037 | Low |
| `rhoPower` | 6 | 7 | 8 | 7 | 0.018 | Low |
| `repairWeight` | 9 | 8 | 6 | 8 | -0.048 | Low |
| `scheduleThreshold` | 5 | 9 | 9 | 9 | 0.011 | Low |

## Paper

Top sensitivities:

| Objective | Rank 1 | Rank 2 | Rank 3 |
|---|---|---|---|
| `J_inner` | `betaPF` (-4.192) | `rhoFronthaul` (-0.577) | `numUEConnections` (0.346) |
| `J_outer` | `numUEConnections` (-10.442) | `numTransmitAntennas` (-1.683) | `betaPF` (1.379) |
| `J_true` | `numUEConnections` (-2.081) | `rhoFronthaul` (-0.669) | `numTransmitAntennas` (0.494) |

Full ranking:

| Parameter | Inner rank | Outer rank | True rank | Composite rank | `S_true_norm` | Class |
|---|---:|---:|---:|---:|---:|---|
| `numUEConnections` | 3 | 1 | 1 | 1 | -2.081 | High |
| `betaPF` | 1 | 3 | 5 | 2 | -0.444 | Low |
| `rhoFronthaul` | 2 | 8 | 2 | 3 | -0.669 | High |
| `numTransmitAntennas` | 4 | 2 | 3 | 4 | 0.494 | Medium |
| `duHeight` | 6 | 5 | 4 | 5 | -0.481 | Medium |
| `rankThreshold` | 8 | 4 | 8 | 6 | 0.018 | Low |
| `rhoPower` | 5 | 6 | 7 | 7 | 0.023 | Low |
| `repairWeight` | 9 | 7 | 6 | 8 | -0.049 | Low |
| `scheduleThreshold` | 7 | 9 | 9 | 9 | 0.009 | Low |

## Cross-Profile Observations

1. `numUEConnections` is the most robust dominant parameter. It ranks first
   for `J_true` and composite sensitivity in all three profiles.
2. `numTransmitAntennas` is consistently important for `J_true`, ranking
   second in `quick` and `standard`, and third in `paper`.
3. `rhoFronthaul` becomes more important as the scale grows. It is only
   fifth for `J_true` in `quick`, third in `standard`, and second in `paper`.
4. `betaPF` dominates `J_inner` in all three profiles, but its true-objective
   rank drops from third in `quick` to fifth in `paper`; it shapes the inner
   loop more strongly than the final scheduled utility at larger scale.
5. `scheduleThreshold`, `rhoPower`, and `repairWeight` remain low-sensitivity
   for `J_true` in the larger profiles.
6. `duHeight` is nearly irrelevant in `quick`, but rises to fourth for
   `J_true` in `paper`; geometry-dependent effects are more visible at the
   larger network size.

## Practical Takeaway

For subsequent outer-search design, keep `numUEConnections`,
`numTransmitAntennas`, and `rhoFronthaul` as priority search dimensions.
Keep `betaPF` because it strongly controls the inner WPS behavior, but do not
assume it is always a top true-utility driver at paper scale. Consider
narrowing or fixing `scheduleThreshold`, `rhoPower`, and `repairWeight` unless
later wider-sample tests show stronger effects.
