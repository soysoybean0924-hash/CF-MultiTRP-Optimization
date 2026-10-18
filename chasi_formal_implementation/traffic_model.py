"""Explicit, reproducible traffic traces; no radio decisions are made here."""
import numpy as np


def generate_traffic(users, duration_tti, seed, mode='legacy_bursts',
                     busy_fraction_target=0.30):
    """Return busy/tail/terminal masks for a half-open TTI window.

    The target mode defines load narrowly as UE×TTI buffer-nonempty duty
    fraction. This is an implementation hypothesis, not a confirmed Huawei
    offered-traffic-load or PRB-occupancy definition.
    """
    if mode not in ('legacy_bursts', 'target_busy_fraction'):
        raise ValueError('unknown traffic mode')
    if not 0 < busy_fraction_target < 1:
        raise ValueError('busy_fraction_target must lie in (0,1)')
    rng = np.random.default_rng(seed + 303)
    busy = np.zeros((users, duration_tti), bool)
    tail = np.zeros_like(busy)
    terminal = np.zeros_like(busy)
    for u in range(users):
        t = 0
        while t < duration_tti:
            if mode == 'legacy_bursts':
                gap = int(rng.integers(1, 6))
            else:
                # Expected burst length is 20 TTIs. The geometric idle gap
                # has mean 20(1-p)/p, giving long-run busy duty p.
                mean_gap = 20.0 * (1.0 - busy_fraction_target) / busy_fraction_target
                gap = int(rng.geometric(1.0 / (mean_gap + 1.0)) - 1)
            t += gap
            if t >= duration_tti:
                break
            length = int(rng.integers(10, 31))
            end = min(t + length, duration_tti)
            busy[u, t:end] = True
            tail_start = t + int(np.floor(0.4 * (end-t)))
            tail[u, tail_start:end] = True
            terminal[u, end-1] = True
            t = end
    return busy, tail, terminal
