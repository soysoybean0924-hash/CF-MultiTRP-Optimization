# M3 Results Summary

Generated at: 2026-07-30 17:05:46

M3 scale: 7 DUs, 100 UEs, 100 RBGs, 2x12 MIMO.

## Full 9-D M3 Algorithm Comparison

| Method | Eval | InnerIter | BestScore | J_true | SumRate | Jain | ActiveLinks | RuntimeSeconds |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| basic | 1 | 35 | 8332.19 | 7308.6 | 7308.6 | 0.6805 | 20000 | 3.936 |
| inner | 1 | 35 | -1310.76 | 2473.19 | 2473.19 | 0.1659 | 534 | 468.920 |
| GA | 8 | 2 | 466.815 | 2468.69 | 2468.69 | 0.3321 | 5567 | 1704.366 |
| PSO | 8 | 2 | 466.815 | 2468.69 | 2468.69 | 0.3321 | 5567 | 1532.116 |
| GA+PSO | 8 | 2 | 466.815 | 2468.69 | 2468.69 | 0.3321 | 5567 | 1509.229 |
| PSO+GA | 8 | 2 | 466.815 | 2468.69 | 2468.69 | 0.3321 | 5567 | 1528.099 |
| PGSAO | 8 | 2 | 466.815 | 2468.69 | 2468.69 | 0.3321 | 5567 | 1511.267 |

## Local Sensitivity Ranking

| Rank | Parameter | Actual field | S_inner_norm | S_outer_norm | S_true_norm |
|---:|---|---|---:|---:|---:|
| 1 | numUEConnections | candidate.numConnections | -4.61519 | -55.5746 | -2.81394 |
| 2 | betaPF | candidate.betaPF | -2.66602 | -27.7363 | -2.39543 |
| 3 | numTransmitAntennas | cfg.numTxAntennas | 0.569088 | 2.2977 | 1.26178 |
| 4 | scheduleThreshold | candidate.scheduleThreshold | 4.80769 | -1.5488 | -0.43302 |
| 5 | duHeight | cfg.duHeight | 1.35332 | -1.26973 | 0.0602494 |
| 6 | rhoFronthaul | candidate.rhoLink | -3.91573 | -0.471322 | -0.0476298 |
| 7 | rhoPower | candidate.rhoPower | -0.0147928 | -0.0560206 | -0.00486696 |
| 8 | repairWeight | candidate.repairPower | 0 | 2.17275 | -0.00172943 |
| 9 | rankThreshold | candidate.rankThreshold | -0.00033768 | -0.00715963 | -0.000172598 |

Most sensitive parameters by ranking recommendation: betaPF, numUEConnections.

## Reduced 3-D M3 Algorithm Comparison

| Method | Eval | InnerIter | BestScore | J_true | SumRate | Jain | ActiveLinks | RuntimeSeconds |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| basic | 1 | 2 | 8332.19 | 7308.6 | 7308.6 | 0.6805 | 20000 | 4.003 |
| inner | 1 | 2 | -213.293 | 3377.95 | 3377.95 | 0.0935 | 1534 | 220.198 |
| GA | 8 | 2 | 1126.57 | 2834.76 | 2834.76 | 0.2563 | 2718 | 1724.430 |
| PSO | 8 | 2 | 1126.57 | 2834.76 | 2834.76 | 0.2563 | 2718 | 1756.980 |
| GA+PSO | 8 | 2 | 1126.57 | 2834.76 | 2834.76 | 0.2563 | 2718 | 1620.575 |
| PSO+GA | 8 | 2 | 1126.57 | 2834.76 | 2834.76 | 0.2563 | 2718 | 1606.776 |
| PGSAO | 8 | 2 | 1126.57 | 2834.76 | 2834.76 | 0.2563 | 2718 | 1602.636 |

## Figures

- figures/fig_m3_full9_algorithm_comparison.png
- figures/fig_m3_parameter_sensitivity_all.png
- figures/fig_m3_reduced3_algorithm_comparison.png
