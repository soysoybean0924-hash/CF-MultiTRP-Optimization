# Research Asset Inventory

This inventory records the current repository state without deleting,
moving, or overwriting research assets.

Snapshot date: 2026-09-02.

## Git Snapshot

- Branch: `main`
- Remote: `origin git@github.com:soysoybean0924-hash/CF-MultiTRP-Optimization.git`
- HEAD: `50cafa0 补充Huawei分组图和M3外层搜索结果`
- Working tree at the start of this cleanup already contained modified and
  untracked files.

Tracked modified before this documentation pass:

- `matlab/core/cf_decode_candidate.m`
- `matlab/core/cf_search.m`
- `matlab/core/run_01_basic.m`
- `setup_project_paths.m`
- `tests/run_smoke_tests.m`

Untracked before this documentation pass:

- `docs/目标函数与评价指标说明.pdf`
- `experiments/paper_ablation/`
- `paper_edit/`

`results/` and `*.mat` are mostly ignored by `.gitignore`; older result files
may still be tracked because they entered Git before the ignore rule.

## 01 Core Algorithm Code

| File | Function | Still called | Called by | Paper track |
|---|---|---|---|---|
| `matlab/core/cf_default_config.m` | Defines `quick`, `standard`, `paper`, `m3`, `huawei` profiles, search space, objective-score weights | Yes | All run scripts | Yes |
| `matlab/core/cf_generate_scenario.m` | Generates DU/UE layout, channels, true/estimated channels, edge metadata | Yes | Tests and experiments | Yes |
| `matlab/core/cf_decode_candidate.m` | Maps 9-D normalized outer vector to scheduling parameters | Yes | `cf_evaluate_candidate`, `cf_search` workflows | Yes |
| `matlab/core/cf_evaluate_candidate.m` | Builds baseline b/r/Q/W, optionally runs inner loop, computes objective and diagnostics | Yes | Basic, inner, all searches | Yes |
| `matlab/core/cf_search.m` | Implements GA, PSO, GA+PSO, PSO+GA, PGSAO with shared objective tracker | Yes | Run scripts and ablation | Yes |
| `matlab/core/cf_compute_true_objective.m` | Recomputes scheduled `sum log2(1+SINR)` objective from result tensors | Yes | Tests and result exporters | Yes |
| `matlab/core/cf_compute_experience_rate.m` | 3GPP-style experience rate diagnostics | Yes | Huawei and evaluation | Secondary |
| `matlab/core/cf_apply_srs_measurement_model.m` | Nonideal SRS / channel-estimation model | Yes | Huawei scenario generation | Huawei stress |
| `matlab/core/cf_classify_edge_users.m` | Edge-user classification | Yes | M3/Huawei scenario generation | Secondary |
| `matlab/core/cf_generate_burst_traffic.m` | Burst traffic traces | Yes | Huawei scenario generation | Secondary |
| `matlab/core/cf_evaluate_three_objectives.m` | Local sensitivity objective bundle | Yes | Sensitivity scripts | Historical |
| `matlab/core/cf_plot_result.m` | Per-result diagnostics plot | Yes | example run scripts | Support |
| `matlab/core/cf_plot_search.m` | Search convergence plot | Yes | search example scripts | Support |
| `matlab/core/cf_print_result.m` | Metric table printer | Yes | run scripts | Support |
| `matlab/core/run_01_basic.m` to `run_07_pgsao.m` | Quick demonstration entry points | Yes | Manual | Smoke/demo |

Important behavior:

- Basic calls `cf_evaluate_candidate(..., false)`.
- Inner-only calls `cf_evaluate_candidate(..., true)`.
- Outer+Inner uses `cf_search(...)`, which by default calls
  `cf_evaluate_candidate(..., true)`.
- Outer-only is controlled by `options.enableInnerOptimization=false`.

## 02 Configurations

| Config | TRP / DU | UE | Tx | Rx | RBG | Seeds | Use | Keep status |
|---|---:|---:|---:|---:|---:|---|---|---|
| `quick` | 4 | 6 | 4 | 2 | 3 | 11/23/37 | Fast smoke and examples | Keep |
| `standard` | 8 | 16 | 8 | 2 | 4 | 11/23/37 | Medium checks | Keep |
| `paper` | 16 | 30 | 8 | 2 | 5 | 11/23/37 | Earlier single-seed paper profile | Historical, keep |
| `m3` | 7 | 100 | 12 | 2 | 100 | 11/23/37 | Large M3 C-RAN profile | Stress, keep |
| `huawei` | 21 | 315 | 64 | 4 | 273 | 11/23/37 plus measurement seed 53 | Full Huawei-inspired profile | Stress, keep |
| `paper_ablation_S1` | 4 | 8 | default 8 | 2 | default 4 | `1:10` mapped to 1000/2000/3000 offsets | Current paper controlled scale | Keep |
| `paper_ablation_S2` | 8 | 16 | default 8 | 2 | default 4 | same | Current main ablation scale | Keep |
| `paper_ablation_S3` | 12 | 24 | default 8 | 2 | default 4 | same | Current scalability scale | Keep |
| `paper_ablation_S4` | 16 | 32 | default 8 | 2 | default 4 | same | Current scalability scale | Keep |

