"""Link-level CDL response adapter for the existing H[K,L,4,64] contract.

The caller supplies persistent CdlLink objects, path gains and the RB group.
No SRS posterior or scene generation is inferred here. A group-center sample
cannot stand in for per-RB physical-rate validation.
"""
import numpy as np


def cdl_group_h(links, gains, rb_start, rb_count, scs_hz, time_s=0.0):
    links=np.asarray(links,dtype=object)
    gains=np.asarray(gains,dtype=float)
    if links.ndim!=2 or gains.shape!=links.shape:
        raise ValueError('links and gains must have matching [K,L] axes')
    if np.any(gains<0) or not np.all(np.isfinite(gains)):
        raise ValueError('gains must be finite and nonnegative')
    out=np.empty((*links.shape,4,64),np.complex128)
    for k in range(links.shape[0]):
        for l in range(links.shape[1]):
            h=links[k,l].resource_response(rb_start,rb_count,scs_hz,
                                           gain=float(gains[k,l]),time_s=time_s)
            if np.shape(h)!=(4,64) or not np.all(np.isfinite(h)):
                raise ValueError(f'CDL link ({k},{l}) returned invalid H')
            out[k,l]=h
    return out
