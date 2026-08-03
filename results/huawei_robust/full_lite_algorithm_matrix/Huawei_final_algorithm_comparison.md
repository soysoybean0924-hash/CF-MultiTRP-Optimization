# Huawei Final Algorithm Comparison

Created: 2026-08-03 12:03:11

Scale: `full_lite`.

Objective: scheduler optimizes H_est; acceptance metrics use H_true when available.

| Edge | Robust | Method | TrueObj | TrueMeanExp | TrueEdgeP5 | Power | Links | Runtime | MeanLoss% | PowerDrop% |
|---|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| edge_aware | nonrobust | basic | 1812.5 | 2.39471 | 1.51734 | 252 | 1476 | 2.087 | 30.952 | -0.000 |
| edge_aware | nonrobust | inner | 2622.52 | 3.46819 | 1.13367 | 252 | 1476 | 2.882 | 0.000 | 0.000 |
| edge_aware | nonrobust | GA | 2842.66 | 3.60573 | 1.01789 | 252 | 2100 | 3.981 | -3.966 | -0.000 |
| edge_aware | nonrobust | PSO | 2842.66 | 3.60573 | 1.01789 | 252 | 2100 | 4.136 | -3.966 | -0.000 |
| edge_aware | nonrobust | GA+PSO | 2842.66 | 3.60573 | 1.01789 | 252 | 2100 | 3.704 | -3.966 | -0.000 |
| edge_aware | nonrobust | PSO+GA | 2842.66 | 3.60573 | 1.01789 | 252 | 2100 | 3.719 | -3.966 | -0.000 |
| edge_aware | nonrobust | PGSAO | 2842.66 | 3.60573 | 1.01789 | 252 | 2100 | 3.908 | -3.966 | -0.000 |
| edge_aware | soft | basic | 1812.5 | 2.39471 | 1.51734 | 252 | 1476 | 0.685 | 31.361 | -0.000 |
| edge_aware | soft | inner | 2639.29 | 3.48885 | 1.09011 | 252 | 1476 | 1.798 | 0.000 | 0.000 |
| edge_aware | soft | GA | 2859.82 | 3.62647 | 1.16225 | 252 | 2100 | 3.318 | -3.944 | 0.000 |
| edge_aware | soft | PSO | 2859.82 | 3.62647 | 1.16225 | 252 | 2100 | 3.480 | -3.944 | 0.000 |
| edge_aware | soft | GA+PSO | 2859.82 | 3.62647 | 1.16225 | 252 | 2100 | 3.642 | -3.944 | 0.000 |
| edge_aware | soft | PSO+GA | 2859.82 | 3.62647 | 1.16225 | 252 | 2100 | 3.210 | -3.944 | 0.000 |
| edge_aware | soft | PGSAO | 2859.82 | 3.62647 | 1.16225 | 252 | 2100 | 3.534 | -3.944 | 0.000 |
| edge_aware | robust | basic | 1812.5 | 2.39471 | 1.51734 | 252 | 1476 | 0.722 | 31.644 | -0.000 |
| edge_aware | robust | inner | 2650.19 | 3.50328 | 1.04604 | 252 | 1476 | 2.379 | 0.000 | 0.000 |
| edge_aware | robust | GA | 2871.29 | 3.64117 | 1.28588 | 252 | 2100 | 3.494 | -3.936 | 0.000 |
| edge_aware | robust | PSO | 2871.29 | 3.64117 | 1.28588 | 252 | 2100 | 3.523 | -3.936 | 0.000 |
| edge_aware | robust | GA+PSO | 2871.29 | 3.64117 | 1.28588 | 252 | 2100 | 3.238 | -3.936 | 0.000 |
| edge_aware | robust | PSO+GA | 2871.29 | 3.64117 | 1.28588 | 252 | 2100 | 3.679 | -3.936 | 0.000 |
| edge_aware | robust | PGSAO | 2871.29 | 3.64117 | 1.28588 | 252 | 2100 | 3.219 | -3.936 | 0.000 |
| edge_aware | aggressive | basic | 1812.5 | 2.39471 | 1.51734 | 252 | 1476 | 0.692 | 31.858 | -0.000 |
| edge_aware | aggressive | inner | 2656.86 | 3.51428 | 0.996427 | 252 | 1476 | 1.695 | 0.000 | 0.000 |
| edge_aware | aggressive | GA | 2879.44 | 3.65341 | 1.35577 | 252 | 2100 | 3.197 | -3.959 | -0.000 |
| edge_aware | aggressive | PSO | 2879.44 | 3.65341 | 1.35577 | 252 | 2100 | 3.181 | -3.959 | -0.000 |
| edge_aware | aggressive | GA+PSO | 2879.44 | 3.65341 | 1.35577 | 252 | 2100 | 3.344 | -3.959 | -0.000 |
| edge_aware | aggressive | PSO+GA | 2879.44 | 3.65341 | 1.35577 | 252 | 2100 | 3.337 | -3.959 | -0.000 |
| edge_aware | aggressive | PGSAO | 2879.44 | 3.65341 | 1.35577 | 252 | 2100 | 3.301 | -3.959 | -0.000 |
| non_edge_aware | nonrobust | basic | 1839.26 | 2.44368 | 1.58659 | 252 | 1512 | 0.797 | 32.094 | -0.000 |
| non_edge_aware | nonrobust | inner | 2694.38 | 3.59861 | 1.0267 | 252 | 1512 | 1.501 | 0.000 | 0.000 |
| non_edge_aware | nonrobust | GA | 3048.83 | 4.00705 | 1.52583 | 252 | 2268 | 3.281 | -11.350 | 0.000 |
| non_edge_aware | nonrobust | PSO | 3048.83 | 4.00705 | 1.52583 | 252 | 2268 | 3.021 | -11.350 | 0.000 |
| non_edge_aware | nonrobust | GA+PSO | 3048.83 | 4.00705 | 1.52583 | 252 | 2268 | 3.074 | -11.350 | 0.000 |
| non_edge_aware | nonrobust | PSO+GA | 3048.83 | 4.00705 | 1.52583 | 252 | 2268 | 3.137 | -11.350 | 0.000 |
| non_edge_aware | nonrobust | PGSAO | 3048.83 | 4.00705 | 1.52583 | 252 | 2268 | 3.114 | -11.350 | 0.000 |
| non_edge_aware | soft | basic | 1839.26 | 2.44368 | 1.58659 | 252 | 1512 | 0.701 | 32.480 | -0.000 |
| non_edge_aware | soft | inner | 2711.51 | 3.61922 | 0.984402 | 252 | 1512 | 1.596 | 0.000 | 0.000 |
| non_edge_aware | soft | GA | 3065.97 | 4.02963 | 1.44426 | 252 | 2268 | 3.212 | -11.340 | -0.000 |
| non_edge_aware | soft | PSO | 3065.97 | 4.02963 | 1.44426 | 252 | 2268 | 3.234 | -11.340 | -0.000 |
| non_edge_aware | soft | GA+PSO | 3065.97 | 4.02963 | 1.44426 | 252 | 2268 | 3.377 | -11.340 | -0.000 |
| non_edge_aware | soft | PSO+GA | 3065.97 | 4.02963 | 1.44426 | 252 | 2268 | 3.328 | -11.340 | -0.000 |
| non_edge_aware | soft | PGSAO | 3065.97 | 4.02963 | 1.44426 | 252 | 2268 | 3.220 | -11.340 | -0.000 |
| non_edge_aware | robust | basic | 1839.26 | 2.44368 | 1.58659 | 252 | 1512 | 0.681 | 32.736 | -0.000 |
| non_edge_aware | robust | inner | 2722.3 | 3.63294 | 0.941047 | 252 | 1512 | 1.670 | 0.000 | 0.000 |
| non_edge_aware | robust | GA | 3076.2 | 4.04423 | 1.37184 | 252 | 2268 | 3.313 | -11.321 | -0.000 |
| non_edge_aware | robust | PSO | 3076.2 | 4.04423 | 1.37184 | 252 | 2268 | 3.198 | -11.321 | -0.000 |
| non_edge_aware | robust | GA+PSO | 3076.2 | 4.04423 | 1.37184 | 252 | 2268 | 3.207 | -11.321 | -0.000 |
| non_edge_aware | robust | PSO+GA | 3076.2 | 4.04423 | 1.37184 | 252 | 2268 | 3.394 | -11.321 | -0.000 |
| non_edge_aware | robust | PGSAO | 3076.2 | 4.04423 | 1.37184 | 252 | 2268 | 3.302 | -11.321 | -0.000 |
| non_edge_aware | aggressive | basic | 1839.26 | 2.44368 | 1.58659 | 252 | 1512 | 0.744 | 32.910 | -0.000 |
| non_edge_aware | aggressive | inner | 2728.17 | 3.64237 | 0.89075 | 252 | 1512 | 1.848 | 0.000 | 0.000 |
| non_edge_aware | aggressive | GA | 3081.22 | 4.05389 | 1.30965 | 252 | 2268 | 3.338 | -11.298 | 0.000 |
| non_edge_aware | aggressive | PSO | 3081.22 | 4.05389 | 1.30965 | 252 | 2268 | 3.181 | -11.298 | 0.000 |
| non_edge_aware | aggressive | GA+PSO | 3081.22 | 4.05389 | 1.30965 | 252 | 2268 | 3.231 | -11.298 | 0.000 |
| non_edge_aware | aggressive | PSO+GA | 3081.22 | 4.05389 | 1.30965 | 252 | 2268 | 3.352 | -11.298 | 0.000 |
| non_edge_aware | aggressive | PGSAO | 3081.22 | 4.05389 | 1.30965 | 252 | 2268 | 3.351 | -11.298 | 0.000 |

