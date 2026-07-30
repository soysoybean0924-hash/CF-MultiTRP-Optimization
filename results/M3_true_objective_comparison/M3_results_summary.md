# M3 Results Summary

Generated at: 2026-07-31 03:16:08

M3 scale: 7 DUs, 100 UEs, 100 RBGs, 2x12 MIMO.

Optimization objective: maximize J_true = scheduled sum log2(1+SINR), matching the max objective in the reference figure.
Jain, ActiveLinks, TotalPower, and runtime are reported only as evaluation metrics.

## Full 9-D M3 Algorithm Comparison

| Method | Eval | InnerIter | Objective | J_true | SumRate | Jain | ActiveLinks | RuntimeSeconds |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| basic | 1 | 2 | 7308.6 | 7308.6 | 7308.6 | 0.6805 | 20000 | 7.344 |
| inner | 1 | 2 | 3394.26 | 3394.26 | 3394.26 | 0.0930 | 1545 | 246.727 |
| GA | 8 | 2 | 2799.17 | 2799.17 | 2799.17 | 0.3249 | 1214 | 1836.438 |
| PSO | 8 | 2 | 2799.17 | 2799.17 | 2799.17 | 0.3249 | 1214 | 1689.217 |
| GA+PSO | 8 | 2 | 2799.17 | 2799.17 | 2799.17 | 0.3249 | 1214 | 1710.509 |
| PSO+GA | 8 | 2 | 2799.17 | 2799.17 | 2799.17 | 0.3249 | 1214 | 1480.936 |
| PGSAO | 8 | 2 | 2799.17 | 2799.17 | 2799.17 | 0.3249 | 1214 | 1484.797 |

## Local Sensitivity Ranking

| Rank | Parameter | Actual field | S_inner_norm | S_outer_norm | S_true_norm |
|---:|---|---|---:|---:|---:|
| 1 | numUEConnections | candidate.numConnections | -3.96469 | -2.80401 | -2.80401 |
| 2 | betaPF | candidate.betaPF | -2.06889 | -2.39204 | -2.39204 |
| 3 | numTransmitAntennas | cfg.numTxAntennas | 0.941472 | 1.26102 | 1.26102 |
| 4 | scheduleThreshold | candidate.scheduleThreshold | 1.65725 | -0.37369 | -0.37369 |
| 5 | duHeight | cfg.duHeight | 0.991577 | 0.0528929 | 0.0528929 |
| 6 | repairWeight | candidate.repairPower | 0 | -0.0109635 | -0.0109635 |
| 7 | rankThreshold | candidate.rankThreshold | -0.000168814 | -0.000195263 | -0.000195263 |
| 8 | rhoFronthaul | candidate.rhoLink | 0 | 0 | 0 |
| 9 | rhoPower | candidate.rhoPower | 0 | 0 | 0 |

Most sensitive parameters by ranking recommendation: betaPF, numUEConnections.

## Reduced 3-D M3 Algorithm Comparison

| Method | Eval | InnerIter | Objective | J_true | SumRate | Jain | ActiveLinks | RuntimeSeconds |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| basic | 1 | 2 | 7308.6 | 7308.6 | 7308.6 | 0.6805 | 20000 | 4.846 |
| inner | 1 | 2 | 3394.26 | 3394.26 | 3394.26 | 0.0930 | 1545 | 213.667 |
| GA | 8 | 2 | 2984.58 | 2984.58 | 2984.58 | 0.2365 | 2726 | 1688.619 |
| PSO | 8 | 2 | 2984.58 | 2984.58 | 2984.58 | 0.2365 | 2726 | 1708.898 |
| GA+PSO | 8 | 2 | 2984.58 | 2984.58 | 2984.58 | 0.2365 | 2726 | 1698.756 |
| PSO+GA | 8 | 2 | 2984.58 | 2984.58 | 2984.58 | 0.2365 | 2726 | 1660.156 |
| PGSAO | 8 | 2 | 2984.58 | 2984.58 | 2984.58 | 0.2365 | 2726 | 1664.128 |

## Figures

- figures/fig_m3_full9_algorithm_comparison.png
- figures/fig_m3_parameter_sensitivity_all.png
- figures/fig_m3_reduced3_algorithm_comparison.png
