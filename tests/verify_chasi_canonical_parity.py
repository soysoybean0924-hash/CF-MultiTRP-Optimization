"""Read-only Python oracle for freshly exported canonical MATLAB fixture runs."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from scipy.io import loadmat


ROOT = Path(__file__).resolve().parents[1]
FIXTURE = (ROOT / "experiments/chasi_formal/migration_20261013/"
           "native_pf_20261014")
NAMES = ("rank1_nominal", "rank2_nominal", "rank2_uniform",
         "rank2_relative", "rank2_statistical")
TOLERANCE = {
    "objective_abs": 1e-6,
    "estimated_sum_abs": 1e-6,
    "true_sum_abs": 1e-6,
    "power_max_abs": 1e-6,
    "V_max_abs": 1e-5,
    "U_max_abs": 1e-5,
    "W_max_abs": 1e-4,
    "E_max_abs": 1e-4,
    "rate_max_abs": 1e-6,
    "per_ue_rate_max_abs": 1e-6,
    "trajectory_objective_max_abs": 1e-6,
    "accepted_step_max_abs": 0.0,
    "admm_primal_max_abs": 1e-4,
    "admm_dual_max_abs": 1e-4,
    "M_max_abs": 1e-8,
    "B_max_abs": 1e-8,
    "D_max_abs": 1e-8,
    "QV_max_abs": 1e-8,
}


def groups(value):
    """SciPy simplifies one cell to a dict, two cells to an object array."""
    return [value] if isinstance(value, dict) else list(np.ravel(value))


def max_diff(actual, expected):
    expected = np.asarray(expected)
    actual = np.asarray(actual).reshape(expected.shape)
    return float(np.max(np.abs(actual - expected))) if expected.size else 0.0


def check(output_dir: Path):
    reference = json.loads((FIXTURE / "python_reference.json").read_text())
    report = {}
    for name in NAMES:
        report[name] = {}
        for outer in (0, 2):
            py = reference[name][str(outer)]
            arrays = np.load(FIXTURE / f"{name}_python_outer{outer}.npz")
            mat = loadmat(output_dir / f"{name}_canonical_outer{outer}.mat",
                          simplify_cells=True)["out"]
            entry = {
                "objective_abs": abs(float(mat["optimization_objective"]) - py["objective"]),
                "estimated_sum_abs": abs(float(mat["estimated_sum_rate"]) - py["estimated_sum"]),
                "true_sum_abs": abs(float(mat["true_sum_rate"]) - py["true_sum"]),
                "power_max_abs": max_diff(mat["power"], py["power"]),
            }
            for field in ("V", "U", "W", "E"):
                entry[f"{field}_max_abs"] = 0.0
            entry["rate_max_abs"] = 0.0
            entry["per_ue_rate_max_abs"] = 0.0
            all_rate = np.zeros(np.asarray(mat["estimated_per_ue_rate"]).size)
            fixture_input = loadmat(FIXTURE / f"{name}_input.mat",
                                    simplify_cells=True)
            resources = groups(fixture_input["resources"])
            for g in range(2):
                weight = float(resources[g]["tx_rb_count"]) / 273.0
                w = np.asarray(arrays[f"W{g}"])
                e = np.linalg.inv(w)
                expected_rate = -np.linalg.slogdet(e)[1] / np.log(2)
                ids = np.asarray(resources[g]["ue_ids"], dtype=int).ravel() - 1
                all_rate[ids] += weight * expected_rate
                for field, public in (("V", "precoder"),
                                      ("U", "rxCombiner"),
                                      ("W", "mseWeight")):
                    actual = groups(mat[public])[g]
                    entry[f"{field}_max_abs"] = max(
                        entry[f"{field}_max_abs"],
                        max_diff(actual, arrays[f"{field}{g}"]))
                entry["E_max_abs"] = max(entry["E_max_abs"],
                    max_diff(groups(mat["mseMatrix"])[g], e))
                entry["rate_max_abs"] = max(entry["rate_max_abs"],
                    max_diff(groups(mat["rate"])[g], expected_rate))
            entry["per_ue_rate_max_abs"] = max_diff(
                mat["estimated_per_ue_rate"], all_rate)
            trajectory = groups(mat["trajectory"])
            if len(trajectory) != len(py["trajectory"]):
                raise AssertionError((name, outer, "trajectory length"))
            for field in ("trajectory_objective_max_abs", "accepted_step_max_abs",
                          "admm_primal_max_abs", "admm_dual_max_abs"):
                entry[field] = 0.0
            for current, expected in zip(trajectory, py["trajectory"]):
                entry["trajectory_objective_max_abs"] = max(
                    entry["trajectory_objective_max_abs"],
                    abs(float(current["objective"]) - expected["objective"]))
                if expected["accepted_step"] is not None:
                    entry["accepted_step_max_abs"] = max(
                        entry["accepted_step_max_abs"],
                        abs(float(current["accepted_step"]) - expected["accepted_step"]))
                    last = current["admm_last"]
                    entry["admm_primal_max_abs"] = max(
                        entry["admm_primal_max_abs"],
                        abs(float(last["primal"]) - expected["primal"]))
                    entry["admm_dual_max_abs"] = max(
                        entry["admm_dual_max_abs"],
                        abs(float(last["dual"]) - expected["dual"]))
            expected_reason = py["reason"].replace(
                "inexact_v_step_no_proxy_improvement",
                "inexact_precoder_step_no_proxy_improvement")
            if str(mat["reason"]) != expected_reason:
                raise AssertionError((name, outer, "stopping reason",
                                      mat["reason"], expected_reason))
            if outer == 2:
                operator = np.load(FIXTURE / f"{name}_python_operator.npz")
                for field in ("M", "B", "D", "QV"):
                    entry[f"{field}_max_abs"] = 0.0
                    for g, probe in enumerate(groups(mat["fixed_receiver_weight_probe"])):
                        actual_field = ("quadraticAppliedToPrecoder"
                                        if field == "QV" else field)
                        entry[f"{field}_max_abs"] = max(
                            entry[f"{field}_max_abs"],
                            max_diff(probe[actual_field], operator[f"{field}{g}"]))
            for metric, value in entry.items():
                if value > TOLERANCE[metric]:
                    raise AssertionError((name, outer, metric, value,
                                          TOLERANCE[metric]))
            report[name][str(outer)] = entry
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    output_dir = args.output_dir.resolve()
    if output_dir == FIXTURE.resolve() or FIXTURE.resolve() in output_dir.parents:
        parser.error("output_dir must not be inside the historical fixture")
    result = check(output_dir)
    (output_dir / "parity_report.json").write_text(
        json.dumps({"tolerances": TOLERANCE, "cases": result}, indent=2))
    maxima = {key: max(case.get(key, 0.0) for item in result.values()
                       for case in item.values()) for key in TOLERANCE}
    print("CHASI_CANONICAL_PARITY_PASS: five fixtures, outer 0 and 2")
    print(json.dumps(maxima, indent=2))
