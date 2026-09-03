# Repository Reorganization Plan

Snapshot date: 2026-09-02.

This plan records a safe cleanup strategy. No algorithm logic, historical
results, or Git history should be changed just to make the tree prettier.

## 中文摘要

这个文件不是已经执行的移动记录，而是后续安全整理仓库的计划。当前最稳妥的策略是：
先不要移动目录，不要删除历史结果，先通过 README、实验索引和结果索引让项目可读。

原因是很多实验入口依赖 `setup_project_paths.m` 中的硬编码路径。直接移动
`experiments/m3_*`、`experiments/huawei_robust` 或历史 `results/` 目录，
可能破坏脚本、文档和论文图表引用。真正需要物理整理时，应使用 `git mv`，
并同步更新路径、测试和文档。

## 1. Current Problems

- `results/` contains many result generations with no root-level trust index.
- Some results are smoke/debug runs but sit next to more complete results.
- M3 result roots are duplicated or near-duplicated:
  `M3_scale_comparison`, `M3_true_objective_comparison`,
  `M3_scale_comparison_capped_eval1_iter1`, and `m3_testbed`.
- Huawei result roots include probe, full-lite, full partial, and smoke runs
  under one directory without status labels.
- `paper_edit/` is untracked and appears unrelated or only loosely related to
  the current Multi-TRP algorithm paper.
- `setup_project_paths.m` hardcodes experiment directories, so moving
  experiment folders can break MATLAB path resolution and smoke tests.
- `results/` is ignored by Git, but many old results are tracked. This mixed
  tracked/ignored state is confusing but should not be fixed by deletion.

## 2. Recommended Target Structure

中文说明：下面是未来目标结构，不是当前已经执行的结构。当前仓库仍保持原目录，
只补充了索引文档。

```text
experiments/
|-- paper_ablation/       Current first-stage paper workflow
|-- m3/                   Future home for M3 testbed + efficiency scripts
|-- huawei/               Future home for Huawei stress scripts
|-- sensitivity/          Future home for local sensitivity scripts
|-- smoke/                Optional manual smoke/demo scripts
|-- archive/              Retired historical experiment scripts

results/
|-- README.md             Root result index
|-- paper_ablation/       Current controlled paper outputs
|-- m3/                   Future normalized M3 outputs
|-- huawei/               Future normalized Huawei outputs
|-- sensitivity/          Future normalized sensitivity outputs
|-- smoke/                Smoke-only outputs
|-- archive/              Historical outputs that should not drive claims

docs/
|-- CURRENT_RESEARCH_STATUS.md
|-- EXPERIMENT_INDEX.md
|-- RESEARCH_ASSET_INVENTORY.md
|-- algorithm/
|-- experiments/
|-- scenarios/
|-- archive/
```

## 3. Recommended Moves

中文说明：这些移动建议暂时不要执行。执行前需要确认 MATLAB path、结果引用和论文图表
不会被破坏。

Do not perform these moves until the scripts and any manuscript references are
updated together.

| Old path | Suggested new path | Method | Risk |
|---|---|---|---|
| `experiments/m3_testbed/` | `experiments/m3/testbed/` | `git mv` | Requires `setup_project_paths.m` and tests update |
| `experiments/m3_efficiency/` | `experiments/m3/efficiency/` | `git mv` | Requires path and docs update |
| `experiments/m3_scale_comparison/` | `experiments/m3/scale_comparison/` | `git mv` | Historical scripts may have hardcoded result paths |
| `experiments/huawei_robust/` | `experiments/huawei/robust/` | `git mv` | Requires path and docs update |
| `experiments/local_sensitivity/` | `experiments/sensitivity/local/` | `git mv` | Requires path and docs update |
| `results/M3_scale_comparison_capped_eval1_iter1/` | `results/archive/m3_scale_comparison_capped_eval1_iter1/` | move after confirmation | Ignored/tracked mixed files |
| `results/huawei_robust/final_smoke_codex/` | `results/smoke/huawei_final_smoke_codex/` | move after confirmation | Ignored/tracked mixed files |
| `results/paper_ablation/smoke_codex/` | `results/smoke/paper_ablation_smoke_codex/` | move after confirmation | Current smoke reference paths would change |
| `docs/20260809_*.md` | `docs/archive/20260809_*.md` | `git mv` | Historical notes, low code risk |
| `paper_edit/` | `paper_edit/` or `docs/archive/paper_edit_note.md` | no move until confirmed | It is untracked and likely a separate manuscript workflow |

## 4. Rename Candidates

| Current path | Suggested name | Reason |
|---|---|---|
| `results/M3_scale_comparison/` | `results/archive/m3_legacy_profile_comparison/` | Historical single-seed profile comparison |
| `results/M3_true_objective_comparison/` | `results/archive/m3_legacy_true_objective_comparison/` | Duplicate-looking historical result root |
| `results/m3_testbed/jtrue_full9_default_seeded_eval16/` | `results/m3/full9_eval16_seeded/` | Cleaner stress-test label |
| `results/huawei_robust/full_lite_algorithm_matrix_eval16/` | `results/huawei/full_lite_algorithm_matrix_eval16/` | Cleaner Huawei stress label |

## 5. Archive Candidates

Archive, do not delete:

- Low-budget debug and capped runs.
- Old sensitivity plots and generated `.fig` files.
- Duplicate-looking M3 true-objective result roots.
- Huawei smoke runs.
- Manuscript rendering intermediates under `paper_edit/render_*`.

## 6. Possible Deletion Candidates

Only delete after explicit user confirmation:

- `paper_edit/__pycache__/`
- `*.pyc`
- MATLAB autosave/backup files if any appear later.

No `.m`, `.csv`, `.mat`, figure, paper draft, or tracked file should be
deleted in the first cleanup pass.

## 7. Path Dependencies

Currently `setup_project_paths.m` adds:

- `matlab/core`
- `experiments/local_sensitivity`
- `experiments/m3_scale_comparison`
- `experiments/m3_testbed`
- `experiments/m3_efficiency`
- `experiments/huawei_robust`
- `experiments/paper_ablation`

Moving any experiment folder requires updating:

- `setup_project_paths.m`
- `tests/run_smoke_tests.m`
- `README.md`
- `docs/EXPERIMENT_INDEX.md`
- all run-script documentation that references old paths

## 8. Results To Keep In Place For Now

Keep these paths stable until paper figures and notes are updated:

- `results/paper_ablation/smoke_codex/`
- `results/M3_scale_comparison/`
- `results/m3_testbed/jtrue_full9_default_seeded_eval16/`
- `results/huawei_robust/full_lite_algorithm_matrix_eval16/`
- `results/huawei_robust/huawei_full_ue_tx_rank1_rbg16_basic_inner/`

## 9. Tracked Files That Need `git mv` If Reorganized

Experiment scripts and historical docs are tracked. Use `git mv` for any
future physical reorganization of:

- `experiments/huawei_robust/*`
- `experiments/local_sensitivity/*`
- `experiments/m3_efficiency/*`
- `experiments/m3_scale_comparison/*`
- `experiments/m3_testbed/*`
- `docs/*.md`

## 10. Recommended Immediate Action

Do not physically move files in this pass. Keep the current runnable layout,
add the documentation indexes, run smoke tests, then commit the documentation
and outer-only ablation code together after user confirmation.
