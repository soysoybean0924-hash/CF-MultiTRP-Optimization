# M3 Efficiency Benchmark

Profiles: `tiny, small`.

Methods: `basic, inner, PSO+GA`.

Budget: innerMaxIter=1, maxEvaluations=2, populationSize=2.

This benchmark is the measurement layer for the mandatory high-efficiency computing target.
It does not yet claim the final target is met; it provides scaling evidence and bottleneck timing.

## Runtime Summary

| Profile | Method | Links | RuntimeSeconds | RuntimePerEvaluation | J_true | ActiveLinks | TotalPower |
|---|---|---:|---:|---:|---:|---:|---:|
| tiny | basic | 360 | 0.905484 | 0.905484 | 175.556 | 240 | 30 |
| tiny | inner | 360 | 0.326522 | 0.326522 | 359.639 | 240 | 30 |
| tiny | PSO+GA | 360 | 0.303481 | 0.15174 | 499.202 | 120 | 30 |
| small | basic | 3000 | 0.510884 | 0.510884 | 715.197 | 1200 | 100 |
| small | inner | 3000 | 0.589402 | 0.589402 | 1228.16 | 1199 | 68.6478 |
| small | PSO+GA | 3000 | 1.49314 | 0.74657 | 1228.32 | 1193 | 68.9133 |

## Scaling Fit

Log-log slope is fitted from RuntimeSeconds versus NumLinks. A slope near 1 is closer to linear scaling.

| Method | Points | LogLogSlope | RSquared |
|---|---:|---:|---:|
| basic | 2 | -0.2699 | 1 |
| inner | 2 | 0.2786 | 1 |
| PSO+GA | 2 | 0.7515 | 1 |

## Current Judgment

- This run establishes the evidence path for the high-efficiency target.
- If slopes are much larger than 1 or M3_probe dominates runtime, the next step should be caching, vectorization, and parallel candidate evaluation.
- A final high-efficiency claim requires an optimized run with improved runtime or near-linear scaling on the same benchmark.
