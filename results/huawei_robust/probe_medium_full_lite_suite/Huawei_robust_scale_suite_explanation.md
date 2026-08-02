# Huawei Robust Probe-Medium-Full-Lite Suite

This suite runs three staged scales before the final full Huawei validation.

- `probe`: logic validation.
- `medium`: robust parameter tuning and algorithm screening.
- `full_lite`: closer-to-Huawei low-budget confirmation.

Medium-selected robust profile for full-lite: `aggressive`.

| Scale | Profile | Method | TrueObj | TrueMeanExp | TrueEdgeP5 | Power | Links | Runtime |
|---|---|---|---:|---:|---:|---:|---:|---:|
| probe | nonrobust | basic | 384.909 | 0 | 0 | 83 | 168 | 0.438 |
| probe | nonrobust | inner | 602.52 | 0 | 0 | 83 | 168 | 0.336 |
| probe | nonrobust | PSO+GA | 639.712 | 0 | 0 | 84 | 252 | 0.565 |
| probe | default | basic | 384.909 | 0 | 0 | 83 | 168 | 0.160 |
| probe | default | inner | 608.284 | 0 | 0 | 83 | 168 | 0.203 |
| probe | default | PSO+GA | 651.207 | 0 | 0 | 84 | 252 | 0.438 |
| medium | nonrobust | basic | 880.581 | 2.17907 | 0 | 168 | 672 | 0.661 |
| medium | nonrobust | inner | 1293.69 | 3.28974 | 0 | 168 | 672 | 0.786 |
| medium | nonrobust | PSO+GA | 1444.32 | 3.56804 | 0 | 168 | 1008 | 1.870 |
| medium | nonrobust | PGSAO | 1444.32 | 3.56804 | 0 | 168 | 1008 | 1.683 |
| medium | soft | basic | 880.581 | 2.17907 | 0 | 168 | 672 | 0.424 |
| medium | soft | inner | 1301.82 | 3.3036 | 0 | 168 | 672 | 0.919 |
| medium | soft | PSO+GA | 1454.62 | 3.59716 | 0 | 168 | 1008 | 1.505 |
| medium | soft | PGSAO | 1454.62 | 3.59716 | 0 | 168 | 1008 | 1.501 |
| medium | default | basic | 880.581 | 2.17907 | 0 | 168 | 672 | 0.369 |
| medium | default | inner | 1306.76 | 3.31102 | 0 | 168 | 672 | 0.764 |
| medium | default | PSO+GA | 1459.84 | 3.61087 | 0 | 168 | 1008 | 1.382 |
| medium | default | PGSAO | 1459.84 | 3.61087 | 0 | 168 | 1008 | 1.416 |
| medium | aggressive | basic | 880.581 | 2.17907 | 0 | 168 | 672 | 0.378 |
| medium | aggressive | inner | 1309.55 | 3.31351 | 0 | 168 | 672 | 0.760 |
| medium | aggressive | PSO+GA | 1462.38 | 3.61743 | 0 | 168 | 1008 | 1.410 |
| medium | aggressive | PGSAO | 1462.38 | 3.61743 | 0 | 168 | 1008 | 1.404 |
| full_lite | nonrobust | basic | 1839.26 | 2.44368 | 1.58659 | 252 | 1512 | 0.704 |
| full_lite | nonrobust | inner | 2694.38 | 3.59861 | 1.0267 | 252 | 1512 | 1.684 |
| full_lite | nonrobust | PSO+GA | 3048.83 | 4.00705 | 1.52583 | 252 | 2268 | 3.060 |
| full_lite | nonrobust | PGSAO | 3048.83 | 4.00705 | 1.52583 | 252 | 2268 | 3.119 |
| full_lite | aggressive | basic | 1839.26 | 2.44368 | 1.58659 | 252 | 1512 | 0.822 |
| full_lite | aggressive | inner | 2728.17 | 3.64237 | 0.89075 | 252 | 1512 | 2.160 |
| full_lite | aggressive | PSO+GA | 3081.22 | 4.05389 | 1.30965 | 252 | 2268 | 3.890 |
| full_lite | aggressive | PGSAO | 3081.22 | 4.05389 | 1.30965 | 252 | 2268 | 3.424 |

## Judgment

- Probe checks logic and output fields.
- Medium compares robust parameters and feasible algorithms.
- Full-lite keeps 21 sectors and larger UE/RBG counts with a low search budget.
- These runs guide final Huawei full-scale settings but do not replace full-scale validation.
