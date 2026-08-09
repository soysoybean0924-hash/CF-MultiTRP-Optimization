# M3 Testbed Explanation

Generated at: 2026-08-09 21:03:18

Run ID: `m3_outer_probe_20260809`

Scale: 7 DUs, 100 UEs, 100 RBGs, 2x12 MIMO.

Search space: full 9-D normalized candidate vector.

Default candidate injection: enabled; cfg.defaultX is the first outer-search candidate.

Budget: populationSize=2, maxEvaluations=2, innerMaxIter=35.

Optimization objective: maximize `J_true = scheduled sum log2(1+SINR)`.
Score, Jain, ActiveLinks, TotalPower, and Runtime are evaluation metrics only.

## Algorithm Comparison

| Method | Objective | Score | J_true | Jain | ActiveLinks | TotalPower | RuntimeSeconds |
|---|---:|---:|---:|---:|---:|---:|---:|
| GA | 2881.39 | 674.043 | 2881.39 | 0.1571 | 728 | 229.092 | 821.839 |
| PSO | 2881.39 | 674.043 | 2881.39 | 0.1571 | 728 | 229.092 | 793.506 |
| GA+PSO | 2881.39 | 674.043 | 2881.39 | 0.1571 | 728 | 229.092 | 791.121 |
| PSO+GA | 2881.39 | 674.043 | 2881.39 | 0.1571 | 728 | 229.092 | 796.339 |
| PGSAO | 2881.39 | 674.043 | 2881.39 | 0.1571 | 728 | 229.092 | 799.471 |

## Result Interpretation

- Best objective: `GA` with 2881.39.
- Best Jain index: `GA` with 0.1571.
- Fewest active links: `GA` with 728 links.

If `basic` is best by objective, it should be treated as a high-link upper baseline rather than a low-cost scheduling solution.
If `inner` beats outer-search methods even after default-candidate injection, the current algorithm update or search-space design is not yet strong enough to improve over the default inner candidate.
If outer-search methods improve objective but worsen Jain or ActiveLinks, the change improves the target max objective but may need engineering constraints later.
