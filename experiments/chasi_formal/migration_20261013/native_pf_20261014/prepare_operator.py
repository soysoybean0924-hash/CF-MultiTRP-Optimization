"""Reference fixed-U/W quadratic arrays for the same five tiny fixtures."""
from pathlib import Path
import sys
import numpy as np
sys.path.insert(0,str(Path(__file__).resolve().parents[4]))
from chasi_formal_implementation import solver
from chasi_formal_implementation.uniform_error import (
    uniform_group_covariances,uniform_relative_group_covariances)
from prepare_compare import build

HERE=Path(__file__).resolve().parent
cases=[('rank1_nominal',1,'matrix_pf_nominal'),
       ('rank2_nominal',2,'matrix_pf_nominal'),
       ('rank2_uniform',2,'matrix_pf_uniform'),
       ('rank2_relative',2,'matrix_pf_uniform_relative'),
       ('rank2_statistical',2,'matrix_pf_statistical')]
for name,rank,branch in cases:
    _,_,_,scene,vs=build(rank,branch)
    solution=solver.solve(scene,branch=branch,initial_precoders=vs)
    if branch=='matrix_pf_nominal':
        covs=[np.zeros_like(r.error_var) for r in scene.resources]
    elif branch=='matrix_pf_uniform':
        covs=uniform_group_covariances(scene.resources)
    elif branch=='matrix_pf_uniform_relative':
        covs=uniform_relative_group_covariances(scene.resources)
    else:
        covs=[r.error_var for r in scene.resources]
    arrays={}
    for g,(r,c,v,u,w,ww) in enumerate(zip(scene.resources,covs,solution.precoders,
            solution.receivers,solution.weights,solution.final_user_weights)):
        m,b,d=solver._quadratic_parts(r.h_est,c,u,w,v.shape,np.asarray(ww))
        qv=solver._q_apply(r.h_est,m,d,v,r.serve)
        arrays.update({f'M{g}':m,f'B{g}':b,f'D{g}':d,f'QV{g}':qv})
    target=HERE/f'{name}_python_operator.npz'
    if target.exists():raise FileExistsError(target)
    np.savez_compressed(target,**arrays)
