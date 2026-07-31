# M3 Testbed Explanation

Generated at: 2026-07-31 10:06:21

Run ID: `jtrue_full9_current`

Scale: 7 DUs, 100 UEs, 100 RBGs, 2x12 MIMO.

Search space: full 9-D normalized candidate vector.

Optimization objective: maximize `J_true = scheduled sum log2(1+SINR)`.
Jain, ActiveLinks, TotalPower, and Runtime are evaluation metrics only.

## Algorithm Comparison

| Method | Objective | J_true | Jain | ActiveLinks | TotalPower | RuntimeSeconds |
|---|---:|---:|---:|---:|---:|---:|
| basic | 7308.6 | 7308.6 | 0.6805 | 20000 | 700 | 4.031 |
| inner | 3394.26 | 3394.26 | 0.0930 | 1545 | 25.9007 | 240.397 |
| GA | 2799.17 | 2799.17 | 0.3249 | 1214 | 55.9035 | 1706.228 |
| PSO | 2799.17 | 2799.17 | 0.3249 | 1214 | 55.9035 | 1722.690 |
| GA+PSO | 2799.17 | 2799.17 | 0.3249 | 1214 | 55.9035 | 1664.761 |
| PSO+GA | 2799.17 | 2799.17 | 0.3249 | 1214 | 55.9035 | 1391.648 |
| PGSAO | 2799.17 | 2799.17 | 0.3249 | 1214 | 55.9035 | 1386.534 |

## Result Interpretation

- Best objective: `basic` with 7308.6.
- Best Jain index: `basic` with 0.6805.
- Fewest active links: `GA` with 1214 links.

If `basic` is best by objective, it should be treated as a high-link upper baseline rather than a low-cost scheduling solution.
If `inner` beats outer-search methods, the current search budget or search-space design is not yet strong enough to improve over the default inner candidate.
If outer-search methods improve objective but worsen Jain or ActiveLinks, the change improves the target max objective but may need engineering constraints later.
