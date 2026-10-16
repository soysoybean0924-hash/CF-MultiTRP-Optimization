"""Compare explicit-input MATLAB evaluation against saved Python reference.

The reference was generated with chasi_formal_implementation.evaluate.evaluate
using the exact h, V, resource and masks in chasi_export_evaluator_parity.m.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from scipy.io import loadmat


REFERENCE = Path(__file__).resolve().parent / "fixtures" / "chasi_eval_reference.json"
FIELDS = (
    "physical_mean_bits_per_s_hz", "physical_sum_bits_per_s_hz",
    "experience_mean_mbps_valid_ues", "experience_bottom5_mbps_valid_ues",
    "experience_bottom5_mbps_all_ues_zero_included",
    "actual_prb_fraction_mean", "actual_busy_ue_tti_fraction",
    "actual_tail_tti_fraction_of_busy", "actual_tail_demand_fraction_of_arrivals",
    "total_radiated_power_watt", "valid_sample_count",
    "per_ue_physical_bits_per_s_hz", "per_ue_valid_tti",
    "per_ue_delivered_bits_proxy", "per_ue_allocated_rb",
)


def main(path: Path) -> None:
    expected = json.loads(REFERENCE.read_text(encoding="utf-8"))
    actual = loadmat(path, simplify_cells=True)["metrics"]
    maxima = {}
    for field in FIELDS:
        a = np.asarray(actual[field], dtype=float).ravel()
        b = np.asarray(expected[field], dtype=float).ravel()
        if a.shape != b.shape:
            raise AssertionError((field, a.shape, b.shape))
        diff = float(np.nanmax(np.abs(a - b)))
        if diff > 1e-8:
            raise AssertionError((field, diff))
        maxima[field] = diff
    print("CHASI_EVALUATOR_PARITY_PASS")
    print(json.dumps(maxima, indent=2))


if __name__ == "__main__":
    main(Path(sys.argv[1]))
