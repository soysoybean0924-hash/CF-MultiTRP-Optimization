"""Independent Python checks on an explicit saved native MATLAB scene.

The fixture is exported by chasi_export_formal_shared_input.m. This script is
offline verification; neither script is on the formal chasi_run call path.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from types import SimpleNamespace
import sys

import h5py
import numpy as np
from scipy.io import loadmat

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from chasi_formal_implementation import solver
from chasi_formal_implementation.config import Config
from chasi_formal_implementation.evaluate import evaluate
from chasi_formal_implementation.scenario import Resource, Scenario


# Frozen before seeing the results of this full-scale comparison.
TOL = {
    "initial_objective_abs": 1e-6,
    "final_fixed_precoder_state_max_abs": 1e-5,
    "initial_state_max_abs": 1e-5,
    "final_fixed_precoder_evaluation_abs": 1e-4,
    "full_objective_abs": 1e-4,
    "full_precoder_max_abs": 2e-3,
    "full_true_sum_se_abs": 1e-4,
    "power_violation_watt": 1e-6,
    "initial_quadratic_max_abs": 1e-4,
    "admm_trace_max_abs": 1e-4,
    "cg_trace_max_abs": 1e-3,
}


def as_cells(value):
    return list(np.ravel(value))


def max_blocks(actual, expected):
    return max(float(np.max(np.abs(np.asarray(a) - np.asarray(b))))
               for a, b in zip(actual, expected))


def load_traffic(path: Path, num_users: int, duration: int):
    with h5py.File(path, "r") as data:
        result = []
        for name in ("busy", "tail", "terminal"):
            array = np.asarray(data["traffic"][name]).astype(bool)
            if array.shape == (duration, num_users):
                array = array.T
            assert array.shape == (num_users, duration), (name, array.shape)
            result.append(array)
        return tuple(result)


def check(run_dir: Path, fixture: Path, solve_full: bool):
    data = loadmat(fixture, simplify_cells=True)
    saved = json.loads((run_dir / "summary.json").read_text(encoding="utf-8"))
    config = saved["config"]
    branch = saved["branches"]["matrix_statistical"]
    num_users = int(config["users"])
    cfg = Config(
        users_per_cell=int(config["usersPerCell"]), seed=int(config["seed"]),
        rank=int(config["rank"]), solver="matrix_statistical",
        outer_iterations=int(config["outerIterations"]),
        admm_iterations=int(config["admmIterations"]),
        cg_iterations=int(config["cgIterations"]),
        power_watt_per_trp=float(config["powerWattPerTrp"]),
        noise_watt_per_rb=float(config["noiseWattPerRb"]),
        prb_utilization=float(config["prbUtilization"]),
        schedule_mode=str(config["scheduleMode"]),
        users_per_active_cell_rb=int(config["usersPerActiveCellRb"]),
        srs_mode=str(config["srsMode"]),
        eps_abs=float(config["epsAbs"]), eps_rel=float(config["epsRel"]),
        outer_rel_tol=float(config["outerRelTol"]),
        outer_precoder_rel_tol=float(config["outerPrecoderRelTol"]),
        pf_rate_floor_bits_per_s_hz=float(config["pfRateFloorBitsPerSHz"]),
        initialization_mode=str(config["initializationMode"]),
        initialization_seed=int(config["initializationSeed"]),
        traffic_model=str(config["trafficModel"]),
        traffic_load=float(config["trafficLoad"]),
        duration_tti=int(config["durationTti"]),
        tti_ms=float(config["ttiMs"]), scs_hz=float(config["scsHz"]),
    )
    cfg.validate()
    assert cfg.users == num_users
    resources = []
    for item in as_cells(data["resources"]):
        ids = np.asarray(item["ueIds"], dtype=int).ravel() - 1
        resources.append(Resource(
            rb_start=int(item["rb_start"]) - 1,
            rb_count=int(item["rb_count"]), users=ids,
            serve=np.asarray(item["servingMask"], dtype=bool),
            h_est=np.asarray(item["H"], dtype=np.complex128),
            h_true=np.asarray(item["H_true"], dtype=np.complex128),
            error_var=np.asarray(item["C_stat"], dtype=np.complex128),
            omitted_gain=np.asarray(item["omitted_gain"], dtype=float),
            age_ms=float(item["age_ms"]), measured=bool(item["measured"]),
            prior_gain=np.asarray(item["prior_gain"], dtype=float),
            tx_rb_count=int(item["tx_rb_count"]),
        ))
    assert len(resources) == 17
    manifest = json.loads((run_dir / "scene_manifest.json").read_text())
    for g, item in enumerate(manifest["groups"]):
        assert np.array_equal(resources[g].users + 1, item["ueIds"])
        assert np.array_equal(np.flatnonzero(resources[g].serve[:, 0]) + 1,
                              item["serving_trps_by_user"][0])
        assert resources[g].tx_rb_count == item["tx_rb_count"]
    scene = Scenario(cfg, np.asarray(manifest["trp_xy_m"]),
                     np.asarray(manifest["ue_xy_m"]),
                     np.asarray(manifest["ue_home_trp"], dtype=int) - 1,
                     resources, [],
                     np.asarray(saved["scenario"]["allocated_prb_fraction_by_trp"]), {})
    initial = [np.asarray(v, dtype=np.complex128) for v in as_cells(data["initialPrecoder"])]
    final = [np.asarray(v, dtype=np.complex128) for v in as_cells(data["finalPrecoder"])]
    assert all(v.shape == (21, len(r.users), 64, cfg.rank)
               for r, v in zip(resources, initial))
    assert all(np.max(np.abs(v[~r.serve])) == 0
               for r, v in zip(resources, final))
    initial_states = [solver._state(r.h_est, r.error_var, v)
                      for r, v in zip(resources, initial)]
    initial_state_errors = {
        "rxCombiner": max_blocks([x[0] for x in initial_states],
                                 as_cells(data["initialRxCombiner"])),
        "mseWeight": max_blocks([x[1] for x in initial_states],
                                as_cells(data["initialMseWeight"])),
        "mseMatrix": max_blocks([np.linalg.inv(x[1]) for x in initial_states],
                                as_cells(data["initialMseMatrix"])),
    }
    initial_snapshot = solver._objective_snapshot(
        scene, resources, initial_states, "matrix_statistical")
    initial_error = abs(initial_snapshot[0] - float(data["initialObjective"]))
    current_initial_error = abs(initial_snapshot[0] - float(data.get(
        "regeneratedInitialObjective", data["initialObjective"])))
    quadratic_errors = {}
    if "initialQuadraticProbe" in data:
        probes = as_cells(data["initialQuadraticProbe"])
        for key in ("M", "B", "D", "quadraticAppliedToPrecoder"):
            quadratic_errors[key] = 0.0
        for resource, v, state, user_weight, probe in zip(
                resources, initial, initial_states, initial_snapshot[4], probes):
            m, b, d = solver._quadratic_parts(
                resource.h_est, resource.error_var, state[0], state[1],
                v.shape, user_weight)
            qv = solver._q_apply(resource.h_est, m, d, v, resource.serve)
            for key, actual in (("M", m), ("B", b), ("D", d),
                                ("quadraticAppliedToPrecoder", qv)):
                quadratic_errors[key] = max(
                    quadratic_errors[key],
                    float(np.max(np.abs(actual - np.asarray(probe[key])))))
    final_states = [solver._state(r.h_est, r.error_var, v)
                    for r, v in zip(resources, final)]
    final_combiner = as_cells(data["finalRxCombiner"])
    final_weight = as_cells(data["finalMseWeight"])
    final_mse = as_cells(data["finalMseMatrix"])
    state_errors = {
        "rxCombiner": max_blocks([x[0] for x in final_states], final_combiner),
        "mseWeight": max_blocks([x[1] for x in final_states], final_weight),
        "mseMatrix": max_blocks([np.linalg.inv(x[1]) for x in final_states], final_mse),
    }
    state_error = max(state_errors.values())
    current_state_errors = {}
    if "currentFinalMseWeight" in data:
        current_state_errors = {
            "rxCombiner": max_blocks([x[0] for x in final_states],
                                     as_cells(data["currentFinalRxCombiner"])),
            "mseWeight": max_blocks([x[1] for x in final_states],
                                    as_cells(data["currentFinalMseWeight"])),
            "mseMatrix": max_blocks([np.linalg.inv(x[1]) for x in final_states],
                                    as_cells(data["currentFinalMseMatrix"])),
        }
    max_weight_magnitude = max(float(np.max(np.abs(w))) for w in final_weight)
    fixed_snapshot = solver._objective_snapshot(
        scene, resources, final_states, "matrix_statistical")
    fixed_objective_error = abs(fixed_snapshot[0] - branch["optimization_objective"])
    traffic = load_traffic(run_dir / "scene.mat", num_users, cfg.duration_tti)
    fixed_eval = evaluate(scene, SimpleNamespace(precoders=final), traffic)
    evaluation_fields = ("physical_sum_bits_per_s_hz",
                         "experience_mean_mbps_valid_ues",
                         "experience_bottom5_mbps_valid_ues",
                         "actual_prb_fraction_mean")
    eval_error = max(abs(fixed_eval[k] - branch["evaluation"][k])
                     for k in evaluation_fields)
    power_violation = float(np.maximum(
        solver.power_by_trp(resources, final) - cfg.power_watt_per_trp, 0).max())
    result = {
        "users": num_users,
        "input": str(fixture),
        "h_axis_order": "local UE, TRP, DL Rx, TRP Tx",
        "group_ue_count_range": [min(len(r.users) for r in resources),
                                 max(len(r.users) for r in resources)],
        "initial_objective_abs": initial_error,
        "current_initial_objective_abs": current_initial_error,
        "initial_state_components_max_abs": initial_state_errors,
        "final_fixed_precoder_state_max_abs": state_error,
        "final_fixed_precoder_state_components": state_errors,
        "current_fixed_precoder_state_components": current_state_errors,
        "current_fixed_state_pass_original_gate": bool(current_state_errors) and
            max(current_state_errors.values()) <= TOL["final_fixed_precoder_state_max_abs"],
        "historical_initial_matches_regenerated": bool(data.get(
            "initialMatchesSavedTrajectory", True)),
        "mse_weight_relative_to_max_magnitude":
            state_errors["mseWeight"] / max(1.0, max_weight_magnitude),
        "final_fixed_precoder_objective_abs": fixed_objective_error,
        "final_fixed_precoder_evaluation_abs": eval_error,
        "power_violation_watt": power_violation,
        "initial_quadratic_components_max_abs": quadratic_errors,
        "tolerances": TOL,
    }
    if solve_full:
        import time
        start = time.perf_counter()
        solution = solver.solve(scene, "matrix_statistical", initial_precoders=initial)
        result["python_solver_seconds"] = time.perf_counter() - start
        result["full_objective_abs"] = abs(
            solution.optimization_objective - branch["optimization_objective"])
        result["full_precoder_max_abs"] = max_blocks(solution.precoders, final)
        py_eval = evaluate(scene, solution, traffic)
        result["full_true_sum_se_abs"] = abs(
            py_eval["physical_sum_bits_per_s_hz"] -
            branch["evaluation"]["physical_sum_bits_per_s_hz"])
        result["python_stop_reason"] = solution.reason
        result["matlab_stop_reason"] = branch["reason"]
        trace_errors = {key: 0.0 for key in (
            "objective", "accepted_step", "precoder_change", "primal",
            "dual", "eps_primal", "eps_dual", "cg_relative")}
        matlab_trace = branch["trajectory"]
        assert len(solution.trajectory) == len(matlab_trace)
        for py_outer, ml_outer in zip(solution.trajectory, matlab_trace):
            trace_errors["objective"] = max(
                trace_errors["objective"],
                abs(py_outer["optimization_objective"] - ml_outer["objective"]))
            if "admm_trace" not in py_outer:
                continue
            for py_key, ml_key in (("accepted_step", "accepted_step"),
                                   ("precoder_change", "precoder_relative_change")):
                trace_errors[py_key] = max(
                    trace_errors[py_key], abs(py_outer[ml_key] - ml_outer[py_key]))
            assert len(py_outer["admm_trace"]) == len(ml_outer["admm_trace"])
            for py_inner, ml_inner in zip(py_outer["admm_trace"],
                                          ml_outer["admm_trace"]):
                for py_key, ml_key in (("primal", "primal_residual"),
                                       ("dual", "dual_residual"),
                                       ("eps_primal", "eps_primal"),
                                       ("eps_dual", "eps_dual"),
                                       ("cg_relative", "cg_max_relative_residual")):
                    trace_errors[py_key] = max(
                        trace_errors[py_key], abs(py_inner[ml_key] - ml_inner[py_key]))
        result["full_trace_components_max_abs"] = trace_errors
        result["full_scale_pass"] = (
            result["full_objective_abs"] <= TOL["full_objective_abs"] and
            result["full_precoder_max_abs"] <= TOL["full_precoder_max_abs"] and
            result["full_true_sum_se_abs"] <= TOL["full_true_sum_se_abs"] and
            max(v for k, v in trace_errors.items() if k != "cg_relative")
            <= TOL["admm_trace_max_abs"] and
            trace_errors["cg_relative"] <= TOL["cg_trace_max_abs"] and
            solution.reason == branch["reason"])
    result["fixed_input_pass"] = (
        initial_error <= TOL["initial_objective_abs"] and
        max(initial_state_errors.values()) <= TOL["initial_state_max_abs"] and
        state_error <= TOL["final_fixed_precoder_state_max_abs"] and
        max(fixed_objective_error, eval_error) <= TOL["final_fixed_precoder_evaluation_abs"] and
        power_violation <= TOL["power_violation_watt"])
    if quadratic_errors:
        result["fixed_input_pass"] &= (
            max(quadratic_errors.values()) <= TOL["initial_quadratic_max_abs"])
    result["current_fixed_input_pass"] = (
        result["current_fixed_state_pass_original_gate"] and
        current_initial_error <= TOL["initial_objective_abs"] and
        max(initial_state_errors.values()) <= TOL["initial_state_max_abs"] and
        max(fixed_objective_error, eval_error) <= TOL["final_fixed_precoder_evaluation_abs"] and
        power_violation <= TOL["power_violation_watt"] and
        (not quadratic_errors or
         max(quadratic_errors.values()) <= TOL["initial_quadratic_max_abs"]))
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("run_dir", type=Path)
    parser.add_argument("fixture", type=Path)
    parser.add_argument("--solve-full", action="store_true")
    parser.add_argument("--report", type=Path,
                        help="Write the exact pass/fail record as lightweight JSON")
    args = parser.parse_args()
    report = check(args.run_dir, args.fixture, args.solve_full)
    if args.report is not None:
        args.report.write_text(json.dumps(report, indent=2) + "\n",
                               encoding="utf-8")
    print(json.dumps(report, indent=2))
    fixed_pass = (report["current_fixed_input_pass"]
                  if report["current_fixed_precoder_state_components"]
                  else report["fixed_input_pass"])
    if not fixed_pass or (args.solve_full and not report["full_scale_pass"]):
        raise SystemExit(1)
