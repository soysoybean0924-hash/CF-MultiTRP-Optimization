"""Export a supplied formal Python scene to the standalone MATLAB port.

This module never generates a scene, schedule or channel. The caller owns the
scene and supplies the exact frozen H, C, service mask and resource metadata.
"""
from pathlib import Path
import numpy as np
from scipy.io import savemat


def export_scene(scene, destination, branch='matrix_nominal', initial_precoders=None):
    cfg = scene.config
    rows = []
    for g, resource in enumerate(scene.resources):
        h = np.asarray(resource.h_true if branch == 'ideal' else resource.h_est,
                       dtype=np.complex128)
        if h.ndim != 4 or h.shape[1] != cfg.trps or h.shape[2:] != (cfg.ue_rx_ports, cfg.tx_ports):
            raise ValueError(f'resource {g}: H axis mismatch')
        serve = np.asarray(resource.serve, dtype=bool)
        if serve.shape != (cfg.trps, h.shape[0]):
            raise ValueError(f'resource {g}: serve axis mismatch')
        if branch in ('ideal', 'matrix_nominal', 'matrix_pf_nominal'):
            cov = np.zeros((h.shape[0],cfg.trps,cfg.ue_rx_ports,cfg.ue_rx_ports),complex)
        elif branch in ('matrix_statistical', 'matrix_pf_statistical'):
            cov = np.asarray(resource.error_var,dtype=np.complex128)
        else:
            raise ValueError(f'unsupported MATLAB export branch: {branch}')
        if cov.shape != (h.shape[0],cfg.trps,cfg.ue_rx_ports,cfg.ue_rx_ports):
            raise ValueError(f'resource {g}: C axis mismatch')
        tx_rb = getattr(resource,'tx_rb_count',None)
        rows.append((h,cov,serve,np.asarray(resource.users,dtype=np.int32)+1,
                     int(resource.rb_count),int(resource.rb_count if tx_rb is None else tx_rb)))
    dtype=[('H','O'),('C','O'),('serve','O'),('ue_ids','O'),
           ('rb_count','O'),('tx_rb_count','O')]
    matlab_resources=np.empty((1,len(rows)),dtype=dtype)
    for g,row in enumerate(rows):
        for (name,_),value in zip(dtype,row): matlab_resources[name][0,g]=value
    options={'rank':int(cfg.rank),'budget':float(cfg.power_watt_per_trp),
             'outer_iterations':int(cfg.outer_iterations),
             'outer_rel_tol':float(cfg.outer_rel_tol),
             'outer_v_tol':float(cfg.outer_precoder_rel_tol),
             'admm_iterations':int(cfg.admm_iterations),
             'cg_iterations':int(cfg.cg_iterations),
             'eps_abs':float(cfg.eps_abs),
             'eps_rel':float(cfg.eps_rel)}
    content={'resources':matlab_resources,'cfg':options,
             'source_seed':int(cfg.seed),'branch':branch}
    if initial_precoders is not None:
        if len(initial_precoders)!=len(rows): raise ValueError('V group count mismatch')
        initial=np.empty((1,len(rows)),dtype=object)
        for g,(v,row) in enumerate(zip(initial_precoders,rows)):
            expected=(cfg.trps,row[0].shape[0],cfg.tx_ports,cfg.rank)
            if np.shape(v)!=expected: raise ValueError(f'V group {g} axis mismatch')
            initial[0,g]=np.asarray(v,dtype=np.complex128)
        content['initialV']=initial
    destination=Path(destination)
    if destination.exists():
        raise FileExistsError(f'refusing to overwrite existing scene input: {destination}')
    destination.parent.mkdir(parents=True,exist_ok=True)
    savemat(destination,content,do_compression=True)
    return {'resources':len(rows),'users_per_resource':[x[0].shape[0] for x in rows],
            'H_shapes':[list(x[0].shape) for x in rows],
            'branch':branch,'seed':int(cfg.seed),'path':str(destination)}
