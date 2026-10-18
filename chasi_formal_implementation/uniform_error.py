"""Equal-average-energy homogeneous error baseline within each resource group."""
import numpy as np


def uniform_group_covariances(resources):
    """Keep each group's modeled-link count and aggregate covariance fixed.

    Every nonzero modeled link receives the arithmetic mean 4x4 C_rx for
    that group. Thus the group's total covariance matrix and trace match
    the heterogeneous posterior exactly; this is not a deliberately inflated
    envelope and is not a calibrated real-SRS covariance.
    """
    output=[]
    for r in resources:
        original=np.asarray(r.error_var,dtype=np.complex128)
        active=np.any(np.abs(original)>0,axis=(-2,-1))
        uniform=np.zeros_like(original)
        if np.any(active):
            mean=np.mean(original[active],axis=0)
            mean=(mean+mean.conj().T)/2
            uniform[active]=mean
        output.append(uniform)
    return output


def uniform_relative_group_covariances(resources):
    """Equal relative C_rx/prior_gain, preserving each group's total C_rx.

    This is a link-scale-aware homogeneous baseline: it uses only the
    optimizer-visible prior gain, never a held-out instantaneous channel.
    """
    output=[]
    for r in resources:
        original=np.asarray(r.error_var,dtype=np.complex128)
        gain=np.asarray(r.prior_gain,dtype=float)
        active=np.any(np.abs(original)>0,axis=(-2,-1))
        uniform=np.zeros_like(original)
        if np.any(active):
            if np.any(~np.isfinite(gain[active])) or np.any(gain[active]<=0):
                raise ValueError('modeled nonzero error must have positive finite prior gain')
            relative=original[active].sum(axis=0)/gain[active].sum()
            relative=(relative+relative.conj().T)/2
            uniform[active]=gain[active,None,None]*relative
        output.append(uniform)
    return output
