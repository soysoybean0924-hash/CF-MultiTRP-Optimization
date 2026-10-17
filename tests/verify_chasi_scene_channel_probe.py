"""Independent numeric check of saved MATLAB H/C on identical explicit arrays.

The observation noises were not saved. This checks posterior covariance exactly
and the realized estimation error statistically, not elementwise H_est parity.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from scipy.io import loadmat


def check(path: Path) -> dict[str, float | int | str]:
    m = loadmat(path, simplify_cells=True)
    truth = np.asarray(m["H_true"])
    estimate = np.asarray(m["H_est"])
    covariance = np.asarray(m["errorCovariance"])
    gain = np.asarray(m["priorGain"])
    omitted = np.asarray(m["omittedGain"])
    assert truth.shape == estimate.shape
    assert truth.shape[:3] == covariance.shape[:3]
    assert truth.shape[2:] == (4, 64)
    assert covariance.shape[2:] == (4, 4)
    assert gain.shape == omitted.shape == truth.shape[:2]
    rows = np.asarray(m["srsRxRows"], dtype=int).ravel() - 1
    pilot_snr = float(m["pilotSnrDb"])
    csi_snr = float(m["csiRsSnrDb"])
    age = float(m["ageMs"])
    csi_age = float(m["csiAgeMs"])
    coherence = float(m["ageCoherenceMs"])
    measured = bool(m["measured"])
    rx_corr = 0.35 ** np.abs(np.arange(4)[:, None] - np.arange(4)[None, :])
    max_relative_covariance_error = 0.0
    whitened_sum = np.zeros((4, 4), complex)
    samples = 0
    for local_ue_idx, trp_idx in np.argwhere(omitted == 0):
        beta = float(gain[local_ue_idx, trp_idx])
        csi_noise = beta / (10 ** (csi_snr / 10)) * np.exp(2 * csi_age / coherence)
        precision = np.linalg.inv(beta * rx_corr) + np.eye(4) / csi_noise
        if measured:
            pilot_noise = beta / (10 ** (pilot_snr / 10)) * np.exp(2 * age / coherence)
            precision[rows, rows] += 1 / pilot_noise
        predicted = np.linalg.inv(precision)
        actual = covariance[local_ue_idx, trp_idx]
        relative = np.linalg.norm(actual - predicted) / np.linalg.norm(predicted)
        max_relative_covariance_error = max(max_relative_covariance_error, relative)
        error = truth[local_ue_idx, trp_idx] - estimate[local_ue_idx, trp_idx]
        whitened = np.linalg.solve(np.linalg.cholesky(predicted), error)
        whitened_sum += whitened @ whitened.conj().T
        samples += error.shape[1]
    assert samples > 0
    whitened_covariance = whitened_sum / samples
    whitened_error = np.linalg.norm(whitened_covariance - np.eye(4)) / 2
    assert max_relative_covariance_error < 1e-6
    assert whitened_error < 0.08
    return {
        "modeled_links": samples // 64,
        "complex_column_samples": samples,
        "max_relative_posterior_covariance_error": max_relative_covariance_error,
        "whitened_error_covariance_relative_fro": float(whitened_error),
        "scope": "saved explicit H_true/H_est/C; no shared observation-noise fixture",
    }


if __name__ == "__main__":
    print(json.dumps(check(Path(sys.argv[1])), indent=2))
