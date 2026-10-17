"""Independent static experience check using explicit saved MATLAB traffic.

This does not validate an online queue or channel evolution.
"""
from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

import numpy as np
from scipy.io import loadmat


def check(run_dir: Path, traffic_mat: Path,
          branch: str = "matrix_statistical") -> dict[str, float | int | str]:
    config = json.loads((run_dir / "config.json").read_text(encoding="utf-8"))
    manifest = json.loads((run_dir / "scene_manifest.json").read_text(encoding="utf-8"))
    summary = json.loads((run_dir / "summary.json").read_text(encoding="utf-8"))
    saved = loadmat(traffic_mat)
    busy = np.asarray(saved["busy"], dtype=bool)
    tail = np.asarray(saved["tail"], dtype=bool)
    terminal = np.asarray(saved["terminal"], dtype=bool)
    assert busy.shape == tail.shape == terminal.shape == (
        config["users"], config["durationTti"])
    assert not np.any(tail & ~busy)
    assert not np.any(terminal & ~busy)
    scheduled = np.zeros(config["users"], dtype=bool)
    for group in manifest["groups"]:
        scheduled[np.asarray(group["ueIds"], dtype=int) - 1] = True
    with (run_dir / f"{branch}_per_ue.csv").open(
            encoding="utf-8-sig", newline="") as stream:
        rows = list(csv.DictReader(stream))
    assert len(rows) == config["users"]
    physical_se = np.asarray(
        [float(row["physical_bits_per_s_hz"]) for row in rows])
    saved_valid = np.asarray([int(row["valid_tti"]) for row in rows])
    saved_experience = np.asarray(
        [float(row["experience_mbps"]) for row in rows])
    eligible = busy & ~terminal
    valid = np.sum(eligible, axis=1) * scheduled
    demand = np.where(tail, 2.0 / 7.0, 1.0)
    bits_per_tti = (physical_se * config["rbTotal"] * 12.0 *
                    config["scsHz"] * config["ttiMs"] / 1000.0)
    delivered_bits = bits_per_tti * np.sum(eligible * demand, axis=1)
    expected = np.full(config["users"], np.nan)
    present = valid > 0
    expected[present] = (delivered_bits[present] /
                         (valid[present] * config["ttiMs"] / 1000.0) / 1e6)
    assert np.array_equal(valid, saved_valid)
    assert np.array_equal(np.isnan(expected), np.isnan(saved_experience))
    max_error = float(np.max(np.abs(expected[present] - saved_experience[present])))
    assert max_error < 1e-9, max_error
    metric = summary["branches"][branch]["evaluation"]
    assert int(np.sum(valid)) == metric["valid_sample_count"]
    assert int(np.sum(present)) == metric["users_with_valid_samples"]
    mean_error = abs(float(np.mean(expected[present])) -
                     metric["experience_mean_mbps_valid_ues"])
    bottom5_error = abs(float(np.percentile(expected[present], 5)) -
                        metric["experience_bottom5_mbps_valid_ues"])
    assert mean_error < 1e-9 and bottom5_error < 1e-9
    return {
        "users": config["users"],
        "valid_ue_tti": int(np.sum(valid)),
        "max_per_ue_experience_error_mbps": max_error,
        "mean_experience_error_mbps": mean_error,
        "bottom5_error_mbps": bottom5_error,
        "scope": "saved masks + static SE; no online queue parity",
    }


if __name__ == "__main__":
    print(json.dumps(check(Path(sys.argv[1]), Path(sys.argv[2])), indent=2))
