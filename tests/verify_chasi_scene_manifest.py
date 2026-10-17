"""Read-only, explicit-output checks of a native MATLAB CHASI scene manifest.

This verifies deterministic geometry, identity, resource and timestamp rules.
It does not regenerate MATLAB random samples or validate H_est samples.
"""
from __future__ import annotations

import json
import math
import sys
from pathlib import Path


def check(run_dir: Path) -> dict[str, float | int | str]:
    config = json.loads((run_dir / "config.json").read_text(encoding="utf-8"))
    manifest = json.loads((run_dir / "scene_manifest.json").read_text(encoding="utf-8"))
    trp_xy = manifest["trp_xy_m"]
    ue_xy = manifest["ue_xy_m"]
    home = manifest["ue_home_trp"]
    groups = manifest["groups"]
    assert manifest["indexing"] == "MATLAB one-based"
    assert len(trp_xy) == config["trps"] == 21
    assert len(ue_xy) == len(home) == config["users"]
    assert len(groups) == config["srsHops"] == 17

    sites = [[450.0, 450.0]] + [
        [450.0 + 300.0 * math.cos(i * math.pi / 3),
         450.0 + 300.0 * math.sin(i * math.pi / 3)]
        for i in range(6)
    ]
    max_site_error = 0.0
    for site_idx, site_xy in enumerate(sites):
        for trp_idx in range(3 * site_idx, 3 * site_idx + 3):
            max_site_error = max(max_site_error, math.dist(trp_xy[trp_idx], site_xy))
    assert max_site_error < 1e-9
    counts_by_home = [0] * 21
    min_radius = float("inf")
    max_radius = 0.0
    max_sector_excess = 0.0
    for k, (point, one_based_trp) in enumerate(zip(ue_xy, home)):
        assert isinstance(one_based_trp, int) and 1 <= one_based_trp <= 21, k
        counts_by_home[one_based_trp - 1] += 1
        center = trp_xy[one_based_trp - 1]
        radius = math.dist(point, center)
        angle = math.atan2(point[1] - center[1], point[0] - center[0])
        boresight = ((one_based_trp - 1) % 3) * 2 * math.pi / 3
        sector_offset = abs(math.atan2(math.sin(angle - boresight),
                                       math.cos(angle - boresight)))
        min_radius = min(min_radius, radius)
        max_radius = max(max_radius, radius)
        max_sector_excess = max(max_sector_excess, sector_offset - math.pi / 3)
        assert 25 - 1e-9 <= radius <= 150 + 1e-9, (k, radius)
        assert sector_offset <= math.pi / 3 + 1e-9, (k, sector_offset)
    assert counts_by_home == [config["usersPerCell"]] * 21

    next_rb = 1
    service_links = 0
    scheduled_occurrences = 0
    for group_idx, group in enumerate(groups):
        assert group["rb_start"] == next_rb
        assert group["rb_count"] == (16 if group_idx < 16 else 17)
        next_rb += group["rb_count"]
        assert 0 <= group["tx_rb_count"] <= group["rb_count"]
        assert abs(group["resourceWeightNu"] -
                   group["tx_rb_count"] / config["rbTotal"]) < 1e-14
        ids = group["ueIds"]
        links = group["serving_trps_by_user"]
        assert len(ids) == len(links) and len(set(ids)) == len(ids)
        first_tti = group_idx * 20
        measured = config["decisionTti"] >= first_tti
        assert group["measured"] == measured
        measured_at = (first_tti +
                       (config["decisionTti"] - first_tti) //
                       config["srsPeriodTti"] * config["srsPeriodTti"])
        expected_age = ((config["decisionTti"] - measured_at) *
                        config["ttiMs"] if measured else -1)
        assert abs(group["age_ms"] - expected_age) < 1e-12
        for one_based_ue, service in zip(ids, links):
            assert 1 <= one_based_ue <= config["users"]
            assert home[one_based_ue - 1] in service
            assert 1 <= len(service) <= config["serviceTrps"]
            assert len(set(service)) == len(service)
            assert all(1 <= trp <= 21 for trp in service)
            service_links += len(service)
        scheduled_occurrences += len(ids)
    assert next_rb - 1 == config["rbTotal"] == 273

    return {
        "users": len(ue_xy),
        "trps": len(trp_xy),
        "groups": len(groups),
        "scheduled_group_ue_occurrences": scheduled_occurrences,
        "service_links": service_links,
        "max_site_coordinate_error_m": max_site_error,
        "min_ue_home_distance_m": min_radius,
        "max_ue_home_distance_m": max_radius,
        "max_sector_boundary_excess_rad": max_sector_excess,
        "data_rb": next_rb - 1,
        "nominal_17_by_16_srs_rb": 17 * 16,
        "scope": "saved explicit geometry/identity/resource/time rules; not random-channel parity",
    }


if __name__ == "__main__":
    print(json.dumps(check(Path(sys.argv[1])), ensure_ascii=False, indent=2))
