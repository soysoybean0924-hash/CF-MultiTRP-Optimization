"""Independent dense SLSQP reference for the fixed U/W multi-RB V subproblem."""
from types import SimpleNamespace
import numpy as np
from scipy.optimize import minimize
from .solver import (_state, _quadratic_parts, _solve_v_admm,
                     _v_objective, power_by_trp, _weight)


def main():
    partial=SimpleNamespace(rb_count=16,tx_rb_count=7)
    assert _weight(partial)==7/273
    assert np.isclose(power_by_trp([partial],[np.ones((2,1,1,1))])[0],7/273)
    rng=np.random.default_rng(7402)
    resources=[SimpleNamespace(rb_count=n) for n in (16,17)]
    hs=[(rng.normal(size=(2,2,4,2))+1j*rng.normal(size=(2,2,4,2)))/3
        for _ in resources]
    masks=[np.ones((2,2),bool) for _ in resources]
    cov=[np.zeros((2,2,4,4),complex) for _ in resources]
    vs=[(rng.normal(size=(2,2,2,1))+1j*rng.normal(size=(2,2,2,1)))/3
        for _ in resources]
    parts=[];dense=[]
    for h,e,v in zip(hs,cov,vs):
        u,w,_=_state(h,e,v)
        base=_quadratic_parts(h,e,u,w,v.shape)
        doubled=_quadratic_parts(h,e,u,w,v.shape,np.full(2,2.0))
        assert all(np.allclose(b,2*a) for a,b in zip(base,doubled))
        uneven=np.array([0.4,2.0])
        wm,wb,wd=_quadratic_parts(h,e,u,w,v.shape,uneven)
        assert np.allclose(wm,base[0]*uneven[:,None,None])
        assert np.allclose(wb,base[1]*uneven[None,:,None,None])
        assert np.allclose(wd,0)
        parts.append(base)
        # Independently form Q and B from the literal coherent interference sum.
        q=np.zeros((2,2,2,2),complex)
        b=np.zeros((2,2,2),complex)
        for l in range(2):
            for j in range(2):
                for k in range(2):
                    m=u[k]@w[k]@u[k].conj().T
                    q[l,j]+=h[k,l].conj().T@m@h[k,j]
            for i in range(2):
                b[l,i]=h[i,l].conj().T@u[i]@w[i][:,0]
        dense.append((q,b))
    budget=0.11
    candidate,trace,converged=_solve_v_admm(resources,hs,masks,parts,vs,budget,
                                              600,40,1e-9,1e-8,rho=.05)
    shape=vs[0].shape
    size=vs[0].size
    def unpack(x):
        z=x[:2*size]+1j*x[2*size:]
        return [z[:size].reshape(shape),z[size:].reshape(shape)]
    def objective(x):
        vv=unpack(x)
        value=0.
        for r,(q,b),v in zip(resources,dense,vv):
            for i in range(2):
                for l in range(2):
                    value-=2*(b[l,i].conj()@v[l,i,:,0]).real*r.rb_count/273
                    for j in range(2):
                        value+=(v[l,i,:,0].conj()@q[l,j]@v[j,i,:,0]).real*r.rb_count/273
        return value
    def constraint(x,l):
        vv=unpack(x)
        return budget-sum(r.rb_count/273*np.vdot(v[l],v[l]).real
                          for r,v in zip(resources,vv))
    start=np.concatenate([np.concatenate([v.ravel().real for v in vs]),
                          np.concatenate([v.ravel().imag for v in vs])])
    ref=minimize(objective,start,method='SLSQP',
                 constraints=[{'type':'ineq','fun':lambda x,l=l:constraint(x,l)} for l in range(2)],
                 options={'ftol':1e-12,'maxiter':1000})
    assert ref.success,ref.message
    got=_v_objective(resources,hs,masks,parts,candidate)
    assert abs(got-objective(np.concatenate([np.concatenate([v.ravel().real for v in candidate]),
                                              np.concatenate([v.ravel().imag for v in candidate])])))<1e-9
    assert abs(got-ref.fun)<2e-5,(got,ref.fun,trace[-1])
    assert max(power_by_trp(resources,candidate))<=budget+1e-9
    print({'status':'passed','admm_objective':got,'independent_slsqp_objective':ref.fun,
           'absolute_gap':abs(got-ref.fun),'iterations':len(trace),
           'admm_converged_under_strict_test_tolerance':converged,
           'last_primal':trace[-1]['primal_residual'],
           'last_dual':trace[-1]['dual_residual']})


if __name__=='__main__':main()
