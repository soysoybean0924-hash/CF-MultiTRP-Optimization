"""Explicit, non-acceptance Chasi throughput-counter contract.

The inputs are simulated delivered-capacity bits, not ACKed RLC SDU counters.
Only bursts wholly contained in a complete second contribute to the new
UE-second candidate. The legacy throughput proxies remain separate.
"""
import numpy as np


def cdf_candidates(values_mbps, fraction=0.05, missing_count=0):
    """Report inverse empirical CDF, linear percentile, and lower-tail mean.

    Missing observations are reported both excluded and zero-filled; neither
    policy is asserted to be the acceptance definition.
    """
    values = np.asarray(values_mbps, dtype=float).ravel()
    if not 0 < fraction <= 1 or missing_count < 0:
        raise ValueError('invalid fraction or missing count')
    if np.any(~np.isfinite(values)) or np.any(values < 0):
        raise ValueError('values must be finite nonnegative Mbps')

    def metrics(data):
        if not data.size:
            return {'sample_count': 0, 'empirical_inverse_cdf_mbps': None,
                    'linear_percentile_mbps': None, 'lower_tail_mean_mbps': None,
                    'lower_tail_count': 0}
        ordered = np.sort(data)
        count = max(1, int(np.ceil(fraction * len(ordered))))
        return {'sample_count': int(len(ordered)),
                'empirical_inverse_cdf_mbps': float(ordered[count - 1]),
                'linear_percentile_mbps': float(np.percentile(ordered, 100 * fraction)),
                'lower_tail_mean_mbps': float(np.mean(ordered[:count])),
                'lower_tail_count': count}

    return {'fraction': fraction, 'valid_only': metrics(values),
            'missing_as_zero': metrics(np.r_[values, np.zeros(missing_count)]),
            'missing_count': int(missing_count),
            'acceptance_missing_policy': None}


def completed_burst_ue_second_candidates(delivered_bits_tti, busy_tti,
                                         terminal_tti, tti_ms=1.0,
                                         completed_tti=None):
    """Compute auditable UE-second candidates from complete in-second bursts.

    A terminal TTI is not counted. Open or cross-second bursts are censored.
    A zero-service but eligible burst is a valid zero-rate observation.
    """
    delivered = np.asarray(delivered_bits_tti, dtype=float)
    busy = np.asarray(busy_tti, dtype=bool)
    terminal = np.asarray(terminal_tti, dtype=bool)
    if delivered.ndim != 2 or delivered.shape != busy.shape or busy.shape != terminal.shape:
        raise ValueError('expected matching [UE, TTI] arrays')
    if not np.all(np.isfinite(delivered)) or np.any(delivered < 0):
        raise ValueError('delivered bits must be finite and nonnegative')
    if np.any(terminal & ~busy):
        raise ValueError('terminal TTI must be busy')
    completed = terminal if completed_tti is None else np.asarray(completed_tti, dtype=bool)
    if completed.shape != terminal.shape or np.any(completed & ~terminal):
        raise ValueError('completed TTI must be a subset of terminal TTI')
    if tti_ms <= 0:
        raise ValueError('TTI duration must be positive')
    tti_per_second = 1000 / tti_ms
    if abs(tti_per_second - round(tti_per_second)) > 1e-9:
        raise ValueError('one second must contain an integer number of TTIs')
    tti_per_second = int(round(tti_per_second))
    users, total_tti = busy.shape
    complete_seconds = total_tti // tti_per_second
    samples = np.full((users, complete_seconds), np.nan)
    eligible_counts = np.zeros_like(samples, dtype=int)
    completed_counts = np.zeros_like(samples, dtype=int)
    censored_cross_second = 0
    censored_open = 0
    terminal_only = 0
    not_queue_completed = 0
    for user in range(users):
        active = False
        start = 0
        bits = 0.0
        eligible = 0
        for t in range(total_tti):
            if busy[user, t] and not active:
                active, start, bits, eligible = True, t, 0.0, 0
            if not active:
                continue
            if busy[user, t] and not terminal[user, t]:
                bits += delivered[user, t]
                eligible += 1
            if terminal[user, t]:
                start_second = start // tti_per_second
                end_second = t // tti_per_second
                if not completed[user, t]:
                    not_queue_completed += 1
                elif eligible == 0:
                    terminal_only += 1
                elif start_second == end_second and end_second < complete_seconds:
                    s = start_second
                    if not np.isfinite(samples[user, s]):
                        samples[user, s] = 0.0
                    # Temporarily hold bits, then normalize by eligible duration.
                    samples[user, s] += bits
                    eligible_counts[user, s] += eligible
                    completed_counts[user, s] += 1
                else:
                    censored_cross_second += 1
                active = False
        if active:
            censored_open += 1
    valid = eligible_counts > 0
    samples[valid] /= eligible_counts[valid] * tti_ms / 1000 * 1e6
    vals = samples[valid]
    cdf = cdf_candidates(vals, missing_count=int(samples.size - vals.size))
    return {'counter_scope': 'simulated capacity/queue proxy, not ACKed RLC SDU',
            'aggregation': 'completed bursts wholly within each complete UE-second',
            'complete_seconds': complete_seconds,
            'potential_ue_second_samples': int(samples.size),
            'valid_ue_second_samples': int(vals.size),
            'ue_seconds_without_valid_burst': int(samples.size - vals.size),
            'completed_bursts_counted': int(completed_counts.sum()),
            'terminal_bursts_not_queue_completed': int(not_queue_completed),
            'bursts_crossing_second_censored': int(censored_cross_second),
            'unfinished_bursts_censored': int(censored_open),
            'terminal_only_bursts': int(terminal_only),
            'discarded_partial_window_tti': int(total_tti - complete_seconds * tti_per_second),
            'cdf_candidates': cdf,
            'per_ue_second_mbps': [[None if not np.isfinite(x) else float(x)
                                    for x in row] for row in samples],
            'per_ue_second_eligible_tti': eligible_counts.tolist(),
            'per_ue_second_completed_bursts': completed_counts.tolist(),
            'formal_edge_mbps': None,
            'formal_edge_unresolved_reason': 'ACKed RLC counter, cross-second burst handling, missing-user policy and CDF quantile convention are not specified by supplied image'}


def acceptance_contract():
    """Machine-readable boundaries for the official measurement contract."""
    return {'system_srs_sinr_db': None,
            'system_srs_sinr_unresolved_reason': 'receiver, pilot/power assignment, link/time aggregation and interference scope not specified',
            'traffic_load_30_percent_pass': None,
            'traffic_load_unresolved_reason': 'official numerator, denominator and interval not specified; UE x TTI busy fraction is a proxy',
            'formal_edge_mbps': None,
            'acceptance_80_percent_pass': None,
            'acceptance_80_percent_interpretation': 'relative improvement: (candidate_edge-baseline_edge)/(ideal_central_edge-baseline_edge) >= 0.80',
            'acceptance_80_percent_reference': 'ideal-CSI centralized cooperation at 50% PRB',
            'acceptance_80_percent_unresolved_reason': 'formal edge samples, common baseline for this item, eligible UE rule and ideal-CSI reference convergence are not established'}
