"""Read saved Chasi results only; produce labelled presentation figures and CSVs.

No solver, scenario generator, or traffic simulator is invoked. The three
branches are compared only after checking their saved scene/resource/traffic
contract. The optional second-level panel uses a DIFFERENT frozen seed22 run.
"""
from __future__ import annotations

import csv
import hashlib
import json
from pathlib import Path

import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib import font_manager
import numpy as np

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
RUN = ROOT / "results/chasi_formal/b3b_uniform_relative210_seed20261027_20261013"
REPLAY = ROOT / "results/chasi_formal/protocol_candidate_replay_seed22_completion_20261013"
NAMES = ("matrix_pf_nominal", "matrix_pf_uniform_relative", "matrix_pf_statistical")
LABELS = ("名义PF", "统一相对误差PF", "异质误差PF")
COLORS = ("#245b91", "#bb7838", "#527f65")


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_csv(name, headers, rows):
    with (HERE / name).open("w", encoding="utf-8-sig", newline="") as stream:
        writer = csv.writer(stream)
        writer.writerow(headers)
        writer.writerows(rows)


def setup_font():
    available = {font.name for font in font_manager.fontManager.ttflist}
    choices = ["Microsoft YaHei", "SimHei", "Noto Sans CJK SC"]
    font = next((item for item in choices if item in available), None)
    if font is None:
        raise RuntimeError("No Chinese font found; figures would have missing glyphs")
    mpl.rcParams.update({
        "font.family": "sans-serif", "font.sans-serif": [font, "Arial", "DejaVu Sans"],
        "axes.unicode_minus": False,
        "pdf.fonttype": 42, "svg.fonttype": "none", "font.size": 9,
        "axes.spines.top": False, "axes.spines.right": False,
        "legend.frameon": False, "savefig.facecolor": "white",
    })
    return font


def save(fig, stem):
    fig.savefig(HERE / f"{stem}.png", dpi=360, bbox_inches="tight")
    fig.savefig(HERE / f"{stem}.pdf", bbox_inches="tight")
    fig.savefig(HERE / f"{stem}.svg", bbox_inches="tight")
    fig.savefig(HERE / f"{stem}.tiff", dpi=600, bbox_inches="tight")
    plt.close(fig)


def footer(fig, value):
    fig.text(0.02, 0.025, value, fontsize=6.7, color="#555555", va="bottom")


def axes(title, ylabel, xlabel="WMMSE轮（0为初始快照）"):
    fig, ax = plt.subplots(figsize=(7.2, 4.4))
    fig.subplots_adjust(left=.13, right=.97, top=.84, bottom=.27)
    ax.set_title(title, loc="left", fontsize=12, weight="bold")
    ax.set(xlabel=xlabel, ylabel=ylabel)
    ax.grid(alpha=.18)
    return fig, ax


def inverse_cdf(values):
    ordered = np.sort(np.asarray(values, float))
    return float(ordered[max(0, int(np.ceil(.05 * len(ordered))) - 1)])


