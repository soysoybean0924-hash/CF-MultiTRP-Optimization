"""Single fixed A/Omega subproblem at two ADMM budgets on explicit input.

This is a diagnostic experiment, not a new formal solver configuration.
It never changes a stopping threshold, objective, or saved formal result.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from scipy.io import loadmat

from verify_chasi_formal_shared_input import as_cells
from chasi_formal_implementation import solver
from chasi_formal_implementation.scenario import Resource


def diagnose(fixture: Path, iterations: tuple[int, ...]) -> dict:
    data = loadmat(fixture, simplify_cells=True)
    cfg = data["cfg"]
    resources = []
    for item in as_cells(data["resources"]):
        resources.append(Resource(
            rb_start=int(item["rb_start"])-1,
            rb_count=int(item["rb_count"]),
            users=np.asarray(item["ueIds"], int).ravel()-1,
            serve=np.asarray(item["servingMask"], bool),
            h_est=np.asarray(item["H"], complex),
            h_true=np.asarray(item["H_true"], complex),
            error_var=np.asarray(item["C_stat"], complex),
            omitted_gain=np.asarray(item["omitted_gain"], float),
            age_ms=float(item["age_ms"]), measured=bool(item["measured"]),
            prior_gain=np.asarray(item["prior_gain"], float),
            tx_rb_count=int(item["tx_rb_count"])))
    start = [np.asarray(x, complex) for x in as_cells(data["initialPrecoder"])]
    hs = [r.h_est for r in resources]
    masks = [r.serve for r in resources]
    states = [solver._state(r.h_est, r.error_var, v)
              for r, v in zip(resources, start)]
    parts = [solver._quadratic_parts(r.h_est, r.error_var,
             state[0], state[1], v.shape)
             for r, state, v in zip(resources, states, start)]
    start_obj = solver._v_objective(resources, hs, masks, parts, start)
    budget = float(cfg["powerWattPerTrp"])
    report = {"input": str(fixture), "users": int(cfg["users"]),
              "scope": "fixed initial A/Omega; same explicit H/C/w; no outer update",
              "fixed_objective_start": start_obj, "runs": []}
    for count in iterations:
        import time
        t0 = time.perf_counter()
        candidate, trace, converged = solver._solve_v_admm(
            resources, hs, masks, parts, start, budget, count,
            int(cfg["cgIterations"]), float(cfg["epsAbs"]),
            float(cfg["epsRel"]), rho=.05)
        last = trace[-1]
        obj = solver._v_objective(resources, hs, masks, parts, candidate)
        report["runs"].append({
            "admm_cap": count, "actual_iterations": len(trace),
            "converged": converged, "seconds": time.perf_counter()-t0,
            "fixed_objective": obj, "fixed_objective_change": obj-start_obj,
            "primal": last["primal_residual"],
            "eps_primal": last["eps_primal"],
            "dual": last["dual_residual"],
            "eps_dual": last["eps_dual"],
            "cg_relative": last["cg_max_relative_residual"],
            "max_power_violation_watt": float(np.maximum(
                solver.power_by_trp(resources, candidate)-budget, 0).max()),
        })
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("fixture", type=Path)
    parser.add_argument("--iterations", type=int, nargs="+", default=[12, 24])
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    if sorted(set(args.iterations)) != args.iterations or args.iterations[0] < 1:
        parser.error("iteration caps must be positive, unique, increasing")
    report = diagnose(args.fixture, tuple(args.iterations))
    encoded = json.dumps(report, indent=2) + "\n"
    if args.report is not None:
        args.report.write_text(encoded, encoding="utf-8")
    print(encoded)