## 03 Formal Experiment Entrypoints

| File | Algorithms | Config | Output | Runs now | Paper formal |
|---|---|---|---|---|---|
| `experiments/paper_ablation/run_controlled_outer_ablation.m` | basic, inner, GA-only, PSO-only, PGSAO-only, GA+Inner, PSO+Inner, PGSAO+Inner | Controlled S1-S4 | `results/paper_ablation/<run_id>/` | Smoke passed | Yes, but full run incomplete |
| `experiments/m3_testbed/run_m3_full9_testbed.m` | basic, inner, GA, PSO, GA+PSO, PSO+GA, PGSAO | `m3` with caps | `results/m3_testbed/<run_id>/` | Path tested | Stress / historical |
| `experiments/m3_scale_comparison/run_m3_algorithm_comparison.m` | basic, inner, GA, PSO, hybrids | quick/standard/paper/m3 | `results/M3_true_objective_comparison/` by default | Not rerun here | Historical |
| `experiments/m3_scale_comparison/run_m3_reduced_algorithm_comparison.m` | Same, reduced dimensions | `m3` plus sensitivity dims | `results/M3_true_objective_comparison/m3_reduced3/` | Not rerun here | Historical |
| `experiments/m3_efficiency/run_m3_efficiency_benchmark.m` | basic, inner, PSO+GA by default | tiny/small/m3_probe | `results/m3_efficiency/<run_id>/` | Path tested | Runtime support |
| `experiments/huawei_robust/run_huawei_final_algorithm_comparison.m` | basic, inner, GA, PSO, GA+PSO, PSO+GA, PGSAO | Huawei probe/medium/full_lite/final | `results/huawei_robust/<run_id>/` | Path tested | Huawei stress |
| `experiments/huawei_robust/run_huawei_robust_comparison.m` | basic, inner, PSO+GA by default | Huawei probe overrides | `results/huawei_robust/<run_id>/` | Path tested | Historical stress |
| `experiments/huawei_robust/run_huawei_robust_scale_suite.m` | basic, inner, PGSAO/PSO+GA subsets | probe/medium/full_lite | `results/huawei_robust/<run_id>/` | Path tested | Historical stress |
| `experiments/local_sensitivity/*.m` | local parameter perturbation | quick/standard/paper | `results/local_sensitivity*` | Not rerun here | Historical support |

## 04 Experiment Results

| Result directory | Category | Key source | Scale | Trust label | Paper usable |
|---|---|---|---|---|---|
| `results/paper_ablation/smoke_codex/` | Outer-only ablation smoke | `run_controlled_outer_ablation.m` | S1, 4 TRP, 8 UE, 2 RBG, 8 Tx, seed 1, eval 2, inner iter 1 | SMOKE | No, wiring only |
| `results/M3_scale_comparison/` | Earlier profile comparison | `run_m3_algorithm_comparison.m` | quick/standard/paper/m3 | COMPLETE historical single-seed | Useful background, not current ablation |
| `results/M3_true_objective_comparison/` | Earlier J_true comparison | `run_m3_algorithm_comparison.m` | quick/standard/paper/m3 | ARCHIVED duplicate-ish historical | Use only with caution |
| `results/M3_scale_comparison_capped_eval1_iter1/` | Capped debug | M3 comparison with very low budget | eval 1 / inner iter 1 | SMOKE/DEBUG | No |
| `results/m3_testbed/jtrue_full9_default_seeded_eval16/` | M3 full 9-D run | `run_m3_full9_testbed.m` | 7 TRP, 100 UE, 100 RBG, 12 Tx, eval 16, inner iter 2 | COMPLETE stress single-seed | Stress evidence only |
| `results/m3_testbed/m3_basic_inner_converged_20260809/` | M3 basic vs inner | `run_m3_full9_testbed.m` | 7 TRP, 100 UE, 100 RBG, 12 Tx | COMPLETE partial | Shows Basic > Inner in M3 |
| `results/m3_testbed/m3_outer_probe_20260809/` | M3 outer probe | `run_m3_full9_testbed.m` | eval 2 | SMOKE/PROBE | No formal ranking |
| `results/m3_efficiency/initial_efficiency_benchmark/` | Runtime probe | `run_m3_efficiency_benchmark.m` | tiny/small | COMPLETE support | Runtime support only |
| `results/huawei_robust/probe_robust_vs_nonrobust/` | Huawei robust probe | `run_huawei_robust_comparison.m` | 21 TRP, 21 UE, 4 RBG, 8 Tx | PROBE | No |
| `results/huawei_robust/probe_medium_full_lite_suite/` | Huawei staged suite | `run_huawei_robust_scale_suite.m` | probe/medium/full_lite | PROBE | Stress support |
| `results/huawei_robust/full_lite_algorithm_matrix_eval16/` | Huawei full-lite algorithm matrix | `run_huawei_final_algorithm_comparison.m` | 21 TRP, 63 UE, 12 RBG, 12 Tx, eval 16 | COMPLETE stress single-seed | Engineering stress evidence |
| `results/huawei_robust/huawei_full_ue_tx_rank1_rbg16_basic_inner/` | Huawei full UE/Tx partial | `run_huawei_final_algorithm_comparison.m` | 21 TRP, 315 UE, 16 RBG, 64 Tx, basic/inner | COMPLETE partial | Stress only, no full algorithm matrix |
| `results/huawei_robust/final_smoke_codex/` | Huawei smoke | prior validation | small Huawei probe | SMOKE | No |
| `results/local_sensitivity/` | Local sensitivity | local sensitivity scripts | default profile | ARCHIVED | Background |
| `results/local_sensitivity_profiles/` | Multi-profile sensitivity | local sensitivity profile comparison | quick/standard/paper | ARCHIVED | Background |

