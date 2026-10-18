"""Separate per-burst samples requested by the supplied protocol slide."""
import numpy as np


def burst_samples(delivered_bits_tti, busy_tti, terminal_tti, tti_ms=1.0):
    delivered=np.asarray(delivered_bits_tti,float)
    busy=np.asarray(busy_tti,bool)
    terminal=np.asarray(terminal_tti,bool)
    if delivered.shape!=busy.shape or terminal.shape!=busy.shape or busy.ndim!=2:
        raise ValueError('matching [UE,TTI] inputs required')
    rates=[]
    per_ue=[]
    empty=0
    incomplete=0
    for u in range(busy.shape[0]):
        ue_rates=[]
        bits=0.0
        count=0
        open_burst=False
        for t in range(busy.shape[1]):
            if busy[u,t]:
                open_burst=True
                if not terminal[u,t]:
                    bits+=delivered[u,t]
                    count+=1
            if terminal[u,t]:
                if count:
                    value=bits/(count*tti_ms/1000)/1e6
                    ue_rates.append(float(value))
                    rates.append(float(value))
                else:
                    empty+=1
                bits=0.0
                count=0
                open_burst=False
        if open_burst:
            incomplete+=1
        per_ue.append(ue_rates)
    return {'valid_burst_samples':len(rates),
            'bursts_without_valid_tti':empty,
            'unfinished_bursts_excluded':incomplete,
            'bottom5_mbps_across_bursts':float(np.percentile(rates,5)) if rates else None,
            'mean_mbps_across_bursts':float(np.mean(rates)) if rates else None,
            'per_ue_burst_mbps':per_ue,
            'scope':'one sample per simulated burst, excluding final TTI; not yet official UE-second CDF or packet counter'}
