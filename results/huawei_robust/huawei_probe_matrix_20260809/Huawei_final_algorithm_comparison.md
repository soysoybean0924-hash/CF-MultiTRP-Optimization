# Huawei Final Algorithm Comparison

Created: 2026-08-09 19:30:44

Scale: `probe`.

Objective: scheduler optimizes H_est; acceptance metrics use H_true when available.

| Edge | Robust | Method | EstObj | Score | TrueObj | TrueMeanExp | TrueEdgeP5 | Power | Links | Runtime | MeanLoss% | PowerDrop% |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| edge_aware | nonrobust | basic | 394.818 | 910.185 | 384.909 | 0 | 0 | 83 | 168 | 0.601 | 0.000 | -11.561 |
| edge_aware | nonrobust | inner | 341.081 | 115.336 | 326.292 | 0 | 0 | 74.3989 | 134 | 4.556 | 0.000 | 0.000 |
| edge_aware | nonrobust | GA | 290.861 | 256.006 | 281.03 | 0 | 0 | 51.7711 | 128 | 8.945 | 0.000 | 30.414 |
| edge_aware | nonrobust | PSO | 290.861 | 256.006 | 281.03 | 0 | 0 | 51.7711 | 128 | 6.801 | 0.000 | 30.414 |
| edge_aware | nonrobust | GA+PSO | 290.861 | 256.006 | 281.03 | 0 | 0 | 51.7711 | 128 | 6.854 | 0.000 | 30.414 |
| edge_aware | nonrobust | PSO+GA | 290.861 | 256.006 | 281.03 | 0 | 0 | 51.7711 | 128 | 6.952 | 0.000 | 30.414 |
| edge_aware | nonrobust | PGSAO | 290.861 | 256.006 | 281.03 | 0 | 0 | 51.7711 | 128 | 7.141 | 0.000 | 30.414 |
| edge_aware | robust | basic | 394.818 | 910.185 | 384.909 | 0 | 0 | 83 | 168 | 0.139 | 0.000 | -13.882 |
| edge_aware | robust | inner | 343.875 | 85.5534 | 332.121 | 0 | 0 | 72.8827 | 136 | 3.762 | 0.000 | 0.000 |
| edge_aware | robust | GA | 296.9 | -198.12 | 290.856 | 0 | 0 | 66.4334 | 138 | 7.437 | 0.000 | 8.849 |
| edge_aware | robust | PSO | 296.9 | -198.12 | 290.856 | 0 | 0 | 66.4334 | 138 | 7.500 | 0.000 | 8.849 |
| edge_aware | robust | GA+PSO | 296.9 | -198.12 | 290.856 | 0 | 0 | 66.4334 | 138 | 8.601 | 0.000 | 8.849 |
| edge_aware | robust | PSO+GA | 296.9 | -198.12 | 290.856 | 0 | 0 | 66.4334 | 138 | 7.675 | 0.000 | 8.849 |
| edge_aware | robust | PGSAO | 296.9 | -198.12 | 290.856 | 0 | 0 | 66.4334 | 138 | 7.349 | 0.000 | 8.849 |
| non_edge_aware | nonrobust | basic | 394.818 | 910.185 | 384.909 | 0 | 0 | 83 | 168 | 0.096 | 0.000 | -11.561 |
| non_edge_aware | nonrobust | inner | 341.081 | 115.336 | 326.292 | 0 | 0 | 74.3989 | 134 | 3.317 | 0.000 | 0.000 |
| non_edge_aware | nonrobust | GA | 290.861 | 256.006 | 281.03 | 0 | 0 | 51.7711 | 128 | 6.708 | 0.000 | 30.414 |
| non_edge_aware | nonrobust | PSO | 290.861 | 256.006 | 281.03 | 0 | 0 | 51.7711 | 128 | 6.898 | 0.000 | 30.414 |
| non_edge_aware | nonrobust | GA+PSO | 290.861 | 256.006 | 281.03 | 0 | 0 | 51.7711 | 128 | 6.870 | 0.000 | 30.414 |
| non_edge_aware | nonrobust | PSO+GA | 290.861 | 256.006 | 281.03 | 0 | 0 | 51.7711 | 128 | 6.745 | 0.000 | 30.414 |
| non_edge_aware | nonrobust | PGSAO | 290.861 | 256.006 | 281.03 | 0 | 0 | 51.7711 | 128 | 6.567 | 0.000 | 30.414 |
| non_edge_aware | robust | basic | 394.818 | 910.185 | 384.909 | 0 | 0 | 83 | 168 | 0.095 | 0.000 | -13.882 |
| non_edge_aware | robust | inner | 343.875 | 85.5534 | 332.121 | 0 | 0 | 72.8827 | 136 | 3.717 | 0.000 | 0.000 |
| non_edge_aware | robust | GA | 282.778 | -503.641 | 279.47 | 0 | 0 | 75.8638 | 125 | 7.592 | 0.000 | -4.090 |
| non_edge_aware | robust | PSO | 282.778 | -503.641 | 279.47 | 0 | 0 | 75.8638 | 125 | 7.415 | 0.000 | -4.090 |
| non_edge_aware | robust | GA+PSO | 282.778 | -503.641 | 279.47 | 0 | 0 | 75.8638 | 125 | 7.790 | 0.000 | -4.090 |
| non_edge_aware | robust | PSO+GA | 282.778 | -503.641 | 279.47 | 0 | 0 | 75.8638 | 125 | 8.098 | 0.000 | -4.090 |
| non_edge_aware | robust | PGSAO | 282.778 | -503.641 | 279.47 | 0 | 0 | 75.8638 | 125 | 7.520 | 0.000 | -4.090 |

