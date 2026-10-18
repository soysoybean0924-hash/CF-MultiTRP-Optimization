"""Offline 210-UE frozen-channel/beam replay on saved MATLAB inputs.

Zero speed and a frozen beam isolate queue and physical-rate aggregation.
The stochastic CSI trajectory and online WMMSE are outside this probe.
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from types import SimpleNamespace

import numpy as np
from scipy.io import loadmat

from verify_chasi_formal_shared_input import as_cells, load_traffic
from chasi_formal_implementation.config import Config
from chasi_formal_implementation.scenario import Resource, Scenario
from chasi_formal_implementation import time_evolution


# Absolute thresholds selected before the first 210-UE dynamic result.
TOL = {"per_ue_mbit": 1e-4, "experience_mbps": 1e-4,
       "physical_sum_se": 1e-4, "prb_fraction": 1e-8,
       "power_violation_watt": 1e-6}


def check(run_dir: Path, static_fixture: Path, dynamic_fixture: Path):
    saved = json.loads((run_dir / "summary.json").read_text(encoding="utf-8"))
    config = saved["config"]
    cfg = Config(users_per_cell=int(config["usersPerCell"]),
                 seed=int(config["seed"]), rank=int(config["rank"]),
                 speed_kmh=0.0, duration_tti=340,
                 power_watt_per_trp=float(config["powerWattPerTrp"]),
                 tti_ms=float(config["ttiMs"]), scs_hz=float(config["scsHz"]),
                 pilot_snr_db=float(config["pilotSnrDb"]),
                 csi_rs_snr_db=float(config["csiRsSnrDb"]),
                 csi_rs_period_tti=int(config["csiRsPeriodTti"]))
    cfg.validate()
    data = loadmat(static_fixture, simplify_cells=True)
    manifest = json.loads((run_dir / "scene_manifest.json").read_text())
    resources = []
    for item in as_cells(data["resources"]):
        resources.append(Resource(
            rb_start=int(item["rb_start"]) - 1,
            rb_count=int(item["rb_count"]),
            users=np.asarray(item["ueIds"], dtype=int).ravel() - 1,
            serve=np.asarray(item["servingMask"], dtype=bool),
            h_est=np.asarray(item["H"], dtype=np.complex128),
            h_true=np.asarray(item["H_true"], dtype=np.complex128),
            error_var=np.asarray(item["C_stat"], dtype=np.complex128),
            omitted_gain=np.asarray(item["omitted_gain"], dtype=float),
            age_ms=float(item["age_ms"]), measured=bool(item["measured"]),
            prior_gain=np.asarray(item["prior_gain"], dtype=float),
            tx_rb_count=int(item["tx_rb_count"])))
    scene = Scenario(cfg, np.asarray(manifest["trp_xy_m"]),
                     np.asarray(manifest["ue_xy_m"]),
                     np.asarray(manifest["ue_home_trp"], dtype=int) - 1,
                     resources, [],
                     np.asarray(saved["scenario"]["allocated_prb_fraction_by_trp"]),
                     {})
    precoders = [np.asarray(x, dtype=np.complex128)
                for x in as_cells(data["finalPrecoder"])]
    busy, tail, terminal = load_traffic(run_dir / "scene.mat", cfg.users, 340)
    matlab_data = loadmat(dynamic_fixture, simplify_cells=True)
    matlab = matlab_data["replay"]
    options = matlab_data["options"]
    original_traffic_samples = time_evolution.traffic_samples
    time_evolution.traffic_samples = lambda _: (busy, tail, terminal)
    try:
        python = time_evolution.simulate(
            scene, SimpleNamespace(precoders=precoders), window_tti=340,
            offered_mbps=float(options["offeredMbps"]),
            fast_period_tti=int(options["fastPeriodTti"]),
            slow_period_tti=int(options["slowPeriodTti"]),
            beam_policy="frozen")
    finally:
        time_evolution.traffic_samples = original_traffic_samples
    matlab_events = as_cells(matlab["events"])
    event_match = all(
        int(m["tti"]) == p["tti"] and
        int(m["srs_group"]) - 1 == p["srs_group"] and
        bool(m["csi_rs"]) == p["csi_rs"]
        for m, p in zip(matlab_events, python["events"]))
    assert len(matlab_events) == len(python["events"]) == 17
    errors = {
        "per_ue_delivered_mbit": float(np.max(np.abs(
            np.asarray(matlab["per_ue_delivered_mbit"]).ravel() -
            python["per_ue_delivered_mbit"]))),
        "experience_mean_mbps": abs(float(matlab["experience_mean_mbps_valid"]) -
                                    python["experience_mean_mbps_valid"]),
        "physical_sum_se": abs(float(matlab["physical_sum_bits_per_s_hz_time_mean"]) -
                               python["physical_sum_bits_per_s_hz_time_mean"]),
        "actual_prb_fraction": abs(float(matlab["actual_prb_fraction_mean"]) -
                                   python["actual_prb_fraction_mean"]),
        "power_violation_watt": abs(float(matlab["max_power_violation_watt"]) -
                                    python["max_power_violation_watt"]),
    }
    counts_match = all(int(matlab[name]) == python[name] for name in
                       ("valid_tti_total", "completed_bursts", "total_bursts"))
    passed = (event_match and counts_match and
              errors["per_ue_delivered_mbit"] <= TOL["per_ue_mbit"] and
              errors["experience_mean_mbps"] <= TOL["experience_mbps"] and
              errors["physical_sum_se"] <= TOL["physical_sum_se"] and
              errors["actual_prb_fraction"] <= TOL["prb_fraction"] and
              errors["power_violation_watt"] <= TOL["power_violation_watt"])
    return {"scope": "saved H/traffic, zero speed, frozen precoder; no online WMMSE",
            "users": cfg.users, "event_match": event_match,
            "count_match": counts_match, "errors": errors,
            "tolerances": TOL, "pass": passed}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("run_dir", type=Path)
    parser.add_argument("static_fixture", type=Path)
    parser.add_argument("dynamic_fixture", type=Path)
    args = parser.parse_args()
    result = check(args.run_dir, args.static_fixture, args.dynamic_fixture)
    print(json.dumps(result, indent=2))
    if not result["pass"]:
        raise SystemExit(1)
