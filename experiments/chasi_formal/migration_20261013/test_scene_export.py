"""Small explicit-scene export contract test; no scene is generated."""
from pathlib import Path
from types import SimpleNamespace
from tempfile import TemporaryDirectory
import numpy as np
from scipy.io import loadmat
from export_scene_to_matlab import export_scene

here=Path(__file__).resolve().parent
fixture=loadmat(here/'matlab_fixture_input.mat',simplify_cells=True)
raw=np.ravel(fixture['resources'])
resources=[]
for row in raw:
    resources.append(SimpleNamespace(h_est=row['H'],h_true=row['H']*1.01,
        error_var=row['C'],serve=row['serve'],users=np.array([0,1]),
        rb_count=int(row['rb_count']),tx_rb_count=int(row['tx_rb_count'])))
cfg=SimpleNamespace(trps=2,ue_rx_ports=4,tx_ports=4,rank=1,seed=7402,
    power_watt_per_trp=.11,outer_iterations=2,outer_rel_tol=1e-4,
    outer_precoder_rel_tol=.005,admm_iterations=80,cg_iterations=80,
    eps_abs=1e-6,eps_rel=1e-5)
scene=SimpleNamespace(config=cfg,resources=resources)
vs=[np.asarray(v)[...,None] for v in np.ravel(fixture['initialV'])]
with TemporaryDirectory() as tmp:
    dest=Path(tmp)/'supplied_scene.mat'
    meta=export_scene(scene,dest,'matrix_statistical',vs)
    got=loadmat(dest,simplify_cells=True)
    rows=np.ravel(got['resources'])
    assert len(rows)==2 and meta['H_shapes']==[[2,2,4,4]]*2
    for old,new in zip(resources,rows):
        assert np.array_equal(old.h_est,new['H'])
        assert np.array_equal(old.error_var,new['C'])
        assert np.array_equal(old.serve,new['serve'])
        assert np.array_equal(new['ue_ids'],[1,2])
        assert old.tx_rb_count==new['tx_rb_count']
    assert np.allclose(np.ravel(got['initialV'])[0],vs[0][...,0])
print('PASS: supplied H/C/serve/UE IDs/RB/initial V preserved in MATLAB input')
