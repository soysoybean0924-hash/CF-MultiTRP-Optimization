"""Locate the saved 210-UE Omega parity outlier without altering the gate.

Run with the explicit MAT exported by chasi_export_formal_shared_input.m.
The reference implementation is imported only by this offline diagnostic.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from scipy.io import loadmat

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from chasi_formal_implementation.solver import _effective, _state
from verify_chasi_formal_shared_input import as_cells


def analyze(path: Path, matlab_probe: Path | None = None) -> dict:
    saved = loadmat(path, simplify_cells=True)
    resources = as_cells(saved["resources"])
    precoders = as_cells(saved["finalPrecoder"])
    combiners = as_cells(saved["finalRxCombiner"])
    matrices = as_cells(saved["finalMseMatrix"])
    weights = as_cells(saved["finalMseWeight"])
    worst = (-1.0, None)
    for g, (resource, v, wm) in enumerate(zip(resources, precoders, weights)):
        wp = _state(resource["H"], resource["C_stat"], v)[1]
        delta = np.abs(wp - wm)
        flat = int(np.argmax(delta))
        if float(delta.flat[flat]) > worst[0]:
            worst = (float(delta.flat[flat]), (g, *np.unravel_index(flat, delta.shape)))
    absolute, indices = worst
    group, local_ue, row, col = map(int, indices)
    r = resources[group]
    v = precoders[group]
    u_ml = combiners[group][local_ue]
    e_ml = matrices[group][local_ue]
    w_ml = weights[group][local_ue]
    u_py, w_py, _ = _state(r["H"], r["C_stat"], v)
    k = local_ue
    effective = _effective(r["H"], v)
    wanted = effective[k, k]
    wanted_sequential = np.zeros_like(wanted)
    for trp in range(r["H"].shape[1]):
        wanted_sequential += r["H"][k,trp] @ v[trp,k]
    power = np.sum(np.abs(v)**2, axis=(1, 2, 3))
    covariance = np.eye(r["H"].shape[2], dtype=complex)
    covariance += np.einsum("irq,isq->rs", effective[k], effective[k].conj())
    covariance += np.einsum("l,lrs->rs", power, r["C_stat"][k])

    def mse(u):
        result = np.eye(v.shape[-1]) - u.conj().T @ wanted - wanted.conj().T @ u
        result += u.conj().T @ covariance @ u
        return (result + result.conj().T) / 2

    e_common_u = mse(u_ml)
    e_python_u = mse(u_py[k])
    w_common_e = np.linalg.solve(e_ml, np.eye(e_ml.shape[0]))
    global_ue = int(np.asarray(r["ueIds"]).ravel()[k])
    result = {
        "input": str(path), "group_one_based": group + 1,
        "local_ue_one_based": local_ue + 1, "global_ue_one_based": global_ue,
        "omega_element_one_based": [row + 1, col + 1],
        "omega_absolute_error": absolute,
        "omega_relative_element_error": absolute / max(abs(w_ml[row, col]), 1e-30),
        "omega_relative_frobenius": float(np.linalg.norm(w_py[k]-w_ml) / np.linalg.norm(w_ml)),
        "omega_matlab_frobenius": float(np.linalg.norm(w_ml)),
        "combiner_max_abs_error": float(np.max(np.abs(u_py[k]-u_ml))),
        "channel_max_abs": float(np.max(np.abs(r["H"][k]))),
        "precoder_max_abs": float(np.max(np.abs(v[:,k]))),
        "wanted_max_abs": float(np.max(np.abs(wanted))),
        "mse_python_u_vs_matlab_max_abs": float(np.max(np.abs(e_python_u-e_ml))),
        "mse_common_matlab_u_max_abs": float(np.max(np.abs(e_common_u-e_ml))),
        "omega_from_same_matlab_e_max_abs": float(np.max(np.abs(w_common_e-w_ml))),
        "omega_python_vs_inverse_matlab_e_max_abs": float(np.max(np.abs(w_py[k]-w_common_e))),
        "mse_condition_2": float(np.linalg.cond(e_ml)),
        "covariance_condition_2": float(np.linalg.cond(covariance)),
        "mse_hermitian_defect": float(np.linalg.norm(e_ml-e_ml.conj().T)),
        "omega_hermitian_defect": float(np.linalg.norm(w_ml-w_ml.conj().T)),
        "mse_min_eigenvalue": float(np.min(np.linalg.eigvalsh(e_ml))),
        "omega_linear_residual": float(np.linalg.norm(e_ml@w_ml-np.eye(e_ml.shape[0]))),
        "original_absolute_gate": 1e-5,
        "original_gate_pass": absolute <= 1e-5,
    }
    if matlab_probe is not None:
        probe = loadmat(matlab_probe, simplify_cells=True)
        result["matlab_saved_recomputed_omega_max_abs"] = float(np.max(np.abs(
            probe["recomputedOmega"]-probe["savedOmega"])))
        result["current_matlab_omega_vs_python_max_abs"] = float(np.max(np.abs(
            probe["recomputedOmega"]-w_py[k])))
        result["current_matlab_e_vs_python_max_abs"] = float(np.max(np.abs(
            probe["recomputedE"]-e_python_u)))
        result["wanted_cross_language_max_abs"] = float(np.max(np.abs(
            wanted-probe["wanted"])))
        result["wanted_python_sequential_vs_matlab_max_abs"] = float(np.max(np.abs(
            wanted_sequential-probe["wanted"])))
        result["wanted_einsum_vs_sequential_max_abs"] = float(np.max(np.abs(
            wanted-wanted_sequential)))
        result["covariance_cross_language_max_abs"] = float(np.max(np.abs(
            covariance-probe["rxCovariance"])))
        result["covariance_relative_frobenius"] = float(np.linalg.norm(
            covariance-probe["rxCovariance"])/np.linalg.norm(probe["rxCovariance"]))
    return result


if __name__ == "__main__":
    report = analyze(Path(sys.argv[1]), Path(sys.argv[2]) if len(sys.argv)>2 else None)
    print(json.dumps(report, indent=2))
