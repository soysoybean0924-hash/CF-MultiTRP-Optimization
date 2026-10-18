"""Controlled alternate initial V policies; no H_true or evaluation feedback."""
import numpy as np
from .solver import _project


def vary_initial(scene, precoders, masks, mode='svd', seed=0):
    if mode not in ('svd','home_biased','jittered'):
        raise ValueError('unknown initial V policy')
    if mode=='svd':
        return [v.copy() for v in precoders]
    rng=np.random.default_rng(seed)
    out=[]
    for r,v,mask in zip(scene.resources,precoders,masks):
        x=v.copy()
        if mode=='home_biased':
            for ki,u in enumerate(r.users):
                for l in np.flatnonzero(mask[:,ki]):
                    x[l,ki]*=(1.5 if l==scene.home[u] else 0.5)
        else:
            noise=(rng.standard_normal(x.shape)+1j*rng.standard_normal(x.shape))/np.sqrt(2*x.shape[2])
            x+=0.15*noise*mask[:,:,None,None]
        out.append(x)
    return _project(scene.resources,out,scene.config.power_watt_per_trp,masks)