## Acceptance Notes

- `TrueEdgeExperienceRate5` is the Bottom 5% UE experience-rate point on H_true.
- `MeanExperienceLossPct` and `PowerReductionPct` are relative to the matching edge/robust `inner` baseline when present.
- `huawei_final_complexity_trend.csv` records runtime-per-evaluation versus DU x UE x RBG x Tx scale.

## Complexity Summary

| Group | Points | MeanRuntimePerEval | LinearSlope | LinearR2 |
|---|---:|---:|---:|---:|
| edge_aware/nonrobust/basic | 1 | 0.600545 | NaN | NaN |
| edge_aware/nonrobust/inner | 1 | 4.55634 | NaN | NaN |
| edge_aware/nonrobust/GA | 1 | 4.47235 | NaN | NaN |
| edge_aware/nonrobust/PSO | 1 | 3.40035 | NaN | NaN |
| edge_aware/nonrobust/GA+PSO | 1 | 3.42708 | NaN | NaN |
| edge_aware/nonrobust/PSO+GA | 1 | 3.47591 | NaN | NaN |
| edge_aware/nonrobust/PGSAO | 1 | 3.57067 | NaN | NaN |
| edge_aware/robust/basic | 1 | 0.138664 | NaN | NaN |
| edge_aware/robust/inner | 1 | 3.7618 | NaN | NaN |
| edge_aware/robust/GA | 1 | 3.71862 | NaN | NaN |
| edge_aware/robust/PSO | 1 | 3.75018 | NaN | NaN |
| edge_aware/robust/GA+PSO | 1 | 4.30073 | NaN | NaN |
| edge_aware/robust/PSO+GA | 1 | 3.83772 | NaN | NaN |
| edge_aware/robust/PGSAO | 1 | 3.6745 | NaN | NaN |
| non_edge_aware/nonrobust/basic | 1 | 0.0964379 | NaN | NaN |
| non_edge_aware/nonrobust/inner | 1 | 3.31668 | NaN | NaN |
| non_edge_aware/nonrobust/GA | 1 | 3.35387 | NaN | NaN |
| non_edge_aware/nonrobust/PSO | 1 | 3.44894 | NaN | NaN |
| non_edge_aware/nonrobust/GA+PSO | 1 | 3.43489 | NaN | NaN |
| non_edge_aware/nonrobust/PSO+GA | 1 | 3.37274 | NaN | NaN |
| non_edge_aware/nonrobust/PGSAO | 1 | 3.28336 | NaN | NaN |
| non_edge_aware/robust/basic | 1 | 0.0951354 | NaN | NaN |
| non_edge_aware/robust/inner | 1 | 3.7175 | NaN | NaN |
| non_edge_aware/robust/GA | 1 | 3.79598 | NaN | NaN |
| non_edge_aware/robust/PSO | 1 | 3.70751 | NaN | NaN |
| non_edge_aware/robust/GA+PSO | 1 | 3.89491 | NaN | NaN |
| non_edge_aware/robust/PSO+GA | 1 | 4.04918 | NaN | NaN |
| non_edge_aware/robust/PGSAO | 1 | 3.75983 | NaN | NaN |
