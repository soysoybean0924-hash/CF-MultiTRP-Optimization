"""Read-only checks of a completed native MATLAB CHASI saved run."""
from __future__ import annotations

import csv
import json
import math
import sys
from pathlib import Path


def check(run_dir: Path, branch: str = "matrix_statistical") -> dict[str, object]:
    cfg = json.loads((run_dir / "config.json").read_text(encoding="utf-8"))
    summary = json.loads((run_dir / "summary.json").read_text(encoding="utf-8"))
    assert summary["language"] == "MATLAB"
    assert summary["entry"] == "matlab/chasi/chasi_run.m"
    assert summary["scene_dimensions"]["users"] == cfg["users"]
    assert summary["scene_dimensions"]["trps"] == 21
    assert summary["scene_dimensions"]["rb"] == 273
    scenario = summary["scenario"]
    if scenario.get("srs_measurement_contract_version") == 2:
        assert scenario["srs_hop_rb_counts"] == [16] * 16 + [17]
        assert scenario["srs_total_measured_rb"] == 273
        # Older v2 summaries retained a mislabeled compatibility alias.
        # Current output omits it; only the explicit widths and total remain.
        if "srs_nominal_hop_rb" in scenario:
            assert scenario["srs_nominal_hop_rb"] == 273
    else:
        # Saved v3 runs predating the source-image check retain their
        # historically incorrect nominal 17-by-16 metadata label.
        assert scenario["srs_nominal_hop_rb"] == 272
    assert scenario["srs_modeled_group_rb"] == 273
    record = summary["branches"][branch]
    assert record["status"] == "completed"
    assert record["result_schema_version"] == 3
    assert record["runtime_seconds"] > 0
    assert record["max_power_violation_watt"] <= 1e-6
    powers = record["per_trp_power_watt"]
    assert len(powers) == 21
    assert max(powers) <= cfg["powerWattPerTrp"] + 1e-6
    metrics = record["evaluation"]
    assert metrics["users_total"] == cfg["users"]
    assert (metrics["users_with_valid_samples"] +
            metrics["users_without_valid_samples"] == cfg["users"])
    assert metrics["valid_sample_count"] >= metrics["users_with_valid_samples"]
    assert math.isfinite(metrics["physical_sum_bits_per_s_hz"])
    assert (run_dir / record["precoders_mat_file"]).is_file()
    assert (run_dir / "scene.mat").is_file()
    with (run_dir / record["per_ue_csv_file"]).open(encoding="utf-8-sig", newline="") as stream:
        rows = list(csv.DictReader(stream))
    assert len(rows) == cfg["users"]
    assert [int(row["ue_id"]) for row in rows] == list(range(1, cfg["users"] + 1))
    summed_rate = sum(float(row["physical_bits_per_s_hz"]) for row in rows)
    assert abs(summed_rate - metrics["physical_sum_bits_per_s_hz"]) < 1e-8
    return {
        "users": cfg["users"],
        "branch": branch,
        "status": record["status"],
        "converged": record["converged"],
        "reason": record["reason"],
        "runtime_seconds": record["runtime_seconds"],
        "true_sum_se_bits_per_s_hz": metrics["physical_sum_bits_per_s_hz"],
        "valid_users": metrics["users_with_valid_samples"],
        "max_power_violation_watt": record["max_power_violation_watt"],
        "saved_schema": record["result_schema_version"],
        "scope": "saved summary/CSV/MAT presence; MAT fields require MATLAB reload",
    }


if __name__ == "__main__":
    name = sys.argv[2] if len(sys.argv) > 2 else "matrix_statistical"
    print(json.dumps(check(Path(sys.argv[1]), name), indent=2))
