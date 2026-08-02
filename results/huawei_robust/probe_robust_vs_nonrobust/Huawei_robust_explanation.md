# Huawei Robust SRS Comparison

Probe scale: DUs=21, UEs=21, RBGs=4, MIMO=8x2.

The scheduler uses `H_est`; robust validation is judged on `H_true` columns.

| Variant | Method | EstObj | TrueObj | TrueEdgeP5 | TotalPower | ActiveLinks | Runtime |
|---|---|---:|---:|---:|---:|---:|---:|
| nonrobust | basic | 394.818 | 384.909 | 0 | 83 | 168 | 0.523 |
| nonrobust | inner | 676.154 | 602.52 | 0 | 83 | 168 | 0.504 |
| nonrobust | PSO+GA | 714.378 | 639.712 | 0 | 84 | 252 | 0.812 |
| robust | basic | 394.818 | 384.909 | 0 | 83 | 168 | 0.200 |
| robust | inner | 673.459 | 608.284 | 0 | 83 | 168 | 0.287 |
| robust | PSO+GA | 713.895 | 651.207 | 0 | 84 | 252 | 0.677 |

## Interpretation

- `nonrobust` uses the same SRS-estimated channel without uncertainty-aware penalties.
- `robust` applies uncertainty shrinkage and extra penalty on high-error or unmeasured SRS links.
- This is a Huawei probe, not the final full-scale validation run.
