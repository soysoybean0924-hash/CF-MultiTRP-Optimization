"""Explicit small complex fixtures for the native MATLAB/Python PF comparison."""
from pathlib import Path
from types import SimpleNamespace
import json
import sys
import numpy as np
from scipy.io import savemat
sys.path.insert(0,str(Path(__file__).resolve().parents[4]))
from chasi_formal_implementation import solver

HERE = Path(__file__).resolve().parent
K, L, NR, NT, G = 2, 2, 4, 4, 2
FIELDS = [('H','O'),('H_true','O'),('C','O'),('C_stat','O'),
          ('serve','O'),('ue_ids','O'),('rb_count','O'),
          ('tx_rb_count','O'),('prior_gain','O')]


def build(rank, branch):
    resources=[]
    matlab=np.empty((1,G),dtype=FIELDS)
    initial=np.empty((1,G),dtype=object)
    for g in range(G):
        h=np.zeros((K,L,NR,NT),complex)
        c=np.zeros((K,L,NR,NR),complex)
        v=np.zeros((L,K,NT,rank),complex)
        for k in range(K):
            for l in range(L):
                for r in range(NR):
                    for n in range(NT):
                        h[k,l,r,n]=(.13+.025*(k+1)+.018*(l+1)+.008*(r+1)+.004*(n+1))*np.exp(1j*(.17*(k+1)-.11*(l+1)+.07*(r+1)+.09*(n+1)+.03*(g+1)))
                    c[k,l,r,r]=.002*(1+.1*(k+1)+.2*(l+1))
                for n in range(NT):
                    v[l,k,n,0]=.2*np.exp(1j*(.2*(l+1)+.3*(k+1)+.1*(n+1)+.04*(g+1)))
                    if rank==2:
                        v[l,k,n,1]=.08*np.exp(1j*(.4*(l+1)-.2*(k+1)+.13*(n+1)))
        true=h*(1.02+0.01j)
        gain=np.mean(abs(h)**2,axis=(2,3))
        serve=np.ones((L,K),bool)
        rb=16+g
        row=(h,true,c,c,serve,np.arange(1,K+1),rb,rb,gain)
        for (name,_),value in zip(FIELDS,row):matlab[name][0,g]=value
        initial[0,g]=v
        resources.append(SimpleNamespace(h_est=h,h_true=true,error_var=c,
            prior_gain=gain,serve=serve,users=np.arange(K),
            rb_count=rb,tx_rb_count=rb))
    opts=dict(rank=rank,budget=.11,users=K,pf_floor=.001,branch=branch,
        outer_iterations=2,outer_rel_tol=1e-4,outer_v_tol=5e-3,
        admm_iterations=80,cg_iterations=80,eps_abs=1e-6,eps_rel=1e-5,rho=.05)
    config=SimpleNamespace(rank=rank,power_watt_per_trp=.11,users=K,
        pf_rate_floor_bits_per_s_hz=.001,outer_iterations=2,
        outer_rel_tol=1e-4,outer_precoder_rel_tol=5e-3,
        admm_iterations=80,cg_iterations=80,eps_abs=1e-6,eps_rel=1e-5)
    return matlab,initial,opts,SimpleNamespace(config=config,resources=resources),[initial[0,g] for g in range(G)]


def create():
    cases=[('rank1_nominal',1,'matrix_pf_nominal'),
           ('rank2_nominal',2,'matrix_pf_nominal'),
           ('rank2_uniform',2,'matrix_pf_uniform'),
           ('rank2_relative',2,'matrix_pf_uniform_relative'),
           ('rank2_statistical',2,'matrix_pf_statistical')]
    report={}
    for name,rank,branch in cases:
        resources,initial,opts,scene,vs=build(rank,branch)
        target=HERE/f'{name}_input.mat'
        if target.exists():raise FileExistsError(target)
        savemat(target,dict(resources=resources,initialV=initial,cfg=opts),do_compression=True)
        observations={}
        for outer in (0,2):
            scene.config.outer_iterations=outer
            solution=solver.solve(scene,branch=branch,initial_precoders=vs)
            observations[str(outer)]={'objective':solution.optimization_objective,
                'estimated_sum':solution.estimated_sum_rate,
                'power':solver.power_by_trp(scene.resources,solution.precoders).tolist(),
                'reason':solution.reason,
                'trajectory':[{'outer':t['outer'],'objective':t['optimization_objective'],
                    'accepted_step':t.get('accepted_step'),
                    'admm_converged':t.get('admm_converged'),
                    'primal':t.get('primal_residual'),'dual':t.get('dual_residual')}
                    for t in solution.trajectory],
                'true_sum':float(sum(solver._weight(r)*sum(solver.rates(r.h_true,v))
                                      for r,v in zip(scene.resources,solution.precoders)))}
            np.savez_compressed(HERE/f'{name}_python_outer{outer}.npz',
                **{f'V{g}':v for g,v in enumerate(solution.precoders)},
                **{f'U{g}':u for g,u in enumerate(solution.receivers)},
                **{f'W{g}':w for g,w in enumerate(solution.weights)})
        report[name]=observations
    (HERE/'python_reference.json').write_text(json.dumps(report,indent=2),encoding='utf-8')


if __name__=='__main__':create()
