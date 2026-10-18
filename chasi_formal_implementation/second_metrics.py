"""Burst-filtered complete-second UE samples; explicit proxy, not BLER/MCS counters."""
import numpy as np


def second_level_samples(delivered_bits_tti, busy_tti, terminal_tti, tti_ms=1.0):
    delivered = np.asarray(delivered_bits_tti, float)
    busy = np.asarray(busy_tti, bool)
    terminal = np.asarray(terminal_tti, bool)
    if delivered.shape != busy.shape or terminal.shape != busy.shape or delivered.ndim != 2:
        raise ValueError('expected matching [UE, TTI] arrays')
    per_second = 1000.0 / tti_ms
    if abs(per_second - round(per_second)) > 1e-9:
        raise ValueError('one second must contain an integer number of TTIs')
    per_second = int(round(per_second))
    users, total = busy.shape
    complete = total // per_second
    eligible = busy & ~terminal
    samples = np.full((users, complete), np.nan)
    valid_counts = np.zeros((users, complete), int)
    for s in range(complete):
        sl = slice(s*per_second, (s+1)*per_second)
        valid = eligible[:, sl]
        count = valid.sum(axis=1)
        valid_counts[:, s] = count
        bits = np.sum(delivered[:, sl]*valid, axis=1)
        np.divide(bits, count*tti_ms/1000, out=samples[:, s], where=count>0)
    valid_samples = samples[np.isfinite(samples)]
    return {'complete_seconds': complete,
            'discarded_partial_window_tti': total-complete*per_second,
            'potential_ue_second_samples': users*complete,
            'valid_ue_second_samples': int(valid_samples.size),
            'ue_second_samples_without_valid_tti': int(users*complete-valid_samples.size),
            'excluded_buffer_empty_tti': int(np.sum(~busy[:, :complete*per_second])),
            'excluded_burst_terminal_tti': int(np.sum(terminal[:, :complete*per_second])),
            'valid_tti_total': int(np.sum(valid_counts)),
            'bottom5_mbps_valid_ue_seconds': float(np.percentile(valid_samples/1e6, 5)) if valid_samples.size else None,
            'mean_mbps_valid_ue_seconds': float(np.mean(valid_samples/1e6)) if valid_samples.size else None,
            'per_ue_second_mbps': [[None if not np.isfinite(v) else float(v/1e6) for v in row] for row in samples],
            'per_ue_second_valid_tti': valid_counts.tolist(),
            'scope': 'full-second burst-filtered simulator throughput proxy; no BLER/MCS/official counter agreement'}