def main():
    font = setup_font()
    summary = read(RUN / "summary.json")
    audit = read(RUN / "paired_error_ablation_audit.json")
    cfg = summary["config"]
    if cfg["seed"] != 20261027 or cfg["users_per_cell"] != 10:
        raise ValueError("Unexpected source run")
    if not audit["shared_per_ue_resource_and_traffic_arrays_verified"]:
        raise ValueError("Saved paired resource/traffic equality not verified")
    actual_hash = hashlib.sha256((RUN / "scene_manifest.json").read_bytes()).hexdigest()
    if actual_hash != summary["controlled_comparison_contract"]["scene_manifest_sha256"]:
        raise ValueError("Scene manifest hash mismatch")
    records = [summary["branches"][name] for name in NAMES]
    if any(r["status"] != "completed" for r in records):
        raise ValueError("Incomplete saved branch")
    if any(r["evaluation"]["users_total"] != 210 for r in records):
        raise ValueError("Unexpected user count")
    counts = [r["evaluation"]["users_with_valid_samples"] for r in records]
    if len(set(counts)) != 1:
        raise ValueError("Static sample counts differ")
    if any(len(r["evaluation"]["per_ue_experience_mbps"]) != 210 for r in records):
        raise ValueError("Missing per-UE values")
    branch = records[0]
    trajectory = branch["trajectory"]
    updates = [t for t in trajectory if "precoder_relative_change" in t]
    if len(trajectory) != 19 or len(updates) != 18:
        raise ValueError("Unexpected trajectory length or missing update values")
    meta = {
        "source_summary": str(RUN / "summary.json"),
        "source_sha256": hashlib.sha256((RUN / "summary.json").read_bytes()).hexdigest(),
        "scene_manifest_sha256": actual_hash,
        "source_code_sha256_at_run_start": summary["source_sha256_at_run_start"],
        "seed": cfg["seed"], "font": font, "rank": cfg["rank"],
        "budget_watt_per_trp": cfg["power_watt_per_trp"],
        "static_observation_window_tti": cfg["duration_tti"],
        "static_sample_count_per_branch": counts,
        "note": "Saved static 0.34-s capacity/traffic proxy; not formal UE-second RLC throughput",
    }
    subtitle = "seed=20261027｜名义PF｜210 UE｜固定调度/rank2｜存档轨迹"

    write_csv("fig01_pf_objective.csv", ["outer", "pf_objective_sum_ln_1_plus_R_over_floor"],
              [(t["outer"], t["optimization_objective"]) for t in trajectory])
    fig, ax = axes("01 估计信道PF目标随WMMSE轮变化", "Σ ln(1 + R_u / 0.001)（无量纲）")
    ax.plot([t["outer"] for t in trajectory], [t["optimization_objective"] for t in trajectory],
            "o-", color=COLORS[0], lw=2, ms=4)
    footer(fig, subtitle + "；末轮是更新后的目标快照；目标不是真信道验收指标")
    save(fig, "fig01_pf_objective")

    write_csv("fig02_v_change.csv", ["update_outer", "relative_V_change", "stop_threshold"],
              [(t["outer"], t["precoder_relative_change"], cfg["outer_precoder_rel_tol"])
               for t in updates])
    fig, ax = axes("02 每次V更新的相对变化", "||V新−V旧|| / max(1,||V旧||)", "执行V更新的WMMSE轮")
    ax.plot([t["outer"] for t in updates], [t["precoder_relative_change"] for t in updates],
            "o-", color=COLORS[0], lw=1.7, ms=4, label="相对V变化")
    ax.axhline(cfg["outer_precoder_rel_tol"], ls="--", color="#aa4d45", label="停止阈值 0.005")
    if any(t["precoder_relative_change"] <= 0 for t in updates):
        raise ValueError("Log axis requires positive saved V changes")
    ax.set_yscale("log")
    ax.legend()
    footer(fig, subtitle + "；实际停止还需目标变化和最近ADMM精度共同满足")
    save(fig, "fig02_v_change")

    write_csv("fig03_admm_end_residuals.csv",
              ["update_outer", "primal", "eps_primal", "dual", "eps_dual", "admm_iterations", "admm_converged"],
              [(t["outer"], t["primal_residual"], t["eps_primal"],
                t["dual_residual"], t["eps_dual"], t["admm_iterations"], t["admm_converged"])
               for t in updates])
    fig, ax = axes("03 各WMMSE轮结束时ADMM残差", "残差与各自阈值（对数坐标）", "执行V更新的WMMSE轮")
    x = [t["outer"] for t in updates]
    for key, threshold, color, label in (("primal_residual", "eps_primal", COLORS[0], "原始"),
                                          ("dual_residual", "eps_dual", COLORS[1], "对偶")):
        if any(t[key] <= 0 or t[threshold] <= 0 for t in updates):
            raise ValueError("Log axis requires positive residuals and thresholds")
        ax.plot(x, [t[key] for t in updates], "o-", color=color, ms=3.3, label=f"{label}残差")
        ax.plot(x, [t[threshold] for t in updates], "--", color=color, alpha=.7, label=f"{label}阈值")
    ax.set_yscale("log")
    ax.legend(ncol=2, fontsize=8)
    footer(fig, subtitle + "；每点是一次内层ADMM的末值，不是连续内层收敛轨迹")
    save(fig, "fig03_admm_end_residuals")

    powers = np.asarray(branch["per_trp_power_watt"], float)
    if powers.shape != (21,):
        raise ValueError("Missing TRP power vector")
    write_csv("fig04_trp_power.csv", ["trp_id_1based", "weighted_radiated_power_watt", "budget_watt"],
              [(i + 1, p, cfg["power_watt_per_trp"]) for i, p in enumerate(powers)])
    fig, ax = axes("04 最终21个TRP跨RB加权发射功率", "功率（W）", "TRP编号")
    ax.bar(np.arange(1, 22), powers, color=COLORS[0], width=.72)
    ax.axhline(cfg["power_watt_per_trp"], ls="--", color="#aa4d45", label="20 W预算")
    ax.set_xticks(np.arange(1, 22, 2)); ax.set_ylim(0, 21.8); ax.legend()
    footer(fig, "P_l = Σg (激活RB_g / 273) ||V_g[l]||²；seed27名义PF；辐射功率，不含电路/前传能耗")
    save(fig, "fig04_trp_power")

    per_ue = [np.asarray(r["evaluation"]["per_ue_experience_mbps"], float) for r in records]
    for arr in per_ue:
        if not np.all(np.isfinite(arr)) or len(arr) != 210:
            raise ValueError("Missing/invalid static user observations")
    write_csv("fig05_static_per_ue.csv", ["ue_id_0based"] + list(NAMES),
              [(u,) + tuple(float(arr[u]) for arr in per_ue) for u in range(210)])
    quantiles = []
    fig, ax = axes("05 同条件三分支逐UE静态速率CDF", "经验CDF：UE比例", "静态业务容量代理速率（Mbps）")
    for arr, rec, color, label in zip(per_ue, records, COLORS, LABELS):
        q_emp = inverse_cdf(arr)
        q_saved = rec["evaluation"]["experience_bottom5_mbps_valid_ues"]
        if not np.isclose(np.percentile(arr, 5), q_saved, rtol=1e-8, atol=1e-8):
            raise ValueError("Saved linear percentile differs from per-UE values")
        ordered = np.sort(arr)
        ax.step(ordered, np.arange(1, 211) / 210, where="post", lw=1.7,
                color=color, label=f"{label}（n=210；线性5%={q_saved:.3f}）")
        ax.plot(q_emp, np.ceil(.05 * 210) / 210, "o", color=color, ms=5)
        quantiles.append((label, q_emp, q_saved, 210))
    ax.axhline(.05, color="#777777", ls="--", lw=1)
    ax.set_ylim(0, 1.02); ax.legend(loc="upper left", fontsize=8)
    footer(fig, "实心点=经验逆CDF第5%（第11/210个UE）；图例=原存档NumPy线性5%代理；0.34秒，非正式秒级感知率")
    save(fig, "fig05_static_ue_cdf")
    write_csv("fig05_static_quantiles.csv",
              ["branch_zh", "empirical_inverse_cdf_5pct_mbps", "saved_linear_5pct_mbps", "sample_count"], quantiles)

    fig, ax = axes("06 三分支静态底部5%速率代理", "NumPy线性第5百分位（Mbps）", "seed27同场景分支")
    q = [row[2] for row in quantiles]
    ax.bar(np.arange(3), q, color=COLORS, width=.6)
    ax.set_xticks(np.arange(3), LABELS); ax.set_ylim(0, max(q) * 1.2)
    for i, value in enumerate(q):
        ax.text(i, value + .012, f"{value:.6f}", ha="center", fontsize=8)
    footer(fig, "各n=210；同一seed/资源/业务；0.34秒静态代理；单样本不能证明泛化或正式80%验收")
    save(fig, "fig06_static_bottom5")
    write_csv("fig06_static_bottom5.csv", ["branch", "linear_bottom5_mbps", "sample_count"],
              [(name, value, 210) for name, value in zip(NAMES, q)])

    replay = read(REPLAY / "summary.json")["runs"][0]["result"]
    candidate = replay["completed_burst_ue_second_candidate"]
    values = np.asarray([item[0] for item in candidate["per_ue_second_mbps"]
                         if item[0] is not None], float)
    missing = candidate["ue_seconds_without_valid_burst"]
    if len(values) != candidate["valid_ue_second_samples"] or len(values) + missing != 210:
        raise ValueError("Seed22 second-level candidate counts inconsistent")
    write_csv("fig07_seed22_second_candidate.csv", ["sample_policy", "value_mbps"],
              [("valid_only", v) for v in values] + [("missing_as_zero", 0.0) for _ in range(missing)])
    fig, ax = axes("07 独立seed22冻结决策：秒级协议候选CDF", "经验CDF：UE秒比例", "完成burst计数候选（Mbps）")
    for data, color, label in ((values, COLORS[0], f"仅有效样本 n={len(values)}"),
                               (np.r_[values, np.zeros(missing)], COLORS[1], "无样本置零 n=210")):
        ordered = np.sort(data)
        ax.step(ordered, np.arange(1, len(ordered) + 1) / len(ordered),
                where="post", lw=1.8, color=color, label=label)
    ax.axhline(.05, color="#777777", ls="--", lw=1)
    ax.legend(loc="upper left")
    footer(fig, "seed22另一样本；容量/队列完成代理，无ACKed RLC；未完成1589 burst，不能与seed27静态图比较收益")
    save(fig, "fig07_seed22_second_candidate_cdf")
    meta["seed22_second_candidate"] = {"valid": len(values), "missing": missing,
                                       "not_queue_completed": candidate["terminal_bursts_not_queue_completed"]}
    (HERE / "plot_manifest.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"figures": 7, "seed27_static_n": counts,
                      "seed27_linear_bottom5_mbps": q,
                      "seed27_empirical_inverse_cdf_mbps": [row[1] for row in quantiles],
                      "seed22_valid": len(values), "seed22_missing": missing}, ensure_ascii=False))


if __name__ == "__main__":
    main()
