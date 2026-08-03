# Huawei Final Algorithm Comparison

Created: 2026-08-03 21:00:08

Scale: `final`.

Objective: scheduler optimizes H_est; acceptance metrics use H_true when available.

| Edge | Robust | Method | TrueObj | TrueMeanExp | TrueEdgeP5 | Power | Links | Runtime | MeanLoss% | PowerDrop% |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| edge_aware | nonrobust | basic | 9621.75 | 1.90241 | 1.30663 | 336 | 9776 | 7.341 | 45.068 | 0.000 |
| edge_aware | nonrobust | inner | 17499.5 | 3.46322 | 1.89781 | 336 | 9776 | 35.369 | 0.000 | 0.000 |
| edge_aware | soft | basic | 9621.75 | 1.90241 | 1.30663 | 336 | 9776 | 9.343 | 45.428 | 0.000 |
| edge_aware | soft | inner | 17612 | 3.48605 | 1.88153 | 336 | 9776 | 31.467 | 0.000 | 0.000 |
| edge_aware | robust | basic | 9621.75 | 1.90241 | 1.30663 | 336 | 9776 | 32.755 | 45.656 | 0.000 |
| edge_aware | robust | inner | 17682.8 | 3.50067 | 1.8833 | 336 | 9776 | 27.214 | 0.000 | 0.000 |
| edge_aware | aggressive | basic | 9621.75 | 1.90241 | 1.30663 | 336 | 9776 | 12.357 | 45.827 | 0.000 |
| edge_aware | aggressive | inner | 17735.5 | 3.51175 | 1.86246 | 336 | 9776 | 27.977 | 0.000 | 0.000 |
| non_edge_aware | nonrobust | basic | 9735.27 | 1.92745 | 1.39886 | 336 | 10080 | 11.833 | 45.863 | 0.000 |
| non_edge_aware | nonrobust | inner | 17980.6 | 3.56034 | 1.79482 | 336 | 10080 | 33.725 | 0.000 | 0.000 |
| non_edge_aware | soft | basic | 9735.27 | 1.92745 | 1.39886 | 336 | 10080 | 11.793 | 46.205 | 0.000 |
| non_edge_aware | soft | inner | 18093.7 | 3.58295 | 1.7806 | 336 | 10080 | 20.350 | 0.000 | 0.000 |
| non_edge_aware | robust | basic | 9735.27 | 1.92745 | 1.39886 | 336 | 10080 | 20.429 | 46.411 | 0.000 |
| non_edge_aware | robust | inner | 18161.8 | 3.59672 | 1.76665 | 336 | 10080 | 33.947 | 0.000 | 0.000 |
| non_edge_aware | aggressive | basic | 9735.27 | 1.92745 | 1.39886 | 336 | 10080 | 6.938 | 46.554 | 0.000 |
| non_edge_aware | aggressive | inner | 18208.3 | 3.60634 | 1.75924 | 336 | 10080 | 30.401 | 0.000 | 0.000 |

## Acceptance Notes

- `TrueEdgeExperienceRate5` is the Bottom 5% UE experience-rate point on H_true.
- `MeanExperienceLossPct` and `PowerReductionPct` are relative to the matching edge/robust `inner` baseline when present.
- `huawei_final_complexity_trend.csv` records runtime-per-evaluation versus DU x UE x RBG x Tx scale.

## Complexity Summary

| Group | Points | MeanRuntimePerEval | LinearSlope | LinearR2 |
|---|---:|---:|---:|---:|
| edge_aware/nonrobust/basic | 1 | 7.34133 | NaN | NaN |
| edge_aware/nonrobust/inner | 1 | 35.3691 | NaN | NaN |
| edge_aware/soft/basic | 1 | 9.34295 | NaN | NaN |
| edge_aware/soft/inner | 1 | 31.467 | NaN | NaN |
| edge_aware/robust/basic | 1 | 32.7554 | NaN | NaN |
| edge_aware/robust/inner | 1 | 27.2143 | NaN | NaN |
| edge_aware/aggressive/basic | 1 | 12.3567 | NaN | NaN |
| edge_aware/aggressive/inner | 1 | 27.9772 | NaN | NaN |
| non_edge_aware/nonrobust/basic | 1 | 11.8332 | NaN | NaN |
| non_edge_aware/nonrobust/inner | 1 | 33.7247 | NaN | NaN |
| non_edge_aware/soft/basic | 1 | 11.7925 | NaN | NaN |
| non_edge_aware/soft/inner | 1 | 20.3498 | NaN | NaN |
| non_edge_aware/robust/basic | 1 | 20.4294 | NaN | NaN |
| non_edge_aware/robust/inner | 1 | 33.9475 | NaN | NaN |
| non_edge_aware/aggressive/basic | 1 | 6.93814 | NaN | NaN |
| non_edge_aware/aggressive/inner | 1 | 30.4008 | NaN | NaN |
