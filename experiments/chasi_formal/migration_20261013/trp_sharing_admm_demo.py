"""Serial simulation of TRP-local sharing ADMM for one fixed-U/W resource.

Each TRP owns its physical V_l and local H_:,l. The coordinator owns z_l,
the sum of effective contributions and M_k. No equality of physical V_l is
imposed. This is a tiny proof of the split, not parallel deployment.
"""
from pathlib import Path
import json
import sys
from types import SimpleNamespace
import numpy as np
from scipy.optimize import minimize

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[2]))
from chasi_formal_implementation import solver as ref  # noqa: E402

rng = np.random.default_rng(7318)
K, L, Nr, Nt, d = 2, 3, 4, 2, 1
h = (rng.normal(size=(K,L,Nr,Nt))+1j*rng.normal(size=(K,L,Nr,Nt)))/3
c = np.zeros((K,L,Nr,Nr),complex)
v0 = (rng.normal(size=(L,K,Nt,d))+1j*rng.normal(size=(L,K,Nt,d)))/4
mask = np.ones((L,K),bool)
r = SimpleNamespace(rb_count=16,tx_rb_count=16)
weight=16/273; budget=.11
u,w,_=ref._state(h,c,v0)
m,b,diag=ref._quadratic_parts(h,c,u,w,v0.shape)
vshape=(K,Nt,d); yshape=(K,K,Nr,d)
nv=np.prod(vshape); ny=np.prod(yshape)

def operator(l):
    A=np.zeros((ny,nv),complex)
    for j in range(nv):
        x=np.zeros(vshape,complex);x.flat[j]=1
        y=np.zeros(yshape,complex)
        for k in range(K):
            for i in range(K): y[k,i]=h[k,l]@x[i]
        A[:,j]=y.ravel()
    return A

A=[operator(l) for l in range(L)]
M=np.zeros((ny,ny),complex)
for k in range(K):
    for i in range(K):
        for r1 in range(Nr):
            for r2 in range(Nr):
                a=np.ravel_multi_index((k,i,r1,0),yshape)
                bb=np.ravel_multi_index((k,i,r2,0),yshape)
                M[a,bb]=m[k,r1,r2]
M*=weight
B=[(weight*b[l]).ravel() for l in range(L)]
D=[weight*diag[l] for l in range(L)]

def objective(v):
    return ref._v_objective([r],[h],[mask],[(m,b,diag)],[v])

def xlocal(l,target,rho):
    # Exact local quadratic update with one scalar power multiplier.
    lhs=D[l]*np.eye(nv)+(rho/2)*(A[l].conj().T@A[l])
    rhs=B[l]+(rho/2)*A[l].conj().T@target
    def candidate(lam): return np.linalg.solve(lhs+lam*weight*np.eye(nv),rhs)
    x=candidate(0)
    if weight*np.vdot(x,x).real <= budget: return x
    low=0.;high=1.
    while weight*np.vdot(candidate(high),candidate(high)).real>budget:high*=2
    for _ in range(55):
        mid=(low+high)/2
        if weight*np.vdot(candidate(mid),candidate(mid)).real>budget:low=mid
        else:high=mid
    return candidate(high)

rho=.4
x=[v0[l].ravel().copy() for l in range(L)]
z=[A[l]@x[l] for l in range(L)]
dual=[np.zeros(ny,complex) for _ in range(L)]
history=[]
for it in range(1,1201):
    for l in range(L):
        x[l]=xlocal(l,z[l]-dual[l],rho)  # serial; mathematically independent
    y=[A[l]@x[l] for l in range(L)]
    t=[y[l]+dual[l] for l in range(L)]
    T=sum(t)
    total=np.linalg.solve(M+(rho/(2*L))*np.eye(ny),(rho/(2*L))*T)
    correction=(total-T)/L
    old=z
    z=[t[l]+correction for l in range(L)]
    dual=[dual[l]+y[l]-z[l] for l in range(L)]
    primal=float(np.sqrt(sum(np.vdot(y[l]-z[l],y[l]-z[l]).real for l in range(L))))
    dualres=float(rho*np.sqrt(sum(np.vdot(z[l]-old[l],z[l]-old[l]).real for l in range(L))))
    if it in (1,10,100,500) or (primal<1e-7 and dualres<1e-7):
        history.append({'iteration':it,'primal':primal,'dual':dualres})
    if primal<1e-7 and dualres<1e-7:break

distributed=np.stack([xx.reshape(vshape) for xx in x])
shape=v0.shape;size=v0.size
def unpack(q):
    return (q[:size]+1j*q[size:]).reshape(shape)
def pack(v):return np.r_[v.ravel().real,v.ravel().imag]
central=minimize(lambda q:objective(unpack(q)),pack(v0),method='SLSQP',
    constraints=[{'type':'ineq','fun':lambda q,l=l:budget-weight*np.vdot(unpack(q)[l],unpack(q)[l]).real}
                 for l in range(L)],options={'ftol':1e-12,'maxiter':1000})
if not central.success:raise RuntimeError(central.message)
p=weight*np.sum(abs(distributed)**2,axis=(1,2,3))
result={'TRPs':L,'UEs':K,'resource_rb':16,'budget_watt':budget,
        'local_update_execution':'serial simulation, independent local x_l solves',
        'coordinator_message':'one complex effective contribution tensor per TRP per iteration',
        'complex_elements_per_TRP_one_way':int(ny),
        'bytes_per_TRP_one_way_complex128':int(ny*16),
        'iterations':it,'distributed_objective':objective(distributed),
        'central_slsqp_objective':central.fun,
        'absolute_objective_gap':abs(objective(distributed)-central.fun),
        'power_watt':p.tolist(),'consistency_primal':primal,
        'consistency_dual':dualres,'trace':history}
(HERE/'trp_sharing_admm_result.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
print(json.dumps(result,indent=2))
assert max(p)<=budget+1e-9
assert abs(objective(distributed)-central.fun)<2e-4