## Acceptance Notes

- `TrueEdgeExperienceRate5` is the Bottom 5% UE experience-rate point on H_true.
- `MeanExperienceLossPct` and `PowerReductionPct` are relative to the matching edge/robust `inner` baseline when present.
- `huawei_final_complexity_trend.csv` records runtime-per-evaluation versus DU x UE x RBG x Tx scale.

## Complexity Summary

| Group | Points | MeanRuntimePerEval | LinearSlope | LinearR2 |
|---|---:|---:|---:|---:|
| edge_aware/nonrobust/basic | 1 | 2.08697 | NaN | NaN |
| edge_aware/nonrobust/inner | 1 | 2.88214 | NaN | NaN |
| edge_aware/nonrobust/GA | 1 | 1.99072 | NaN | NaN |
| edge_aware/nonrobust/PSO | 1 | 2.0682 | NaN | NaN |
| edge_aware/nonrobust/GA+PSO | 1 | 1.85223 | NaN | NaN |
| edge_aware/nonrobust/PSO+GA | 1 | 1.85968 | NaN | NaN |
| edge_aware/nonrobust/PGSAO | 1 | 1.95388 | NaN | NaN |
| edge_aware/soft/basic | 1 | 0.684509 | NaN | NaN |
| edge_aware/soft/inner | 1 | 1.79777 | NaN | NaN |
| edge_aware/soft/GA | 1 | 1.65899 | NaN | NaN |
| edge_aware/soft/PSO | 1 | 1.74017 | NaN | NaN |
| edge_aware/soft/GA+PSO | 1 | 1.82083 | NaN | NaN |
| edge_aware/soft/PSO+GA | 1 | 1.60522 | NaN | NaN |
| edge_aware/soft/PGSAO | 1 | 1.76719 | NaN | NaN |
| edge_aware/robust/basic | 1 | 0.722125 | NaN | NaN |
| edge_aware/robust/inner | 1 | 2.37921 | NaN | NaN |
| edge_aware/robust/GA | 1 | 1.74701 | NaN | NaN |
| edge_aware/robust/PSO | 1 | 1.7613 | NaN | NaN |
| edge_aware/robust/GA+PSO | 1 | 1.61919 | NaN | NaN |
| edge_aware/robust/PSO+GA | 1 | 1.83943 | NaN | NaN |
| edge_aware/robust/PGSAO | 1 | 1.60956 | NaN | NaN |
| edge_aware/aggressive/basic | 1 | 0.691867 | NaN | NaN |
| edge_aware/aggressive/inner | 1 | 1.69529 | NaN | NaN |
| edge_aware/aggressive/GA | 1 | 1.59866 | NaN | NaN |
| edge_aware/aggressive/PSO | 1 | 1.59053 | NaN | NaN |
| edge_aware/aggressive/GA+PSO | 1 | 1.67214 | NaN | NaN |
| edge_aware/aggressive/PSO+GA | 1 | 1.66865 | NaN | NaN |
| edge_aware/aggressive/PGSAO | 1 | 1.65063 | NaN | NaN |
| non_edge_aware/nonrobust/basic | 1 | 0.797287 | NaN | NaN |
| non_edge_aware/nonrobust/inner | 1 | 1.50078 | NaN | NaN |
| non_edge_aware/nonrobust/GA | 1 | 1.64045 | NaN | NaN |
| non_edge_aware/nonrobust/PSO | 1 | 1.51036 | NaN | NaN |
| non_edge_aware/nonrobust/GA+PSO | 1 | 1.53679 | NaN | NaN |
| non_edge_aware/nonrobust/PSO+GA | 1 | 1.5683 | NaN | NaN |
| non_edge_aware/nonrobust/PGSAO | 1 | 1.55685 | NaN | NaN |
| non_edge_aware/soft/basic | 1 | 0.701407 | NaN | NaN |
| non_edge_aware/soft/inner | 1 | 1.59634 | NaN | NaN |
| non_edge_aware/soft/GA | 1 | 1.60616 | NaN | NaN |
| non_edge_aware/soft/PSO | 1 | 1.61717 | NaN | NaN |
| non_edge_aware/soft/GA+PSO | 1 | 1.68856 | NaN | NaN |
| non_edge_aware/soft/PSO+GA | 1 | 1.66393 | NaN | NaN |
| non_edge_aware/soft/PGSAO | 1 | 1.60993 | NaN | NaN |
| non_edge_aware/robust/basic | 1 | 0.680801 | NaN | NaN |
| non_edge_aware/robust/inner | 1 | 1.66974 | NaN | NaN |
| non_edge_aware/robust/GA | 1 | 1.65672 | NaN | NaN |
| non_edge_aware/robust/PSO | 1 | 1.59884 | NaN | NaN |
| non_edge_aware/robust/GA+PSO | 1 | 1.60353 | NaN | NaN |
| non_edge_aware/robust/PSO+GA | 1 | 1.69682 | NaN | NaN |
| non_edge_aware/robust/PGSAO | 1 | 1.65081 | NaN | NaN |
| non_edge_aware/aggressive/basic | 1 | 0.743714 | NaN | NaN |
| non_edge_aware/aggressive/inner | 1 | 1.84818 | NaN | NaN |
| non_edge_aware/aggressive/GA | 1 | 1.6692 | NaN | NaN |
| non_edge_aware/aggressive/PSO | 1 | 1.59034 | NaN | NaN |
| non_edge_aware/aggressive/GA+PSO | 1 | 1.6154 | NaN | NaN |
| non_edge_aware/aggressive/PSO+GA | 1 | 1.67589 | NaN | NaN |
| non_edge_aware/aggressive/PGSAO | 1 | 1.67527 | NaN | NaN |
