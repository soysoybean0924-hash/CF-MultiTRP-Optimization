# M3 Testbed Explanation

Generated at: 2026-07-31 15:32:48

Run ID: `jtrue_full9_default_seeded_eval16`

Scale: 7 DUs, 100 UEs, 100 RBGs, 2x12 MIMO.

Search space: full 9-D normalized candidate vector.

Default candidate injection: enabled; cfg.defaultX is the first outer-search candidate.

Budget: populationSize=8, maxEvaluations=16, innerMaxIter=2.

Optimization objective: maximize `J_true = scheduled sum log2(1+SINR)`.
Jain, ActiveLinks, TotalPower, and Runtime are evaluation metrics only.

## Algorithm Comparison

| Method | Objective | J_true | Jain | ActiveLinks | TotalPower | RuntimeSeconds |
|---|---:|---:|---:|---:|---:|---:|
| basic | 7308.6 | 7308.6 | 0.6805 | 20000 | 700 | 4.494 |
| inner | 3394.26 | 3394.26 | 0.0930 | 1545 | 25.9007 | 239.129 |
| GA | 3394.26 | 3394.26 | 0.0930 | 1545 | 25.9007 | 3795.823 |
| PSO | 3394.26 | 3394.26 | 0.0930 | 1545 | 25.9007 | 4121.364 |
| GA+PSO | 3394.26 | 3394.26 | 0.0930 | 1545 | 25.9007 | 3500.310 |
| PSO+GA | 6248.14 | 6248.14 | 0.1672 | 2894 | 131.444 | 3981.630 |
| PGSAO | 3823.24 | 3823.24 | 0.1200 | 3754 | 45.7651 | 3649.543 |

## Result Interpretation

- Best objective: `basic` with 7308.6.
- Best Jain index: `basic` with 0.6805.
- Fewest active links: `inner` with 1545 links.

If `basic` is best by objective, it should be treated as a high-link upper baseline rather than a low-cost scheduling solution.
If `inner` beats outer-search methods even after default-candidate injection, the current algorithm update or search-space design is not yet strong enough to improve over the default inner candidate.
If outer-search methods improve objective but worsen Jain or ActiveLinks, the change improves the target max objective but may need engineering constraints later.