Known key values:

- `results/paper_ablation/smoke_codex/scale_comparison.csv`:
  `PGSAO+Inner = 73.1412`, `Inner = 69.0187`, `PGSAO-only = 47.9226`,
  but `GA+Inner`, `PSO+Inner`, and `PGSAO+Inner` tie under the tiny budget.
- `results/M3_scale_comparison/algorithm_profile_comparison.csv`:
  quick best `PGSAO = 96.3405`, standard best `PGSAO = 401.8330`,
  paper best `GA = 816.1461`, M3 best `basic = 7308.5991`.
- `results/m3_testbed/jtrue_full9_default_seeded_eval16/algorithm_comparison.csv`:
  M3 `basic = 7308.5991`, `inner = 3394.2603`,
  best search `PSO+GA = 6248.1431`.
- `results/huawei_robust/full_lite_algorithm_matrix_eval16/huawei_final_algorithm_comparison.csv`:
  full-lite stress scale is 21 TRP, 63 UE, 12 RBG, 12 Tx, eval 16.

## 05 Documentation

| File | Status |
|---|---|
| `README.md` | Updated as current project entry |
| `docs/CURRENT_RESEARCH_STATUS.md` | New concise research status |
| `docs/EXPERIMENT_INDEX.md` | New experiment index |
| `docs/REPOSITORY_REORGANIZATION_PLAN.md` | New safe reorganization plan |
| `docs/RESEARCH_ASSET_INVENTORY.md` | This full inventory |
| `docs/MATLAB_CODE_GUIDE.md` | Historical but useful |
| `docs/代码递进说明.md` | Historical algorithm narrative |
| `docs/目标函数与评价指标说明.md` | Important objective/metric note |
| `docs/HUAWEI_VALIDATION_SCENE.md` | Huawei scenario note |
| `docs/LOCAL_SENSITIVITY_PROFILE_COMPARISON.md` | Historical sensitivity note |
| `docs/20260809_*.md` | Historical run notes, some terminal display may appear mojibake depending console encoding |

## 06 Paper Materials

`paper_edit/` is currently untracked. It contains PDF-building scripts,
rendered page PNGs, extracted text, and digital-twin paper PDFs. It appears
to be a separate paper-editing workspace or prior manuscript artifact, not
the current Multi-TRP algorithm paper source. Keep for now, but do not mix it
with the core algorithm paper until ownership is confirmed.

## 07 Tests

| Test | File | Coverage | Latest status |
|---|---|---|---|
| Smoke pipeline | `tests/run_smoke_tests.m` | MATLAB path, M3/Huawei config sanity, quick basic/inner evaluation, reduced PSO, outer-only PSO | Passed before this inventory |

No broad unit-test suite or statistical regression suite currently exists.

## 08 Temporary / Archive Candidates

Do not delete in this pass. Candidates for later archival:

- `results/M3_scale_comparison_capped_eval1_iter1/`: capped debug result.
- `results/huawei_robust/final_smoke_codex/`: smoke result.
- `paper_edit/render_*` and `paper_edit/__pycache__/`: generated manuscript
  rendering/cache artifacts.
- Duplicate-looking M3 result roots:
  `results/M3_scale_comparison/` and `results/M3_true_objective_comparison/`.
- Huawei versioned full runs:
  `huawei_full_ue_tx_rank1_rbg16_core`,
  `huawei_full_ue_tx_rank1_rbg16_core_v2`,
  `huawei_full_ue_tx_rbg16_core`.

These should be moved only after matching each directory to its generating
script and confirming no external manuscript currently references its path.
